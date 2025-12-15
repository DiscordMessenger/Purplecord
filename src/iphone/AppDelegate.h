#import <UIKit/UIKit.h>
#import "NewNavigationController.h"

@class GuildListController;

@interface AppDelegate : NSObject <UIApplicationDelegate> {
	UIWindow *window;
	NewNavigationController *navController;
}

@property (nonatomic, retain) NewNavigationController *navController;

@end
