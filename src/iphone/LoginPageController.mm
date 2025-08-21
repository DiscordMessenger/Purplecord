#import "LoginPageController.h"
#include "../discord/LocalSettings.hpp"
#include "../discord/DiscordRequest.hpp"
#include "../discord/DiscordAPI.hpp"

std::string GetDiscordToken()
{
	return GetLocalSettings()->GetToken();
}

@interface LoginPageController() {
	UITextField* tokenTextField;
	UIBarButtonItem* logInButton;
}

@end

LoginPageController* g_pLoginPageController;

@implementation LoginPageController

- (void)loadView
{
	g_pLoginPageController = self;
	
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
	
 	// Not 100% decided about this.
	// - If the token already exists, then yes, we definitely want to hide it.
	// - But do we want to hide it when the user is trying to type it in?
	// We should make it a checkbo, but I'm lazy.
	//textField.secureTextEntry = YES;
	
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
	logInButton = [
		[UIBarButtonItem alloc]
		initWithTitle:@"Log In"
		style:UIBarButtonItemStylePlain
		target:self
		action:@selector(logIn)
	];
	self.navigationItem.rightBarButtonItem = logInButton;
	
	// Are we logged in?
	std::string token = GetLocalSettings()->GetToken();
	if (!token.empty())
	{
		// We are logged in, so pre-populate the text field.
		NSString* str = [NSString stringWithUTF8String:token.c_str()];
		textField.text = str;
		
		// Hide the token so no one can see it.
		textField.secureTextEntry = YES;
	}
	
	[self.view addSubview:textField];
	[self.view addSubview:label];
	[logInButton release];
	[label release];
}

- (void)viewDidLoad
{
	if (!GetLocalSettings()->GetToken().empty())
		[self logIn];
}

- (void)logIn
{
	logInButton.title = @"Logging in...";
	
	GetHTTPClient()->PerformRequest(
		false,
		NetRequest::GET,
		GetDiscordAPI() + "gateway",
		DiscordRequest::GATEWAY,
		0, "", GetDiscordToken()
	);
}

- (void)dealloc
{
	g_pLoginPageController = NULL;
	
	[tokenTextField release];
	[super dealloc];
}

@end
