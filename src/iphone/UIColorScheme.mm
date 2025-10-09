#import "UIColorScheme.h"
#include "../discord/LocalSettings.hpp"

@implementation UIColorScheme

+ (BOOL)useDarkMode
{
	return GetLocalSettings()->UseDarkMode() ? YES : NO;
}

+ (UIColor*)getBackgroundColor
{
	if ([self useDarkMode])
		return [UIColor blackColor];
	else
#ifdef IPHONE_OS_3
		return [UIColor groupTableViewBackgroundColor];
#else
		return [UIColor underPageBackgroundColor];
#endif
}

+ (UIColor*)getTextBackgroundColor
{
	if ([self useDarkMode])
		return [UIColor blackColor];
	else
		return [UIColor whiteColor];
}

+ (UIColor*)getTextColor
{
	if ([self useDarkMode])
		return [UIColor whiteColor];
	else
		return [UIColor blackColor];
}

@end
