// This is a private API. Normally I don't use these.
// Taken from https://github.com/kennytm/iphone-private-frameworks/blob/master/UIKit/UIProgressHUD.h
#import "UIProgressHUD.h"
#import <UIKit/UIView.h>

@class UIImageView, UILabel, UIProgressIndicator, UIWindow;

@interface UIProgressHUD : UIView {
	UIProgressIndicator* _progressIndicator;
	UILabel* _progressMessage;
	UIImageView* _doneView;
	UIWindow* _parentWindow;
	struct {
		unsigned isShowing : 1;
		unsigned isShowingText : 1;
		unsigned fixedFrame : 1;
		unsigned reserved : 30;
	} _progressHUDFlags;
}
-(id)_progressIndicator;
-(id)initWithFrame:(CGRect)frame;
-(void)setText:(id)text;
-(void)setShowsText:(BOOL)text;
-(void)setFontSize:(int)size;
-(void)drawRect:(CGRect)rect;
-(void)layoutSubviews;
-(void)showInView:(id)view;
-(void)hide;
-(void)done;
-(void)dealloc;
@end

@interface UIProgressHUD (Deprecated)
-(id)initWithWindow:(id)window;
-(void)show:(BOOL)show;
@end