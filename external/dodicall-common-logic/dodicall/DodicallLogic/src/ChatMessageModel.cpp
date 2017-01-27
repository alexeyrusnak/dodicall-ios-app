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
#include "ChatMessageModel.h"

namespace dodicall
{
namespace model
{

ChatMessageModel::ChatMessageModel(void): Rownum(0), Servered(false), Readed(false), Type(ChatMessageTypeTextMessage), Id(""), ChatId(""), StringContent(""), Encrypted(false)
{
}
ChatMessageModel::ChatMessageModel(const ChatMessageDbModel& dbmessage): Rownum(dbmessage.Rownum), Id(dbmessage.Id), ChatId(dbmessage.ChatId), Servered(dbmessage.Servered), SendTime(dbmessage.SendTime),
	Readed(dbmessage.Readed), Type(dbmessage.Type), StringContent(dbmessage.StringContent), Encrypted(dbmessage.Encrypted)
{
}
ChatMessageModel::~ChatMessageModel(void)
{
}

bool operator < (const ChatMessageModel& left, const ChatMessageModel& right) 
{
    return (left.Id < right.Id);
}

}
}
