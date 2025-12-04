#import "AvatarCache.h"
#import "ImageLoader.h"
#import "UIProportions.h"
#import "NetworkController.h"
#include "../discord/HTTPClient.hpp"
#include "../discord/Frontend.hpp"
#include "../discord/DiscordAPI.hpp"
#include <md5/MD5.h>
#include <unistd.h>

#define MAX_BITMAPS_KEEP_LOADED (16)

//#define DISABLE_AVATAR_LOADING_FOR_DEBUGGING

AvatarCache* g_pAvatarCache;
AvatarCache* GetAvatarCache() {
	return g_pAvatarCache;
}

static int NearestPowerOfTwo(int x) {
	if (x > (1 << 30))
		return 1 << 30;

	if (x < 2)
		return 2;

	int i;
	for (i = 1; i < x; i <<= 1);
	return i;
}

@implementation AvatarCache {
	// Cache for MakeIdentifier.  MD5 hashes aren't too cheap.
	std::unordered_map<std::string, std::string> m_resourceNameToID;

	// The value has two items: the bitmap itself and an 'age'. From time to time,
	// bitmaps are 'aged'; GetBitmap resets the age of the specific bitmap to zero.
	std::unordered_map<std::string, BitmapObject> m_profileToBitmap;

	// The place where the resource with the specified ID can be found.
	std::unordered_map<std::string, ImagePlace> m_imagePlaces;

	// A list of resources pending load.
	std::set<std::string> m_loadingResources;
	
	// The default profile picture.
	UIImage* m_defaultImage;
}

- (instancetype)init
{
	assert(!g_pAvatarCache);
	g_pAvatarCache = self;
	
	m_defaultImage = [[UIImage imageNamed:@"defaultProfilePicture.png"] retain];
	return self;
}

- (void)dealloc
{
	if (g_pAvatarCache == self)
		g_pAvatarCache = nil;
	
	[m_defaultImage release];
	[super dealloc];
}

- (std::string)makeIdentifier:(const std::string&)resource
{
	if (!m_resourceNameToID[resource].empty())
		return m_resourceNameToID[resource];

	if (resource.size() == 32) {
		bool isAlreadyResource = true;
		for (auto chr : resource) {
			if (!((chr >= '0' && chr <= '9') || (chr >= 'a' && chr <= 'f'))) {
				isAlreadyResource = false;
				break;
			}
		}
		if (isAlreadyResource)
			return resource;
	}

	m_resourceNameToID[resource] = MD5(resource).finalize().hexdigest();
	return m_resourceNameToID[resource];
}

- (std::string)addImagePlace:(const std::string&)resource imagePlace:(eImagePlace)ip place:(const std::string&)place imageId:(Snowflake)sf sizeOverride:(NSInteger)sizeOverride
{
	std::string myId = [self makeIdentifier:resource];
	m_imagePlaces[myId] = { ip, sf, place, myId, sizeOverride };
	return myId;
}

- (void)setImage:(const std::string&)resource image:(UIImage*)image
{
	std::string myId = [self makeIdentifier:resource];

	// Remove the least recently used bitmap until the maximum amount is loaded.
	while (m_profileToBitmap.size() > MAX_BITMAPS_KEEP_LOADED)
	{
		if (![self trimBitmap])
			break;
	}
	
	[self ageBitmaps];

	auto iter = m_profileToBitmap.find(myId);
	if (iter != m_profileToBitmap.end())
	{
		iter->second.SetImage(image);
		iter->second.m_age = 0;
		return;
	}

	m_profileToBitmap[myId] = BitmapObject(image, 0);
}

- (ImagePlace)getPlace:(const std::string&)resource
{
	std::string myId = [self makeIdentifier:resource];
	return m_imagePlaces[myId];
}

- (void)loadedResource:(const std::string&)resource
{
	std::string myId = [self makeIdentifier:resource];
	auto iter = m_loadingResources.find(myId);
	if (iter != m_loadingResources.end())
		m_loadingResources.erase(iter);
}

- (void)loadImageFromFile:(NSString*)myIdNS
{
@autoreleasepool {
	std::string myId([myIdNS UTF8String]);
	std::string final_path = GetCachePath() + "/" + myId;
	
	DbgPrintF("Loading image %s", final_path.c_str());
	FILE* f = fopen(final_path.c_str(), "rb");
	if (!f) {
		// below is broken, I'll fix it at some point
		//[GetNetworkController() loadedImageFromDataBackgroundThread:HIMAGE_ERROR withAdditData:myIdNS];
		return;
	}

	fseek(f, 0, SEEK_END);
	int sz = int(ftell(f));
	fseek(f, 0, SEEK_SET);

	uint8_t* pData = new uint8_t[sz];
	fread(pData, 1, sz, f);

	fclose(f);
	
	// Note: Assumes no need to resize.  However, the network controller saves the pre-processed
	// version, so this should be fine.
	UIImage* himg = [ImageLoader convertToBitmap:pData size:sz resizeToWidth:0 andHeight:0];
	delete[] pData;
	
	if (!himg)
	{
		DbgPrintF("Image %s could not be decoded!", myId.c_str());
		himg = HIMAGE_ERROR;
	}
	
	// I'm too lazy to replicate the same behavior so just reuse it.
	// It may be a circular reference but I don't care.
	[GetNetworkController() loadedImageFromDataBackgroundThread:himg withAdditData:myIdNS saveToCache:NO];
}
}

- (UIImage*)getImageSpecial:(const std::string&)resource
{
	std::string myId = [self makeIdentifier:resource];

	auto iter = m_profileToBitmap.find(myId);
	if (iter != m_profileToBitmap.end()) {
		iter->second.m_age = 0;
		return iter->second.GetImage();
	}

	auto iterIP = m_imagePlaces.find(myId);
	if (iterIP == m_imagePlaces.end())
	{
		// this shouldn't happen.  Just set to default
		DbgPrintF("Could not load resource %s, no image place was registered", myId.c_str());
		[self setImage:myId image:HIMAGE_LOADING];
		return [self getImageSpecial:myId];
	}
	
	eImagePlace pla = iterIP->second.type;

	// Check if we have already downloaded a cached version.
	std::string final_path = GetCachePath() + "/" + myId;
	if (access(final_path.c_str(), R_OK) == 0)
	{
#ifndef DISABLE_AVATAR_LOADING_FOR_DEBUGGING
		NSString* idStr = [NSString stringWithUTF8String:myId.c_str()];
		[self performSelectorInBackground:@selector(loadImageFromFile:) withObject:idStr];
		[self setImage:myId image:HIMAGE_LOADING];
		return [self getImageSpecial:myId];


#endif
		[self setImage:myId image:HIMAGE_ERROR];
		return [self getImageSpecial:myId];
	}

	// Could not find it in the cache, so request it from discord
	[self setImage:myId image:HIMAGE_LOADING];

	if (iterIP->second.place.empty()) {
		DbgPrintF("Image %s could not be fetched!  Place is empty", myId.c_str());
		return [self getImageSpecial:myId];
	}

	std::string url = iterIP->second.GetURL();

	if (!url.empty())
	{
		// if not inserted already
		if (!m_loadingResources.insert(url).second)
			return [self getImageSpecial:myId];

#ifdef DISABLE_AVATAR_LOADING_FOR_DEBUGGING
		GetFrontend()->OnAttachmentFailed(!iterIP->second.IsAttachment(), myId);
#else
		// send a request to the networker thread to grab the profile picture
		GetHTTPClient()->PerformRequest(
			false,
			NetRequest::GET,
			url,
			iterIP->second.IsAttachment() ? DiscordRequest::IMAGE_ATTACHMENT : DiscordRequest::IMAGE,
			uint64_t(iterIP->second.sf),
			"",
			"",
			myId
		);
#endif
	}
	else
	{
		DbgPrintF("Image %s could not be downloaded! URL is empty!", myId.c_str());
	}

	return [self getImageSpecial:myId];
}

- (UIImage*)getImageNullable:(const std::string&)resource andCheckIfError:(BOOL*)errorState
{
	UIImage* him = [self getImageSpecial:resource];
	
	*errorState = false;
	if (him == HIMAGE_ERROR || him == HIMAGE_LOADING)
	{
		him = nil;
		*errorState = him == HIMAGE_ERROR;
	}
	
	return him;
}

- (UIImage*)getImage:(const std::string&)resource
{
	UIImage* him = [self getImageSpecial:resource];
	
	if (him == HIMAGE_ERROR || him == HIMAGE_LOADING)
		him = m_defaultImage;
	
	return him;
}

- (void)wipeBitmaps
{
	m_profileToBitmap.clear();
	m_imagePlaces.clear();
}

- (void)eraseBitmap:(const std::string&)resource
{
	auto iter = m_profileToBitmap.find(resource);
	if (iter == m_profileToBitmap.end())
		return;

	m_profileToBitmap.erase(iter);
}

- (bool)trimBitmap
{
	int maxAge = 0;
	std::string rid = "";

	for (auto &b : m_profileToBitmap) {
		if (maxAge < b.second.m_age &&
			b.second.GetImage() != m_defaultImage &&
			!b.second.IsSpecialImage()) {
			maxAge = b.second.m_age;
			rid    = b.first;
		}
	}

	if (rid.empty()) return false;

	auto iter = m_profileToBitmap.find(rid);
	assert(iter != m_profileToBitmap.end());

	auto iter2 = m_loadingResources.find(m_imagePlaces[iter->first].GetURL());

	if (iter2 != m_loadingResources.end())
		m_loadingResources.erase(iter2);

	m_profileToBitmap.erase(iter);

	return true;
}

- (int)trimBitmaps:(NSInteger)count
{
	if (count < 0)
		return 0;

	int trimCount = 0;
	for (int i = 0; i < count; i++) {
		if (![self trimBitmap])
			return trimCount;
		trimCount++;
	}
	return trimCount;
}

- (void)ageBitmaps
{
	for (auto &b : m_profileToBitmap) {
		b.second.m_age++;
	}
}

- (void)clearProcessingRequests
{
	m_loadingResources.clear();
}

- (UIImage*)getDefaultImage
{
	return m_defaultImage;
}

@end

std::string ImagePlace::GetURL() const
{
	bool bIsAttachment = false;
	bool useOnlySnowflake = false;
	bool dontAppendSize = false;
	std::string path = "";
	switch (type)
	{
		case eImagePlace::AVATARS:
			path = "avatars";
			break;
		case eImagePlace::ICONS:
			path = "icons";
			break;
		case eImagePlace::CHANNEL_ICONS:
			path = "channel-icons";
			break;
		case eImagePlace::EMOJIS:
			path = "emojis";
			useOnlySnowflake = true;
			break;
		case eImagePlace::ATTACHMENTS:
			path = "z";
			bIsAttachment = true;
			dontAppendSize = true;
			break;
	}

	if (path.empty()) {
		DbgPrintF("Image %s could not be downloaded! Path is empty!", key.c_str());
		return "";
	}

	if (bIsAttachment)
		return place;

	std::string url = GetDiscordCDN() + path + "/" + std::to_string(sf);

	if (!useOnlySnowflake)
		url += "/" + place;

	// Add in the webp at the end.
	url += ".webp";

	// Also the size should reflect the active profile picture size.
	if (!dontAppendSize)
	{
		int size = NearestPowerOfTwo(sizeOverride ? sizeOverride : ScaleByDPI(GetProfilePictureSize()));
		// actually increase it a bit to increase quality
		if (size < 128)
			size = 128;

		url += "?size=" + std::to_string(size);
	}

	return url;
}
