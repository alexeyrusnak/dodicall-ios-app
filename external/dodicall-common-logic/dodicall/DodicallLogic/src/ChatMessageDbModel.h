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

#include "ContactModel.h"
#include "DateTimeUtils.h"

namespace dodicall
{
namespace dbmodel
{

typedef std::string ChatIdType;
typedef std::set<ChatIdType> ChatIdSet;

typedef std::string ChatMessageIdType;
typedef std::set<ChatMessageIdType> ChatMessageIdSet;

typedef std::string ChatContactIdentityType;
typedef std::set<ChatContactIdentityType> ChatContactIdentitySet;

enum ChatMessageType
{
	ChatMessageTypeTextMessage,
	ChatMessageTypeSubject,
	ChatMessageTypeAudioMessage,
	ChatMessageTypeNotification,
	ChatMessageTypeContact,
	ChatMessageTypeDeleter
};

class ChatMessageDbModel
{
public:
	int Rownum;
	ChatMessageIdType Id;
	ChatIdType ChatId;
	ChatContactIdentityType Sender;
	bool Servered;
	DateType SendTime;
	bool Readed;
	ChatMessageType Type;
	std::string StringContent;
	std::string ExtendedContent;
    ChatMessageIdType ReplacedId;
    bool Changed;
    bool Encrypted;

	bool IsNew;

	ChatMessageDbModel(void);
	~ChatMessageDbModel(void);
    
	operator bool(void) const
	{
		return !this->Id.empty();
	}

	friend bool operator == (const ChatMessageDbModel& left, const ChatMessageDbModel& right);
    friend bool operator != (const ChatMessageDbModel& left, const ChatMessageDbModel& right);
    friend bool operator < (const ChatMessageDbModel& left, const ChatMessageDbModel& right);
};
    
typedef std::set<ChatMessageDbModel> ChatMessageDbModelSet;
typedef std::vector<ChatMessageDbModel> ChatMessageDbModelList;

}
}
