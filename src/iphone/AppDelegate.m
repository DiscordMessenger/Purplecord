#import "AppDelegate.h"
#import "GuildListController.h"

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
	CGRect screenBounds = [[UIScreen mainScreen] bounds];
	window = [[UIWindow alloc] initWithFrame:screenBounds];

	mainVC = [[GuildListController alloc] init];
	navController = [[UINavigationController alloc] initWithRootViewController:mainVC];

	[window addSubview:navController.view];
	[window makeKeyAndVisible];

	return YES;
}

- (void)dealloc {
	[mainVC release];
	[navController release];
	[window release];
	[super dealloc];
}

@end