#import <UIKit/UIKit.h>
#include "../discord/Message.hpp"

@interface MessageItem : UITableViewCell
{
	UILabel* authorLabel;
	UILabel* dateLabel;
	UILabel* messageLabel;
	UIImageView* imageView;
	UIActivityIndicatorView* spinner;
	MessagePtr message;
	CGFloat height;
}

@property (nonatomic) MessagePtr message;

- (void)dealloc;

- (void)configureWithMessage:(MessagePtr)message;

+ (CGFloat)computeHeightForMessage:(MessagePtr)message;

@end
