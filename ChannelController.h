#import <UIKit/UIKit.h>

@interface ChannelController : UIViewController <UITableViewDataSource, UITableViewDelegate> {
    UITableView *tableView;
}

- (instancetype)initWithChannelID:(uint64_t)_channelID andGuildID:(uint64_t)_guildID andChannelName:(NSString*)_channelName;

@end
