#import "MessageItem.h"
#import "ChannelController.h"
#import "UIColorScheme.h"
#import "AvatarCache.h"
#include "../discord/DiscordInstance.hpp"
#include "../discord/Util.hpp"

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
		//case MessageType::CHANNEL_PINNED_MESSAGE:
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

@implementation MessageItem

@synthesize message;

- (void)dealloc
{
	[self removeExtraViewsIfNeeded];
	if (authorLabel) [authorLabel release];
	if (dateLabel) [dateLabel release];
	if (messageLabel) [messageLabel release];
	if (imageView) [imageView release];
	if (imageReference) [imageReference release];
	if (spinner) [spinner release];
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
		authorLabel.font = [MessageItem createAuthorTextFont];
		[self.contentView addSubview:authorLabel];
		
		dateLabel = [[UILabel alloc] initWithFrame:CGRectZero];
		dateLabel.numberOfLines = 1;
		dateLabel.font = [MessageItem createMessageTextFont];
		[self.contentView addSubview:dateLabel];
		
		messageLabel = [[UILabel alloc] initWithFrame:CGRectZero];
		messageLabel.numberOfLines = 0;
		messageLabel.font = [MessageItem createMessageTextFont];
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
	
	if (imageReference)
	{
		[imageReference release];
		imageReference = nil;
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

// KEEP IN SYNC WITH configureWithMessage!!!
+ (CGFloat)computeHeightForMessage:(MessagePtr)message
{
	CGRect screenBounds = [[UIScreen mainScreen] bounds];
	
	CGFloat height = 0.0f;
	CGFloat padding = OUT_MESSAGE_PADDING;
	CGFloat paddingIn = IN_MESSAGE_PADDING;
	CGFloat cellWidth = screenBounds.size.width;
	CGSize maxMessageSize = CGSizeMake(cellWidth - padding * 2, 99999.0);
	
	NSString* authorText = @"";
	NSString* messageText = @"";
	
	if (IsActionMessage(message->m_type))
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
				messageText = [MessageItem userJoinString:message->m_snowflake withAuthor:message->m_author];
				break;
			}
			
			case MessageType::CHANNEL_HEADER:
			{
				minHeight = 40;
				
				Channel* channel = GetDiscordInstance()->GetCurrentChannel();
				messageText = [MessageItem channelHeaderString:channel];
				break;
			}
		}
		
		CGSize messageTextSize = [
			messageText
			sizeWithFont:[MessageItem createMessageTextFont]
			constrainedToSize:maxMessageSize
			lineBreakMode:UILineBreakModeWordWrap
		];
		
		height += padding * 2 + messageTextSize.height;
		
		if (height < minHeight)
			height = minHeight;
		
		return height;
	}
	
	CGFloat pfpSize = GetProfilePictureSize();
	
	authorText = [NSString stringWithUTF8String:message->m_author.c_str()];
	messageText = [NSString stringWithUTF8String:message->m_message.c_str()];
	
	CGSize maxAuthorSize = CGSizeMake(cellWidth - padding * 2 - paddingIn - pfpSize, 40.0);
	CGSize authorTextSize = [
		authorText
		sizeWithFont:[MessageItem createAuthorTextFont]
		constrainedToSize:maxAuthorSize
		lineBreakMode:UILineBreakModeClip
	];
	CGSize messageTextSize = [
		messageText
		sizeWithFont:[MessageItem createMessageTextFont]
		constrainedToSize:maxMessageSize
		lineBreakMode:UILineBreakModeWordWrap
	];
	
	height = padding * 2 + paddingIn + authorTextSize.height + messageTextSize.height;
	return height;
}

- (void)configureWithMessage:(MessagePtr)_message
{
	message = _message;
	
	[self removeExtraViewsIfNeeded];
	
	self.opaque = YES;
	self.backgroundColor = [UIColorScheme getTextBackgroundColor];
	self.textColor = [UIColorScheme getTextColor];
	self.contentView.backgroundColor = [UIColorScheme getTextBackgroundColor];
	
	CGFloat padding = OUT_MESSAGE_PADDING;
	CGFloat paddingIn = IN_MESSAGE_PADDING;
	CGFloat cellWidth = self.contentView.bounds.size.width;
	CGSize maxMessageSize = CGSizeMake(cellWidth - padding * 2, 99999.0);
	
	if (IsActionMessage(message->m_type))
	{
		int minHeight = 0;
		authorLabel.text = dateLabel.text = @"";
		height = 0;
		
		UIImage* image = nil;
		
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
				messageLabel.text = [MessageItem userJoinString:message->m_snowflake withAuthor:message->m_author];
				break;
			}
			
			case MessageType::CHANNEL_HEADER:
			{
				[self makeTransparent];
				
				Channel* channel = GetDiscordInstance()->GetCurrentChannel();
				messageLabel.text = [MessageItem channelHeaderString:channel];
				
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
			lineBreakMode:UILineBreakModeWordWrap
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
	
	authorLabel.text = [NSString stringWithUTF8String:message->m_author.c_str()];
	messageLabel.text = [NSString stringWithUTF8String:message->m_message.c_str()];
	
	if (message->m_dateTime > 0) {
		std::string date = FormatTimeLong(message->m_dateTime);
		if (message->m_timeEdited)
			date += " (Edited " + FormatTimeLong(message->m_timeEdited) + ")";
		
		dateLabel.text = [NSString stringWithUTF8String:date.c_str()];
	}
	else {
		dateLabel.text = @"";
	}
	
	CGFloat pfpSize = GetProfilePictureSize();
	CGSize maxAuthorSize = CGSizeMake(cellWidth - padding * 2 - pfpSize - paddingIn, 40.0);
	CGSize authorTextSize = [
		authorLabel.text
		sizeWithFont:authorLabel.font
		constrainedToSize:maxAuthorSize
		lineBreakMode:UILineBreakModeClip
	];
	CGSize messageTextSize = [
		messageLabel.text
		sizeWithFont:messageLabel.font
		constrainedToSize:maxMessageSize
		lineBreakMode:UILineBreakModeWordWrap
	];
	
	height = padding * 2 + paddingIn + authorTextSize.height + messageTextSize.height;
	
	authorLabel.frame = CGRectMake(padding + pfpSize + paddingIn, padding, authorTextSize.width, authorTextSize.height);
	dateLabel.frame = CGRectMake(padding + pfpSize + paddingIn * 2 + authorTextSize.width, padding, cellWidth - padding * 3 - authorTextSize.width, authorTextSize.height);
	messageLabel.frame = CGRectMake(padding, padding + paddingIn + authorTextSize.height, messageTextSize.width, messageTextSize.height);
	
	[GetAvatarCache() addImagePlace:message->m_avatar imagePlace:eImagePlace::AVATARS place:message->m_avatar imageId:message->m_author_snowflake sizeOverride:0];
	
	UIImage* someImage = [GetAvatarCache() getImage:message->m_avatar];
	DbgPrintF("someImage: %p", someImage);
	DbgPrintF("someImage.CGImage: %p", someImage.CGImage);
	
	imageReference = [someImage retain];
	imageView = [[UIImageView alloc] initWithImage:someImage];
	imageView.frame = CGRectMake(padding, padding + (authorTextSize.height - pfpSize) / 2, pfpSize, pfpSize);
	[self.contentView addSubview:imageView];
}

@end
