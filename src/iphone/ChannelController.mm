#import "ChannelController.h"
#import "MessageItem.h"
#import "UIColorScheme.h"
#include "UIProportions.h"
#include "../discord/DiscordInstance.hpp"

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

- (void)messageInputView:(MessageInputView *)inputView didSendMessage:(NSString *)message
{
	std::string message([message UTF8String]);
	
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
	
	self.title = [NSString stringWithUTF8String:(pChannel->GetTypeSymbol() + pChannel->m_name).c_str()];
	
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
	
	UIEdgeInsets insets = tableView.contentInset;
	insets.bottom = keyboardHeight;
	tableView.contentInset = insets;
	tableView.scrollIndicatorInsets = insets;
	
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
	
	UIEdgeInsets insets = tableView.contentInset;
	insets.bottom = 0;
	tableView.contentInset = insets;
	tableView.scrollIndicatorInsets = insets;
	
	[UIView commitAnimations];
}

- (void)refreshMessages:(ScrollDir::eScrollDir)sd withGapCulprit:(Snowflake)gapCulprit
{
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
	
	[tableView reloadData];
	
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

- (void)reloadDataAndScrollToBottomIfNeeded
{
	// Figure out if we need to scroll to bottom or not
	CGFloat oldContentHeight = tableView.contentSize.height;
	CGFloat oldOffsetY = tableView.contentOffset.y;
	CGFloat distanceFromBottom = oldContentHeight - oldOffsetY;
	
	[tableView reloadData];
	
	if (distanceFromBottom < 2000)
		[self performSelector:@selector(scrollToBottom) withObject:nil afterDelay:0];
}

- (void)addMessage:(MessagePtr)message
{
	if (message->m_anchor)
		[self removeMessage:message->m_anchor];
	
	m_messages.push_back(message);
	
	[self reloadDataAndScrollToBottomIfNeeded];
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
	
	m_messages.erase(iter);
	
	[self reloadDataAndScrollToBottomIfNeeded];
}

- (void)updateMessage:(MessagePtr)message
{
	Snowflake messageID = message->m_snowflake;
	auto iter = std::find_if(m_messages.begin(), m_messages.end(), [messageID] (MessagePtr ptr) {
		return ptr->m_snowflake == messageID;
	});
	
	if (iter == m_messages.end())
	{
		DbgPrintF("Message with id %lld not found for update, resorting to add", messageID);
		[self addMessage:message];
		return;
	}
	
	*iter = message;
	[self reloadDataAndScrollToBottomIfNeeded];
}


- (void)update
{
	[self refreshMessages:ScrollDir::AROUND withGapCulprit:0];
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
	[item configureWithMessage:message];
	
	return item;
}

- (CGFloat)tableView:(UITableView *)tv heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	if (indexPath.row < 0 || indexPath.row >= (int) m_messages.size())
		return nil;
	
	static NSString *cellId = @"MessageItem";
	MessageItem* item = (MessageItem*) [tv dequeueReusableCellWithIdentifier:cellId];
	if (!item)
		item = [[[MessageItem alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellId] autorelease];
	
	MessagePtr message = m_messages[indexPath.row];
	[item configureWithMessage:message];
	
	return item.height;
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

- (void)tableView:(UITableView *)tv didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	// TODO
}

- (void)dealloc {
	g_pChannelController = nullptr;
	[tableView release];
	[inputView release];
	[super dealloc];
}

@end
