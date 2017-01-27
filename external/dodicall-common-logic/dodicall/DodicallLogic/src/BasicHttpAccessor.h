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

#pragma once

#include "stdafx.h"
#include "CurlSlistContainer.h"
#include "JsonHelper.h"
#include "ResultTypes.h"

namespace dodicall
{
using namespace results;
    
class BasicHttpAccessor
{
    
private:
	static unsigned gLinksCount;
	static boost::mutex gMutex;

protected:
	CURL* mCurl;
	
	CurlSlistContainerPtr mCookies;
	CurlSlistContainerPtr mHeaders;
	boost::mutex mMutex;

public:
	BasicHttpAccessor(void);
	~BasicHttpAccessor(void);
    
    std::string mHost;
    
	void Init(const char* userAgent = 0, const char* userPwd = 0, long timeout = 30, long connectionTimeout = 15, bool keepAlive = true);
	void SetHeader(const char* header);
	void Cleanup(void);

	CURLcode Request(const char* url, const char* postData, long& httpCode, std::vector<char>& responseData, long timeout = 0, long connectionTimeout = 0, long requestMethod = 0);

	std::string UrlEncode(const char* source) const;

	static std::string PtreeToGetParameters(const boost::property_tree::ptree& tree);

	template <class CONVERTOR, class T> CURLcode Request(const char* url, const char* postData, long& httpCode, T& response, long timeout = 0, long connectionTimeout = 0, long requestMethod = 0)
	{
		std::vector<char> responseData;
		CURLcode result = this->Request(url, postData, httpCode, responseData, timeout, connectionTimeout, requestMethod);
		if (result == CURLE_OK)
			CONVERTOR(responseData, response);
		return result;
	}
    
    DownloadFileResult DownloadFile(std::string const &url, std::string const &path);

	static void MergeHeadersAndCookies(BasicHttpAccessor& first, BasicHttpAccessor& second);

private:
	static CURLcode JustRequest(CURL* curl, const char* url, const char* postData, long& httpCode, std::vector<char>& responseData, curl_slist** cookies, long requestMethod);
};

class CharVectorToPtreeConvertor
{
public:
	inline CharVectorToPtreeConvertor(const std::vector<char>& input, boost::property_tree::ptree& output)
	{
		JsonHelper::json_to_ptree(std::string(input.begin(), input.end()).c_str(), output);
	}
};

}