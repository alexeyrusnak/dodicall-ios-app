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

#include "ResultTypes.h"
#include <curl/curl.h>

namespace dodicall
{
    
using namespace results;
    
class JiraAccessor 
{
private:

	std::vector<char> mResponseData;

	const std::string mUserPwd;
	const std::string mBaseUrl;
	const std::string mPrjKey;
	
public:

    JiraAccessor();
    ~JiraAccessor();
        
    CreateTroubleTicketResult SendTroubleTicket(
		const char *subject, 
		const char *description, 
		const std::map<std::string,std::string>& logs
	);

private:

	int CreateTicket(
		CURL *curl,
		const char *subject, 
		const char *description, 
		long *id
	);

	int AttachLogs(
		CURL *curl,
		const std::map<std::string,std::string>& logs,
		long id
	);

	int AttachOneLog(
		CURL *curl, 
		const char *bufferName,
		const char *bufferPtr,
		const int bufferLength,
		const char *contentType
	);

};
    
}


