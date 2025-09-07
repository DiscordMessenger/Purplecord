#import "MessageItem.h"
#import "ChannelController.h"
#include "../discord/DiscordInstance.hpp"
#include "../discord/Util.hpp"

bool IsActionMessage(MessageType::eType msgType)
{
	switch (msgType)
	{
		//case MessageType::USER_JOIN:
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
		//case MessageType::CHANNEL_HEADER:
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

@synthesize authorLabel, dateLabel, messageLabel, message, height;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
	if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier])
	{
		authorLabel = [[UILabel alloc] initWithFrame:CGRectZero];
		authorLabel.numberOfLines = 1;
		authorLabel.font = [UIFont boldSystemFontOfSize:16];
		[self.contentView addSubview:authorLabel];
		
		dateLabel = [[UILabel alloc] initWithFrame:CGRectZero];
		dateLabel.numberOfLines = 1;
		dateLabel.font = [UIFont systemFontOfSize:16];
		[self.contentView addSubview:dateLabel];
		
		messageLabel = [[UILabel alloc] initWithFrame:CGRectZero];
		messageLabel.numberOfLines = 0;
		messageLabel.font = [UIFont systemFontOfSize:16];
		[self.contentView addSubview:messageLabel];
	}
	
	return self;
}

- (void)configureWithMessage:(MessagePtr)_message
{
	message = _message;
	
	self.opaque = YES;
	self.backgroundColor = [UIColor whiteColor];
	self.contentView.backgroundColor = [UIColor whiteColor];
	
	CGFloat padding = 15.0f;
	CGFloat cellWidth = self.contentView.bounds.size.width;
	CGSize maxMessageSize = CGSizeMake(cellWidth - padding * 2, 99999.0);
	
	if (IsActionMessage(message->m_type))
	{
		authorLabel.text = dateLabel.text = @"";
		height = 0;
		
		switch (message->m_type)
		{
			case MessageType::GAP_UP:
			case MessageType::GAP_DOWN:
			case MessageType::GAP_AROUND:
			{
				messageLabel.text = @"Purplecord is loading messages, please wait...";
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
	
	CGSize maxAuthorSize = CGSizeMake(cellWidth - padding * 2, 40.0);
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
	
	height = padding * 3 + authorTextSize.height + messageTextSize.height;
	
	authorLabel.frame = CGRectMake(padding, padding, authorTextSize.width, authorTextSize.height);
	dateLabel.frame = CGRectMake(padding * 2 + authorTextSize.width, padding, cellWidth - padding * 3 - authorTextSize.width, authorTextSize.height);
	messageLabel.frame = CGRectMake(padding, padding * 2 + authorTextSize.height, messageTextSize.width, messageTextSize.height);
}

- (void)dealloc
{
	[authorLabel release];
	[dateLabel release];
	[messageLabel release];
	[super dealloc];
}

@end
