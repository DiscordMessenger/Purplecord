#import "ChannelController.h"
#import "MessageCell.h"
#import "UIColorScheme.h"
#import "AvatarCache.h"
#import "UIProportions.h"
#import "DeviceModel.h"
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

bool ShouldBeDateGap(time_t oldTime, time_t newTime)
{
	return oldTime / 86400 != newTime / 86400;
}

bool ShouldStartNewChain(Snowflake prevAuthor, time_t prevTime, int prevPlaceInChain, MessageType::eType prevType, const std::string& prevAuthorName, const std::string& prevAuthorAvatar, const MessageItem& item, bool ifChainTooLongToo)
{
	if (prevPlaceInChain >= 9 && ifChainTooLongToo)
		return true;

	if (prevAuthor != item.m_msg->m_author_snowflake)
		return true;

	if (prevTime + 15 * 60 < item.m_msg->m_dateTime)
		return true;

	if (item.m_msg->IsLoadGap())
		return true;

	if (item.m_msg->m_pReferencedMessage != nullptr)
		return true;

	if (item.m_msg->m_type == MessageType::REPLY)
		return true;

	if (IsActionMessage(prevType))
		return true;

	if (IsActionMessage(item.m_msg->m_type))
		return true;
	
	if (ShouldBeDateGap(prevTime, item.m_msg->m_dateTime))
		return true;

	if (prevAuthorName != item.m_msg->m_author)
		return true;

	if (prevAuthorAvatar != item.m_msg->m_avatar)
		return true;

	return false;
}

void MessageItem::UpdateDetails(Snowflake guildID)
{
	m_bWasMentioned = m_msg->CheckWasMentioned(GetDiscordInstance()->GetUserID(), guildID);
}

@interface ChannelController () {
	MessageInputView* inputView;
	
	uint64_t guildID;
	uint64_t channelID;
	
	Channel* pChannel;
	
	std::vector<MessageItemPtr> m_messages;
	
	bool m_doNotLoadMessages;
	bool m_forceReloadAttachments;
	
	bool m_bContextMenuActive;
	NSIndexPath* m_tableIndexPath;
	MessageItemPtr m_contextMenuMessage;
	
	bool m_bAcknowledgeNow;
	
#ifndef IPHONE_OS_3
	UIPopoverController* popoverController;
#endif
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

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingImage:(UIImage *)image editingInfo:(NSDictionary *)editingInfo
{
#ifndef IPHONE_OS_3
	[popoverController dismissPopoverAnimated:YES];
	popoverController = nil;
#else
	[self dismissModalViewControllerAnimated:YES];
#endif

	// If the image is smaller than this screen's resolution, then upload it as a PNG.
	// Else, upload it as a JPG.
	NSData* imageData = nil;
	
	BOOL usePng = YES;
	std::string fileName;
	CGRect screenBounds = [[UIScreen mainScreen] bounds];
	if (image.size.width > ScaleByDPI(screenBounds.size.width) && image.size.height > ScaleByDPI(screenBounds.size.height))
		usePng = NO;
	
	if (usePng) {
		imageData = UIImagePNGRepresentation(image);
		fileName = "unknown.png";
	}
	else {
		imageData = UIImageJPEGRepresentation(image, 0.9);
		fileName = "unknown.jpg";
	}
	
	// TODO: Allow fore more configuration options.
	Snowflake sf;
	if (!GetDiscordInstance()->SendMessageAndAttachmentToCurrentChannel(
			"",
			sf,
			imageData.bytes,
			imageData.length,
			fileName,
			false
		))
	{
		return;
	}
	
	// Add a temporary message
	MessagePtr m = MakeMessage();
	Profile* pf = GetDiscordInstance()->GetProfile();
	
	m->m_snowflake = sf;
	m->m_author_snowflake = pf->m_snowflake;
	m->m_author = pf->m_name;
	m->m_avatar = pf->m_avatarlnk;
	m->m_message = "(Attachment)";
	m->m_type = MessageType::SENDING_MESSAGE;
	m->SetTime(time(NULL));
	m->m_dateFull = "Sending...";
	m->m_dateCompact = "Sending...";
	
	[self addMessage:m];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
#ifndef IPHONE_OS_3
	[popoverController dismissPopoverAnimated:YES];
	popoverController = nil;
#else
	[self dismissModalViewControllerAnimated:YES];
#endif
}

- (void)messageInputView:(MessageInputView *)theInputView didAttachFile:(void *)unused
{
	if (![UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary])
		return;
	
	UIImagePickerController *picker = [[UIImagePickerController alloc] init];
	picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
	picker.delegate = self;
	picker.allowsEditing = NO;

#ifndef IPHONE_OS_3
	if (IsIPad())
	{
		UIPopoverController *popover = [[UIPopoverController alloc] initWithContentViewController:picker];
		popoverController = popover;
		
        [popoverController presentPopoverFromRect:theInputView.bounds inView:theInputView permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
	}
	else
	{
		[self presentModalViewController:picker animated:YES];
	}
#else
	[self presentModalViewController:picker animated:YES];
#endif
	[picker release];
}

- (void)loadView
{
	// create a view filling the entire screen boundaries
	CGRect screenBounds = [[UIScreen mainScreen] bounds];
	UIView *mainView = [[UIView alloc] initWithFrame:screenBounds];
	mainView.backgroundColor = [UIColorScheme getBackgroundColor];
	self.view = mainView;
	[mainView release];
}

- (void)viewDidLoad
{
	[super viewDidLoad];
	
	self.view.autoresizingMask =
		UIViewAutoresizingFlexibleWidth |
		UIViewAutoresizingFlexibleHeight;
	
	CGFloat bottomBarHeight = BOTTOM_BAR_HEIGHT;
	
	CGRect frame = CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.height - bottomBarHeight);
	tableView = [[UITableView alloc] initWithFrame:frame style:UITableViewStylePlain];
	tableView.dataSource = self;
	tableView.delegate = self;
	tableView.backgroundColor = [UIColorScheme getBackgroundColor];
	tableView.opaque = YES;
	tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
	tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
	[self.view addSubview:tableView];
	
	self.title = [NSString stringWithUTF8String:pChannel->GetFullName().c_str()];
	
	//UIBarButtonItem *toggleButton = [[UIBarButtonItem alloc] initWithTitle:@"Toggle Data Set" style:UIBarButtonItemStylePlain target:self action:@selector(toggleFlag)];
	//self.navigationItem.rightBarButtonItem = toggleButton;
	//[toggleButton release];
	
	inputView = [[MessageInputView alloc] initWithFrame:CGRectZero];
	inputView.delegate = self;
	inputView.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleWidth;
	inputView.frame = CGRectMake(0, self.view.bounds.size.height - bottomBarHeight, self.view.bounds.size.width, bottomBarHeight);
	
	[self.view addSubview:inputView];
}

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	
	// let us know when the keyboard shows up
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
	
	GetDiscordInstance()->OnSelectChannel(channelID);
	GetDiscordInstance()->HandledChannelSwitch();
	
	m_bAcknowledgeNow = true;
	
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

- (void)updateMessageChains
{
	DbgPrintF("-[ChannelController updateMessageChains]");
	bool isCompact = false; // TODO
	Snowflake addedMessagesBeforeThisID = 0; // TODO
	Snowflake addedMessagesAfterThisID = 0; // TODO
	
	time_t prevTime = 0;
	Snowflake prevAuthor = Snowflake(-1);
	MessageType::eType prevType = MessageType::DEFAULT;
	std::string prevAuthorName = "", prevAuthorAvatar = "";
	int prevPlaceInChain = 0;
	
	for (auto iter = m_messages.begin();
		iter != m_messages.end();
		++iter)
	{
		MessageItemPtr ptr = *iter;
		bool modifyChainOrder = true; //addedMessagesBeforeThisID == 0 || ptr->m_msg->m_snowflake <= addedMessagesBeforeThisID || ptr->m_msg->m_snowflake >= addedMessagesAfterThisID;

		bool bIsDateGap = ShouldBeDateGap(prevTime, ptr->m_msg->m_dateTime);
		bool startNewChain = isCompact || ShouldStartNewChain(prevAuthor, prevTime, prevPlaceInChain, prevType, prevAuthorName, prevAuthorAvatar, *ptr, modifyChainOrder);

		bool msgOldIsDateGap = ptr->m_bIsDateGap;
		bool msgOldWasChainBeg = ptr->m_placeInChain == 0;

		ptr->m_bIsDateGap = bIsDateGap;

		if (modifyChainOrder) {
			ptr->m_placeInChain = startNewChain ? 0 : 1 + prevPlaceInChain;
		}
		else {
			startNewChain = msgOldWasChainBeg;
		}
		
		ptr->m_cachedHeight = 0;
		
		prevPlaceInChain = ptr->m_placeInChain;
		prevAuthor = ptr->m_msg->m_author_snowflake;
		prevAuthorName = ptr->m_msg->m_author;
		prevAuthorAvatar = ptr->m_msg->m_avatar;
		prevTime = ptr->m_msg->m_dateTime;
		prevType = ptr->m_msg->m_type;
	}
}

- (void)requestMarkRead
{
	GetDiscordInstance()->RequestAcknowledgeChannel(channelID);
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
	
	BeginProfiling("ChannelController: refreshMessages get loaded messages");
	std::map<Snowflake, MessageItemPtr> oldMessagePointers;
	for (auto& message : m_messages)
		oldMessagePointers[message->m_msg->m_snowflake] = message;
	
	m_messages.clear();
	
	std::vector<MessagePtr> messages;
	GetMessageCache()->GetLoadedMessages(channelID, guildID, messages);
	EndProfiling();
	
	BeginProfiling("ChannelController: refreshMessages sift through messages");
	for (auto& message : messages)
	{
		auto messageItem = oldMessagePointers[message->m_snowflake];
		if (!messageItem) {
			messageItem = MakeMessageItem(message);
			messageItem->UpdateDetails(guildID);
		}
		
		m_messages.push_back(messageItem);
	}
	
	messages.clear();
	EndProfiling();
	
	m_doNotLoadMessages = true;
	
	BeginProfiling("ChannelController: updateMessageChains in refreshMessages");
	[self updateMessageChains];
	EndProfiling();
	
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

- (void)onUpdateMessage:(Snowflake)messageId updateNextMessage:(BOOL)updateNxtMsg updatePreviousMessage:(BOOL)updatePrvMsg updateInTableView:(BOOL)updateInTableView
{
	Snowflake prevAuthor = Snowflake(-1);
	time_t prevDate = 0;
	int prevPlaceInChain = -1;
	MessageType::eType prevType = MessageType::DEFAULT;
	std::string prevAuthorName = "", prevAuthorAvatar = "";
	
	// Find the previous ID and next ID of the message, as well as their indices.
	Snowflake previousPreviousId = 0, previousId = 0, currentId = 0, nextId = 0;
	size_t previousPreviousIndex = 0, previousIndex = 0, currentIndex = 0, nextIndex = 0;
	
	for (size_t i = 0; i < m_messages.size(); i++)
	{
		MessageItemPtr item = m_messages[i];
		
		if (item->m_msg->m_snowflake == messageId)
		{
			if (i + 1 < m_messages.size()) {
				nextId = m_messages[i + 1]->m_msg->m_snowflake;
				nextIndex = i + 1;
			}
			
			currentIndex = i;
			currentId = messageId;
			break;
		}
		
		previousPreviousId = previousId;
		previousPreviousIndex = previousIndex;
		previousId = item->m_msg->m_snowflake;
		previousIndex = i;
	}
	
	// If the message we're looking for wasn't found, just return.
	if (currentId < 0)
		return;
	
	MessageItemPtr beginningItem = nullptr;
	
	// If we want to update the previous message, then we need to load all the prev* fields
	// with the pre-previous message.
	if (updatePrvMsg && previousPreviousId > 0) {
		beginningItem = m_messages[previousPreviousIndex];
	}
	else if (previousId > 0) {
		beginningItem = m_messages[previousIndex];
	}
	
	// If there is a beginning item, fill its properties, otherwise they'll just be
	// the default ones because we are near the beginning of the message log.
	if (beginningItem) {
		prevAuthor = beginningItem->m_msg->m_author_snowflake;
		prevDate = beginningItem->m_msg->m_dateTime;
		prevType = beginningItem->m_msg->m_type;
		prevPlaceInChain = beginningItem->m_placeInChain;
		prevAuthorName = beginningItem->m_msg->m_author;
		prevAuthorAvatar = beginningItem->m_msg->m_avatar;
	}
	
	// Well, using a lambda here was the easiest way for me to do this, because I'm lazy
	auto updateMessage = [&] (Snowflake msgId, size_t index)
	{
		if (msgId == 0)
			return;
		
		MessageItemPtr item = m_messages[index];
		MessagePtr message = item->m_msg;
		
		assert(message->m_snowflake == msgId);
		
		if (ShouldBeDateGap(prevDate, message->m_dateTime))
			item->m_bIsDateGap = true;

		if (prevPlaceInChain < 0 || ShouldStartNewChain(prevAuthor, prevDate, prevPlaceInChain, prevType, prevAuthorName, prevAuthorAvatar, *item, true))
			item->m_placeInChain = 0;
		else
			item->m_placeInChain = prevPlaceInChain + 1;
		
		// reset cached height
		item->m_cachedHeight = 0.0f;
		
		if (updateInTableView)
			[self onUpdatedRowAtIndex:index animated:NO];
		
		prevAuthor = message->m_author_snowflake;
		prevDate = message->m_dateTime;
		prevType = message->m_type;
		prevAuthorName = message->m_author;
		prevAuthorAvatar = message->m_avatar;
		prevPlaceInChain = item->m_placeInChain;
	};
	
	if (updatePrvMsg && previousId > 0)
		updateMessage(previousId, previousIndex);
	
	updateMessage(currentId, currentIndex);
	
	if (updateNxtMsg && nextId > 0)
		updateMessage(nextId, nextIndex);
	
	DbgPrintF("Updating messages. PrevID: %lld CurrID: %lld NextID: %lld", previousId, currentId, nextId);
}

- (void)onUpdateLastMessage
{
	if (m_messages.empty())
		return;
	
	auto item = *m_messages.rbegin();
	[self onUpdateMessage:item->m_msg->m_snowflake updateNextMessage:NO updatePreviousMessage:YES updateInTableView:YES];
}

- (void)addMessage:(MessagePtr)message
{
	if (message->m_anchor)
	{
		// if the message can't be found come back here with anchor reset
		[self updateMessageById:message->m_anchor message:message];
		return;
	}
	
	m_messages.push_back(MakeMessageItem(message));
	[self onUpdateMessage:message->m_snowflake updateNextMessage:NO updatePreviousMessage:YES updateInTableView:NO];
	[self onAddedRowAtIndex:m_messages.size() - 1 animated:YES];
	[self scrollToBottomIfNeeded];
}

- (void)removeMessage:(Snowflake)messageID
{
	auto iter = std::find_if(m_messages.begin(), m_messages.end(), [messageID] (MessageItemPtr ptr) {
		return ptr->m_msg->m_snowflake == messageID;
	});
	
	if (iter == m_messages.end())
	{
		DbgPrintF("Message with id %lld not found for deletion", messageID);
		return;
	}
	
	size_t index = std::distance(m_messages.begin(), iter);
	m_messages.erase(iter);
	[self onRemovedRowAtIndex:index animated:YES];
	
	// what message occupies this index now?
	if (index >= m_messages.size()) {
		// none, update the last message
		[self onUpdateLastMessage];
	}
	else {
		MessageItemPtr item = m_messages[index];
		[self onUpdateMessage:item->m_msg->m_snowflake updateNextMessage:NO updatePreviousMessage:YES updateInTableView:YES];
	}
	
	[self scrollToBottomIfNeeded];
}

- (void)updateMessageById:(Snowflake)messageID message:(MessagePtr)message
{
	auto iter = std::find_if(m_messages.begin(), m_messages.end(), [messageID] (MessageItemPtr ptr) {
		return ptr->m_msg->m_snowflake == messageID;
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
	
	MessageItemPtr ptr = *iter;
	
	ptr->m_msg = message;
	ptr->m_placeInChain = 0;
	ptr->m_cachedHeight = 0;
	ptr->m_bIsDateGap = false;
	
	[self onUpdateMessage:messageID updateNextMessage:YES updatePreviousMessage:YES updateInTableView:YES];
	[self onUpdateMessage:message->m_snowflake updateNextMessage:YES updatePreviousMessage:YES updateInTableView:YES];
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
		auto& msg = m_messages[i]->m_msg;
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
	[tableView beginUpdates];
	
	m_forceReloadAttachments = true;
	
	for (size_t i = 0; i < m_messages.size(); i++)
	{
		auto& msg = m_messages[i]->m_msg;
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
	
	static NSString *cellId = @"MessageCell";
	MessageCell* item = (MessageCell*) [tv dequeueReusableCellWithIdentifier:cellId];
	if (!item)
		item = [[[MessageCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellId] autorelease];
	
	MessageItemPtr message = m_messages[indexPath.row];
	bool isEndOfChain = true;
	if (indexPath.row + 1 < m_messages.size()) {
		MessageItemPtr nextMessage = m_messages[indexPath.row + 1];
		isEndOfChain = nextMessage->m_placeInChain == 0;
	}
	
	[item configureWithMessage:message andReload:m_forceReloadAttachments isEndOfChain:isEndOfChain];
	
	item.selectionStyle = UITableViewCellSelectionStyleGray;
	
	Channel* channel = GetDiscordInstance()->GetCurrentChannel();
	if (channel &&
		m_messages.size() != 0 &&
		m_messages[m_messages.size() - 1]->m_msg->m_snowflake == message->m_msg->m_snowflake &&
		channel->m_lastSentMsg != channel->m_lastViewedMsg &&
		m_bAcknowledgeNow)
	{
		[self requestMarkRead];
		channel->m_lastViewedMsg = channel->m_lastSentMsg;
	}
	
	return item;
}

- (CGFloat)tableView:(UITableView *)tv heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	if (indexPath.row < 0 || indexPath.row >= (int) m_messages.size())
		return nil;
	
	MessageItemPtr message = m_messages[indexPath.row];
	if (message->m_cachedHeight)
		return message->m_cachedHeight;
	
	bool isEndOfChain = true;
	if (indexPath.row + 1 < m_messages.size()) {
		MessageItemPtr nextMessage = m_messages[indexPath.row + 1];
		isEndOfChain = nextMessage->m_placeInChain == 0;
	}
	
	CGFloat height = [MessageCell computeHeightForMessage:message isEndOfChain:isEndOfChain];
	message->m_cachedHeight = height;
	return height;
}

- (void)tableView:(UITableView*)tv willDisplayCell:(UITableViewCell*)cell forRowAtIndexPath:(NSIndexPath*)indexPath
{
	if (m_doNotLoadMessages)
		return;
	
	// If the message is a gap, request it
	MessageCell* item = (MessageCell*) cell;
	
	MessagePtr msg = item.messageItem->m_msg;
	if (msg->IsLoadGap())
	{
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

#define DELETE_NAME      @"Delete"
#define COPY_TEXT_NAME   @"Copy Text"
#define PIN_NAME         @"Pin"
#define EDIT_NAME        @"Edit"
#define REPLY_NAME       @"Reply"
#define CANCEL_NAME      @"Cancel"
#define MARK_UNREAD_NAME @"Mark as Unread"

- (void)tableView:(UITableView *)tv didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	UITableViewCell* cell = [tableView cellForRowAtIndexPath:indexPath];
	if (!cell) return;
	
	[self.view endEditing:YES];
	
	MessageCell* item = (MessageCell*) cell;
	MessageItemPtr msgItem = item.messageItem;
	MessagePtr msg = msgItem->m_msg;
	
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
	bool mayPin    = mayManageMessages && IsPinnableActionMessage(msg->m_type);
	bool maySpeak  = !isActionMessage && !msg->m_message.empty();
	bool mayReply  = !isActionMessage || IsReplyableActionMessage(msg->m_type);

	// Generate the action sheet for this message.
	NSString* cancelOption = CANCEL_NAME;
	NSString* deleteOption = nil;
	std::vector<NSString*> options;
	
	if (mayDelete) deleteOption = DELETE_NAME;
	if (mayCopy)   options.push_back(COPY_TEXT_NAME);
	if (mayEdit)   options.push_back(EDIT_NAME);
	// TODO: if (mayPin)    options.push_back(PIN_NAME);
	if (mayReply)  options.push_back(REPLY_NAME);
	options.push_back(MARK_UNREAD_NAME);
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
	
#ifdef IPHONE_OS_3
	[actionSheet showInView:self.view];
#else
	if (IsIPad()) {
		CGRect rectInView = [cell convertRect:cell.bounds toView:self.view];
		[actionSheet showFromRect:rectInView inView:self.view animated:YES];
	}
	else {
		[actionSheet showInView:self.view];
	}
#endif
	
	[actionSheet release];
	
	m_tableIndexPath = [indexPath retain];
	m_bContextMenuActive = true;
	m_contextMenuMessage = msgItem;
	
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
		// TODO: Add confirmation.  For delete confirmations iOS usually just
		// shows an action sheet.
		
		GetDiscordInstance()->RequestDeleteMessage(self->channelID, m_contextMenuMessage->m_msg->m_snowflake);
	}
	else if ([buttonName isEqualToString:COPY_TEXT_NAME])
	{
		UIPasteboard *pb = [UIPasteboard generalPasteboard];
		pb.string = [NSString stringWithUTF8String:m_contextMenuMessage->m_msg->m_message.c_str()];
	}
	else if ([buttonName isEqualToString:MARK_UNREAD_NAME])
	{
		Snowflake messageBeforeContextMessage = 0;
		
		for (auto iter = m_messages.rbegin(); iter != m_messages.rend(); ++iter)
		{
			if ((*iter)->m_msg->m_snowflake == m_contextMenuMessage->m_msg->m_snowflake)
			{
				MessageItemPtr pMsg = *iter;

				++iter;
				if (iter != m_messages.rend())
					messageBeforeContextMessage = (*iter)->m_msg->m_snowflake;
				break;
			}
		}
	
		if (messageBeforeContextMessage == 0)
		{
			uint64_t timeStamp = m_contextMenuMessage->m_msg->m_snowflake >> 22;
			timeStamp--; // in milliseconds since Discord epoch - irrelevant because we just want to take ONE millisecond
			messageBeforeContextMessage = timeStamp << 22;
		}

		GetDiscordInstance()->RequestAcknowledgeMessages(channelID, messageBeforeContextMessage);
		
		// block acknowledgements until we switch to the channel again.
		m_bAcknowledgeNow = false;
	}
	else if ([buttonName isEqualToString:EDIT_NAME])
	{
		// TODO
		DbgPrintF("Edit!");
	}
	else if ([buttonName isEqualToString:REPLY_NAME])
	{
		// TODO
		DbgPrintF("Reply!");
	}
	
	m_bContextMenuActive = false;
	m_contextMenuMessage = nullptr;
	[m_tableIndexPath release];
}

- (void)dealloc {
	g_pChannelController = nullptr;
	[tableView release];
	[inputView release];
#ifndef IPHONE_OS_3
	[popoverController release];
#endif
	[super dealloc];
}

@end
