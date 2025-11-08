#import <UIKit/UIKit.h>
#include "UIProportions.h"

@class MessageInputView;

@protocol MessageInputViewDelegate <NSObject>
- (void)messageInputView:(MessageInputView *)inputView didSendMessage:(NSString *)message;

- (void)messageInputView:(MessageInputView *)inputView didAttachFile:(void*)unused;
@end

@interface MessageInputView : UIView <UITextFieldDelegate> {
	UITextField* textField;
	UIButton* sendButton;
	UIButton* photoButton;
}

@property (nonatomic, assign) id<MessageInputViewDelegate> delegate;

- (void)closeKeyboard;

@end
