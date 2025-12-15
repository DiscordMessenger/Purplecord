#import "NewNavigationController.h"

@implementation NewNavigationController

- (BOOL)shouldAutorotate {
	return YES;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
		// Allow all orientations on iPad
		return YES;
	} else {
		// Only portrait on iPhone
		return (interfaceOrientation == UIInterfaceOrientationPortrait);
	}
}


@end
