#import <UIKit/UIKit.h>
#include "../discord/Message.hpp"
#include "MessageItem.h"

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

@interface MessageCell : UITableViewCell
{
	UILabel* authorLabel;
	UILabel* dateLabel;
	UILabel* messageLabel;
	UIImageView* imageView;
	AttachedImage* attachedImages;
	size_t attachedImagesCount;
	UIActivityIndicatorView* spinner;
	MessageItemPtr messageItem;
	CGFloat height;
}

@property (nonatomic) MessageItemPtr messageItem;

- (void)dealloc;

- (void)configureWithMessage:(MessageItemPtr)messageItem andReload:(bool)reloadAttachments isEndOfChain:(bool)isEndOfChain;

+ (CGFloat)computeHeightForMessage:(MessageItemPtr)messageItem isEndOfChain:(bool)isEndOfChain;

@end
