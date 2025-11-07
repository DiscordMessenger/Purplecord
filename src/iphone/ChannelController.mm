#import "ChannelController.h"
#import "MessageItem.h"
#import "UIColorScheme.h"
#import "AvatarCache.h"
#include "UIProportions.h"
#include "../discord/DiscordInstance.hpp"

#define MAX_MESSAGE_SIZE 2000
#define MAX_MESSAGE_SIZE_PREMIUM 4000

static bool IsJustWhiteSpace(const char* str)
{
	while (*str)
	{
		if (*str != ' ' && *str != '\r' && *str != '\n' && *str != '\t')
			// Not going to add exceptions for ALL of the characters that Discord thinks are white space.
			// Just assume good faith from the user.  They'll get an "invalid request" response if they
			// try :(
			return false;

		str++;
	}

	return true;
}

static bool ContainsAuthenticationToken(const std::string& str)
{
	const int lengthToken = 58;
	const int placeFirstSep = 23;
	const int placeSecondSep = 30;

	if (str.size() < lengthToken) return false;

	for (size_t i = 0; i <= str.size() - lengthToken; i++)
	{
		if (str[i + placeFirstSep] != L'.' || str[i + placeSecondSep] != L'.')
			continue;

		bool fake = false;
		for (size_t j = 0; j < lengthToken; j++)
		{
			if (j == placeFirstSep || j == placeSecondSep)
				continue;

			if (strchr("0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ-_", (char)str[i + j]) == NULL) {
				fake = true;
				break;
			}
		}

		if (!fake)
			return true;
	}

	return false;
}

ChannelController* g_pChannelController;
ChannelController* GetChannelController() {
	return g_pChannelController;
}

@interface ChannelController () {
	MessageInputView* inputView;
	
	uint64_t guildID;
	uint64_t channelID;
	
	Channel* pChannel;
	
	std::vector<MessagePtr> m_messages;
	
	bool m_doNotLoadMessages;
	bool m_forceReloadAttachments;
	
	bool m_bContextMenuActive;
	NSIndexPath* m_tableIndexPath;
	Snowflake m_contextMenuMessage;
}
@end

@implementation ChannelController

- (instancetype)initWithChannelID:(uint64_t)_channelID andGuildID:(uint64_t)_guildID {
	self = [self init];
	if (!self)
		return self;
	
	guildID = _guildID;
	channelID = _channelID;
	
	Guild* pGuild = GetDiscordInstance()->GetGuild(guildID);
	pChannel = pGuild->GetChannel(channelID);
	
	assert(!g_pChannelController);
	g_pChannelController = self;
	
	return self;
}

// MessageInputView communication
- (BOOL)canBecomeFirstResponder
{
	return YES;
}

- (int)maxMessageLength
{
	// TODO: Detect if user has Nitro and return MAX_MESSAGE_SIZE_PREMIUM
	return MAX_MESSAGE_SIZE;
}

- (void)messageInputView:(MessageInputView *)inputView didSendMessage:(NSString *)messageNS
{
	std::string message([messageNS UTF8String]);
	if (message.empty() || IsJustWhiteSpace(message.c_str()))
		return;
	
	if (ContainsAuthenticationToken(message)) {
		// TODO: Show a UIAlertView then wait.
		DbgPrintF("WARNING: Message contains authentication token!");
	}
	
	// TODO: Reply Support
	// TODO: Edit Support
	
	if (message.size() > [self maxMessageLength]) {
		// TODO: Show a UIAlertView.
		DbgPrintF("WARNING: Message is %zu chars long longer than the maximum of %d!", message.size(), [self maxMessageLength]);
		return;
	}
	
	Snowflake sf;
	if (!GetDiscordInstance()->SendMessageToCurrentChannel(message, sf))
		return;
	
	// Add a temporary message
	MessagePtr m = MakeMessage();
	Profile* pf = GetDiscordInstance()->GetProfile();
	
	m->m_snowflake = sf;
	m->m_author_snowflake = pf->m_snowflake;
	m->m_author = pf->m_name;
	m->m_avatar = pf->m_avatarlnk;
	m->m_message = message;
	m->m_type = MessageType::SENDING_MESSAGE;
	m->SetTime(time(NULL));
	m->m_dateFull = "Sending...";
	m->m_dateCompact = "Sending...";
	
	[self addMessage:m];
}

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	
	CGRect screenBounds = [[UIScreen mainScreen] bounds];
	UIView *mainView = [[UIView alloc] initWithFrame:screenBounds];
	mainView.backgroundColor = [UIColorScheme getBackgroundColor];
	self.view = mainView;
	[mainView release];
	
	CGFloat bottomBarHeight = BOTTOM_BAR_HEIGHT;
	
	CGRect frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height - bottomBarHeight);
	tableView = [[UITableView alloc] initWithFrame:frame style:UITableViewStylePlain];
	tableView.dataSource = self;
	tableView.delegate = self;
	tableView.backgroundColor = [UIColorScheme getBackgroundColor];
	tableView.opaque = YES;
	tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
	[self.view addSubview:tableView];
	
	self.title = [NSString stringWithUTF8String:pChannel->GetFullName().c_str()];
	
	//UIBarButtonItem *toggleButton = [[UIBarButtonItem alloc] initWithTitle:@"Toggle Data Set" style:UIBarButtonItemStylePlain target:self action:@selector(toggleFlag)];
	//self.navigationItem.rightBarButtonItem = toggleButton;
	//[toggleButton release];
	
	inputView = [[MessageInputView alloc] initWithFrame:CGRectZero];
	inputView.delegate = self;
	inputView.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleWidth;
	inputView.frame = CGRectMake(0, self.view.frame.size.height - bottomBarHeight, self.view.frame.size.width, bottomBarHeight);
	
	[self.view addSubview:inputView];
	
	// let us know when the keyboard shows up
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
	
	GetDiscordInstance()->OnSelectChannel(channelID);
	GetDiscordInstance()->HandledChannelSwitch();
	
	[self update];
}

- (void)viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)keyboardWillShow:(NSNotification*)notification
{
	NSDictionary* info = [notification userInfo];
	CGRect keyboardRect = [[info objectForKey:UIKeyboardBoundsUserInfoKey] CGRectValue];
	NSTimeInterval duration = [[info objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue];
	UIViewAnimationCurve curve = (UIViewAnimationCurve) [[info objectForKey:UIKeyboardAnimationCurveUserInfoKey] intValue];
	CGFloat keyboardHeight = keyboardRect.size.height;
	
	[UIView beginAnimations:nil context:NULL];
	[UIView setAnimationDuration:duration];
	[UIView setAnimationCurve:curve];
	
	CGFloat bottomBarHeight = BOTTOM_BAR_HEIGHT;
	inputView.frame = CGRectMake(0, self.view.frame.size.height - bottomBarHeight - keyboardHeight, self.view.frame.size.width, bottomBarHeight);
	
	CGRect tableViewFrame = tableView.frame;
	tableViewFrame.size.height = self.view.frame.size.height - bottomBarHeight - keyboardHeight;
	tableView.frame = tableViewFrame;
	
	[UIView commitAnimations];
	
	[self performSelector:@selector(scrollToBottom) withObject:nil afterDelay:0.01];
}

- (void)keyboardWillHide:(NSNotification*)notification
{
	NSDictionary* info = [notification userInfo];
	NSTimeInterval duration = [[info objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue];
	UIViewAnimationCurve curve = (UIViewAnimationCurve) [[info objectForKey:UIKeyboardAnimationCurveUserInfoKey] intValue];
	
	[UIView beginAnimations:nil context:NULL];
	[UIView setAnimationDuration:duration];
	[UIView setAnimationCurve:curve];
	
	CGFloat bottomBarHeight = BOTTOM_BAR_HEIGHT;
	inputView.frame = CGRectMake(0, self.view.frame.size.height - bottomBarHeight, self.view.frame.size.width, bottomBarHeight);
	
	CGRect tableViewFrame = tableView.frame;
	tableViewFrame.size.height = self.view.frame.size.height - bottomBarHeight;
	tableView.frame = tableViewFrame;
	
	[UIView commitAnimations];
}

- (void)refreshMessages:(ScrollDir::eScrollDir)sd withGapCulprit:(Snowflake)gapCulprit
{
	Profiler profiler("- [ChannelController refreshMessages:withGapCulprit:]");
	tableView.scrollEnabled = NO;
	
	[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
	
	size_t oldMessageCount = m_messages.size();
	CGFloat oldContentHeight = tableView.contentSize.height;
	CGFloat oldOffsetY = tableView.contentOffset.y;
	CGFloat distanceFromBottom = oldContentHeight - oldOffsetY;
	
	// TODO: Keep the scroll position
	// TODO: Imitate what DM does
	m_messages.clear();
	GetMessageCache()->GetLoadedMessages(channelID, guildID, m_messages);
	
	m_doNotLoadMessages = true;
	
	BeginProfiling("ChannelController: reloadData in refreshMessages");
	[tableView reloadData];
	EndProfiling();
	
	if (oldMessageCount < 2 || distanceFromBottom < tableView.frame.size.height)
	{
		// scroll to the bottom
		if (m_messages.size() > 1)
		{
			NSInteger lastRow = (NSInteger)(m_messages.size() - 1);
			NSIndexPath *lastIndexPath = [NSIndexPath indexPathForRow:lastRow inSection:0];
			[tableView scrollToRowAtIndexPath:lastIndexPath atScrollPosition:UITableViewScrollPositionBottom animated:NO];
		}
	}
	else
	{
		// keep the scroll the EXACT same
		CGFloat newOffsetY = tableView.contentSize.height - distanceFromBottom;
		tableView.contentOffset = CGPointMake(0, newOffsetY);
	}
	
	m_doNotLoadMessages = false;
	tableView.scrollEnabled = YES;
}

- (BOOL)isChannelIDActive:(Snowflake)_channelID
{
	return channelID == _channelID;
}

- (void)scrollToBottomAnimated:(BOOL)animated
{
	// scroll to bottom
	if (m_messages.empty())
		return;
	
	NSInteger lastRow = (NSInteger)(m_messages.size() - 1);
	NSIndexPath *lastIndexPath = [NSIndexPath indexPathForRow:lastRow inSection:0];
	[tableView scrollToRowAtIndexPath:lastIndexPath atScrollPosition:UITableViewScrollPositionBottom animated:animated];
}

- (void)scrollToBottom
{
	[self scrollToBottomAnimated:YES];
}

- (void)scrollToBottomIfNeeded
{
	Profiler profiler("- [ChannelController scrollToBottomIfNeeded]");
	
	// Figure out if we need to scroll to bottom or not
	CGFloat oldContentHeight = tableView.contentSize.height;
	CGFloat oldOffsetY = tableView.contentOffset.y;
	CGFloat distanceFromBottom = oldContentHeight - oldOffsetY;
	
	if (distanceFromBottom < 2000)
		[self performSelector:@selector(scrollToBottom) withObject:nil afterDelay:0];
}

- (void)onAddedRowAtIndex:(size_t)index animated:(BOOL)animated
{
	auto anim = UITableViewRowAnimationNone;
	if (animated)
		anim = UITableViewRowAnimationRight;
	
	NSIndexPath* indexPath = [NSIndexPath indexPathForRow:(NSInteger)index inSection:0];
	[tableView insertRowsAtIndexPaths:@[indexPath] withRowAnimation:anim];
}

- (void)onUpdatedRowAtIndex:(size_t)index animated:(BOOL)animated
{
	auto anim = UITableViewRowAnimationNone;
	if (animated)
		anim = UITableViewRowAnimationRight;
	
	NSIndexPath* indexPath = [NSIndexPath indexPathForRow:(NSInteger)index inSection:0];
	[tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:anim];
}

- (void)onRemovedRowAtIndex:(size_t) index animated:(BOOL)animated
{
	auto anim = UITableViewRowAnimationNone;
	if (animated)
		anim = UITableViewRowAnimationRight;
	
	NSIndexPath* indexPath = [NSIndexPath indexPathForRow:(NSInteger)index inSection:0];
	[tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:anim];
}

- (void)addMessage:(MessagePtr)message
{
	if (message->m_anchor)
	{
		// if the message can't be found come back here with anchor reset
		[self updateMessageById:message->m_anchor message:message];
		return;
	}
	
	m_messages.push_back(message);
	[self onAddedRowAtIndex:m_messages.size() - 1 animated:YES];
	[self scrollToBottomIfNeeded];
}

- (void)removeMessage:(Snowflake)messageID
{
	auto iter = std::find_if(m_messages.begin(), m_messages.end(), [messageID] (MessagePtr ptr) {
		return ptr->m_snowflake == messageID;
	});
	
	if (iter == m_messages.end())
	{
		DbgPrintF("Message with id %lld not found for deletion", messageID);
		return;
	}
	
	size_t index = std::distance(m_messages.begin(), iter);
	m_messages.erase(iter);
	
	[self onRemovedRowAtIndex:index animated:YES];
	[self scrollToBottomIfNeeded];
}

- (void)updateMessageById:(Snowflake)messageID message:(MessagePtr)message
{
	auto iter = std::find_if(m_messages.begin(), m_messages.end(), [messageID] (MessagePtr ptr) {
		return ptr->m_snowflake == messageID;
	});
	
	if (iter == m_messages.end())
	{
		DbgPrintF("Message with id %lld not found for update, resorting to add", messageID);
		
		// reset anchor to avoid recursion
		if (message->m_anchor == messageID)
			message->m_anchor = 0;
		
		[self addMessage:message];
		return;
	}
	
	*iter = message;
	
	size_t index = std::distance(m_messages.begin(), iter);
	[self onUpdatedRowAtIndex:index animated:NO];
	[self scrollToBottomIfNeeded];
}

- (void)updateMessage:(MessagePtr)message
{
	[self updateMessageById:message->m_snowflake message:message];
}

- (void)updateMembers:(const std::set<Snowflake>&)members
{
	[tableView beginUpdates];
	
	for (size_t i = 0; i < m_messages.size(); i++)
	{
		auto& msg = m_messages[i];
		if (msg->m_author_snowflake == 0 || msg->IsWebHook())
			continue;
		
		auto iter = members.find(msg->m_author_snowflake);
		if (iter == members.end())
			continue; // no need to refresh
		
		Profile* pf = GetProfileCache()->LookupProfile(*iter, "", "", "", false);
		msg->m_author = pf->GetName(guildID);
		
		[self onUpdatedRowAtIndex:i animated:NO];
	}
	
	[tableView endUpdates];
}

- (void)updateAttachmentByID:(const std::string&)rid
{
	DbgPrintF("updateAttachmentByID: %s", rid.c_str());
	
	// TODO: check for attachments too
	[tableView beginUpdates];
	
	m_forceReloadAttachments = true;
	
	for (size_t i = 0; i < m_messages.size(); i++)
	{
		auto& msg = m_messages[i];
		bool update = false;
		
		if ([GetAvatarCache() makeIdentifier:msg->m_avatar] == rid)
			update = true;
		
		for (auto& attach : msg->m_attachments)
		{
			if (update)
				continue;
			
			if (!attach.IsImage())
				continue;
			
			std::string crid = [GetAvatarCache() makeIdentifier:(
				std::to_string(attach.m_id) +
				attach.m_proxyUrl +
				attach.m_actualUrl
			)];
			
			if (rid == crid)
				update = true;
		}
		
		if (update)
			[self onUpdatedRowAtIndex:i animated:NO];
	}
	
	m_forceReloadAttachments = false;
	
	[tableView endUpdates];
}

- (void)update
{
	[self refreshMessages:ScrollDir::AROUND withGapCulprit:0];
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
	[inputView closeKeyboard];
}

- (NSInteger)tableView:(UITableView *)tv numberOfRowsInSection:(NSInteger)section
{
	return (NSInteger) m_messages.size();
}

- (UITableViewCell *)tableView:(UITableView *)tv cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	if (indexPath.row < 0 || indexPath.row >= (int) m_messages.size())
		return nil;
	
	static NSString *cellId = @"MessageItem";
	MessageItem* item = (MessageItem*) [tv dequeueReusableCellWithIdentifier:cellId];
	if (!item)
		item = [[[MessageItem alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellId] autorelease];
	
	MessagePtr message = m_messages[indexPath.row];
	[item configureWithMessage:message andReload:m_forceReloadAttachments];
	
	item.selectionStyle = UITableViewCellSelectionStyleGray;
	
	return item;
}

- (CGFloat)tableView:(UITableView *)tv heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	if (indexPath.row < 0 || indexPath.row >= (int) m_messages.size())
		return nil;
	
	MessagePtr message = m_messages[indexPath.row];
	if (message->m_cachedHeight)
		return message->m_cachedHeight;
	
	CGFloat height = [MessageItem computeHeightForMessage:message];
	message->m_cachedHeight = height;
	return height;
}

- (void)tableView:(UITableView*)tv willDisplayCell:(UITableViewCell*)cell forRowAtIndexPath:(NSIndexPath*)indexPath
{
	if (m_doNotLoadMessages)
		return;
	
	// If the message is a gap, request it
	MessageItem* item = (MessageItem*) cell;
	
	MessagePtr msg = item.message;
	if (msg->IsLoadGap())
	{
		DbgPrintF("Load gap %lld being rendered!", msg->m_snowflake);
		
		ScrollDir::eScrollDir sd;
		switch (msg->m_type) {
			default:
			case MessageType::GAP_AROUND: sd = ScrollDir::AROUND; break;
			case MessageType::GAP_UP:	 sd = ScrollDir::BEFORE; break;
			case MessageType::GAP_DOWN:   sd = ScrollDir::AFTER; break;
		}

		// gap message - load
		[UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
		GetDiscordInstance()->RequestMessages(
			channelID,
			sd,
			msg->m_anchor,
			msg->m_snowflake
		);
	}
}

#define DELETE_NAME    @"Delete"
#define COPY_TEXT_NAME @"Copy Text"
#define PIN_NAME       @"Pin"
#define EDIT_NAME      @"Edit"
#define REPLY_NAME     @"Reply"
#define CANCEL_NAME    @"Cancel"

- (void)tableView:(UITableView *)tv didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	UITableViewCell* cell = [tableView cellForRowAtIndexPath:indexPath];
	if (!cell) return;
	
	MessageItem* item = (MessageItem*) cell;
	MessagePtr msg = item.message;
	
	Profile* ourPf = GetDiscordInstance()->GetProfile();
	Channel* pChan = GetDiscordInstance()->GetCurrentChannel();
	if (!pChan) return;
	
	// Determine the dialog's properties based on the message.
	std::string shortenedMessage = msg->m_message;
	if (shortenedMessage.size() > 50)
		shortenedMessage = shortenedMessage.substr(0, 50) + "...";
	
	if (!shortenedMessage.empty()) {
		shortenedMessage = "\"" + shortenedMessage + "\"";
	}
	else if (!msg->m_attachments.empty()) {
		shortenedMessage += "(" + std::to_string(msg->m_attachments.size()) + " attachments)";
	}
	
	std::string dialogTitle = msg->m_author;
	
	if (!shortenedMessage.empty())
		dialogTitle += ": " + shortenedMessage;
	
	bool isThisMyMessage   = msg->m_author_snowflake == ourPf->m_snowflake;
	bool mayManageMessages = pChan->HasPermission(PERM_MANAGE_MESSAGES);
	bool isActionMessage   = IsActionMessage(msg->m_type) || IsClientSideMessage(msg->m_type);
	bool isForward         = msg->m_bIsForward;

	bool mayCopy   = !isForward && !isActionMessage;
	bool mayDelete = isThisMyMessage || mayManageMessages;
	bool mayEdit   = isThisMyMessage && !isForward && !isActionMessage;
	bool mayPin    = mayManageMessages;
	bool maySpeak  = !isActionMessage && !msg->m_message.empty();
	bool mayReply  = !isActionMessage || IsReplyableActionMessage(msg->m_type);

	// Generate the action sheet for this message.
	NSString* cancelOption = CANCEL_NAME;
	NSString* deleteOption = nil;
	std::vector<NSString*> options;
	
	if (mayDelete) deleteOption = DELETE_NAME;
	if (mayCopy)   options.push_back(COPY_TEXT_NAME);
	if (mayEdit)   options.push_back(EDIT_NAME);
	if (mayPin)    options.push_back(PIN_NAME);
	if (mayReply)  options.push_back(REPLY_NAME);
	options.push_back(cancelOption);
	
	NSString* dialogTitleN = [NSString stringWithUTF8String:dialogTitle.c_str()];
	
	UIActionSheet* actionSheet = [[UIActionSheet alloc]
		initWithTitle:dialogTitleN
		delegate:self
		cancelButtonTitle:nil
		destructiveButtonTitle:deleteOption
		otherButtonTitles:nil
	];
	
	for (auto& item : options)
		[actionSheet addButtonWithTitle:item];
	
	actionSheet.cancelButtonIndex = [actionSheet numberOfButtons] - 1;
	
	[actionSheet showInView:self.view];
	[actionSheet release];
	
	m_tableIndexPath = [indexPath retain];
	m_bContextMenuActive = true;
	
	//[tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
	if (!m_bContextMenuActive)
		return;
	
	[tableView deselectRowAtIndexPath:m_tableIndexPath animated:YES];
	
	NSString *buttonName = [actionSheet buttonTitleAtIndex:buttonIndex];
	
	// TODO: Hard-coded button names.  But I honestly don't care.
	if ([buttonName isEqualToString:DELETE_NAME])
	{
		DbgPrintF("Delete!");
	}
	else if ([buttonName isEqualToString:EDIT_NAME])
	{
		DbgPrintF("Edit!");
	}
	else if ([buttonName isEqualToString:REPLY_NAME])
	{
		DbgPrintF("Reply!");
	}
	else if ([buttonName isEqualToString:PIN_NAME])
	{
		DbgPrintF("Pin!");
	}
	else if ([buttonName isEqualToString:COPY_TEXT_NAME])
	{
		DbgPrintF("Copy Text!");
	}
	
	m_bContextMenuActive = false;
	[m_tableIndexPath release];
}

- (void)dealloc {
	g_pChannelController = nullptr;
	[tableView release];
	[inputView release];
	[super dealloc];
}

@end
