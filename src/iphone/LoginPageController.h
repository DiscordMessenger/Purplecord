#pragma once
#import <UIKit/UIKit.h>

@interface LoginPageController : UIViewController {
}

- (void)sendToGuildList;
- (void)setLoginStage:(NSString*)stage;

@end

LoginPageController* GetLoginPageController();
