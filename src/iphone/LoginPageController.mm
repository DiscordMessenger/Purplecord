#import <UIKit/UIKit.h>
#import "LoginPageController.h"
#import "GuildListController.h"
#import "AppDelegate.h"
#import "UIColorScheme.h"
#import "DeviceModel.h"

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
	UILabel* bottomLabel;
	UIButton* tokenShowHideButton;
	bool loggingIn;
	bool shouldLogInAgain;
}

@end

@implementation LoginPageController

- (instancetype)init
{
	self = [super init];
	shouldLogInAgain = YES;
	return self;
}

- (instancetype)initWithReconnectFlag:(BOOL)flag
{
	self = [super init];
	shouldLogInAgain = flag;
	return self;
}

- (void)loadView
{
	g_pLoginPageController = self;
	
	self->loggingIn = false;
	
	CGRect screenBounds = [[UIScreen mainScreen] bounds];
	UIView *mainView = [[UIView alloc] initWithFrame:screenBounds];
	mainView.backgroundColor = [UIColorScheme getBackgroundColor]; 
	self.view = mainView;
	[mainView release];
}

- (void)viewDidLoad
{
	CGRect screenBounds = self.view.bounds;
	
	self.title = @"Purplecord";
	
	// Add the login token box
	int width = screenBounds.size.width;
	UITextField* textField = [[UITextField alloc] initWithFrame: CGRectMake(20, 140, width - 40, 30)];
	textField.placeholder = @"Token...";
	textField.font = [UIFont systemFontOfSize:16];
	textField.textColor = [UIColorScheme getTextColor];
	textField.backgroundColor = [UIColorScheme getTextBackgroundColor];
	textField.borderStyle = UITextBorderStyleRoundedRect;
	textField.autoresizingMask = UIViewAutoresizingFlexibleWidth;
	
	tokenTextField = textField;
	
	// Also, a label above that tells you you should log in.
	label = [[UILabel alloc] initWithFrame: CGRectMake(21, 30, width - 40, 80)];
	label.text = @"Welcome to Purplecord!\nBefore you can use this client you must first log in using your token.";
	label.textAlignment = UI_TEXT_ALIGNMENT_CENTER;
	label.backgroundColor = [UIColorScheme getBackgroundColor];
	label.textColor = [UIColorScheme getTextColor];
	label.numberOfLines = 0;
	label.lineBreakMode = UI_LINE_BREAK_MODE_WORD_WRAP;
	label.font = [UIFont systemFontOfSize:15];
	label.autoresizingMask = UIViewAutoresizingFlexibleWidth;
	
	bottomLabel = [[UILabel alloc] initWithFrame:CGRectMake(21, 240, width - 40, 80)];
	bottomLabel.text = @"";
	bottomLabel.textAlignment = UI_TEXT_ALIGNMENT_CENTER;
	bottomLabel.backgroundColor = [UIColorScheme getBackgroundColor];
	bottomLabel.textColor = [UIColorScheme getTextColor];
	bottomLabel.numberOfLines = 0;
	bottomLabel.lineBreakMode = UI_LINE_BREAK_MODE_WORD_WRAP;
	bottomLabel.font = [UIFont systemFontOfSize:15];
	bottomLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
	
	// And a button
	logInButton = [
		[UIBarButtonItem alloc]
		initWithTitle:@"Login"
		style:UIBarButtonItemStylePlain
		target:self
		action:@selector(logIn)
	];
	self.navigationItem.rightBarButtonItem = logInButton;
	
	// And another button to show and hide the token input
	CGRect showButtonFrame = CGRectMake(0, 0, 20, 20);
	tokenShowHideButton = [UIButton buttonWithType:UIButtonTypeCustom];
	tokenShowHideButton.frame = showButtonFrame;
	[tokenShowHideButton retain]; // so we can release it in dealloc and keep a reference to it
	[tokenShowHideButton addTarget:self action:@selector(toggleTokenVisibility:) forControlEvents:UIControlEventTouchUpInside];
	[tokenShowHideButton setBackgroundImage:[UIImage imageNamed:@"hideEye.png"] forState:UIControlStateNormal];
	[tokenShowHideButton setBackgroundImage:[UIImage imageNamed:@"hideEyeP.png"] forState:UIControlStateHighlighted];
	tokenTextField.rightView = tokenShowHideButton;
	tokenTextField.rightViewMode = UITextFieldViewModeAlways;
	
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
	
	[self updateTokenShowHideButton];
	[self.view addSubview:textField];
	[self.view addSubview:label];
	[self.view addSubview:bottomLabel];
	[self.view addSubview:tokenShowHideButton];

	if (!GetLocalSettings()->GetToken().empty() && shouldLogInAgain) {
		[self logIn];
	}
	
	shouldLogInAgain = true;
}

- (void)updateTokenShowHideButton
{
	NSString *fn1, *fn2;
	if (tokenTextField.secureTextEntry) {
		fn1 = @"showEye.png";
		fn2 = @"showEyeP.png";
	}
	else {
		fn1 = @"hideEye.png";
		fn2 = @"hideEyeP.png";
	}
	
	[tokenShowHideButton setBackgroundImage:[UIImage imageNamed:fn1] forState:UIControlStateNormal];
	[tokenShowHideButton setBackgroundImage:[UIImage imageNamed:fn2] forState:UIControlStateHighlighted];
}

- (void)toggleTokenVisibility:(UIButton*)button
{
	tokenTextField.secureTextEntry = !tokenTextField.secureTextEntry;
	[self updateTokenShowHideButton];
}

- (void)sendToGuildList
{
	GuildListController* controller = [[GuildListController alloc] init];
	controller.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
	
	AppDelegate *appDelegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
	UINavigationController *navController = appDelegate.navController;
	
	[navController setViewControllers:@[controller] animated:NO];
	
	[UIView beginAnimations:nil context:NULL];
	[UIView setAnimationDuration:0.5];
	
	[UIView
		setAnimationTransition:UIViewAnimationTransitionFlipFromLeft
		forView:navController.view
		cache:YES];
	
	[UIView commitAnimations];
	
	[controller release];
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
	
	if (IsSlowIDevice())
	{
	#ifdef _DEBUG
		label.text = @"Logging in...\nThis may take up to two minutes.";
	#else
		label.text = @"Logging in...\nThis may take up to a minute.";
	#endif
	}
	else
	{
		label.text = @"Logging in...\nThis shouldn't take long.";
	}
	
	// show animation
	UIActivityIndicatorView* spinner = [
		[UIActivityIndicatorView alloc]
		initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray
	];
	spinner.center = self.view.center;
	spinner.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
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

- (void)setLoginStage:(NSString*)stage
{
	bottomLabel.text = stage;
}

- (void)dealloc
{
	g_pLoginPageController = NULL;
	
	[label release];
	[bottomLabel release];
	[logInButton release];
	[tokenTextField release];
	[tokenShowHideButton release];
	[super dealloc];
}

@end
