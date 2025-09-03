#pragma once
#import <UIKit/UIKit.h>
#include "HTTPClient_iOS.h"

@interface GuildListController : UIViewController <UITableViewDataSource, UITableViewDelegate> {
	UITableView *tableView;
}

@end
