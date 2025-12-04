#import <UIKit/UIKit.h>
#include <string>

// This is nothing more than a container for loaded image data.
struct LoadedImage {
	uint8_t* m_pData;
	size_t m_size;
	int m_width, m_height;
	void(*m_freeFunc)(void*);
	
	LoadedImage(uint8_t* data, size_t size, int width, int height, void(*freefunc)(void*));
	LoadedImage(const LoadedImage& other) = delete;
	LoadedImage(LoadedImage&& other);
	~LoadedImage();
	
	UIImage* ToUIImage();
	
	void MultiplyAlpha();
	
	void Resize(int width, int height);
	
	void Save(const std::string& path);
};

class ImageLoader
{
public:
	static LoadedImage* ConvertToBitmap(const uint8_t* data, size_t size, int resizeToWidth = 0, int resizeToHeight = 0);
};
