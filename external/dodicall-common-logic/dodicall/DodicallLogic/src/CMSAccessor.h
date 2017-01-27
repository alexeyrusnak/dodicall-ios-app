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

namespace dodicall
{

using namespace results;

class CMSAccessor
{
private:
	const std::string cRedMineUrl;
	const std::string cRedMineUserPwd;
	const unsigned cRedMineProjectId;
	const unsigned cRedMineUserForAssign; 
	const std::string cRedMineApiKey;

public:
	CMSAccessor(void);
	~CMSAccessor(void);

	CreateTroubleTicketResult SendTroubleTicket(const char* subject, const char* description, const std::map<std::string,std::string>& logs);

private:
	void PrepareForRequest(CURL* curl, std::vector<char>& response, const char* contentType = "application/json") const;
	
	std::string UploadFile(const std::string& fileData);
	int UploadBigFile(const std::string& fileName, const std::string& fileData, std::map<std::string, std::string>& tokens);
	CreateTroubleTicketResult CreateTicket(const std::string& subject, const std::string& description, const std::map<std::string,std::string>& fileTokens);
};

}
