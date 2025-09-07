#pragma once
#import <UIKit/UIKit.h>

@interface GuildListController : UIViewController <UITableViewDataSource, UITableViewDelegate> {
	UITableView *tableView;
}

- (void)refreshGuilds;

@end

GuildListController* GetGuildListController();
