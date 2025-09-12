#import <UIKit/UIKit.h>
#include <string>
#include <vector>
#include <map>
#include <set>
#include "../discord/Snowflake.hpp"

enum class eImagePlace
{
	NONE,
	AVATARS,       // profile avatars
	ICONS,         // server icons
	ATTACHMENTS,   // attachments
	CHANNEL_ICONS, // channel icons
	EMOJIS,        // emojis
};

struct ImagePlace
{
	eImagePlace type = eImagePlace::NONE;
	Snowflake sf = 0;
	std::string place;
	std::string key;
	int sizeOverride = 0;
	
	ImagePlace() {}
	ImagePlace(eImagePlace t, Snowflake s, const std::string& p, const std::string& k, int so):
		type(t), sf(s), place(p), key(k), sizeOverride(so) {}

	void SetSizeOverride(int so) { sizeOverride = so; }
	bool IsAttachment() const { return type == eImagePlace::ATTACHMENTS; }
	std::string GetURL() const;
};

#define HIMAGE_LOADING ((UIImage*) (uintptr_t) 0xDDCCBBAA)
#define HIMAGE_ERROR   ((UIImage*) (uintptr_t) 0xDDCCBBAB)

class BitmapObject
{
public:
	BitmapObject() {}
	BitmapObject(UIImage* image, int age): m_age(age) {
		SetImage(image);
	}
	
	~BitmapObject() {
		ClearImage();
	}
	
	BitmapObject(BitmapObject&& other) noexcept {
		m_image = other.m_image;
		m_age = other.m_age;
		other.m_image = NULL;
	}
	
	BitmapObject(const BitmapObject& other) {
		SetImage(other.m_image);
		m_age = other.m_age;
	}
	
	BitmapObject& operator=(const BitmapObject& other) {
		SetImage(other.m_image);
		m_age = other.m_age;
		return *this;
	}
	
	BitmapObject& operator=(BitmapObject&& other) noexcept {
		m_image = other.m_image;
		m_age = other.m_age;
		other.m_image = NULL;
		return *this;
	}
	
	void SetImage(UIImage* image) {
		ClearImage();
		
		m_image = image;
		if (!IsSpecialImage())
			[m_image retain];
	}

	void ClearImage() {
		if (!IsSpecialImage())
			[m_image release];
		
		m_image = nil;
	}

	UIImage* GetImage() {
		return m_image;
	}
	
	bool IsSpecialImage() const {
		return m_image == HIMAGE_LOADING || m_image == HIMAGE_ERROR || m_image == nil;
	}
	
private:
	UIImage* m_image = nil;
public:
	int m_age = 0;
};

@interface AvatarCache : NSObject

// Initializes.
- (instancetype)init;

// Deallocates.
- (void)dealloc;

// Create a 32-character identifier based on the resource name.  If a 32 character
// GUID was provided, return it, otherwise perform the MD5 hash of the string.
- (std::string)makeIdentifier:(const std::string&)resource;

// Let the avatar cache know where resource with the specified ID is located.
// Returns the resource ID to avoid further md5 hashes on the same content.
- (std::string)addImagePlace:(const std::string&)resource imagePlace:(eImagePlace)ip place:(const std::string&)place imageId:(Snowflake)sf sizeOverride:(NSInteger)sizeOverride;

// Sets the bitmap associated with the resource ID.
- (void)setImage:(const std::string&)resource image:(UIImage*)image;

// Get the type of the resource with the specified ID.
- (ImagePlace)getPlace:(const std::string&)resource;

// Let the avatar cache know that the resource was loaded.
- (void)loadedResource:(const std::string&)resource;

// Get the bitmap associated with the resource.  If it isn't loaded, request it, and return a default.
- (UIImage*)getImage:(const std::string&)resource;

// Get the bitmap associated with the resource.  If it isn't loaded, request it, and return NULL.
- (UIImage*)getImageNullable:(const std::string&)resource;

// Delete all bitmaps.
- (void)wipeBitmaps;

// Erase the bitmap with the specified ID.
- (void)eraseBitmap:(const std::string&)resource;

// Trim a single bitmap slot.  This makes room for another.
- (bool)trimBitmap;

// Trim X bitmap slots.  This makes room for others.
- (int)trimBitmaps:(NSInteger)num;

// Age all loaded bitmaps.  This is used to determine which ones are least frequent and ripe to purge.
- (void)ageBitmaps;

// Clear the processing requests set.  These requests will never be fulfilled.
- (void)clearProcessingRequests;

@end

AvatarCache* GetAvatarCache();
