#import "GuildController.h"
#import "ChannelController.h"
#include "../discord/DiscordInstance.hpp"

struct ChannelMember
{
	Snowflake m_category;
	Snowflake m_id;
	Channel::eChannelType m_type;
	std::string m_name;
	int m_categIndex;
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

	bool operator<(const ChannelMember& other) const
	{
		if (IsDM()) {
			// the other is probably a DM too
			if (m_lastMessageID != other.m_lastMessageID)
				return m_lastMessageID > other.m_lastMessageID;
		}

		// sort by which category we're in
		if (m_categIndex != other.m_categIndex)
			return m_categIndex < other.m_categIndex;
		
		if (m_category != other.m_category)
			return m_category < other.m_category;

		// within each category, sort by position
		if (!IsCategory() && !other.IsCategory() && m_pos != other.m_pos)
			return m_pos < other.m_pos;
		
		return m_id < other.m_id;
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

	return mentions + ch.GetTypeSymbol() + ch.m_name + unreadMarker;
}

GuildController* g_pGuildController;
GuildController* GetGuildController() {
	return g_pGuildController;
}

@interface GuildController() {
	uint64_t guildID;
	Guild* pGuild;
	std::map<Snowflake, int> m_idToIdx;
	std::vector<ChannelMember> m_items;
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
	
	assert(!g_pGuildController);
	g_pGuildController = self;
	
	return self;
}

- (void)exitIfYouDontExist
{
	if (!GetDiscordInstance()->GetGuild(guildID))
		[self.navigationController popViewControllerAnimated:YES];
}

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
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
	
	GetDiscordInstance()->OnSelectGuild(guildID);
	
	[self updateChannelList];
}

- (void)onClickedSettingsButton {
	// TODO
}

- (void)addChannel:(const Channel&) ch
{
	if (!ch.HasPermissionConst(PERM_VIEW_CHANNEL))
	{
		// If not a category, return.  We'll remove invisible categories without elements after the fact.
		if (ch.m_channelType != Channel::CATEGORY)
			return;
	}

	// TODO: Implement category order sorting. For now, they're sorted by ID.
	// 11/06/2025 - Are they!?
	int categIndex = ch.IsCategory() ? ch.m_pos : 0;

	m_idToIdx[ch.m_snowflake] = (int) m_items.size();
	m_items.push_back({ ch.m_parentCateg, ch.m_snowflake, ch.m_channelType, GetChannelString(ch), categIndex, ch.m_pos, ch.m_lastSentMsg });
}

- (void)commitChannels
{
	// calculate category indices
	std::map<Snowflake, int> categIdxs;
	for (auto& item : m_items) {
		if (item.m_type == Channel::CATEGORY)
			categIdxs[item.m_id] = item.m_categIndex;
	}

	for (auto& item : m_items) {
		if (item.m_type != Channel::CATEGORY)
			item.m_categIndex = categIdxs[item.m_category];
	}

	std::sort(m_items.begin(), m_items.end());
}

- (void)recomputeChannels
{
	m_items.clear();
	m_idToIdx.clear();
	
	if (!pGuild->m_bChannelsLoaded)
	{
		pGuild->RequestFetchChannels();
		return;
	}
	
	for (auto& ch : pGuild->m_channels)
		[self addChannel:ch.second];
	
	[self commitChannels];
	
	for (size_t i = 0; i < m_items.size(); )
	{
		// remove any empty categories.
		if (m_items[i].IsCategory() && (i + 1 >= m_items.size() || m_items[i + 1].IsCategory()))
			m_items.erase(m_items.begin() + i);
		else
			i++;
	}
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

- (NSInteger)tableView:(UITableView*)tv numberOfRowsInSection:(NSInteger)section {
	if (![self ensureGuildPointerExists])
		return 0;
	
	return m_items.size();
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	if (![self ensureGuildPointerExists])
		return nil;
	
	if (indexPath.row < 0 || indexPath.row >= m_items.size())
		return nil;
	
	auto& item = m_items[indexPath.row];
	if (item.IsCategory())
		return 28.0f;
	
	return 44.0f; // default
}

- (UITableViewCell*)tableView:(UITableView*)tv cellForRowAtIndexPath:(NSIndexPath*)indexPath {
	if (![self ensureGuildPointerExists])
		return nil;
	
	if (indexPath.row < 0 || indexPath.row >= m_items.size())
		return nil;
	
	auto& item = m_items[indexPath.row];
	
	NSString* text = [NSString stringWithUTF8String:item.m_name.c_str()];
	UITableViewCell *cell = [[UITableViewCell alloc] initWithFrame:CGRectMake(0,0,tv.bounds.size.width,44)];
	
	if (item.IsCategory()) {
		cell.textLabel.textColor = [UIColor lightGrayColor];
		cell.textLabel.font = [UIFont boldSystemFontOfSize:16.0];
		cell.selectionStyle = UITableViewCellSelectionStyleNone;
		cell.userInteractionEnabled = NO;
	}
	else {
		cell.textLabel.textColor = [UIColor blackColor];
		cell.textLabel.font = [UIFont boldSystemFontOfSize:20.0];
		cell.selectionStyle = UITableViewCellSelectionStyleBlue;
		cell.userInteractionEnabled = YES;
	}
	
	cell.text = text;
	return cell;
}

- (void)tableView:(UITableView *)tv didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	if (![self ensureGuildPointerExists])
		return;
	
	if (indexPath.row < 0 || indexPath.row >= m_items.size())
		return;
	
	auto& item = m_items[indexPath.row];
	
	Snowflake channelID = item.m_id;
	Channel* pChan = pGuild->GetChannel(channelID);
	if (!pChan)
		return;
	
	if (pChan->IsCategory())
		return;
	
	ChannelController *channelVC = [[ChannelController alloc] initWithChannelID:channelID andGuildID:guildID];
	channelVC.view.backgroundColor = [UIColor whiteColor];
	
	[self.navigationController pushViewController:channelVC animated:YES];
	[channelVC release];
}

- (void)dealloc {
	g_pGuildController = nullptr;
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
