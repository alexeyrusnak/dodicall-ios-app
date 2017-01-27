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

#include "JiraAccessor.h"
#include "JsonHelper.h"

namespace dodicall
{
    
JiraAccessor::JiraAccessor(): 
	mUserPwd("dmc-noreply@swisstok.ru:iddqd123"),
	mBaseUrl("https://jira.swisstok.net"),
	mPrjKey("DMC")
{ }
    
JiraAccessor::~JiraAccessor() 
{ }
    
size_t CurlWriteFunc(const void *ptr, size_t size, size_t nmemb, std::vector<char>* responseData);

CreateTroubleTicketResult JiraAccessor::SendTroubleTicket(
	const char *subject, 
	const char *description, 
	const std::map<std::string,std::string>& logs
) 
{
	long ticketId = -1;
	CreateTroubleTicketResult result = ResultFromErrorCode<CreateTroubleTicketResult>(ResultErrorSystem);
	CURL *curl = curl_easy_init();

	if (NULL == curl) {
		return result;
    }
    
    this->mResponseData.clear();

    curl_easy_setopt(curl, CURLOPT_USERPWD, this->mUserPwd.c_str());
    curl_easy_setopt(curl, CURLOPT_NOSIGNAL, 1);
    curl_easy_setopt(curl, CURLOPT_TIMEOUT, 50);
    curl_easy_setopt(curl, CURLOPT_FOLLOWLOCATION, 1);
    curl_easy_setopt(curl, CURLOPT_WRITEFUNCTION, CurlWriteFunc);
    curl_easy_setopt(curl, CURLOPT_WRITEDATA, &(this->mResponseData));

	if (!this->CreateTicket(curl, subject, description, &ticketId)) {

		if (-1 != ticketId) {

			this->mResponseData.clear();

			/* Attach logs when we have a valid ticket id only */
			this->AttachLogs(curl, logs, ticketId);

			/* And save the id for the future */
			result = ResultFromErrorCode<CreateTroubleTicketResult>(ResultErrorNo);
			result.IssueId = ticketId;
		}
	}

	curl_easy_cleanup(curl);

	return result;
}
    
int JiraAccessor::CreateTicket(
	CURL *curl,
	const char *subject, 
	const char *description, 
	long *id
)
{
	struct curl_slist *headers = NULL;

	headers = curl_slist_append(headers, "X-Atlassian-Token: no-check");
	headers = curl_slist_append(headers, "Content-Type: application/json");

	std::string postData;
	{
		boost::property_tree::ptree root;
		boost::property_tree::ptree fields;
		boost::property_tree::ptree project;
		boost::property_tree::ptree issueType;
		
		project.add("key", this->mPrjKey.c_str());
		fields.add_child("project", project);

		fields.add("summary", subject);
		fields.add("description", description);
			
		issueType.add("name", "Bug");
		fields.add_child("issuetype", issueType);

		root.add_child("fields", fields);

		postData = JsonHelper::ptree_to_json(root);
	}

    curl_easy_setopt(curl, CURLOPT_HTTPHEADER, headers);
	curl_easy_setopt(curl, CURLOPT_URL, (this->mBaseUrl + "/rest/api/2/issue/").c_str());
	curl_easy_setopt(curl, CURLOPT_POSTFIELDS, postData.c_str());

	CURLcode resCode = curl_easy_perform(curl);
	long httpCode = 0;

	curl_easy_getinfo(curl, CURLINFO_RESPONSE_CODE, &httpCode);

	if ((CURLE_OK == resCode) && (201 == httpCode)) {

		std::string responseString = std::string(this->mResponseData.begin(),this->mResponseData.end());
		
		boost::property_tree::ptree responseJson;

		if (JsonHelper::json_to_ptree(responseString.c_str(),responseJson)) {
			std::string idString = responseJson.get<std::string>("key","");
            int const prefixLength = idString.find_first_of("-") + 1;
            idString = idString.substr(prefixLength, idString.length()-prefixLength);
			*id = boost::lexical_cast<long>(idString);
			return 0;
		}
	}

	return -1;
}

int JiraAccessor::AttachLogs(
	CURL *curl,
	const std::map<std::string,std::string>& logs,
	long id
)
{
	struct curl_slist *headers = NULL;
	struct curl_httppost *post = NULL;
	struct curl_httppost *last = NULL;

	headers = curl_slist_append(headers, "X-Atlassian-Token: no-check");

    curl_easy_setopt(curl, CURLOPT_HTTPHEADER, headers);
	std::string fullUrl = this->mBaseUrl + "/rest/api/2/issue/" + this->mPrjKey + "-" + std::to_string(id) + "/attachments";

	curl_easy_setopt(curl, CURLOPT_URL, fullUrl.c_str());

    for (std::map<std::string,std::string>::const_iterator iter = logs.begin(); iter != logs.end(); iter++) {
		this->AttachOneLog(
			curl,
			iter->first.c_str(),
			iter->second.c_str(),
			iter->second.size(),
			"text/plain"
		);
	}

	return 0;
}

int JiraAccessor::AttachOneLog(
	CURL *curl, 
	const char *bufferName,
	const char *bufferPtr,
	const int bufferLength,
	const char *contentType
)
{
    const int maxLength = 10 * 1024 * 1024; /* 10MB */
    int length = bufferLength;
    int offset = 0;
    int filePart = 0;

    while (length > 0) {
        struct curl_httppost *post = NULL;
        struct curl_httppost *last = NULL;
        struct curl_forms forms[5];
        int curLength = (length > maxLength) ? maxLength : length;
        
        forms[0].option = CURLFORM_BUFFER;
        forms[0].value = (filePart > 0) ? std::string(std::string(bufferName) + ".part" + std::to_string(filePart)).c_str() : bufferName;
        forms[1].option = CURLFORM_BUFFERPTR;
        forms[1].value = bufferPtr + offset;
        forms[2].option = CURLFORM_BUFFERLENGTH;
        forms[2].value = (char*)curLength; /* Don't worry! I swear that it's normal. */
        forms[3].option = CURLFORM_CONTENTTYPE;
        forms[3].value = contentType;
        forms[4].option = CURLFORM_END;
        
        curl_formadd(&post, &last,
                     CURLFORM_COPYNAME, "file",
                     CURLFORM_ARRAY, forms,
                     CURLFORM_END
                     );
    
        curl_easy_setopt(curl, CURLOPT_HTTPPOST, post);
        
        CURLcode resCode = curl_easy_perform(curl);
        long httpCode = 0;
        
        curl_easy_getinfo(curl, CURLINFO_RESPONSE_CODE, &httpCode);
        
        std::string responseString = std::string(this->mResponseData.begin(),this->mResponseData.end());
        
        this->mResponseData.clear();
        
        if ((CURLE_OK != resCode) || (200 != httpCode)) {
            return -1;
        }
        
        length -= (length > maxLength) ? maxLength : length;
        offset += curLength;
        filePart++;
    }

	return 0;
}

}
