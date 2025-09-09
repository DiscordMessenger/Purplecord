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

@property (nonatomic, retain) UILabel *authorLabel;
@property (nonatomic, retain) UILabel *dateLabel;
@property (nonatomic, retain) UILabel *messageLabel;
@property (nonatomic) MessagePtr message;
@property (nonatomic) CGFloat height;

- (void)configureWithMessage:(MessagePtr)message;

@end
