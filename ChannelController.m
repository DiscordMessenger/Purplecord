#import "ChannelController.h"

@interface ChannelController () {
	BOOL useSecondSet;
	NSArray *items1, *items2;
	NSArray *activeItems;
	
	uint64_t guildID;
	uint64_t channelID;
	NSString* channelName;
}
@end

@implementation ChannelController

- (instancetype)initWithChannelID:(uint64_t)_channelID andGuildID:(uint64_t)_guildID andChannelName:(NSString*)_channelName {
	self = [self init];
	if (self) {
		guildID = _guildID;
		channelID = _channelID;
		channelName = _channelName;
	}
	return self;
}

- (void)loadView {
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

    items1 = [[NSArray alloc] initWithObjects:@"#1 Item 1", @"#1 Item 2", @"#1 Item 3", @"#1 Item 4", nil];
    items2 = [[NSArray alloc] initWithObjects:@"#2 Item 1", @"#2 Item 2", @"#2 Item 3", @"#2 Item 4", @"#2 Item 5", @"#2 Item 6", @"#2 Item 7", @"#2 Item 8", @"#2 Item 9", @"#2 Item 10", @"#2 Item 11", @"#2 Item 12", @"#2 Item 13", @"#2 Item 14", @"#2 Item 15", @"#2 Item 16", nil];
}

- (void)viewDidLoad {
	[super viewDidLoad];
	
	useSecondSet = NO;
	activeItems = items1;
	
	self.title = channelName;
	
	UIBarButtonItem *toggleButton = [[UIBarButtonItem alloc] initWithTitle:@"Toggle Data Set" style:UIBarButtonItemStylePlain target:self action:@selector(toggleFlag)];
	self.navigationItem.rightBarButtonItem = toggleButton;
	[toggleButton release];
}

- (void)toggleFlag {
	useSecondSet = !useSecondSet;
	
	activeItems = useSecondSet ? items2 : items1;
	[tableView reloadData];
}

#pragma mark - UITableView DataSource / Delegate

- (NSInteger)tableView:(UITableView *)tv numberOfRowsInSection:(NSInteger)section {
    return [activeItems count];
}

- (UITableViewCell *)tableView:(UITableView *)tv cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *cellId = @"Cell";
    UITableViewCell *cell = [tv dequeueReusableCellWithIdentifier:cellId];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithFrame:CGRectMake(0,0,tv.bounds.size.width,44) reuseIdentifier:cellId];
        cell.selectionStyle = UITableViewCellSelectionStyleBlue;
    }
    cell.text = [activeItems objectAtIndex:indexPath.row];
    return cell;
}

- (void)tableView:(UITableView *)tv didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	// TODO
}

- (void)dealloc {
    [tableView release];
    [items1 release];
    [items2 release];
    [super dealloc];
}

@end
