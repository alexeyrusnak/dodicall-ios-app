/*
Copyright (C) 2016, Telco Cloud Trading & Logistic Ltd
*/
//  This file is part of dodicall.
//  dodicall is free software : you can redistribute it and / or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  dodicall is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with dodicall.If not, see <http://www.gnu.org/licenses/>.

#include "stdafx.h"

#include "BasicHttpAccessor.h"
#include "LogManager.h"
#include "DateTimeUtils.h"
#include "FilesystemHelper.h"

#include <time.h>
#include <sstream>

namespace dodicall
{

unsigned BasicHttpAccessor::gLinksCount = 0;
boost::mutex BasicHttpAccessor::gMutex;

BasicHttpAccessor::BasicHttpAccessor(): mCurl(0), mCookies(new CurlSlistContainer()), mHeaders(new CurlSlistContainer())
{
	boost::lock_guard<boost::mutex> _lock(gMutex);
	if (!gLinksCount)
		curl_global_init(CURL_GLOBAL_ALL);
	gLinksCount++;
}

BasicHttpAccessor::~BasicHttpAccessor()
{
	this->Cleanup();
	boost::lock_guard<boost::mutex> _lock(gMutex);
	gLinksCount--;
	if (!gLinksCount)
		curl_global_cleanup();
}

void BasicHttpAccessor::Init(const char* userAgent, const char* userPwd, long timeout, long connectionTimeout, bool keepAlive)
{
	boost::lock_guard<boost::mutex> _lock(this->mMutex);
	if (this->mCurl)
		curl_easy_cleanup(this->mCurl);
	this->mCurl = curl_easy_init();
	if (this->mCurl)
	{
		if (userAgent)
			curl_easy_setopt(this->mCurl, CURLOPT_USERAGENT, userAgent);
		if (userPwd)
			curl_easy_setopt(this->mCurl, CURLOPT_USERPWD, userPwd);
		if (keepAlive)
			curl_easy_setopt(this->mCurl, CURLOPT_TCP_KEEPALIVE, 1L);
		curl_easy_setopt(this->mCurl, CURLOPT_TIMEOUT, timeout);
		curl_easy_setopt(this->mCurl, CURLOPT_CONNECTTIMEOUT, connectionTimeout);
		curl_easy_setopt(this->mCurl, CURLOPT_COOKIEFILE, "cookies.txt");
		if (this->mHeaders->SList)
			curl_easy_setopt(this->mCurl, CURLOPT_HTTPHEADER, this->mHeaders->SList);
		// TODO: потом обязательно убрать!
		curl_easy_setopt(this->mCurl, CURLOPT_SSL_VERIFYPEER, 0);
		curl_easy_setopt(this->mCurl, CURLOPT_SSL_VERIFYHOST, 0);
	}
}

void BasicHttpAccessor::SetHeader(const char* header)
{
	boost::lock_guard<boost::mutex> _lock(this->mMutex);
	if (this->mCurl)
	{
		this->mHeaders->SList = curl_slist_append(this->mHeaders->SList, header);
		curl_easy_setopt(this->mCurl, CURLOPT_HTTPHEADER, this->mHeaders->SList);
	}
}

void BasicHttpAccessor::Cleanup(void)
{
	boost::lock_guard<boost::mutex> _lock(this->mMutex);
	if (this->mCurl)
	{
		curl_easy_cleanup(this->mCurl);
		this->mCurl = 0;
	}
}

CURLcode BasicHttpAccessor::Request(const char* url, const char* postData, long& httpCode, std::vector<char>& responseData, long timeout, long connectionTimeout, long requestMethod)
{
	if (!this->mCurl)
	{
		LogManager::GetInstance().AppServerLogger(LogLevelError) << "Curl is not initialized";
		return CURLE_FAILED_INIT;
	}
	CURL* curl = 0;
	CurlSlistContainerPtr cookies;
	{
		boost::lock_guard<boost::mutex> _lock1(this->mMutex);
		curl = curl_easy_duphandle(this->mCurl);

		if (!curl)
		{
			LogManager::GetInstance().AppServerLogger(LogLevelError) << "Failed to dublicate curl";
			return CURLE_FAILED_INIT;
		}
		if (timeout)
			curl_easy_setopt(this->mCurl, CURLOPT_TIMEOUT, timeout);
		if (connectionTimeout)
			curl_easy_setopt(this->mCurl, CURLOPT_CONNECTTIMEOUT, connectionTimeout);

		cookies = CloneCurlSlistContainer(this->mCookies);
	}

	std::string strUrl = url;
	if (strUrl.find_first_of(':') == strUrl.npos)
		strUrl = this->mHost + strUrl;

	CURLcode result = this->JustRequest(curl, strUrl.c_str(), postData, httpCode, responseData, &cookies->SList, requestMethod);

	boost::lock_guard<boost::mutex> _lock2(this->mMutex);
	this->mCookies = cookies;

	curl_easy_cleanup(curl);

	return result;
}



void HideText(std::string &source, std::string const &symbols)
{
	size_t last_found = 0;
	while (last_found < source.length()) 
	{
		size_t found = source.find(symbols.c_str(), last_found, symbols.length());
		last_found = found;
		if (found != std::string::npos) 
		{
			// find ':' pos
			size_t found_pwd = source.find(":", found + 1, 1);
			last_found = found_pwd;
			if (found_pwd != std::string::npos) 
			{
				size_t dataLength = 0;
				// find '"' pos
				size_t found_end = source.find("\"", found_pwd + 2, 1);
				last_found = found_end;
				if (found_end != std::string::npos) 
				{
					dataLength = found_end - (found_pwd + 2);
					source.replace(found_pwd + 2, dataLength, "***");
				}
			}
		}
	}
}

void HideHalfText(std::string &source, std::string const &symbols) 
{
	size_t id = source.find(symbols);

	if (id == std::string::npos)
		return;

	std::size_t lastTab = source.find_last_of("\t");
	std::string prefixStr;

	if (lastTab != std::string::npos)
		prefixStr = source.substr(0, lastTab + 1);

	std::string sessionStr = source.substr(id + symbols.length() + 1, std::string::npos);
	size_t sessionLength = sessionStr.length();
	int hideStartPos = sessionLength >> 2;
	int replaceLength = sessionLength >> 1;

	sessionStr.replace(hideStartPos, replaceLength, "***");
	source = prefixStr + sessionStr;
}

size_t CurlWriteFunc(const void *ptr, size_t size, size_t nmemb, std::vector<char>* responseData)
{
	size_t fullsize = size*nmemb;
	responseData->insert(responseData->end(), (const char*)ptr, ((const char*)ptr) + fullsize);
	return fullsize;
}

CURLcode BasicHttpAccessor::JustRequest(CURL* curl, const char* url, const char* postData, long& httpCode, std::vector<char>& responseData, curl_slist** cookies, long requestMethod)
{
	Logger& logger = LogManager::GetInstance().AppServerLogger;

	std::string strMethod = (postData ? (requestMethod == CURLOPT_PUT ? "PUT " : "POST ") : "GET ");

	logger(LogLevelInfo) << "Start executing request: \n" << strMethod << url;

	curl_easy_setopt(curl, CURLOPT_URL, url);
	if (postData)
	{
		curl_easy_setopt(curl, CURLOPT_POSTFIELDS, postData);
		// mask passwords
		std::string dataStr(postData);

		HideText(dataStr, "password");

		logger(LogLevelDebug) << strMethod << " data: \n" << dataStr.c_str();
		if (requestMethod == CURLOPT_PUT)
			curl_easy_setopt(curl, CURLOPT_PUT, true);
	}
	curl_easy_setopt(curl, CURLOPT_WRITEFUNCTION, CurlWriteFunc);
	curl_easy_setopt(curl, CURLOPT_WRITEDATA, &responseData);

	if (cookies && *cookies)
	{
		curl_slist* iter = *cookies;
		while (iter)
		{
			CURLcode cookieCode = curl_easy_setopt(curl, CURLOPT_COOKIELIST, iter->data);
			iter = iter->next;
		}
		// REVIEW SV->AM: нужно логировать и маскировать значения ВСЕХ куков, а не только первой
		// TODO: mask tokens
		std::string cookiesStr((**cookies).data);

		HideHalfText(cookiesStr, "PHPSESSID");
		HideHalfText(cookiesStr, "dodiauth");
		logger(LogLevelDebug) << "Request cookies: \n" << cookiesStr.c_str()/* **cookies */;
	}

	CURLcode resCode = curl_easy_perform(curl);

	curl_easy_getinfo(curl, CURLINFO_RESPONSE_CODE, &httpCode);
	std::string responseString = std::string(responseData.begin(), responseData.end());

	logger(LogLevelInfo) << "Response completed with code " << httpCode;
	// mask passwords
	std::string respStr(responseString);

	HideText(respStr, "password");

	logger(LogLevelDebug) << "Response data: \n" << respStr.c_str();

	if (cookies)
	{
		curl_easy_getinfo(curl, CURLINFO_COOKIELIST, cookies);
		if (*cookies) 
		{
			// REVIEW SV->AM: нужно логировать и маскировать значения ВСЕХ куков, а не только первой
			std::string cookiesStr((**cookies).data);

			HideHalfText(cookiesStr, "PHPSESSID");
			HideHalfText(cookiesStr, "dodiauth");
			logger(LogLevelDebug) << "Response cookies: \n" << cookiesStr.c_str()/* **cookies */;
		}
	}
	return resCode;
}

std::string BasicHttpAccessor::UrlEncode(const char* source) const
{
	char* cres = curl_easy_escape(this->mCurl, source, strlen(source));
	std::string result = cres;
	curl_free(cres);
	return result;
}

std::string BasicHttpAccessor::PtreeToGetParameters(const boost::property_tree::ptree& tree)
{
	std::string result;
	for (boost::property_tree::ptree::const_iterator iter = tree.begin(); iter != tree.end(); iter++)
	{
		if (iter == tree.begin())
			result += "?";
		else
			result += "&";
		result += iter->first + "=" + tree.get<std::string>(iter->first);
	}
	return result;
}
    
static size_t HeaderCallback(char *buffer, size_t size, size_t nitems, void *headersArr)
{
    if(buffer != NULL)
    {
        std::string headerString(buffer);
        std::string nameDivider = ": ";
        
        size_t endNameIndex = headerString.find_first_of(nameDivider);
        
        if(endNameIndex != std::string::npos)
        {
            std::string headerName = headerString.substr(0, endNameIndex);
            std::string headerValue = headerString.substr(endNameIndex + nameDivider.length(), headerString.length()-endNameIndex-nameDivider.length());
            
            (*(std::map<std::string, std::string> *)headersArr)[headerName] = headerValue;
        }
        
    }
    
    size_t numbytes = size * nitems;
    return numbytes;
}
    
size_t WriteData(void *ptr, size_t size, size_t nmemb, void *stream) {
    std::string data((const char*) ptr, (size_t) size * nmemb);
    *((std::stringstream*) stream) << data;
    return size * nmemb;
}

DownloadFileResult BasicHttpAccessor::DownloadFile(std::string const &url, std::string const &path)
{
	// REVIEW SV->MV: Добавить логирование запроса аналогично функции JustRequest
	// выводить в лог как минимум заголовки запроса и ответа
    std::string fullUrl = this->mHost + url;
    boost::filesystem::path pathToWrite{path};
    
	Logger& logger = LogManager::GetInstance().AppServerLogger;

    if(boost::filesystem::is_directory(path))
    {
        size_t startFilename = fullUrl.find_last_of("/");
        std::string fileName = fullUrl.substr(startFilename, fullUrl.length() - startFilename);
        pathToWrite = pathToWrite/boost::filesystem::path{fileName};
    }
    
    std::time_t lastModifiedTime = boost::filesystem::exists(pathToWrite) ? last_write_time(pathToWrite) : NULL;
    
    CURLcode curlResult;
    DownloadFileResult downloadResult = ResultFromErrorCode<DownloadFileResult>(ResultErrorSystem);

	CurlSlistContainer requestHeadersList;

    if(lastModifiedTime) 
	{
        std::tm* timeinfo(std::localtime(&lastModifiedTime));
		if (timeinfo)
		{
			std::string strTime = "If-Modified-Since: " + std::string(std::asctime(timeinfo));
			requestHeadersList.SList = curl_slist_append(requestHeadersList.SList, strTime.c_str());
			logger(LogLevelDebug) << "Localtime string of " << lastModifiedTime << " is " << strTime << " for " << path;
		}
		else
			logger(LogLevelWarning) << "Failed to get localtime string of " << lastModifiedTime << " for " << path;
	}

    if (!this->mCurl)
        return downloadResult;

    CURL* curl = 0;
    {
        boost::lock_guard<boost::mutex> _lock1(this->mMutex);
        curl = curl_easy_duphandle(this->mCurl);
    }

    if (!curl)
        return downloadResult;
    
    
    std::stringstream dataStream;
    std::map<std::string, std::string> responseHeadersMap;
    
    curl_easy_setopt(curl, CURLOPT_URL, fullUrl.c_str());
    curl_easy_setopt(curl, CURLOPT_WRITEFUNCTION, WriteData);
    curl_easy_setopt(curl, CURLOPT_WRITEDATA, &dataStream);
    curl_easy_setopt(curl, CURLOPT_HEADERFUNCTION, HeaderCallback);
    curl_easy_setopt(curl, CURLOPT_HEADERDATA, &responseHeadersMap);
    curl_easy_setopt(curl, CURLOPT_FOLLOWLOCATION, 1);
    curl_easy_setopt(curl, CURLOPT_TIMEOUT, 300L);
    curl_easy_setopt(curl, CURLOPT_CONNECTTIMEOUT, 15L);

    if(requestHeadersList.SList)
        curl_easy_setopt(curl, CURLOPT_HTTPHEADER, requestHeadersList.SList);
    
    curlResult = curl_easy_perform(curl);
    
	long httpCode = 0;
	curl_easy_getinfo(curl, CURLINFO_RESPONSE_CODE, &httpCode);
	
	if (curlResult != CURLE_OK || httpCode != 200 && httpCode != 304)
        return downloadResult;
    
	downloadResult = DownloadFileResult(true, ResultErrorNo, DownloadFileStatusDownloaded, pathToWrite.string(), responseHeadersMap);

	bool fileChanged = true;
    std::time_t newModifiedTime = NULL;
    
	if (httpCode == 304) // NOT MODIFIED
		fileChanged = false;
	else
	{
		bool success = false;
		std::map<std::string, std::string>::const_iterator lastModifiedIter = responseHeadersMap.find("Last-Modified");
		if (lastModifiedIter != responseHeadersMap.end())
		{
			std::string dateTimeString = lastModifiedIter->second;
			std::tm t;

			static std::vector<std::string> gHttpFormats = boost::assign::list_of("%a, %d %b %Y %H:%M:%S GMT");
			for (auto iter = gHttpFormats.begin(); !success && iter != gHttpFormats.end(); iter++)
			{
				std::istringstream ss(dateTimeString);
				ss >> std::get_time(&t, iter->c_str());
				success = !ss.fail();
			}

			if (success)
			{
				newModifiedTime = std::mktime(&t);
				logger(LogLevelDebug) << "Last-Modified value of " << dateTimeString << " is " << newModifiedTime << " for " << fullUrl;

				if (newModifiedTime <= lastModifiedTime)
					fileChanged = false;
			}
			else
				logger(LogLevelWarning) << "Failed to parse header Last-Modified " << dateTimeString << " for " << fullUrl;
		}

		if (!success || !fileChanged || lastModifiedIter == responseHeadersMap.end())
		{
			downloadResult.LastModifiedProblemDetected = true;

			static bool ifLastModifiedProblemReported = false;
			if (!ifLastModifiedProblemReported)
			{
				logger(LogLevelWarning) << "Problem with Last-Modified header detected!";
				ifLastModifiedProblemReported = true;
			}
		}
	}

//		Check size
//        dataStream.seekg(0, std::ios::end);
//        int size = dataStream.tellg();
//        dataStream.seekg(0, std::ios::beg);
    
    if (fileChanged)
    {
        std::ofstream outFile;
		FilesystemHelper::OpenStream(outFile, pathToWrite, std::ios::binary | std::ios::out | std::ios::trunc);
        if (outFile)
        {
			std::string dataStr = dataStream.str();
			outFile.write(dataStr.c_str(), dataStr.size());
            outFile.close();
            
            if(newModifiedTime)
                boost::filesystem::last_write_time(pathToWrite, newModifiedTime);
        }
        
    }
    
    if(fileChanged)
        downloadResult.FileStatus = DownloadFileStatusDownloaded;
	else
		downloadResult.FileStatus = DownloadFileStatusNotChanged;
    
	curl_easy_cleanup(curl);

    return downloadResult;
}

void BasicHttpAccessor::MergeHeadersAndCookies(BasicHttpAccessor& first, BasicHttpAccessor& second)
{
	// TODO: сделать реальный merge
	second.mHeaders = first.mHeaders;
	second.mCookies = first.mCookies;
}

}
