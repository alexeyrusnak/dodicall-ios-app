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
#include "ChatMessageDbModel.h"
#include "DateTimeUtils.h"

namespace dodicall
{
namespace dbmodel
{

ChatMessageDbModel::ChatMessageDbModel(void): Rownum(0), Servered(false), Readed(false), Type(ChatMessageTypeTextMessage), IsNew(true), 
	SendTime(posix_time_now()), Encrypted(false), Changed(false)
{
}
ChatMessageDbModel::~ChatMessageDbModel(void) 
{
}

int compare(const ChatMessageDbModel& left, const ChatMessageDbModel& right) 
{
    if (left.Id < right.Id)
        return -1;
    if (left.Id > right.Id)
        return 1;
    return 0;
}
    
bool operator == (const ChatMessageDbModel& left, const ChatMessageDbModel& right) 
{
    return (compare(left,right) == 0);
}
bool operator != (const ChatMessageDbModel& left, const ChatMessageDbModel& right) 
{
    return (compare(left,right) != 0);
}
bool operator < (const ChatMessageDbModel& left, const ChatMessageDbModel& right) 
{
    return (compare(left,right) < 0);
}

}
}
