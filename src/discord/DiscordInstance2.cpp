#include "DiscordInstance.hpp"
#include "Util.hpp"
#include "HTTPClient.hpp"
#include "Frontend.hpp"
#include "iprogsjson.hpp"

// split away because this function was causing crash problems with clang-21
// (yes the compiler was literally crashing, i'm not joking)

using Json = iprog::JsonObject;

void DiscordInstance::OnUploadAttachmentFirst(NetRequest* pReq)
{
	auto& ups = m_pendingUploads;

	if (pReq->result != HTTP_OK)
	{
		// Delete enqueued upload
		auto iter = ups.find(pReq->key);
		std::string name = iter->second.m_uploadFileName;
		if (iter != ups.end())
			ups.erase(iter);

		GetFrontend()->OnFailedToUploadFile(name, pReq->result);
		return;
	}

	Json j = iprog::JsonParser::parse(pReq->response);
	assert(j["attachments"].size() == 1);

	for (auto& att : j["attachments"])
	{
		Snowflake id = GetSnowflakeFromJsonObject(att["id"]);

		PendingUpload& up = ups[id];
		up.m_uploadUrl = GetFieldSafe(att, "upload_url");
		up.m_uploadFileName = GetFieldSafe(att, "upload_filename");

		// Send data to the upload URL
		uint8_t* pNewData = new uint8_t[up.m_data.size()];
		memcpy(pNewData, up.m_data.data(), up.m_data.size());

		GetHTTPClient()->PerformRequest(
			true,
			NetRequest::PUT_OCTETS_PROGRESS,
			up.m_uploadUrl,
			DiscordRequest::UPLOAD_ATTACHMENT_2,
			pReq->key,
			"",
			"",//GetToken(),
			"",
			nullptr, // default processing
			pNewData,
			up.m_data.size()
		);

		GetFrontend()->OnStartProgress(pReq->key, up.m_name, true);
	}
}
