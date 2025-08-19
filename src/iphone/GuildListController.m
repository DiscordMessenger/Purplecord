#import "GuildListController.h"
#import "ChannelListController.h"

@interface GuildListController() {
	NSArray* items;
}
@end

@implementation GuildListController

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
	
	items = [[NSArray alloc] initWithObjects:@"#2 Item 1", @"#2 Item 2", @"#2 Item 3", @"#2 Item 4", @"#2 Item 5", @"#2 Item 6", @"#2 Item 7", @"#2 Item 8", @"#2 Item 9", @"#2 Item 10", @"#2 Item 11", @"#2 Item 12", @"#2 Item 13", @"#2 Item 14", @"#2 Item 15", @"#2 Item 16", nil];
}

- (void)viewDidLoad {
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

- (void)onClickedSettingsButton {
	TestFunction();
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

	ChannelListController *channelVC = [[ChannelListController alloc] initWithGuildID:indexPath.row andGuildName:selected];
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
