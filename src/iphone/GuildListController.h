#pragma once
#import <UIKit/UIKit.h>

@interface GuildListController : UIViewController <UITableViewDataSource, UITableViewDelegate> {
	UITableView *tableView;
}

@end
