#import "ChannelListController.h"
#import "ChannelController.h"

@interface ChannelListController() {
	NSArray* items;
	
	uint64_t guildID;
	NSString* guildName;
}
@end

@implementation ChannelListController

- (instancetype)initWithGuildID:(uint64_t)_guildID andGuildName:(NSString*)_guildName {
	self = [self init];
	if (self) {
		guildID = _guildID;
		guildName = _guildName;
	}
	return self;
}

- (void)loadView {
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
	
	items = [[NSArray alloc] initWithObjects:@"Channel 1", @"Channel 2", @"Channel 3", nil];
}

- (void)onClickedSettingsButton {
	// TODO
}

- (NSInteger)tableView:(UITableView*)tv numberOfRowsInSection:(NSInteger)section {
	return [items count];
}

- (UITableViewCell*)tableView:(UITableView*)tv cellForRowAtIndexPath:(NSIndexPath*)indexPath {
    static NSString *cellId = @"Cell";
    UITableViewCell *cell = [tv dequeueReusableCellWithIdentifier:cellId];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithFrame:CGRectMake(0,0,tv.bounds.size.width,44) reuseIdentifier:cellId];
        cell.selectionStyle = UITableViewCellSelectionStyleBlue;
    }
    cell.text = [items objectAtIndex:indexPath.row];
    return cell;
}

- (void)tableView:(UITableView *)tv didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString *selected = [items objectAtIndex:indexPath.row];

	ChannelController *channelVC = [[ChannelController alloc] initWithChannelID:indexPath.row andGuildID:guildID andChannelName:selected];
    channelVC.view.backgroundColor = [UIColor whiteColor];
    channelVC.title = selected;

    [self.navigationController pushViewController:channelVC animated:YES];
    [channelVC release];
}

- (void)dealloc {
    [tableView release];
    [items release];
    [super dealloc];
}

@end
