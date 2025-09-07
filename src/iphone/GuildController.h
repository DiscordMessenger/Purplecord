#import <UIKit/UIKit.h>
#include <stdint.h>

@interface GuildController : UIViewController <UITableViewDataSource, UITableViewDelegate> {
	UITableView *tableView;
}

- (instancetype)initWithGuildID:(uint64_t)_guildID;
- (void)exitIfYouDontExist;
- (void)updateChannelList;

@end

GuildController* GetGuildController();
