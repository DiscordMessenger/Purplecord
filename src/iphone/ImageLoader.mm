#import "ImageLoader.h"
#import "UIProportions.h"

#define STBI_NO_THREAD_LOCALS // libc++ doesn't support thread locals
#define STB_IMAGE_IMPLEMENTATION
#define STB_IMAGE_WRITE_IMPLEMENTATION
#define STB_IMAGE_RESIZE_IMPLEMENTATION
#include <stb/stb_image.h>
#include <stb/stb_image_write.h>
#include <stb/stb_image_resize2.h>
#include <webp/decode.h>
#include "../discord/Util.hpp"

LoadedImage::LoadedImage(uint8_t* data, size_t size, int width, int height, void(*freefunc)(void*))
{
	m_pData = data;
	m_size = size;
	m_width = width;
	m_height = height;
	m_freeFunc = freefunc;
}

LoadedImage::LoadedImage(LoadedImage&& other)
{
	m_pData = other.m_pData;
	m_size = other.m_size;
	m_width = other.m_width;
	m_height = other.m_height;
	m_freeFunc = other.m_freeFunc;
	
	other.m_pData = nullptr;
	other.m_freeFunc = nullptr;
}

LoadedImage::~LoadedImage()
{
	if (m_pData && m_freeFunc)
		m_freeFunc(m_pData);
	
	m_pData = nullptr;
	m_freeFunc = nullptr;
}

void LoadedImage::MultiplyAlpha()
{
	size_t wh = (size_t)m_width * m_height;
	for (size_t i = 0; i < wh; i++)
	{
		float alpha = m_pData[4 * i + 3] / 255.f;
		m_pData[4 * i + 0] *= alpha;
		m_pData[4 * i + 1] *= alpha;
		m_pData[4 * i + 2] *= alpha;
	}
}

UIImage* LoadedImage::ToUIImage()
{
	CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
	CGContextRef ctx = CGBitmapContextCreate(
		(void *)m_pData, m_width, m_height, 8, m_width * 4,
		colorSpace, kCGBitmapByteOrder32Big | kCGImageAlphaPremultipliedLast);

	CGImageRef cgImage = CGBitmapContextCreateImage(ctx);
	UIImage *image = [UIImage imageWithCGImage:cgImage];

	CGImageRelease(cgImage);
	CGContextRelease(ctx);
	CGColorSpaceRelease(colorSpace);
	return image;
}

void LoadedImage::Resize(int width, int height)
{
	if (m_width == width && m_height == height)
		return;
	
	if (!m_pData) {
		DbgPrintF("No data to resize!");
		return;
	}
	
	uint8_t* newBuffer = stbir_resize_uint8_linear(
		m_pData, m_width, m_height, m_width * sizeof(uint32_t),
		nullptr, width, height, width * sizeof(uint32_t),
		STBIR_RGBA
	);
	
	if (!newBuffer) {
		DbgPrintF("Resizing failed!");
		return;
	}
	
	if (m_pData && m_freeFunc)
		m_freeFunc(m_pData);
	
	m_width = width;
	m_height = height;
	m_pData = newBuffer;
	m_freeFunc = free;
}

void LoadedImage::Save(const std::string& path)
{
	stbi_write_png(path.c_str(), m_width, m_height, sizeof(uint32_t), m_pData, m_width * sizeof(uint32_t));
}

static LoadedImage* DecodeWebpImage(const uint8_t* data, size_t size)
{
	int width = 0, height = 0;
	uint8_t* dataWebp = WebPDecodeRGBA(data, size, &width, &height);
	if (!dataWebp)
		return nullptr;
	
	return new LoadedImage(dataWebp, width * height * sizeof(uint32_t), width, height, WebPFree);
}

static LoadedImage* DecodeStbiImage(const uint8_t* data, size_t size)
{
	if (size > INT_MAX)
		return nullptr;

	int cif = 0, w = 0, h = 0;
	stbi_uc* dataStbi = stbi_load_from_memory(data, int(size), &w, &h, &cif, 4);
	if (!dataStbi)
		return nullptr;
	
	return new LoadedImage(dataStbi, w * h * sizeof(uint32_t), w, h, stbi_image_free);
}

LoadedImage* ImageLoader::ConvertToBitmap(const uint8_t* data, size_t size, int newWidth, int newHeight)
{
	LoadedImage* image = DecodeWebpImage(data, size);
	if (!image)
	{
		image = DecodeStbiImage(data, size);
		if (!image)
			return nullptr;
	}
	
	if (newWidth < 0)
		newWidth = ScaleByDPI(GetProfilePictureSize());
	if (newHeight < 0)
		newHeight = ScaleByDPI(GetProfilePictureSize());
	
	if (!newWidth)
		newWidth = image->m_width;
	if (!newHeight)
		newHeight = image->m_height;
	
	image->Resize(newWidth, newHeight);
	image->MultiplyAlpha();
	return image;
}
