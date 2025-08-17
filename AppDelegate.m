#import "AppDelegate.h"
#import "MainTableController.h"

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    CGRect screenBounds = [[UIScreen mainScreen] bounds];
    window = [[UIWindow alloc] initWithFrame:screenBounds];

    mainVC = [[MainTableController alloc] init];
    navController = [[UINavigationController alloc] initWithRootViewController:mainVC];

    [window addSubview:navController.view];  // iOS 2.0 style
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