#pragma once
#import <UIKit/UIKit.h>

@interface LoginPageController : UIViewController {
}

- (instancetype)init;
- (instancetype)initWithReconnectFlag:(BOOL)shouldLogInAgain;
- (void)sendToGuildList;
- (void)setLoginStage:(NSString*)stage;

@end

LoginPageController* GetLoginPageController();
