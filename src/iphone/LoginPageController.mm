#import "LoginPageController.h"
#include "../discord/LocalSettings.hpp"

@interface LoginPageController() {
	UITextField* tokenTextField;
}

@end

@implementation LoginPageController

- (void)loadView
{
	// Are we logged in?
	if (!GetLocalSettings()->GetToken().empty())
	{
		// We are logged in, so don't create anything and just log in
		// TODO
		return;
	}
	
	CGRect screenBounds = [[UIScreen mainScreen] bounds];
	
	UIView *mainView = [[UIView alloc] initWithFrame:screenBounds];
	mainView.backgroundColor = [UIColor groupTableViewBackgroundColor]; 
	self.view = mainView;
	[mainView release];
	
	self.title = @"Log In to Purplecord";
	
	// Add the login token box
	int width = screenBounds.size.width;
	UITextField* textField = [[UITextField alloc] initWithFrame: CGRectMake(20, 140, width - 40, 30)];
	textField.placeholder = @"Token...";
	textField.font = [UIFont systemFontOfSize:16];
	textField.backgroundColor = [UIColor groupTableViewBackgroundColor];
	textField.textColor = [UIColor blackColor];
	textField.borderStyle = UITextBorderStyleRoundedRect;
	tokenTextField = textField;
	
	// Also, a label above that tells you you should log in.
	UILabel* label = [[UILabel alloc] initWithFrame: CGRectMake(20, 30, width - 40, 80)];
	label.text = @"Welcome to Purplecord!\nBefore you can use this client you must first log in using your token.";
	label.textAlignment = UITextAlignmentCenter;
	label.backgroundColor = [UIColor groupTableViewBackgroundColor];
	label.numberOfLines = 0;
	label.lineBreakMode = UILineBreakModeWordWrap;
	label.font = [UIFont systemFontOfSize:15];
	
	// And a button
	UIBarButtonItem* logInButton = [
		[UIBarButtonItem alloc]
		initWithTitle:@"Log In"
		style:UIBarButtonItemStylePlain
		target:self
		action:@selector(logIn)
	];
	self.navigationItem.rightBarButtonItem = logInButton;
	
	[self.view addSubview:textField];
	[self.view addSubview:label];
	[logInButton release];
	[label release];
}

- (void)logIn
{
	// TODO
}

- (void)dealloc
{
	[tokenTextField release];
	[super dealloc];
}

@end
