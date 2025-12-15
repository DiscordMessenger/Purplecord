#import "AppDelegate.h"
#import "LoginPageController.h"
#import "NetworkController.h"
#import "UIColorScheme.h"
#import "AvatarCache.h"

@interface AppDelegate() {
	NetworkController* networkController;
	AvatarCache* avatarCache;
	LoginPageController* mainVC;
}
@end

@implementation AppDelegate

@synthesize navController;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
	networkController = [[NetworkController alloc] init];
	avatarCache = [[AvatarCache alloc] init];
	
	CGRect screenBounds = [[UIScreen mainScreen] bounds];
	window = [[UIWindow alloc] initWithFrame:screenBounds];

	mainVC = [[LoginPageController alloc] init];
	navController = [[NewNavigationController alloc] initWithRootViewController:mainVC];
	
	navController.view.frame = window.bounds;
	navController.view.autoresizingMask =
		UIViewAutoresizingFlexibleWidth |
		UIViewAutoresizingFlexibleHeight;
	
	if ([UIColorScheme useDarkMode])
	{
		navController.navigationBar.barStyle = UIBarStyleBlack;
		[UIApplication sharedApplication].statusBarStyle = UIStatusBarStyleBlackOpaque;
	}
	
#ifdef IPHONE_OS_3
	[window addSubview:navController.view];
#else
	window.rootViewController = navController;
#endif

	[window makeKeyAndVisible];

	return YES;
}

- (void)dealloc {
	[mainVC release];
	[navController release];
	[window release];
	[networkController release];
	[avatarCache release];
	[super dealloc];
}

@end