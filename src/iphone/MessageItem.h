#import <UIKit/UIKit.h>
#include "../discord/Message.hpp"

struct AttachedImage
{
	std::string hash;
	UIImageView* imageView = nullptr;
	
	~AttachedImage();
	void SetImageView(UIImageView* iv);
};

@interface MessageItem : UITableViewCell
{
	UILabel* authorLabel;
	UILabel* dateLabel;
	UILabel* messageLabel;
	UIImageView* imageView;
	AttachedImage* attachedImages;
	size_t attachedImagesCount;
	UIActivityIndicatorView* spinner;
	MessagePtr message;
	CGFloat height;
}

@property (nonatomic) MessagePtr message;

- (void)dealloc;

- (void)configureWithMessage:(MessagePtr)message andReload:(bool)reloadAttachments;

+ (CGFloat)computeHeightForMessage:(MessagePtr)message;

@end
