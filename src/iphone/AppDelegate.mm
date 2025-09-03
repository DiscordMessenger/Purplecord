#import "AppDelegate.h"
#import "LoginPageController.h"
#import "NetworkController.h"

@interface AppDelegate() {
	NetworkController* networkController;
	LoginPageController* mainVC;
}
@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
	networkController = [[NetworkController alloc] init];
	
	CGRect screenBounds = [[UIScreen mainScreen] bounds];
	window = [[UIWindow alloc] initWithFrame:screenBounds];

	mainVC = [[LoginPageController alloc] init];
	navController = [[UINavigationController alloc] initWithRootViewController:mainVC];

	[window addSubview:navController.view];
	[window makeKeyAndVisible];

	return YES;
}

- (void)dealloc {
	[mainVC release];
	[navController release];
	[window release];
	[networkController dealloc];
	[super dealloc];
}

@end