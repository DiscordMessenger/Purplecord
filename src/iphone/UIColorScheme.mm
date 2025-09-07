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
		return [UIColor groupTableViewBackgroundColor];
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
