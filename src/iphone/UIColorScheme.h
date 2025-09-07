#import <UIKit/UIKit.h>

@interface UIColorScheme : NSObject

// checks if dark mode is enabled
+ (BOOL)useDarkMode;

// gets the background color behind UI elements
+ (UIColor*)getBackgroundColor;

// gets the background color on UI elements
+ (UIColor*)getTextBackgroundColor;

// gets the color of text
+ (UIColor*)getTextColor;

@end

UIColorScheme* GetUIColorScheme();
