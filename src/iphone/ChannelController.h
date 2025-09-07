#import <UIKit/UIKit.h>
#include "../discord/ScrollDir.hpp"
#include "../discord/Snowflake.hpp"

@interface ChannelController : UIViewController <UITableViewDataSource, UITableViewDelegate> {
	UITableView* tableView;
}

- (instancetype)initWithChannelID:(uint64_t)_channelID andGuildID:(uint64_t)_guildID;
- (void)update;
- (void)refreshMessages:(ScrollDir::eScrollDir)sd withGapCulprit:(Snowflake)gapCulprit;

@end

ChannelController* GetChannelController();
