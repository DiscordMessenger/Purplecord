#pragma once

struct MessageItem
{
	MessagePtr m_msg;
	float m_cachedHeight = 0.0f;
	
	MessageItem(MessagePtr msgPtr = nullptr) {
		m_msg = msgPtr;
	}
};

typedef std::shared_ptr<MessageItem> MessageItemPtr;

static MessageItemPtr MakeMessageItem(MessagePtr msgPtr = nullptr)
{
	return std::make_shared<MessageItem>(msgPtr);
}
