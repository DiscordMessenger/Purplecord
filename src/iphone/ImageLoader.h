#import <UIKit/UIKit.h>

@interface ImageLoader : NSObject

+ (UIImage*)convertToBitmap:(const uint8_t*)data size:(size_t)size resizeToWidth:(NSInteger)width andHeight:(NSInteger)height;

@end
