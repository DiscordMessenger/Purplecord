#import "GuildListController.h"
#import "GuildController.h"
#import "SettingsController.h"
#import "UIColorScheme.h"
#import "AvatarCache.h"
#include "HTTPClient_curl.h"
#include "../discord/DiscordInstance.hpp"

GuildListController* g_pGuildListController;
GuildListController* GetGuildListController() {
	return g_pGuildListController;
}

@interface GuildListController() {
	std::vector<Snowflake> m_guilds;
}
@end

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
	tableView.backgroundColor = [UIColorScheme getTextBackgroundColor];
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
	SettingsController *settings = [[[SettingsController alloc] init] autorelease];
	[self.navigationController pushViewController:settings animated:YES];
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
	if (!cell) 
		cell = [[UITableViewCell alloc] initWithFrame:CGRectMake(0, 0, tv.bounds.size.width, 44) reuseIdentifier:cellId];
	
	cell.selectionStyle = UITableViewCellSelectionStyleBlue;
	cell.textLabel.textColor = [UIColorScheme getTextColor];
	cell.text = guildNameNS;
	
	UIImage* image = [GetAvatarCache() getImage:pGuild->m_avatarlnk];
	cell.imageView.image = image;
	
	return cell;
}

- (void)updateAttachmentByID:(const std::string&)resource
{
	[tableView beginUpdates];
	
	for (size_t i = 0; i < m_guilds.size(); i++)
	{
		Guild* guild = GetDiscordInstance()->GetGuild(m_guilds[i]);
		if (!guild) continue;
		
		if ([GetAvatarCache() makeIdentifier:guild->m_avatarlnk] == resource)
		{
			NSIndexPath* indexPath = [NSIndexPath indexPathForRow:(NSInteger)i inSection:0];
			[tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
		}
	}
	
	[tableView endUpdates];
}

- (void)tableView:(UITableView *)tv didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	[tableView deselectRowAtIndexPath:indexPath animated:NO];
	
	int index = indexPath.row;
	if (index < 0 || index > (int) m_guilds.size())
		return;
	
	Snowflake guildId = m_guilds[index];
	Guild* pGuild = GetDiscordInstance()->GetGuild(guildId);
	if (!pGuild)
		return;
	
	GuildController *guildVC = [[GuildController alloc] initWithGuildID:guildId];
	guildVC.view.backgroundColor = [UIColorScheme getBackgroundColor];

	[self.navigationController pushViewController:guildVC animated:YES];
	[guildVC release];
}

- (void)dealloc
{
	g_pGuildListController = NULL;
	
	[tableView release];
	[super dealloc];
}

@end
