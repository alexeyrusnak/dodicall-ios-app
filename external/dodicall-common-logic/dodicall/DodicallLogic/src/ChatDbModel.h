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

#include "ChatMessageDbModel.h"

namespace dodicall
{
namespace dbmodel
{

class ChatDbModel 
{
public:
	ChatIdType Id;
	std::string CustomTitle;
	bool Servered;
	bool Active;
	bool Visible;
	DateType LastClearTime;
	bool IsP2P;
	bool Synchronized;

	ChatContactIdentitySet ContactXmppIds;

	// Statistics
	bool IsNew;
	int TotalMessagesCount;
	int NewMessagesCount;
	DateType LastModifiedDate;
    
    DateType CreationDate;
    

	ChatDbModel(const ChatIdType& id = (ChatIdType)"");
	~ChatDbModel(void);

	// REVIEW SV->AM: следует избавиться от этой функции, вместо неё использовать поле IsP2P.
	bool IsP2p(void) const;
	DateType GetDateOfCreation(void) const;

	operator bool(void) const
	{
		return !this->Id.empty();
	}

    friend bool operator == (const ChatDbModel& left, const ChatDbModel& right);
    friend bool operator != (const ChatDbModel& left, const ChatDbModel& right);
    friend bool operator < (const ChatDbModel& left, const ChatDbModel& right);

	friend bool equals(const ChatDbModel& left, const ChatDbModel& right);
};
    
typedef std::set<ChatDbModel> ChatDbModelSet;

enum UnsynchronizedChatEventType
{
	UnsynchronizedChatEventInvite = 1,
	UnsynchronizedChatEventRevoke
};

class UnsynchronizedChatEventDbModel
{
public:
	UnsynchronizedChatEventType Type;
	std::string Identity;

	UnsynchronizedChatEventDbModel(UnsynchronizedChatEventType t = UnsynchronizedChatEventInvite, const std::string& identity = "");

	friend bool operator < (const UnsynchronizedChatEventDbModel& left, const UnsynchronizedChatEventDbModel& right);
};

typedef std::set<UnsynchronizedChatEventDbModel> UnsynchronizedChatEventDbSet;

}
}