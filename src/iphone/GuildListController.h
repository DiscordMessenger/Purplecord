#pragma once
#import <UIKit/UIKit.h>
#include <string>

@interface GuildListController : UIViewController <UITableViewDataSource, UITableViewDelegate> {
	UITableView *tableView;
}

- (void)refreshGuilds;
- (void)updateAttachmentByID:(const std::string&)resource;

@end

GuildListController* GetGuildListController();
