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
#include "ChatDbModel.h"

#include "DateTimeUtils.h"
#include "StringUtils.h"

namespace dodicall
{
namespace dbmodel
{
    
ChatDbModel::ChatDbModel(const ChatIdType& id): Id(id), Servered(true), Active(true), Visible(true)
	, TotalMessagesCount(0), NewMessagesCount(0), IsNew(true), LastClearTime(time_t_to_posix_time((time_t)0)), IsP2P(false), Synchronized(true)
{
}
ChatDbModel::~ChatDbModel(void) 
{
}

bool ChatDbModel::IsP2p(void) const
{
    return IsP2P;
}

DateType ChatDbModel::GetDateOfCreation(void) const
{
    if (IsP2P) {
        //std::string s = to_simple_string(CreationDate);
        return CreationDate;
    }
 
    if (this->Id.empty())
        return DateType();
    
    if (posix_time_to_time_t(this->LastClearTime) > 0)
		return this->LastClearTime;
	DateType result = time_t_to_posix_time((time_t)0);
	std::string part = CutDomain(this->Id);
	size_t index = part.length();
	bool isDdc2 = (part.at(index-1) == 'x');
	if (index > 9)
	{
		part = part.substr(0, index - 3);
		index -= 3;
		if (index > 14)
		{
			part = part.substr(index - 14, 14);
			if (part.find_first_not_of("0123456789") == part.npos)
			{
				if (isDdc2)
					part.insert(8, "T");
				else
					part = part.substr(0, 8) + "T000000";
				result = boost::posix_time::from_iso_string(part);
			}
		}
	}
	return result;
}


int compare(const ChatDbModel& left, const ChatDbModel& right) 
{
    if (left.Id < right.Id)
        return -1;
    if (left.Id > right.Id)
        return 1;
	return 0;
}
    
bool operator == (const ChatDbModel& left, const ChatDbModel& right) 
{
    return (compare(left,right) == 0);
}
bool operator != (const ChatDbModel& left, const ChatDbModel& right) 
{
    return (compare(left,right) != 0);
}
bool operator < (const ChatDbModel& left, const ChatDbModel& right) 
{
    return (compare(left,right) < 0);
}

bool equals(const ChatDbModel& left, const ChatDbModel& right)
{
	if (left.Id == right.Id && left.CustomTitle == right.CustomTitle && left.LastClearTime == right.LastClearTime && left.Servered == right.Servered
		&& left.Visible == right.Visible && left.Active == right.Active && left.IsP2P == right.IsP2P && left.ContactXmppIds.size() == left.ContactXmppIds.size())
	{
		for (auto iter = left.ContactXmppIds.begin(); iter != left.ContactXmppIds.end(); iter++)
			if (right.ContactXmppIds.find(*iter) == right.ContactXmppIds.end())
				return false;
		return true;
	}
	return false;
}

UnsynchronizedChatEventDbModel::UnsynchronizedChatEventDbModel(UnsynchronizedChatEventType t, const std::string& identity):
	Type(t), Identity(identity)
{
}

bool operator < (const UnsynchronizedChatEventDbModel& left, const UnsynchronizedChatEventDbModel& right)
{
	if (left.Type < right.Type)
		return true;
	if (left.Identity < right.Identity)
		return true;
	return false;
}

}
}
