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
#include "CMSAccessor.h"

#include "JsonHelper.h"

namespace dodicall
{

size_t CurlWriteFunc(const void *ptr, size_t size, size_t nmemb, std::vector<char>* responseData);

CMSAccessor::CMSAccessor(void): cRedMineUrl("http://redmine.t-mind.ru/"), cRedMineUserPwd("tm:dozor"), 
	cRedMineProjectId(30), cRedMineUserForAssign(41), cRedMineApiKey("3af27124d2013ab784a85274143dd0b1f291cc79")
{
}
CMSAccessor::~CMSAccessor(void)
{
}

CreateTroubleTicketResult CMSAccessor::SendTroubleTicket(const char* subject, const char* description, const std::map<std::string,std::string>& logs)
{
	std::map<std::string,std::string> tokens;
	for (std::map<std::string,std::string>::const_iterator iter = logs.begin(); iter != logs.end(); iter++)
	{
		/* This way doesn't work sometimes when we have a large file */
		/*
		std::string token = this->UploadFile(iter->second);
		if (!token.empty())
			tokens[iter->first] = token;
		*/
		this->UploadBigFile(iter->first, iter->second, tokens);
	}
	return this->CreateTicket(subject,description,tokens);
}

void CMSAccessor::PrepareForRequest(CURL* curl, std::vector<char>& response, const char* contentType) const
{
	curl_easy_setopt(curl, CURLOPT_USERPWD, this->cRedMineUserPwd.c_str());
	curl_easy_setopt(curl, CURLOPT_NOSIGNAL, 1);
	curl_easy_setopt(curl, CURLOPT_TIMEOUT, 50);
	curl_easy_setopt(curl, CURLOPT_WRITEFUNCTION, CurlWriteFunc);
	curl_easy_setopt(curl, CURLOPT_WRITEDATA, &response);

	curl_slist* headers = 0;
	headers = curl_slist_append(headers, (std::string("Content-Type: ") + contentType).c_str());
	headers = curl_slist_append(headers, (std::string("X-Redmine-API-Key: ") + this->cRedMineApiKey).c_str());
	curl_easy_setopt(curl, CURLOPT_HTTPHEADER, headers);
}

std::string CMSAccessor::UploadFile(const std::string& fileData)
{
	CURL* curl = curl_easy_init();
	std::string result;
	if (curl)
	{
		std::vector<char> responseData;
		PrepareForRequest(curl,responseData,"application/octet-stream");

		curl_easy_setopt(curl, CURLOPT_URL, (this->cRedMineUrl+"uploads.json").c_str());
		curl_easy_setopt(curl, CURLOPT_POSTFIELDS, fileData.c_str());

		CURLcode resCode = curl_easy_perform(curl);
		long httpCode = 0;
		curl_easy_getinfo(curl, CURLINFO_RESPONSE_CODE, &httpCode);
		std::string responseString = std::string(responseData.begin(),responseData.end());

		if (resCode == CURLE_OK && httpCode == 201)
		{
			boost::property_tree::ptree responseJson;
			JsonHelper::json_to_ptree(responseString.c_str(),responseJson);
			if (responseJson.count("upload") > 0)
			{
				boost::property_tree::ptree upload = responseJson.get_child("upload");
				result = upload.get<std::string>("token","");
			}
		}
		curl_easy_cleanup(curl);
	}
	return result;
}

int CMSAccessor::UploadBigFile(const std::string& fileName, const std::string& fileData, std::map<std::string,std::string>& tokens)
{
	std::vector<char> responseData;
	CURL* curl = curl_easy_init();

	if (NULL == curl) {
		return -1;
	}

	PrepareForRequest(curl, responseData, "application/octet-stream");

	curl_easy_setopt(curl, CURLOPT_URL, (this->cRedMineUrl+"uploads.json").c_str());

	const int maxLength = 5 * 1024 * 1024; /* 5MB */
	const char *buffer = fileData.c_str();
	int length = fileData.size();
	int offset = 0;
	int filePart = 0;

	while (length > 0) {
		int curLength = (length > maxLength) ? maxLength : length;
		std::string curFileName = (filePart > 0) ? (fileName + ".part" + std::to_string(filePart)).c_str() : fileName;

        curl_easy_setopt(curl, CURLOPT_POSTFIELDSIZE, curLength);
		curl_easy_setopt(curl, CURLOPT_POSTFIELDS, buffer + offset);

		CURLcode resCode = curl_easy_perform(curl);
		long httpCode = 0;
		curl_easy_getinfo(curl, CURLINFO_RESPONSE_CODE, &httpCode);
		std::string responseString = std::string(responseData.begin(),responseData.end());

		if (resCode == CURLE_OK && httpCode == 201)
		{
			boost::property_tree::ptree responseJson;
			JsonHelper::json_to_ptree(responseString.c_str(),responseJson);
			if (responseJson.count("upload") > 0)
			{
				boost::property_tree::ptree upload = responseJson.get_child("upload");
				std::string token;
				token = upload.get<std::string>("token","");
				if (!token.empty()) {
					tokens[curFileName] = token;
				}
			}
		}

        responseData.clear();
        
		length -= (length > maxLength) ? maxLength : length;
		offset += curLength;
		filePart++;
	} /* while (length > 0) */

	curl_easy_cleanup(curl);

	return 0;
}

CreateTroubleTicketResult CMSAccessor::CreateTicket(
	const std::string& subject, 
	const std::string& description, 
	const std::map<std::string,std::string>& fileTokens
)
{
	CURL* curl = curl_easy_init();
	if (curl)
	{
		std::vector<char> responseData;
		PrepareForRequest(curl,responseData,"application/json");

		std::string postData;
		{
			boost::property_tree::ptree issueJson;
			issueJson.add("project_id",this->cRedMineProjectId);
			issueJson.add("subject",subject);
			issueJson.add("description",description);
			issueJson.add("assigned_to_id",this->cRedMineUserForAssign);
			
			boost::property_tree::ptree uploadsJson;
			for (std::map<std::string,std::string>::const_iterator iter = fileTokens.begin(); iter != fileTokens.end(); iter++)
			{
				boost::property_tree::ptree uploadJson;
				uploadJson.add("filename",iter->first);
				uploadJson.add("token",iter->second);
				uploadJson.add("content_type","plain/text");
				uploadsJson.push_back(std::make_pair("",uploadJson));
			}
			issueJson.add_child("uploads",uploadsJson);

			boost::property_tree::ptree postJson;
			postJson.add_child("issue",issueJson);
			postData = JsonHelper::ptree_to_json(postJson);
		}

		curl_easy_setopt(curl, CURLOPT_URL, (this->cRedMineUrl+"issues.json").c_str());
		curl_easy_setopt(curl, CURLOPT_POSTFIELDS, postData.c_str());

		CURLcode resCode = curl_easy_perform(curl);
		long httpCode = 0;
		curl_easy_getinfo(curl, CURLINFO_RESPONSE_CODE, &httpCode);

		CreateTroubleTicketResult result;
		if (resCode == CURLE_OK && httpCode == 201)
		{
			std::string responseString = std::string(responseData.begin(),responseData.end());
			boost::property_tree::ptree responseJson;
			if (JsonHelper::json_to_ptree(responseString.c_str(),responseJson) && responseJson.count("issue") > 0)
			{
				boost::property_tree::ptree issueJson = responseJson.get_child("issue");
				long id = issueJson.get<long>("id",0);
				if (id)
				{
					result = ResultFromErrorCode<CreateTroubleTicketResult>(ResultErrorNo);
					result.IssueId = id;
				}
				else
					result = ResultFromErrorCode<CreateTroubleTicketResult>(ResultErrorSystem);
			}
		}
		else
			result = ResultFromErrorCode<CreateTroubleTicketResult>(ResultErrorSystem);
		curl_easy_cleanup(curl);
		return result;
	}
	return ResultFromErrorCode<CreateTroubleTicketResult>(ResultErrorSystem);
}

}
