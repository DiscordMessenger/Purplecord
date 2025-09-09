#import <UIKit/UIKit.h>
#include "UIProportions.h"

@class MessageInputView;

@protocol MessageInputViewDelegate <NSObject>
- (void)messageInputView:(MessageInputView *)inputView didSendMessage:(NSString *)message;
@end

@interface MessageInputView : UIView <UITextFieldDelegate> {
	UITextField* textField;
	UIButton* sendButton;
}

@property (nonatomic, assign) id<MessageInputViewDelegate> delegate;

- (void)closeKeyboard;

@end
