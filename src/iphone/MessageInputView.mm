#import "MessageInputView.h"

@implementation MessageInputView

- (id)initWithFrame:(CGRect)frame
{
	self = [super initWithFrame:frame];
	if (self)
	{
		UIImage* image = [UIImage imageNamed:@"messageEntryBG.png"];
		UIImageView* imageView = [[UIImageView alloc] initWithImage:image];
		
		imageView.frame = frame;
		imageView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
		
		[self addSubview:imageView];
		[imageView release];
		
		textField = [[UITextField alloc] initWithFrame:CGRectZero];
		textField.borderStyle = UITextBorderStyleRoundedRect;
		textField.autoresizingMask = UIViewAutoresizingFlexibleWidth;
		textField.delegate = self;
		textField.returnKeyType = UIReturnKeySend;
		[self addSubview:textField];
		
		sendButton = [UIButton buttonWithType:UIButtonTypeCustom];
		[sendButton setTitle:@"Send" forState:UIControlStateNormal];
		[sendButton addTarget:self action:@selector(sendPressed) forControlEvents:UIControlEventTouchUpInside];
		sendButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
		sendButton.titleLabel.font = [UIFont boldSystemFontOfSize:16];
		[self addSubview:sendButton];
		
		// make the button look like the SMS app's send button
		UIImage* buttonImageNP = [[UIImage imageNamed:@"sendButton.png"] stretchableImageWithLeftCapWidth:13 topCapHeight:13];
		UIImage* buttonImageP = [[UIImage imageNamed:@"sendButtonPressed.png"] stretchableImageWithLeftCapWidth:13 topCapHeight:13];
		[sendButton setBackgroundImage:buttonImageNP forState:UIControlStateNormal];
		[sendButton setBackgroundImage:buttonImageP forState:UIControlStateHighlighted];
		[sendButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
		[sendButton setTitleColor:[UIColor lightGrayColor] forState:UIControlStateHighlighted];
		[sendButton setTitleColor:[UIColor grayColor] forState:UIControlStateDisabled];
	}
	
	return self;
}

- (void)layoutSubviews
{
	[super layoutSubviews];
	
	CGFloat padding = 8.0f;
	CGFloat buttonWidth = SEND_BUTTON_WIDTH;
	CGFloat height = self.bounds.size.height - padding * 2;
	
	sendButton.frame = CGRectMake(self.bounds.size.width - buttonWidth - padding, padding, buttonWidth, height);
	textField.frame = CGRectMake(padding, padding, self.bounds.size.width - buttonWidth - padding * 3, height);
}

- (CGSize)sizeThatFits:(CGSize)size
{
	return CGSizeMake(size.width, BOTTOM_BAR_HEIGHT);
}

- (void)sendPressed
{
	if (textField.text.length <= 0)
		return;
	
	if ([_delegate respondsToSelector:@selector(messageInputView:didSendMessage:)])
		[_delegate messageInputView:self didSendMessage:textField.text];
	
	textField.text = @"";
}

- (void)closeKeyboard
{
	[textField resignFirstResponder];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
	[self sendPressed];
	return YES;
}

@end
