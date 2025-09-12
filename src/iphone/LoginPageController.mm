#import <UIKit/UIKit.h>
#import "LoginPageController.h"
#import "GuildListController.h"
#import "UIColorScheme.h"

#include "../discord/LocalSettings.hpp"
#include "../discord/DiscordRequest.hpp"
#include "../discord/DiscordAPI.hpp"
#include "../discord/Util.hpp"
#include "HTTPClient_curl.h"

LoginPageController* g_pLoginPageController;
LoginPageController* GetLoginPageController() {
	return g_pLoginPageController;
}

// N.B.  This has RESTRICTED access to GetDiscordInstance() while logging in,
// because things may be worked on in a background thread!

std::string GetDiscordToken()
{
	return GetLocalSettings()->GetToken();
}

void CreateDiscordInstanceIfNeeded();

@interface LoginPageController() {
	UITextField* tokenTextField;
	UIBarButtonItem* logInButton;
	UILabel* label;
	bool loggingIn;
}

@end

@implementation LoginPageController

- (void)loadView
{
	g_pLoginPageController = self;
	
	self->loggingIn = false;
	
	CGRect screenBounds = [[UIScreen mainScreen] bounds];
	
	UIView *mainView = [[UIView alloc] initWithFrame:screenBounds];
	mainView.backgroundColor = [UIColorScheme getBackgroundColor]; 
	self.view = mainView;
	[mainView release];
	
	self.title = @"Purplecord";
	
	// Add the login token box
	int width = screenBounds.size.width;
	UITextField* textField = [[UITextField alloc] initWithFrame: CGRectMake(20, 140, width - 40, 30)];
	textField.placeholder = @"Token...";
	textField.font = [UIFont systemFontOfSize:16];
	textField.backgroundColor = [UIColorScheme getBackgroundColor];
	textField.borderStyle = UITextBorderStyleRoundedRect;
	
 	// Not 100% decided about this.
	// - If the token already exists, then yes, we definitely want to hide it.
	// - But do we want to hide it when the user is trying to type it in?
	// We should make it a checkbo, but I'm lazy.
	//textField.secureTextEntry = YES;
	
	tokenTextField = textField;
	
	// Also, a label above that tells you you should log in.
	label = [[UILabel alloc] initWithFrame: CGRectMake(20, 30, width - 40, 80)];
	label.text = @"Welcome to Purplecord!\nBefore you can use this client you must first log in using your token.";
	label.textAlignment = UITextAlignmentCenter;
	label.backgroundColor = [UIColorScheme getBackgroundColor];
	label.textColor = [UIColorScheme getTextColor];
	label.numberOfLines = 0;
	label.lineBreakMode = UILineBreakModeWordWrap;
	label.font = [UIFont systemFontOfSize:15];
	
	// And a button
	logInButton = [
		[UIBarButtonItem alloc]
		initWithTitle:@"Login"
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

- (void)sendToGuildList
{
	GuildListController* controller = [[GuildListController alloc] init];
	UINavigationController* navController = [[UINavigationController alloc] initWithRootViewController:controller];
	
	if ([UIColorScheme useDarkMode])
		navController.navigationBar.barStyle = UIBarStyleBlack;
	
	UIWindow* window = [UIApplication sharedApplication].keyWindow;
	if (!window) {
		window = [[UIApplication sharedApplication].windows objectAtIndex:0];
	}
	
	[window addSubview:navController.view];
	[window makeKeyAndVisible];
	
	[UIView beginAnimations:nil context:NULL];
	[UIView setAnimationDuration:0.5];
	[UIView setAnimationTransition:UIViewAnimationTransitionFlipFromLeft forView:window cache:YES];
	
	[self.view removeFromSuperview];
	[UIView commitAnimations];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
	// RETURN pressed
	[self logIn];
	return YES;
}

- (void)logIn
{
	// close keyboard
	[tokenTextField resignFirstResponder];
	
	if (self->loggingIn)
		return;
	
	NSString* nsString = tokenTextField.text;
	const char* utf8String = [nsString cStringUsingEncoding:NSUTF8StringEncoding];
	std::string token(utf8String ? utf8String : "");
	
	if (token.empty())
	{
		UIAlertView* alert = [[UIAlertView alloc]
			initWithTitle:@"No token inserted"
			message:@"You must log in using a token."
			delegate:nil
			cancelButtonTitle:@"Got it"
			otherButtonTitles:nil
		];
		
		[alert show];
		[alert release];
		return;
	}
	
	self->loggingIn = true;
	logInButton.title = @"Logging in...";
	logInButton.enabled = NO;
	
	label.text = @"Please wait...\nThis may take up to a minute. Sorry it isn't faster.";
	
	// show animation
	UIActivityIndicatorView* spinner = [
		[UIActivityIndicatorView alloc]
		initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray
	];
	spinner.center = self.view.center;
	[self.view addSubview:spinner];
	[spinner startAnimating];
	[spinner release];
	
	// kick-start the login procedure
	GetLocalSettings()->SetToken(token);
	GetLocalSettings()->Save();
	CreateDiscordInstanceIfNeeded();
	
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
	
	[label release];
	[tokenTextField release];
	[super dealloc];
}

@end
