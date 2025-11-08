#import "MessageCell.h"
#import "ChannelController.h"
#import "UIColorScheme.h"
#import "AvatarCache.h"
#include "../discord/DiscordInstance.hpp"
#include "../discord/Util.hpp"

AttachedImage::~AttachedImage()
{
	if (imageView) {
		[imageView removeFromSuperview];
		[imageView release];
	}
	
	if (spinnerView) {
		[spinnerView removeFromSuperview];
		[spinnerView release];
	}
}

void AttachedImage::SetImageView(UIImageView* iv)
{
	if (imageView) {
		[imageView removeFromSuperview];
		[imageView release];
	}
	
	imageView = iv ? [iv retain] : nil;
}

void AttachedImage::SetSpinnerView(UIActivityIndicatorView* av)
{
	if (spinnerView) {
		[spinnerView removeFromSuperview];
		[spinnerView release];
	}
	
	spinnerView = av ? [av retain] : nil;
}

static const char* const welcomeTexts[] = {
	"$ joined the party.",
	"$ is here.",
	"Welcome, $. We hope you brought pizza.",
	"A wild $ appeared.",
	"$ just landed.",
	"$ just slid into the server!",
	"$ just showed up!",
	"Welcome $. Say hi!",
	"$ hopped into the server.",
	"Everyone welcome $!",
	"Glad you're here, $.",
	"Good to see you, $.",
	"Yay you made it, $!",
};
static const int welcomeTextCount = 13;

bool IsActionMessage(MessageType::eType msgType)
{
	switch (msgType)
	{
		case MessageType::USER_JOIN:
		case MessageType::CHANNEL_PINNED_MESSAGE:
		//case MessageType::RECIPIENT_ADD:
		//case MessageType::RECIPIENT_REMOVE:
		//case MessageType::CHANNEL_NAME_CHANGE:
		//case MessageType::CHANNEL_ICON_CHANGE:
		case MessageType::GAP_UP:
		case MessageType::GAP_DOWN:
		case MessageType::GAP_AROUND:
		//case MessageType::CANT_VIEW_MSG_HISTORY:
		//case MessageType::LOADING_PINNED_MESSAGES:
		//case MessageType::NO_PINNED_MESSAGES:
		//case MessageType::NO_NOTIFICATIONS:
		case MessageType::CHANNEL_HEADER:
		//case MessageType::STAGE_START:
		//case MessageType::STAGE_END:
		//case MessageType::STAGE_SPEAKER:
		//case MessageType::STAGE_TOPIC:
		//case MessageType::GUILD_BOOST:
		//case MessageType::GUILD_BOOST_TIER_1:
		//case MessageType::GUILD_BOOST_TIER_2:
		//case MessageType::GUILD_BOOST_TIER_3:
			return true;
	}

	return false;
}

bool IsClientSideMessage(MessageType::eType msgType)
{
	switch (msgType)
	{
		case MessageType::GAP_UP:
		case MessageType::GAP_DOWN:
		case MessageType::GAP_AROUND:
		case MessageType::CANT_VIEW_MSG_HISTORY:
		case MessageType::LOADING_PINNED_MESSAGES:
		case MessageType::NO_PINNED_MESSAGES:
		case MessageType::NO_NOTIFICATIONS:
		case MessageType::CHANNEL_HEADER:
			return true;
	}

	return false;
}

bool IsReplyableActionMessage(MessageType::eType msgType)
{
	if (!IsActionMessage(msgType))
		return true;

	switch (msgType)
	{
		case MessageType::USER_JOIN:
			return true;
	}

	return false;
}

bool IsPinnableActionMessage(MessageType::eType msgType)
{
	if (!IsActionMessage(msgType)) return true;
	
	// no action message pinnable for now.
	return false;
}

@implementation MessageCell

@synthesize messageItem;

- (void)tearDownImages
{
	if (!attachedImages)
		return;
	
	delete[] attachedImages;
	attachedImages = nullptr;
}

- (void)dealloc
{
	[self removeExtraViewsIfNeeded];
	if (authorLabel) [authorLabel release];
	if (dateLabel) [dateLabel release];
	if (messageLabel) [messageLabel release];
	if (imageView) [imageView release];
	if (spinner) [spinner release];
	
	[self tearDownImages];
	
	[super dealloc];
}

+ (UIFont*)createAuthorTextFont
{
	return [UIFont boldSystemFontOfSize:16];
}

+ (UIFont*)createMessageTextFont
{
	return [UIFont systemFontOfSize:16];
}

- (void)applyThemingOn:(UILabel*)label
{
	label.backgroundColor = [UIColorScheme getTextBackgroundColor];
	label.textColor = [UIColorScheme getTextColor];
}

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
	if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier])
	{
		authorLabel = [[UILabel alloc] initWithFrame:CGRectZero];
		authorLabel.numberOfLines = 1;
		authorLabel.font = [MessageCell createAuthorTextFont];
		[self.contentView addSubview:authorLabel];
		
		dateLabel = [[UILabel alloc] initWithFrame:CGRectZero];
		dateLabel.numberOfLines = 1;
		dateLabel.font = [MessageCell createMessageTextFont];
		[self.contentView addSubview:dateLabel];
		
		messageLabel = [[UILabel alloc] initWithFrame:CGRectZero];
		messageLabel.numberOfLines = 0;
		messageLabel.font = [MessageCell createMessageTextFont];
		[self.contentView addSubview:messageLabel];
		
		[self applyThemingOn:authorLabel];
		[self applyThemingOn:dateLabel];
		[self applyThemingOn:messageLabel];
	}
	
	return self;
}

- (NSString*)getChannelHeader
{
	if ([UIColorScheme useDarkMode])
		return @"channelHeaderDark.png";
	
	return @"channelHeader.png";
}

- (void)makeTransparent
{
	self.contentView.backgroundColor = [UIColor clearColor];
	self.opaque = NO;
	
	authorLabel.backgroundColor = [UIColor clearColor];
	dateLabel.backgroundColor = [UIColor clearColor];
	messageLabel.backgroundColor = [UIColor clearColor];
	authorLabel.opaque = NO;
	dateLabel.opaque = NO;
	messageLabel.opaque = NO;
}

- (void)removeExtraViewsIfNeeded
{
	if (imageView)
	{
		[imageView removeFromSuperview];
		[imageView release];
		imageView = nil;
	}
	
	if (spinner)
	{
		[spinner removeFromSuperview];
		[spinner release];
		spinner = nil;
	}
}

+ (NSString*)channelHeaderString:(Channel*)channel
{
	std::string channelName = channel->GetFullName();
	return [NSString stringWithUTF8String:("Welcome to the beginning of the " + channelName + " channel.").c_str()];;
}

+ (NSString*)userJoinString:(Snowflake)messageID withAuthor:(const std::string&)author 
{
	int welcomeTextIndex = ExtractTimestamp(messageID) % welcomeTextCount;
	const char* welcomeText = welcomeTexts[welcomeTextIndex];
	size_t dollarPos = 0;
	
	for (size_t i = 0; welcomeText[i] != 0; i++)
	{
		if (welcomeText[i] == '$')
		{
			dollarPos = i;
			break;
		}
	}
	
	std::string message = std::string(welcomeText, dollarPos) + author + std::string(welcomeText + dollarPos + 1);
	return [NSString stringWithUTF8String:message.c_str()];
}

+ (NSString*)messagePinString:(Snowflake)messageID withAuthor:(const std::string&)author 
{
	std::string message = author + " pinned a message to this channel.";
	return [NSString stringWithUTF8String:message.c_str()];
}

// KEEP IN SYNC WITH configureWithMessage!!!
+ (CGFloat)computeHeightForMessage:(MessageItemPtr)messageItem isEndOfChain:(bool)isEndOfChain
{
	MessagePtr message = messageItem->m_msg;
	
	bool isActionMessage = IsActionMessage(message->m_type);
	
	CGRect screenBounds = [[UIScreen mainScreen] bounds];
	
	CGFloat height = 0.0f;
	CGFloat padding = OUT_MESSAGE_PADDING;
	CGFloat paddingIn = IN_MESSAGE_PADDING;
	CGFloat paddingY = padding;
	CGFloat paddingEnd = isEndOfChain ? padding : paddingIn;
	CGFloat cellWidth = screenBounds.size.width;
	CGSize maxMessageSize = CGSizeMake(cellWidth - padding * 2, 99999.0);
	
	NSString* authorText = @"";
	NSString* messageText = @"";
	
	bool showAuthorAndDate = isActionMessage || messageItem->m_placeInChain == 0;
	
	if (isActionMessage)
	{
		int minHeight = 0;
		height = 0;
		
		switch (message->m_type)
		{
			case MessageType::GAP_UP:
			case MessageType::GAP_DOWN:
			case MessageType::GAP_AROUND:
				return 80;
			
			case MessageType::USER_JOIN:
			{
				messageText = [MessageCell userJoinString:message->m_snowflake withAuthor:message->m_author];
				break;
			}
			
			case MessageType::CHANNEL_PINNED_MESSAGE:
			{
				messageText = [MessageCell messagePinString:message->m_snowflake withAuthor:message->m_author];
				break;
			}
			
			case MessageType::CHANNEL_HEADER:
			{
				minHeight = 40;
				
				Channel* channel = GetDiscordInstance()->GetCurrentChannel();
				messageText = [MessageCell channelHeaderString:channel];
				break;
			}
		}
		
		CGSize messageTextSize = [
			messageText
			sizeWithFont:[MessageCell createMessageTextFont]
			constrainedToSize:maxMessageSize
			lineBreakMode:UI_LINE_BREAK_MODE_WORD_WRAP
		];
		
		height += padding * 2 + messageTextSize.height;
		
		if (height < minHeight)
			height = minHeight;
		
		return height;
	}
	
	CGFloat pfpSize = GetProfilePictureSize();
	CGFloat actualPaddingIn = paddingIn;
	CGSize authorTextSize = CGSizeMake(0, 0), messageTextSize = CGSizeMake(0, 0);
	
	messageText = [NSString stringWithUTF8String:message->m_message.c_str()];
	
	if (showAuthorAndDate)
	{
		authorText = [NSString stringWithUTF8String:message->m_author.c_str()];
		
		CGSize maxAuthorSize = CGSizeMake(cellWidth - padding * 2 - paddingIn - pfpSize, 40.0);
		authorTextSize = [
			authorText
			sizeWithFont:[MessageCell createAuthorTextFont]
			constrainedToSize:maxAuthorSize
			lineBreakMode:UI_LINE_BREAK_MODE_CLIP
		];
	}
	else if (!showAuthorAndDate)
	{
		actualPaddingIn = 0.0f;
		paddingY = paddingIn;
	}
	
	if (message->m_message.size())
	{
		messageTextSize = [
			messageText
			sizeWithFont:[MessageCell createMessageTextFont]
			constrainedToSize:maxMessageSize
			lineBreakMode:UI_LINE_BREAK_MODE_WORD_WRAP
		];
	}
	else if (!showAuthorAndDate)
	{
		actualPaddingIn = 0.0f;
		paddingEnd = 0.0f;
	}
	
	height = paddingY + actualPaddingIn + authorTextSize.height + messageTextSize.height;
	
	if (message->m_attachments.size() != 0)
		height += paddingIn;
	else
		height += paddingEnd;
	
	// for each embed inside the message, add its height.
	for (auto& attach : message->m_attachments)
	{
		if (!attach.IsImage())
		{
			// TODO: generate an embed for it.  Skip for now
			continue;
		}
		
		attach.UpdatePreviewSize();
		height += paddingIn + attach.m_previewHeight;
	}
	
	return height;
}

- (void)configureWithMessage:(MessageItemPtr)_messageItem andReload:(bool)reloadAttachments isEndOfChain:(bool)isEndOfChain
{
	bool messageChanged = !messageItem || messageItem->m_msg->m_snowflake != _messageItem->m_msg->m_snowflake;
	
	messageItem = _messageItem;
	MessagePtr message = messageItem->m_msg;
	
	if (messageChanged)
	{
		// any properties that pertain to the message having changed
		// shall be reset here.
		
		reloadAttachments = true;
	}
	
	[self removeExtraViewsIfNeeded];
	
	bool isActionMessage = IsActionMessage(message->m_type);
	
	self.opaque = YES;
	self.backgroundColor = [UIColorScheme getTextBackgroundColor];
	self.textColor = [UIColorScheme getTextColor];
	self.contentView.backgroundColor = [UIColorScheme getTextBackgroundColor];
	
	UIImage* image = nil;
	
	CGRect screenBounds = [[UIScreen mainScreen] bounds];
	
	CGFloat padding = OUT_MESSAGE_PADDING;
	CGFloat paddingIn = IN_MESSAGE_PADDING;
	CGFloat paddingY = padding;
	CGFloat paddingEnd = isEndOfChain ? padding : paddingIn;
	CGFloat cellWidth = screenBounds.size.width;
	CGSize maxMessageSize = CGSizeMake(cellWidth - padding * 2, 99999.0);
	
	bool showAuthorAndDate = isActionMessage || messageItem->m_placeInChain == 0;
	
	if (isActionMessage)
	{
		int minHeight = 0;
		authorLabel.text = dateLabel.text = @"";
		height = 0;
		
		switch (message->m_type)
		{
			case MessageType::GAP_UP:
			case MessageType::GAP_DOWN:
			case MessageType::GAP_AROUND:
			{
				messageLabel.text = @"";
				
				spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
				spinner.center = CGPointMake(cellWidth / 2, 40);
				
				[self.contentView addSubview:spinner];
				[spinner startAnimating];
				
				[self makeTransparent];
				height = 80;
				return;
			}
			
			case MessageType::USER_JOIN:
			{
				messageLabel.text = [MessageCell userJoinString:message->m_snowflake withAuthor:message->m_author];
				break;
			}
			
			case MessageType::CHANNEL_PINNED_MESSAGE:
			{
				messageLabel.text = [MessageCell messagePinString:message->m_snowflake withAuthor:message->m_author];
				break;
			}
			
			case MessageType::CHANNEL_HEADER:
			{
				[self makeTransparent];
				
				Channel* channel = GetDiscordInstance()->GetCurrentChannel();
				messageLabel.text = [MessageCell channelHeaderString:channel];
				
				image = [UIImage imageNamed:[self getChannelHeader]];
				imageView = [[UIImageView alloc] initWithImage:image];
				
				[self.contentView insertSubview:imageView atIndex:0];
				
				minHeight = 40;
				break;
			}
		}
		
		CGSize messageTextSize = [
			messageLabel.text
			sizeWithFont:messageLabel.font
			constrainedToSize:maxMessageSize
			lineBreakMode:UI_LINE_BREAK_MODE_WORD_WRAP
		];
		
		messageLabel.frame = CGRectMake(padding, padding, messageTextSize.width, messageTextSize.height);
		height += padding * 2 + messageTextSize.height;
		
		if (height < minHeight)
			height = minHeight;
		
		if (imageView)
		{
			// place it at the bottom.
			imageView.frame = CGRectMake(0, height - image.size.height, image.size.width, image.size.height);
		}
		
		return;
	}
	
	messageLabel.text = [NSString stringWithUTF8String:message->m_message.c_str()];
	
	CGFloat actualPaddingIn = paddingIn;
	if (showAuthorAndDate)
	{
		authorLabel.text = [NSString stringWithUTF8String:message->m_author.c_str()];
		
		if (message->m_dateTime > 0) {
			std::string date = FormatTimeLong(message->m_dateTime);
			if (message->m_timeEdited)
				date += " (Edited " + FormatTimeLong(message->m_timeEdited) + ")";
			
			dateLabel.text = [NSString stringWithUTF8String:date.c_str()];
		}
		else {
			dateLabel.text = @"";
		}
	}
	else
	{
		actualPaddingIn = 0;
		paddingY = paddingIn;
	}
	
	CGFloat pfpSize = GetProfilePictureSize();
	CGSize authorTextSize = CGSizeMake(0, 0), messageTextSize = CGSizeMake(0, 0);
	
	if (showAuthorAndDate)
	{
		CGSize maxAuthorSize = CGSizeMake(cellWidth - padding * 2 - pfpSize - paddingIn, 40.0);
		
		authorTextSize = [
			authorLabel.text
			sizeWithFont:authorLabel.font
			constrainedToSize:maxAuthorSize
			lineBreakMode:UI_LINE_BREAK_MODE_CLIP
		];
	}
	
	if (message->m_message.size())
	{
		messageTextSize = [
			messageLabel.text
			sizeWithFont:messageLabel.font
			constrainedToSize:maxMessageSize
			lineBreakMode:UI_LINE_BREAK_MODE_WORD_WRAP
		];
	}
	else if (!showAuthorAndDate)
	{
		actualPaddingIn = 0.0f;
		paddingEnd = 0.0f;
	}
	
	height = paddingY + actualPaddingIn + authorTextSize.height + messageTextSize.height;
	
	if (message->m_attachments.size() != 0)
		height += paddingIn;
	else
		height += paddingEnd;
	
	messageLabel.frame = CGRectMake(padding, paddingY + actualPaddingIn + authorTextSize.height, messageTextSize.width, messageTextSize.height);
	
	if (showAuthorAndDate)
	{
		authorLabel.frame = CGRectMake(padding + pfpSize + paddingIn, padding, authorTextSize.width, authorTextSize.height);
		dateLabel.frame = CGRectMake(padding + pfpSize + paddingIn * 2 + authorTextSize.width, padding, cellWidth - padding * 3 - authorTextSize.width, authorTextSize.height);
		
		[GetAvatarCache() addImagePlace:message->m_avatar imagePlace:eImagePlace::AVATARS place:message->m_avatar imageId:message->m_author_snowflake sizeOverride:0];
		
		image = [GetAvatarCache() getImage:message->m_avatar];
		imageView = [[UIImageView alloc] initWithImage:image];
		imageView.frame = CGRectMake(padding, padding + (authorTextSize.height - pfpSize) / 2, pfpSize, pfpSize);
		[self.contentView addSubview:imageView];
	}
	else
	{
		// just hide them from view
		authorLabel.frame = dateLabel.frame = CGRectMake(0, 0, 0, 0);
	}
	
	bool needToRegenerate = reloadAttachments;
	
	if (attachedImagesCount != message->m_attachments.size())
		needToRegenerate = true;
	
	if (!needToRegenerate)
	{
		size_t idx = 0;
		for (auto& attach : message->m_attachments)
		{
			if (!attach.IsImage())
				continue;
			
			std::string rid = [GetAvatarCache() makeIdentifier:(
				std::to_string(attach.m_id) +
				attach.m_proxyUrl +
				attach.m_actualUrl
			)];
			
			if (idx >= attachedImagesCount ||
				attachedImages[idx].hash != rid)
			{
				needToRegenerate = true;
				break;
			}
			
			idx++;
		}
	}
	
	if (needToRegenerate)
	{
		[self tearDownImages];
		
		attachedImagesCount = message->m_attachments.size();
		attachedImages = new AttachedImage[attachedImagesCount];
		
		size_t idx = 0;
		for (auto& attach : message->m_attachments)
		{
			if (!attach.IsImage())
			{
				// TODO: generate an embed for it.  Skip for now
				continue;
			}
			
			std::string rid = [GetAvatarCache() makeIdentifier:(
				std::to_string(attach.m_id) +
				attach.m_proxyUrl +
				attach.m_actualUrl
			)];
			
			AttachedImage& atimg = attachedImages[idx];
			
			std::string url = attach.m_proxyUrl;
			if (attach.PreviewDifferent())
			{
				bool hasQMark = false;
				for (auto ch : url) {
					if (ch == '?') {
						hasQMark = true;
						break;
					}
				}

				if (url.empty() || url[url.size() - 1] != '&' || url[url.size() - 1] != '?')
					url += hasQMark ? "&" : "?";

				url += "width=" + std::to_string(ScaleByDPI(attach.m_previewWidth));
				url += "&height=" + std::to_string(ScaleByDPI(attach.m_previewHeight));
			}

			DbgPrintF("This image's attachment ID is %s.  Url is %s.", rid.c_str(), attach.m_proxyUrl.c_str());
			[GetAvatarCache() addImagePlace:rid imagePlace:eImagePlace::ATTACHMENTS place:url imageId:attach.m_id sizeOverride:0];
			
			BOOL isError = NO;
			UIImage* auxImage = [GetAvatarCache() getImageNullable:rid andCheckIfError:&isError];
			if (!auxImage)
			{
				if (isError)
				{
					auxImage = [UIImage imageNamed:@"error.png"];
					
					UIImageView* auxImageView = [[UIImageView alloc] initWithImage:auxImage];
					auxImageView.frame = CGRectMake(0, 0, 16, 16);
					auxImageView.center = CGPointMake(padding + attach.m_previewWidth / 2, height + attach.m_previewHeight / 2);
					[self.contentView addSubview:auxImageView];
					
					atimg.SetImageView(auxImageView);
					[auxImageView release];
				}
				else
				{
					UIActivityIndicatorView* auxSpinner;
					auxSpinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
					auxSpinner.center = CGPointMake(padding + attach.m_previewWidth / 2, height + attach.m_previewHeight / 2);
					[self.contentView addSubview:auxSpinner];
					
					atimg.SetSpinnerView(auxSpinner);
					[auxSpinner startAnimating];
					[auxSpinner release];
				}
			}
			else
			{
				UIImageView* auxImageView = [[UIImageView alloc] initWithImage:auxImage];
				auxImageView.frame = CGRectMake(padding, height, attach.m_previewWidth, attach.m_previewHeight);
				[self.contentView addSubview:auxImageView];
				
				atimg.SetImageView(auxImageView);
				[auxImageView release];
			}
			
			idx++;
			height += paddingIn + attach.m_previewHeight;
		}
	}
}

@end
