#import "ChannelController.h"
#include "../discord/DiscordInstance.hpp"

ChannelController* g_pChannelController;
ChannelController* GetChannelController() {
	return g_pChannelController;
}

@interface ChannelController () {
	uint64_t guildID;
	uint64_t channelID;
	
	Channel* pChannel;
}
@end

@implementation ChannelController

- (instancetype)initWithChannelID:(uint64_t)_channelID andGuildID:(uint64_t)_guildID {
	self = [self init];
	if (self) {
		guildID = _guildID;
		channelID = _channelID;
		
		Guild* pGuild = GetDiscordInstance()->GetGuild(guildID);
		pChannel = pGuild->GetChannel(channelID);
		
		assert(!g_pChannelController);
		g_pChannelController = self;
	}
	return self;
}

- (void)viewWillAppear:(BOOL)animated {
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
	[self.view addSubview:tableView];
	
	self.title = [NSString stringWithUTF8String:(pChannel->GetTypeSymbol() + pChannel->m_name).c_str()];
	
	//UIBarButtonItem *toggleButton = [[UIBarButtonItem alloc] initWithTitle:@"Toggle Data Set" style:UIBarButtonItemStylePlain target:self action:@selector(toggleFlag)];
	//self.navigationItem.rightBarButtonItem = toggleButton;
	//[toggleButton release];
}

- (void)update
{
	// TODO
}

- (NSInteger)tableView:(UITableView *)tv numberOfRowsInSection:(NSInteger)section
{
	// TODO
	return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tv cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	// TODO
	//static NSString *cellId = @"Cell";
	//UITableViewCell *cell = [tv dequeueReusableCellWithIdentifier:cellId];
	//if (!cell) {
	//	cell = [[UITableViewCell alloc] initWithFrame:CGRectMake(0, 0, tv.bounds.size.width, 44) reuseIdentifier:cellId];
	//	cell.selectionStyle = UITableViewCellSelectionStyleBlue;
	//}
	//cell.text = text;
	//return cell;
	return nil;
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
