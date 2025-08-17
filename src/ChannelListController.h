#import <UIKit/UIKit.h>
#include <stdint.h>

@interface ChannelListController : UIViewController <UITableViewDataSource, UITableViewDelegate> {
	UITableView *tableView;
}

- (instancetype)initWithGuildID:(uint64_t)_guildID andGuildName:(NSString*)_guildName;

@end
