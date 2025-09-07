#pragma once
#import <UIKit/UIKit.h>

@interface LoginPageController : UIViewController {
}

- (void)sendToGuildList;

@end

LoginPageController* GetLoginPageController();
