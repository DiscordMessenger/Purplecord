#pragma once

struct MessageItem
{
	MessagePtr m_msg;
	float m_cachedHeight = 0.0f;
	bool m_bWasMentioned = false;
	int m_placeInChain = 0;
	bool m_bIsDateGap = false;
	
	MessageItem(MessagePtr msgPtr = nullptr)
	{
		m_msg = msgPtr;
	}
	
	void UpdateDetails(Snowflake guildID);
};

typedef std::shared_ptr<MessageItem> MessageItemPtr;

static MessageItemPtr MakeMessageItem(MessagePtr msgPtr = nullptr)
{
	return std::make_shared<MessageItem>(msgPtr);
}
