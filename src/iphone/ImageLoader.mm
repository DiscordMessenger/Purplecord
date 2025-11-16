#import "ImageLoader.h"
#import "UIProportions.h"

#define STBI_NO_THREAD_LOCALS // libc++ doesn't support thread locals
#define STB_IMAGE_IMPLEMENTATION
#define STB_IMAGE_WRITE_IMPLEMENTATION
#include <stb/stb_image.h>
#include <stb/stb_image_write.h>
#include <webp/decode.h>
#include "../discord/Util.hpp"

@implementation ImageLoader

+ (UIImage*)decodeWebp:(const uint8_t*)data size:(size_t)size
{
	int width = 0, height = 0;
	uint8_t* dataWebp = WebPDecodeRGBA(data, size, &width, &height);
	if (!dataWebp)
		return nil;

	// Annoyingly you can't just create a UIImage with raw data.
	// Have to do this instead.
	CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
	CGContextRef ctx = CGBitmapContextCreate(
		(void *)dataWebp, width, height, 8, width * 4,
		colorSpace, kCGBitmapByteOrder32Big | kCGImageAlphaPremultipliedLast);

	CGImageRef cgImage = CGBitmapContextCreateImage(ctx);
	UIImage *image = [UIImage imageWithCGImage:cgImage];

	CGImageRelease(cgImage);
	CGContextRelease(ctx);
	CGColorSpaceRelease(colorSpace);
	
	WebPFree(dataWebp);
	return image;
}

+ (UIImage*)decodeWithStbImage:(const uint8_t*)data size:(size_t)size
{
	if (size > INT_MAX)
		return nil;

	int cif = 0, w = 0, h = 0;
	stbi_uc* dataStbi = stbi_load_from_memory(data, int(size), &w, &h, &cif, 4);
	if (!dataStbi)
		return nil;

	// Annoyingly you can't just create a UIImage with raw data.
	// Have to do this instead.
	CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
	CGContextRef ctx = CGBitmapContextCreate(
		(void *)dataStbi, w, h, 8, w * 4,
		colorSpace, kCGBitmapByteOrder32Big | kCGImageAlphaPremultipliedLast);

	CGImageRef cgImage = CGBitmapContextCreateImage(ctx);
	UIImage *image = [UIImage imageWithCGImage:cgImage];

	CGImageRelease(cgImage);
	CGContextRelease(ctx);
	CGColorSpaceRelease(colorSpace);
	
	stbi_image_free(dataStbi);
	return image;
}

+ (UIImage*)resizeImage:(UIImage*)image width:(NSInteger)width height:(NSInteger)height
{
	if (image == nil)
		return image;
	if (width == image.size.width && height == image.size.height)
		return image;
	
#ifdef IPHONE_OS_3
	UIGraphicsBeginImageContext(CGSizeMake(width, height));
#else
	UIGraphicsBeginImageContextWithOptions(
		CGSizeMake(UnscaleByDPI(width), UnscaleByDPI(height)),
		NO,
		[[UIScreen mainScreen] scale]
	);
#endif
	
	DbgPrintF("Width: %d   UnscaleByDPI(Width): %d", width, UnscaleByDPI(width));
	[image drawInRect:CGRectMake(0, 0, UnscaleByDPI(width), UnscaleByDPI(height))];
	
	UIImage* newImage = UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();
	return newImage;
}

+ (UIImage*)convertToBitmap:(const uint8_t*)data size:(size_t)size resizeToWidth:(NSInteger)newWidth andHeight:(NSInteger)newHeight
{
	UIImage* img = [ImageLoader decodeWebp:data size:size];
	
	if (img == nil)
	{
		// try using stb_image instead, probably a png/gif/jpg
		img = [ImageLoader decodeWithStbImage:data size:size];
		
		if (img == nil)
			return nil;
	}
	
	if (newWidth < 0)
		newWidth = ScaleByDPI(GetProfilePictureSize());
	if (newHeight < 0)
		newHeight = ScaleByDPI(GetProfilePictureSize());
	
	if (!newWidth)
		newWidth = img.size.width;
	if (!newHeight)
		newHeight = img.size.height;
	
	img = [ImageLoader resizeImage:img width:newWidth height:newHeight];
	return img;
}

@end
