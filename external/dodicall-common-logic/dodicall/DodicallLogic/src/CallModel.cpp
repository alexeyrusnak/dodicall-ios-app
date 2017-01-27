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
#include "CallModel.h"

namespace dodicall
{
namespace model
{

const char delim = ',';

CallModel::CallModel(const char* id): Id(id ? id : ""), Duration(0)
{
}
CallModel::~CallModel(void)
{
}

std::string PeerModel::GetId() const
{
	std::string id;
	if ((bool)Contact)
	{
		id = std::to_string(Contact->Id)
			+ delim + Contact->DodicallId
			+ delim + Contact->PhonebookId
			+ delim + Contact->NativeId;
	}
	else
	{
		id += delim;
		id += delim;
		id += delim;
	}
	return id + delim + std::to_string(AddressType) + delim + Identity;
}

bool ExtractLast(std::string& from, std::string& to)
{
	size_t delimPos = from.find_last_of(delim);
	bool ret = delimPos != std::string::npos;
	if (ret)
	{
		to = from.substr(delimPos + 1);
		from.erase(delimPos);
		assert(delimPos == from.length()); // дело принципа: хоть что-то проверить
	}
	return ret;
}

bool PeerModel::FromStringPartial(std::string peerString)
{
	PeerModel me = *this;
	std::string s = peerString;
	bool ret = ExtractLast(s, Identity) && Identity.length() > 0;
	while (ret) // do it once...
	{
		std::string addresType;
		ret = ret && ExtractLast(s, addresType) && addresType.length() == 1 && isdigit(addresType[0]);
		if (!ret)
			break;
		AddressType = static_cast<CallAddressType>(atoi(addresType.c_str()));
		assert(AddressType <= CallAddressDodicall);   // просто чтобы вовремя отреагировать, если появятся еще какие-то непредусмотренные варианты
		dodicall::dbmodel::ContactModel contact;
		ret = ret && ExtractLast(s, contact.NativeId);
		ret = ret && ExtractLast(s, contact.PhonebookId);
		ret = ret && ExtractLast(s, contact.DodicallId);
		if (!ret)
			break;
		long id = 0;
		if (s.length())
		{
			contact.Id = atoi(s.c_str());
			ret = ret && s == std::to_string(contact.Id);
		}
		if (ret && contact)
			Contact = contact;
		break; // ... do it once
	}
	if (!ret)
	{
		assert(!("wrong peerString {" + peerString + "}").c_str());
		*this = me;
	}
	return ret;
}

}
}

