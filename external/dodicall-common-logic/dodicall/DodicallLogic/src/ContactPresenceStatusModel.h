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

namespace dodicall
{
namespace model
{

using namespace dbmodel;

enum BaseUserStatus
{
	BaseUserStatusOffline = 0,
	BaseUserStatusOnline,
	BaseUserStatusHidden,
	BaseUserStatusAway,
	BaseUserStatusDnd
};

class DODICALLLOGICAPI ContactPresenceStatusModel
{
public:
	ContactXmppIdType XmppId;
	BaseUserStatus BaseStatus;
	std::string ExtStatus;

	ContactPresenceStatusModel(const ContactXmppIdType& xmppId = "", BaseUserStatus baseStatus = BaseUserStatusOffline, const std::string& extStatus = "");

	DODICALLLOGICAPI friend bool operator < (const ContactPresenceStatusModel& p1, const ContactPresenceStatusModel& p2);
};

typedef std::set<ContactPresenceStatusModel> ContactPresenceStatusSet;

BaseUserStatus StringToBaseStatus(std::string str, bool self);
std::string BaseStatusToString(BaseUserStatus status);

}
}
