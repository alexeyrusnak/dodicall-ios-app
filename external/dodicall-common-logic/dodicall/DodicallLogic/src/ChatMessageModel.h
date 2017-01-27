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
#include "ContactModel.h"

namespace dodicall
{
namespace model
{

using namespace dbmodel;

enum ChatNotificationType
{
	ChatNotificationTypeCreate,
	ChatNotificationTypeInvite,
	ChatNotificationTypeRevoke,
	ChatNotificationTypeLeave,
	ChatNotificationTypeRemove
};

class DODICALLLOGICAPI ChatNotificationData
{
public:
	ChatNotificationType Type;
	ContactModelSet Contacts;
};

class DODICALLLOGICAPI ChatMessageModel
{
public:
	int Rownum;
	ChatMessageIdType Id;
	ChatIdType ChatId;
	ContactModel Sender;
	bool Servered;
	DateType SendTime;
	bool Readed;
	ChatMessageType Type;
	std::string StringContent;
    bool Changed;
    bool Encrypted;

	boost::optional<ContactModel> ContactData;
	boost::optional<ChatNotificationData> NotificationData;

	ChatMessageModel(void);
	ChatMessageModel(const ChatMessageDbModel& dbmessage);
	~ChatMessageModel(void);

    DODICALLLOGICAPI friend bool operator < (const ChatMessageModel& left, const ChatMessageModel& right);
};

typedef std::set<ChatMessageModel> ChatMessageModelSet;
typedef std::vector<ChatMessageModel> ChatMessageModelList;

}
}
