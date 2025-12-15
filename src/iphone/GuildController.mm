#import "GuildController.h"
#import "ChannelController.h"
#import "UIColorScheme.h"
#import "Frontend_iOS.h"
#include "../discord/DiscordInstance.hpp"

struct ChannelMember
{
	Snowflake m_category;
	Snowflake m_id;
	Channel::eChannelType m_type;
	std::string m_name;
	int m_pos;
	Snowflake m_lastMessageID = 0;

	bool IsCategory() const
	{
		return m_type == Channel::CATEGORY;
	}

	bool IsDM() const
	{
		return m_type == Channel::DM || m_type == Channel::GROUPDM;
	}
	
	bool IsVoice() const
	{
		return m_type == Channel::VOICE || m_type == Channel::STAGEVOICE;
	}

	bool operator<(const ChannelMember& other) const
	{
		if (IsDM()) {
			// the other is probably a DM too
			if (m_lastMessageID != other.m_lastMessageID)
				return m_lastMessageID > other.m_lastMessageID;
		}

		// voice channels are always below text channels
		if (IsVoice() && !other.IsVoice()) return false;
		if (!IsVoice() && other.IsVoice()) return true;

		// sort by position
		if (m_pos != other.m_pos)
			return m_pos < other.m_pos;
		
		return m_id < other.m_id;
	}
};

struct Category
{
	Snowflake m_id;
	int m_pos;
	std::string m_name;
	std::vector<ChannelMember> m_channels;
	
	Category(Snowflake theId, int pos, const std::string& name)
	{
		m_id = theId;
		m_pos = pos;
		m_name = name;
	}
	
	bool operator<(const Category& other) const
	{
		if (m_pos != other.m_pos) return m_pos < other.m_pos;
		return m_id < other.m_id;
	}
	
	void SortChannels()
	{
		std::sort(m_channels.begin(), m_channels.end());
	}
};

static std::string GetChannelString(const Channel& ch)
{
	std::string mentions = "";
	std::string unreadMarker = "";
	if (ch.WasMentioned()) {
		mentions = "(" + std::to_string(ch.m_mentionCount) + ") ";
	}

	if (ch.HasUnreadMessages()) {
		unreadMarker = " *";
	}

	return mentions + ch.GetFullName() + unreadMarker;
}

GuildController* g_pGuildController;
GuildController* GetGuildController() {
	return g_pGuildController;
}

@interface GuildController() {
	uint64_t guildID;
	Guild* pGuild;
	std::vector<Category> m_categories;
	int m_nextCategIndex;
}
@end

@implementation GuildController

- (instancetype)initWithGuildID:(uint64_t)_guildID
{
	self = [self init];
	if (self) {
		guildID = _guildID;
		pGuild = GetDiscordInstance()->GetGuild(_guildID);
		self.title = [NSString stringWithUTF8String:pGuild->m_name.c_str()];
	}
	
	if (g_pGuildController)
	{
		DbgPrintF("ERROR: Guild controller already opened!  GuildID: %lld", g_pGuildController->guildID);
	}
	
	assert(!g_pGuildController);
	g_pGuildController = self;
	
	return self;
}

- (void)viewDidLoad
{
	[super viewDidLoad];
	
	self.view.backgroundColor = [UIColorScheme getBackgroundColor];
	self.view.autoresizingMask =
		UIViewAutoresizingFlexibleWidth |
		UIViewAutoresizingFlexibleHeight;
	
	CGRect screenBounds = [[UIScreen mainScreen] bounds];
	
	// create a tableview that spans the entire screen minus the header
	CGFloat statusBarHeight = [[UIApplication sharedApplication] statusBarFrame].size.height;
	CGFloat navBarHeight = self.navigationController.navigationBar.frame.size.height;
	
	CGRect frame = self.view.bounds;
	
	tableView = [[UITableView alloc] initWithFrame:frame style:UITableViewStyleGrouped];
	tableView.dataSource = self;
	tableView.delegate = self;
	tableView.backgroundColor = [UIColorScheme getBackgroundColor];
	tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
	[self.view addSubview:tableView];
	
	GetDiscordInstance()->OnSelectGuild(guildID);
}

- (void)exitIfYouDontExist
{
	if (!GetDiscordInstance()->GetGuild(guildID))
	{
		if (g_pGuildController == self)
			g_pGuildController = nil;
		[self.navigationController popViewControllerAnimated:YES];
	}
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

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	
	[self updateChannelList];
}

- (void)viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];
	if (g_pGuildController == self)
		g_pGuildController = nil;
}

- (void)addChannel:(const Channel&) ch
{
	if (!ch.HasPermissionConst(PERM_VIEW_CHANNEL))
	{
		// If not a category, return.  We'll remove invisible categories without elements after the fact.
		if (ch.m_channelType != Channel::CATEGORY)
			return;
	}
	
	if (ch.IsCategory())
	{
		// Add this category.
		m_categories.push_back(Category(ch.m_snowflake, ch.m_pos, ch.m_name));
		return;
	}
	
	// Add this channel to the category.
	Category* category = nullptr;
	
	for (auto& categ : m_categories)
	{
		if (categ.m_id == ch.m_parentCateg) {
			category = &categ;
			break;
		}
	}
	
	if (!category)
	{
		m_categories.push_back(Category(ch.m_parentCateg, 0, "Unknown Category"));
		category = &m_categories[m_categories.size() - 1];
	}
	
	category->m_channels.push_back({ ch.m_parentCateg, ch.m_snowflake, ch.m_channelType, GetChannelString(ch), ch.m_pos, ch.m_lastSentMsg });
}

- (void)commitChannels
{
	for (auto& categ : m_categories)
	{
		categ.SortChannels();
	}
	
	std::sort(m_categories.begin(), m_categories.end());
	
	for (auto iter = m_categories.begin(); iter != m_categories.end(); )
	{
		if (iter->m_channels.size() == 0)
		{
			m_categories.erase(iter);
			iter = m_categories.begin();
			continue;
		}
		
		++iter;
	}
}

- (void)recomputeChannels
{
	m_categories.clear();
	m_categories.push_back(Category(0, 0, "Uncategorized"));
	
	if (!pGuild->m_bChannelsLoaded)
	{
		pGuild->RequestFetchChannels();
		return;
	}
	
	for (auto& ch : pGuild->m_channels)
	{
		if (ch.second.IsCategory())
			[self addChannel:ch.second];
	}
	
	for (auto& ch : pGuild->m_channels)
	{
		if (!ch.second.IsCategory())
			[self addChannel:ch.second];
	}
	
	[self commitChannels];
}

- (void)updateChannelList
{
	if (![self ensureGuildPointerExists])
		return;
	
	Guild* guild = GetDiscordInstance()->GetGuild(guildID);
	if (!guild)
		[self.navigationController popToRootViewControllerAnimated:YES];
	
	[self recomputeChannels];
	[tableView reloadData];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView*)tv
{
	if (![self ensureGuildPointerExists])
		return 0;
	
	return m_categories.size();
}

- (NSInteger)tableView:(UITableView*)tv numberOfRowsInSection:(NSInteger)section
{
	if (![self ensureGuildPointerExists])
		return 0;
	if (section < 0 || section >= (NSInteger) m_categories.size())
		return 0;
	
	return (NSInteger) m_categories[section].m_channels.size();
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
	if (![self ensureGuildPointerExists])
		return nil;
	if (section < 0 || section >= (NSInteger) m_categories.size())
		return nil;
	
	return [NSString stringWithUTF8String:m_categories[section].m_name.c_str()];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	return 44.0f; // default
}

- (UITableViewCell*)tableView:(UITableView*)tv cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
	if (![self ensureGuildPointerExists])
		return nil;
	
	if (indexPath.section < 0 || indexPath.section >= m_categories.size())
		return nil;
	
	auto& categ = m_categories[indexPath.section];
	if (indexPath.row < 0 || indexPath.row >= categ.m_channels.size())
		return nil;
	
	auto& item = categ.m_channels[indexPath.row];
	
	//std::string name = item.m_name + " [" + std::to_string(item.m_categIndex) + "] (" + std::to_string(item.m_pos) + ") {" + std::to_string(item.m_id) + "}";
	std::string& name = item.m_name;
	NSString* text = [NSString stringWithUTF8String:name.c_str()];
	UITableViewCell *cell = [[UITableViewCell alloc] initWithFrame:CGRectMake(0,0,tv.bounds.size.width,44)];
	
	cell.backgroundColor = [UIColorScheme getTextBackgroundColor];
	cell.textLabel.textColor = [UIColorScheme getTextColor];
	cell.textLabel.font = [UIFont boldSystemFontOfSize:20.0];
	cell.selectionStyle = UITableViewCellSelectionStyleBlue;
	cell.userInteractionEnabled = YES;
	
	cell.text = text;
	return cell;
}

- (void)tableView:(UITableView *)tv didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
	
	if (![self ensureGuildPointerExists])
		return;
	
	if (indexPath.section < 0 || indexPath.section >= m_categories.size())
		return;
	
	auto& categ = m_categories[indexPath.section];
	if (indexPath.row < 0 || indexPath.row >= categ.m_channels.size())
		return;
	
	auto& item = categ.m_channels[indexPath.row];
	
	Snowflake channelID = item.m_id;
	Channel* pChan = pGuild->GetChannel(channelID);
	if (!pChan)
		return;
	
	if (pChan->IsCategory())
		return;
	
	if (GetDiscordInstance()->ReceivedForbiddenForChannelID(channelID))
	{
		GetFrontend()->OnCantViewChannel(pChan->GetFullName());
		return;
	}
	
	ChannelController *channelVC = [[ChannelController alloc] initWithChannelID:channelID andGuildID:guildID];
	channelVC.view.backgroundColor = [UIColorScheme getTextBackgroundColor];
	channelVC.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
	
	[self.navigationController pushViewController:channelVC animated:YES];
	[channelVC release];
}

- (void)dealloc
{
	if (g_pGuildController == self)
		g_pGuildController = nil;
	
	[tableView release];
	[super dealloc];
}

- (BOOL)ensureGuildPointerExists
{
	pGuild = GetDiscordInstance()->GetGuild(guildID);
	if (!pGuild) {
		[self exitIfYouDontExist];
		return NO;
	}
	
	return YES;
}

@end
