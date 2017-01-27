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
#include "ChatModel.h"

#include "DateTimeUtils.h"

namespace dodicall
{
namespace model
{

ChatModel::ChatModel(void): Id(""), Title(""), Active(true), TotalMessagesCount(0), NewMessagesCount(0), LastModifiedDate(time_t_to_posix_time((time_t)0)), IsP2p(true)
{
}
ChatModel::ChatModel(const ChatDbModel& dbchat): Id(dbchat.Id), Title(dbchat.CustomTitle), Active(dbchat.Active), 
	TotalMessagesCount(dbchat.TotalMessagesCount), NewMessagesCount(dbchat.NewMessagesCount), LastModifiedDate(dbchat.LastModifiedDate), IsP2p(dbchat.IsP2p())
{
}
ChatModel::~ChatModel(void)
{
}

bool operator < (const ChatModel& left, const ChatModel& right)
{
	return (left.Id < right.Id);
}

}
}
