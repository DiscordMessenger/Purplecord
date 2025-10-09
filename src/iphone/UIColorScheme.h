#import <UIKit/UIKit.h>

// Not sure why they changed this.
#ifdef IPHONE_OS_3

#define UI_LINE_BREAK_MODE_WORD_WRAP UILineBreakModeWordWrap
#define UI_LINE_BREAK_MODE_CLIP      UILineBreakModeClip
#define UI_TEXT_ALIGNMENT_CENTER     UITextAlignmentCenter

#else

#define UI_LINE_BREAK_MODE_WORD_WRAP NSLineBreakByWordWrapping
#define UI_LINE_BREAK_MODE_CLIP      NSLineBreakByClipping
#define UI_TEXT_ALIGNMENT_CENTER     NSTextAlignmentCenter

#endif

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
