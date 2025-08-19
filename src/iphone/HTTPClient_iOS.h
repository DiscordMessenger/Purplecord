#pragma once
#include <cassert>
#include <string>
#include <thread>
#include <mutex>
#include <atomic>
#include <chrono>
#include <list>
#include <condition_variable>
#include <curl/curl.h>
#include "boronlist.h"

#include "../discord/HTTPClient.hpp"
#include "../discord/DiscordClientConfig.hpp"
#include "../discord/LocalSettings.hpp"

class HTTPClient_iOS : public HTTPClient
{
public:
	HTTPClient_iOS()
	{
		InitializeListHead(&m_netRequests);
	}
	
	virtual ~HTTPClient_iOS() {}
	
	void Init() override;
	void Kill() override;
	void StopAllRequests() override;
	void PrepareQuit() override;
	std::string ErrorMessage(int code) const override;
	void PerformRequest(
		bool interactive,
		NetRequest::eType type,
		const std::string& url,
		int itype,
		uint64_t requestKey,
		std::string params,
		std::string authorization,
		std::string additional_data,
		NetRequest::NetworkResponseFunc pRespFunc,
		uint8_t* stream_bytes,
		size_t stream_size
	) override;
	
private:
	struct HTTPRequest
	{
		LIST_ENTRY entry;
		NetRequest* netRequest = nullptr;
		CURL* easyHandle = nullptr;
		
		~HTTPRequest()
		{
			if (netRequest)
				delete netRequest;
			assert(!easyHandle);
		}
		
		HTTPRequest() {}
		HTTPRequest(const HTTPRequest&) = delete;
		HTTPRequest(HTTPRequest&& other) {
			netRequest = other.netRequest;
			easyHandle = other.easyHandle;
			other.netRequest = nullptr;
			other.easyHandle = nullptr;
		}
	};
	
private:
	std::thread m_workerThread;
	std::mutex m_workerThreadMutex;
	std::condition_variable m_signalCV;
	std::atomic<bool> m_bRunning { false };
	
	LIST_ENTRY m_netRequests;
	
	CURLM* m_multi = nullptr;
	
	void WorkerThreadRun();
	static void WorkerThreadInit(HTTPClient_iOS* instance);
	static size_t ReadCallback(void* contents, size_t size, size_t nmemb, void* userp);
	static size_t WriteCallback(void* contents, size_t size, size_t nmemb, void* userp);
	static int GetProgress(void* userp, curl_off_t dltotal, curl_off_t dlnow, curl_off_t ultotal, curl_off_t ulnow);
	static int PutProgress(void* userp, curl_off_t dltotal, curl_off_t dlnow, curl_off_t ultotal, curl_off_t ulnow);
};
