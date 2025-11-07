#import <UIKit/UIKit.h>
#include "../discord/Message.hpp"

struct AttachedImage
{
	std::string hash;
	UIImageView* imageView = nullptr;
	UIActivityIndicatorView* spinnerView = nullptr;
	
	~AttachedImage();
	void SetImageView(UIImageView* iv);
	void SetSpinnerView(UIActivityIndicatorView* av);
};

bool IsActionMessage(MessageType::eType msgType);
bool IsClientSideMessage(MessageType::eType msgType);
bool IsPinnableActionMessage(MessageType::eType msgType);
bool IsReplyableActionMessage(MessageType::eType msgType);

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
