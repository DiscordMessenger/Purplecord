#import "MessageInputView.h"

@implementation MessageInputView

#define PHOTO_BUTTON_WIDTH 26
#define PHOTO_BUTTON_HEIGHT 27

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
		
		photoButton = [UIButton buttonWithType:UIButtonTypeCustom];
		[photoButton setTitle:@"" forState:UIControlStateNormal];
		[photoButton addTarget:self action:@selector(photoPressed) forControlEvents:UIControlEventTouchUpInside];
		photoButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
		photoButton.titleLabel.font = [UIFont boldSystemFontOfSize:16];
		[self addSubview:photoButton];
		
		// make the button look like the SMS app's send button
		UIImage* buttonImageNP = [[UIImage imageNamed:@"sendButton.png"] stretchableImageWithLeftCapWidth:13 topCapHeight:13];
		UIImage* buttonImageP = [[UIImage imageNamed:@"sendButtonPressed.png"] stretchableImageWithLeftCapWidth:13 topCapHeight:13];
		[sendButton setBackgroundImage:buttonImageNP forState:UIControlStateNormal];
		[sendButton setBackgroundImage:buttonImageP forState:UIControlStateHighlighted];
		[sendButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
		[sendButton setTitleColor:[UIColor lightGrayColor] forState:UIControlStateHighlighted];
		[sendButton setTitleColor:[UIColor grayColor] forState:UIControlStateDisabled];
		
		UIImage* photoButtonImageNP = [[UIImage imageNamed:@"photoButton.png"] stretchableImageWithLeftCapWidth:13 topCapHeight:13];
		UIImage* photoButtonImageP = [[UIImage imageNamed:@"photoButtonPressed.png"] stretchableImageWithLeftCapWidth:13 topCapHeight:13];
		UIImage* photoButtonImageD = [[UIImage imageNamed:@"photoButtonDisabled.png"] stretchableImageWithLeftCapWidth:13 topCapHeight:13];
		[photoButton setBackgroundImage:photoButtonImageNP forState:UIControlStateNormal];
		[photoButton setBackgroundImage:photoButtonImageP forState:UIControlStateHighlighted];
	}
	
	return self;
}

- (void)layoutSubviews
{
	[super layoutSubviews];
	
	bool addPhotoButton = true; // TODO
	
	CGFloat padding = 8.0f;
	CGFloat buttonWidth = SEND_BUTTON_WIDTH;
	CGFloat photoButtonWidth = PHOTO_BUTTON_WIDTH;
	CGFloat height = self.bounds.size.height - padding * 2;
	
	sendButton.frame = CGRectMake(self.bounds.size.width - buttonWidth - padding, padding, buttonWidth, height);
	
	if (addPhotoButton) {
		photoButton.frame = CGRectMake(padding, padding, PHOTO_BUTTON_WIDTH, PHOTO_BUTTON_HEIGHT);
		textField.frame = CGRectMake(padding * 2 + photoButtonWidth, padding, self.bounds.size.width - buttonWidth - padding * 4 - photoButtonWidth, height);
	}
	else {
		photoButton.frame = CGRectMake(0, 0, 0, 0);
		textField.frame = CGRectMake(padding, padding, self.bounds.size.width - buttonWidth - padding * 3, height);
	}
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

- (void)photoPressed
{
	// TODO
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
