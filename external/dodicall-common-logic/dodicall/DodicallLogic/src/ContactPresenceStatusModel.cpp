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
#include "ContactPresenceStatusModel.h"

namespace dodicall
{
namespace model
{

ContactPresenceStatusModel::ContactPresenceStatusModel(const ContactXmppIdType& xmppId, BaseUserStatus baseStatus, const std::string& extStatus):
	XmppId(xmppId), BaseStatus(baseStatus), ExtStatus(extStatus)
{
}

bool operator < (const ContactPresenceStatusModel& p1, const ContactPresenceStatusModel& p2)
{
	return p1.XmppId < p2.XmppId;
}

BaseUserStatus StringToBaseStatus(std::string str, bool self)
{
	BaseUserStatus result;
	if (str.empty() || str == "online")
		result = BaseUserStatusOnline;
	else if (str == "away")
		result = BaseUserStatusAway;
	else if (str == "dnd")
		result = BaseUserStatusDnd;
	else if (str == "xa" && self)
		result = BaseUserStatusHidden;
	else
		result = BaseUserStatusOffline;
	return result;
}

std::string BaseStatusToString(BaseUserStatus status)
{
	std::string statusString;
	switch (status)
	{
	case BaseUserStatusAway:
		statusString = "away";
		break;
	case BaseUserStatusDnd:
		statusString = "dnd";
		break;
	case BaseUserStatusHidden:
		statusString = "xa";
		break;
	case BaseUserStatusOffline:
		statusString = "unavailable";
		break;
	default:
		// online
		break;
	}
	return statusString;
}

}
}