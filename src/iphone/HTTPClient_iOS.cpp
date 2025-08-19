#include "HTTPClient_iOS.h"

bool AddExtraHeaders()
{
	return GetLocalSettings()->AddExtraHeaders();
}

void HTTPClient_iOS::Init() 
{
	m_multi = curl_multi_init();
	m_bRunning.store(true);
	m_workerThread = std::thread(WorkerThreadInit, this);
}

void HTTPClient_iOS::Kill() 
{
	m_bRunning.store(false);
	m_signalCV.notify_all();
	m_workerThread.join();
	
	curl_multi_cleanup(m_multi);
	m_multi = nullptr;
}

void HTTPClient_iOS::StopAllRequests() 
{
	// TODO
}

void HTTPClient_iOS::PrepareQuit() 
{
	// TODO
}

std::string HTTPClient_iOS::ErrorMessage(int code) const
{
	// TODO
	return "TODO";
}

int HTTPClient_iOS::GetProgress(void* userp, curl_off_t dltotal, curl_off_t dlnow, curl_off_t ultotal, curl_off_t ulnow)
{
	HTTPRequest* request = (HTTPRequest*) userp;
	NetRequest* netRequest = request->netRequest;
	
	netRequest->m_bCancelOp = false;
	netRequest->m_offset = dlnow;
	netRequest->m_length = dltotal;
	netRequest->result = HTTP_PROGRESS;
	netRequest->pFunc(netRequest);
	
	return netRequest->m_bCancelOp;
}

int HTTPClient_iOS::PutProgress(void* userp, curl_off_t dltotal, curl_off_t dlnow, curl_off_t ultotal, curl_off_t ulnow)
{
	HTTPRequest* request = (HTTPRequest*) userp;
	NetRequest* netRequest = request->netRequest;
	
	netRequest->m_bCancelOp = false;
	netRequest->m_offset = ulnow;
	netRequest->m_length = ultotal;
	netRequest->result = HTTP_PROGRESS;
	netRequest->pFunc(netRequest);
	
	return netRequest->m_bCancelOp;
}


size_t HTTPClient_iOS::WriteCallback(void* contents, size_t size, size_t nmemb, void* userp)
{
	HTTPRequest* request = (HTTPRequest*) userp;
	NetRequest* netRequest = request->netRequest;
	netRequest->response.append((char*) contents, size * nmemb);
	return size * nmemb;
}

size_t HTTPClient_iOS::ReadCallback(void* contents, size_t size, size_t nmemb, void* userp)
{
	HTTPRequest* request = (HTTPRequest*) userp;
	NetRequest* netRequest = request->netRequest;
	
	size_t byteCount = size * nmemb;
	size_t startOffset = netRequest->m_offset;
	size_t endOffset = netRequest->m_offset + byteCount;
	
	if (endOffset >= netRequest->params_bytes.size()) {
		endOffset = netRequest->params_bytes.size();
		if (endOffset <= startOffset)
			return 0;
		
		byteCount = endOffset - startOffset;
	}
	
	memcpy(contents, netRequest->params_bytes.data(), byteCount);
	return byteCount;
}

void HTTPClient_iOS::PerformRequest(
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
)
{
	HTTPRequest* pRequest = new HTTPRequest;
	pRequest->netRequest = new NetRequest(0, itype, requestKey, type, url, "", params, authorization, additional_data, pRespFunc, stream_bytes, stream_size);
	pRequest->easyHandle = curl_easy_init();
	
	// Configure handle
	curl_easy_setopt(pRequest->easyHandle, CURLOPT_URL, url.c_str());
	curl_easy_setopt(pRequest->easyHandle, CURLOPT_WRITEDATA, pRequest->netRequest);
	curl_easy_setopt(pRequest->easyHandle, CURLOPT_READDATA, pRequest->netRequest);
	curl_easy_setopt(pRequest->easyHandle, CURLOPT_PRIVATE, pRequest);
	
	switch (type)
	{
		case NetRequest::GET_PROGRESS:
			curl_easy_setopt(pRequest->easyHandle, CURLOPT_NOPROGRESS, 0L);
			curl_easy_setopt(pRequest->easyHandle, CURLOPT_XFERINFOFUNCTION, GetProgress);
		case NetRequest::GET:
			curl_easy_setopt(pRequest->easyHandle, CURLOPT_HTTPGET, 1L);
			curl_easy_setopt(pRequest->easyHandle, CURLOPT_WRITEFUNCTION, WriteCallback);
			break;
		
		case NetRequest::DELETE_:
			curl_easy_setopt(pRequest->easyHandle, CURLOPT_CUSTOMREQUEST, "DELETE");
			break;
		
		case NetRequest::POST:
		case NetRequest::POST_JSON:
			curl_easy_setopt(pRequest->easyHandle, CURLOPT_POST, 1L);
			curl_easy_setopt(pRequest->easyHandle, CURLOPT_POSTFIELDS, params.c_str());
			break;
		
		case NetRequest::PUT:
		case NetRequest::PUT_JSON:
			curl_easy_setopt(pRequest->easyHandle, CURLOPT_CUSTOMREQUEST, "PUT");
			curl_easy_setopt(pRequest->easyHandle, CURLOPT_POSTFIELDS, params.c_str());
			break;
		
		case NetRequest::PUT_OCTETS_PROGRESS:
			curl_easy_setopt(pRequest->easyHandle, CURLOPT_NOPROGRESS, 0L);
			curl_easy_setopt(pRequest->easyHandle, CURLOPT_XFERINFOFUNCTION, PutProgress);
		case NetRequest::PUT_OCTETS:
			curl_easy_setopt(pRequest->easyHandle, CURLOPT_CUSTOMREQUEST, "PUT");
			curl_easy_setopt(pRequest->easyHandle, CURLOPT_UPLOAD, 1L);
			curl_easy_setopt(pRequest->easyHandle, CURLOPT_READFUNCTION, ReadCallback);
			curl_easy_setopt(pRequest->easyHandle, CURLOPT_INFILESIZE_LARGE, (curl_off_t) stream_size);
			break;
		
		case NetRequest::PATCH:
			curl_easy_setopt(pRequest->easyHandle, CURLOPT_CUSTOMREQUEST, "PATCH");
			curl_easy_setopt(pRequest->easyHandle, CURLOPT_POSTFIELDS, params.c_str());
			break;
	}
	
	struct curl_slist* headers = nullptr;
	
	// Set proper content type
	switch (type)
	{
		case NetRequest::PUT_JSON:
		case NetRequest::POST_JSON:
		case NetRequest::PATCH:
		case NetRequest::DELETE_:
		{
			headers = curl_slist_append(headers, "Content-Type: application/json");
			break;
		}
		case NetRequest::POST:
		case NetRequest::PUT:
		{
			headers = curl_slist_append(headers, "Content-Type: application/x-www-form-urlencoded");
			break;
		}
		case NetRequest::PUT_OCTETS:
		case NetRequest::PUT_OCTETS_PROGRESS:
		{
			headers = curl_slist_append(headers, "Content-Type: application/octet-stream");
			break;
		}
	}
	
	if (AddExtraHeaders())
	{
		headers = curl_slist_append(headers, ("X-Super-Properties: " + GetClientConfig()->GetSerializedBase64Blob()).c_str());
		headers = curl_slist_append(headers, ("X-Discord-Timezone: " + GetClientConfig()->GetTimezone()).c_str());
		headers = curl_slist_append(headers, ("X-Discord-Locale: " + GetClientConfig()->GetLocale()).c_str());
		headers = curl_slist_append(headers, ("Sec-Ch-Ua: " + GetClientConfig()->GetSecChUa()).c_str());
		headers = curl_slist_append(headers, "Sec-Ch-Ua-Mobile: ?0");
		headers = curl_slist_append(headers, ("Sec-Ch-Ua-Platform: " + GetClientConfig()->GetOS()).c_str());
	}
	
	if (!authorization.empty())
	{
		headers = curl_slist_append(headers, ("Authorization: " + authorization).c_str());
	}
	
	curl_easy_setopt(pRequest->easyHandle, CURLOPT_HTTPHEADER, headers);
	
	m_workerThreadMutex.lock();
	
	curl_multi_add_handle(m_multi, pRequest->easyHandle);
	InsertTailList(&m_netRequests, &pRequest->entry);
	
	m_workerThreadMutex.unlock();
	m_signalCV.notify_all();
}

void HTTPClient_iOS::WorkerThreadRun()
{
	while (m_bRunning)
	{
		int stillRunning = 0;
		curl_multi_perform(m_multi, &stillRunning);
		
		CURLMsg* msg;
		int msgsInQueue;
		while ((msg = curl_multi_info_read(m_multi, &msgsInQueue)))
		{
			if (msg->msg != CURLMSG_DONE)
				continue;
			
			CURL* easy = msg->easy_handle;
			HTTPRequest* request = nullptr;
			curl_easy_getinfo(easy, CURLINFO_PRIVATE, &request);
			
			m_workerThreadMutex.lock();
			RemoveEntryList(&request->entry);
			m_workerThreadMutex.unlock();
			
			NetRequest* netRequest = request->netRequest;
			
			CURLcode result = msg->data.result;
			
			long httpStatus = 0;
			curl_easy_getinfo(easy, CURLINFO_RESPONSE_CODE, &httpStatus);
			
			if (result != CURLE_OK)
			{
				netRequest->result = -1;
				netRequest->response = std::string("CURL error: ") + curl_easy_strerror(result);
				
				// TODO: Allow trying again.
			}
			else
			{
				netRequest->result = httpStatus;
			}
			
			// invoke callback now
			netRequest->pFunc(netRequest);
			
			// and then cleanup
			curl_multi_remove_handle(m_multi, easy);
			curl_easy_cleanup(easy);
			delete request;
		}
		
		std::unique_lock<std::mutex> lock (m_workerThreadMutex);
		m_signalCV.wait_for(lock, std::chrono::milliseconds(10));
	}
}

void HTTPClient_iOS::WorkerThreadInit(HTTPClient_iOS* instance)
{
	return instance->WorkerThreadRun();
}
