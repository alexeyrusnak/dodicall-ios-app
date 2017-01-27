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

#include "ChatDbModel.h"
#include "ChatMessageModel.h"
#include "ContactModel.h"

namespace dodicall
{
namespace model
{

using namespace dbmodel;

class DODICALLLOGICAPI ChatModel
{
public:
	ChatIdType Id;
	std::string Title;
	bool Active;
	bool IsP2p;

	ContactModelSet Contacts;

	// Statistics
	int TotalMessagesCount;
	int NewMessagesCount;
	DateType LastModifiedDate;
	boost::optional<ChatMessageModel> LastMessage;

	ChatModel();
	ChatModel(const ChatDbModel& dbchat);
	~ChatModel(void);
    
    friend DODICALLLOGICAPI bool operator < (const ChatModel& left, const ChatModel& right);
};
    
typedef std::set<ChatModel> ChatModelSet;

}
}
