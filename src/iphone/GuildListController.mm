#import "GuildListController.h"
#import "ChannelListController.h"
#include "HTTPClient_curl.h"
#include "../discord/DiscordInstance.hpp"

@interface GuildListController() {
	std::vector<Snowflake> m_guilds;
}
@end

GuildListController* g_pGuildListController;

@implementation GuildListController

- (void)loadView
{
	g_pGuildListController = self;
	
	CGRect screenBounds = [[UIScreen mainScreen] bounds];
	
	// create a view filling the entire screen boundaries
	UIView *mainView = [[UIView alloc] initWithFrame:screenBounds];
	self.view = mainView;
	[mainView release];
	
	// create a tableview that spans the entire screen minus the header
	CGFloat statusBarHeight = [[UIApplication sharedApplication] statusBarFrame].size.height;
	CGFloat navBarHeight = self.navigationController.navigationBar.frame.size.height;
	
	CGRect frame = CGRectMake(
		0, 0,
		screenBounds.size.width,
		screenBounds.size.height - statusBarHeight - navBarHeight
	);
	
	tableView = [[UITableView alloc] initWithFrame:frame style:UITableViewStylePlain];
	tableView.dataSource = self;
	tableView.delegate = self;
	[self.view addSubview:tableView];
	
	[self refreshGuilds];
}

- (void)refreshGuilds
{
	m_guilds.clear();
	
	std::vector<Snowflake> snowflakes;
	GetDiscordInstance()->GetGuildIDsOrdered(snowflakes, true);
	
	for (auto snowflake : snowflakes)
	{
		if (snowflake == 1) continue;
		if (snowflake & BIT_FOLDER) continue; // Ignore folders for now.
		
		m_guilds.push_back(snowflake);
	}
	
	[tableView reloadData];
}

- (void)viewDidLoad
{
	[super viewDidLoad];
	
	self.title = @"Purplecord";
	
	UIBarButtonItem* settingsButton = [
		[UIBarButtonItem alloc]
		initWithTitle:@"Settings"
		style:UIBarButtonItemStylePlain
		target:self
		action:@selector(onClickedSettingsButton)
	];
	
	self.navigationItem.leftBarButtonItem = settingsButton;
	[settingsButton release];
}

void TestFunction();

- (void)onClickedSettingsButton
{
	// TODO
}

- (NSInteger)tableView:(UITableView*)tv numberOfRowsInSection:(NSInteger)section
{
	return m_guilds.size();
}

- (UITableViewCell*)tableView:(UITableView*)tv cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
	int index = indexPath.row;
	if (index < 0 || index > (int) m_guilds.size())
		return nil;
	
	std::string guildName;
	
	Guild* pGuild = GetDiscordInstance()->GetGuild(m_guilds[index]);
	if (pGuild)
		guildName = pGuild->m_name;
	else
		guildName = "Unknown Guild " + std::to_string(m_guilds[index]);
	
	NSString* guildNameNS = [NSString stringWithUTF8String:guildName.c_str()];
	
	static NSString *cellId = @"Cell";
	UITableViewCell *cell = [tv dequeueReusableCellWithIdentifier:cellId];
	if (!cell) {
		cell = [[UITableViewCell alloc] initWithFrame:CGRectMake(0,0,tv.bounds.size.width,44) reuseIdentifier:cellId];
		cell.selectionStyle = UITableViewCellSelectionStyleBlue;
	}
	cell.text = guildNameNS;
	return cell;
}

- (void)tableView:(UITableView *)tv didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	int index = indexPath.row;
	if (index < 0 || index > (int) m_guilds.size())
		return;
	
	Snowflake guildId = m_guilds[index];
	Guild* pGuild = GetDiscordInstance()->GetGuild(guildId);
	if (!pGuild)
		return;
	
	NSString *selected = [NSString stringWithUTF8String:pGuild->m_name.c_str()];

	ChannelListController *channelVC = [[ChannelListController alloc] initWithGuildID:guildId andGuildName:selected];
	channelVC.view.backgroundColor = [UIColor whiteColor];
	channelVC.title = selected;

	[self.navigationController pushViewController:channelVC animated:YES];
	[channelVC release];
}

- (void)dealloc
{
	g_pGuildListController = NULL;
	
	[tableView release];
	[super dealloc];
}

@end
