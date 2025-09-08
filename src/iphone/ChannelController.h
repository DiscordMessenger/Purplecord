#import <UIKit/UIKit.h>
#import "MessageInputView.h"
#include "../discord/ScrollDir.hpp"
#include "../discord/Message.hpp"

@interface ChannelController : UIViewController <UITableViewDataSource, UITableViewDelegate, MessageInputViewDelegate> {
	UITableView* tableView;
}

- (instancetype)initWithChannelID:(uint64_t)_channelID andGuildID:(uint64_t)_guildID;
- (void)update;
- (void)refreshMessages:(ScrollDir::eScrollDir)sd withGapCulprit:(Snowflake)gapCulprit;
- (BOOL)isChannelIDActive:(Snowflake)channelID;
- (void)addMessage:(MessagePtr)message;
- (void)removeMessage:(Snowflake)messageID;
- (void)updateMessage:(MessagePtr)message;

@end

ChannelController* GetChannelController();
