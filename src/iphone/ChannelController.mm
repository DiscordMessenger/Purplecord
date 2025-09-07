#import "ChannelController.h"
#import "MessageItem.h"
#include "../discord/DiscordInstance.hpp"

ChannelController* g_pChannelController;
ChannelController* GetChannelController() {
	return g_pChannelController;
}

@interface ChannelController () {
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

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	CGRect screenBounds = [[UIScreen mainScreen] bounds];
	UIView *mainView = [[UIView alloc] initWithFrame:screenBounds];
	mainView.backgroundColor = [UIColor groupTableViewBackgroundColor];
	self.view = mainView;
	[mainView release];
	
	CGFloat statusBarHeight = [[UIApplication sharedApplication] statusBarFrame].size.height;
	CGFloat navBarHeight = self.navigationController.navigationBar.frame.size.height;
	
	CGRect frame = CGRectMake(0, 0, screenBounds.size.width, screenBounds.size.height - statusBarHeight - navBarHeight);
	tableView = [[UITableView alloc] initWithFrame:frame style:UITableViewStylePlain];
	tableView.dataSource = self;
	tableView.delegate = self;
	tableView.backgroundColor = [UIColor groupTableViewBackgroundColor];
	tableView.opaque = YES;
	tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
	[self.view addSubview:tableView];
	
	self.title = [NSString stringWithUTF8String:(pChannel->GetTypeSymbol() + pChannel->m_name).c_str()];
	
	//UIBarButtonItem *toggleButton = [[UIBarButtonItem alloc] initWithTitle:@"Toggle Data Set" style:UIBarButtonItemStylePlain target:self action:@selector(toggleFlag)];
	//self.navigationItem.rightBarButtonItem = toggleButton;
	//[toggleButton release];
	
	GetDiscordInstance()->OnSelectChannel(channelID);
	
	[self update];
}

- (void)refreshMessages:(ScrollDir::eScrollDir)sd withGapCulprit:(Snowflake)gapCulprit
{
	[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
	
	// TODO: Keep the scroll position
	// TODO: Imitate what DM does
	m_messages.clear();
	GetMessageCache()->GetLoadedMessages(channelID, guildID, m_messages);
	
	m_doNotLoadMessages = true;
	
	[tableView reloadData];
	
	NSInteger lastRow = (NSInteger)(m_messages.size() - 1);
	NSIndexPath *lastIndexPath = [NSIndexPath indexPathForRow:lastRow inSection:0];
	[tableView scrollToRowAtIndexPath:lastIndexPath atScrollPosition:UITableViewScrollPositionBottom animated:NO];
	
	m_doNotLoadMessages = false;
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
			case MessageType::GAP_UP:     sd = ScrollDir::BEFORE; break;
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
	[super dealloc];
}

@end
