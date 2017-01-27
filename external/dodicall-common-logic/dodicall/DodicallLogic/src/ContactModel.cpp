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
#include "ContactModel.h"

#include "DateTimeUtils.h"

namespace dodicall
{
namespace dbmodel
{

ContactsContactModel::ContactsContactModel(const std::string& identity, ContactsContactType type):
	Identity(identity), Type(type), Favourite(false), Manual(false)
{
}

ContactModel::ContactModel(void): Id(0), Blocked(false), White(false), Synchronized(false), 
	Deleted(false), Iam(false), LastModifiedDate(posix_time_now())
{
}
ContactModel::ContactModel(const ContactModel& from): Id(from.Id), NativeId(from.NativeId), DodicallId(from.DodicallId), PhonebookId(from.PhonebookId), CompanyId(from.CompanyId),
	FirstName(from.FirstName), LastName(from.LastName), Blocked(from.Blocked), White(from.White),
    Contacts(from.Contacts),
    Synchronized(from.Synchronized),
	Deleted(from.Deleted), Iam(from.Iam), Subscription(from.Subscription), AvatarPath(from.AvatarPath), LastModifiedDate(from.LastModifiedDate)
{
}
ContactModel::~ContactModel(void)
{
}

model::ContactXmppIdType ContactModel::GetXmppId(void) const
{
	for (ContactsContactSet::const_iterator iter = this->Contacts.begin(); iter != this->Contacts.end(); iter++)
		if (iter->Type == ContactsContactXmpp)
			return iter->Identity;
	return std::string();
}

int compare(const ContactModel& left, const ContactModel& right)
{
	if (!left.DodicallId.empty())
	{
		if (!right.DodicallId.empty())
		{
			if (left.DodicallId < right.DodicallId)
				return -1;
			if (left.DodicallId > right.DodicallId)
				return 1;
			return 0;
		}
		return -1;
	}
	else if (!right.DodicallId.empty())
		return 1;
	if (!left.NativeId.empty())
	{
		if (!right.NativeId.empty())
		{
			if (left.NativeId < right.NativeId)
				return -1;
			if (left.NativeId > right.NativeId)
				return 1;
			return 0;
		}
		return -1;
	}
	else if (!right.NativeId.empty())
		return 1;
	if (!left.PhonebookId.empty())
	{
		if (!right.PhonebookId.empty())
		{
			if (left.PhonebookId < right.PhonebookId)
				return -1;
			if (left.PhonebookId > right.PhonebookId)
				return 1;
			return 0;
		}
		return -1;
	}
	else if (!right.PhonebookId.empty())
		return 1;

	bool sameFio = (!left.FirstName.empty() && left.FirstName == right.FirstName &&
		!left.LastName.empty() && left.LastName == right.LastName &&
		((left.MiddleName.empty() && right.MiddleName.empty()) || left.MiddleName == right.MiddleName));

	int leftPhoneCnt = 0;
	int rightPhoneCnt = 0;
	int samePhoneCnt = 0;
	for (ContactsContactSet::const_iterator liter = left.Contacts.begin(); liter != left.Contacts.end(); liter++)
	{
		if (liter->Type == ContactsContactPhone || liter->Type == ContactsContactSip)
			leftPhoneCnt++;
		for (ContactsContactSet::const_iterator riter = right.Contacts.begin(); riter != right.Contacts.end(); riter++)
		{
			if (liter == left.Contacts.begin() && riter->Type == ContactsContactPhone || riter->Type == ContactsContactSip)
				rightPhoneCnt++;
			if (liter->Type == riter->Type && liter->Identity == riter->Identity)
				samePhoneCnt++;
		}
	}
	bool samePhones = (leftPhoneCnt == rightPhoneCnt && rightPhoneCnt == samePhoneCnt);

	if (sameFio || samePhones)
		return 0;
	if (!left.FirstName.empty() && !right.FirstName.empty())
	{
		if (left.FirstName < right.FirstName)
			return -1;
		if (left.FirstName > right.FirstName)
			return 1;
	}
	if (!left.LastName.empty() && !right.LastName.empty())
	{
		if (left.LastName < right.LastName)
			return -1;
		if (left.LastName > right.LastName)
			return 1;
	}
	if (!left.MiddleName.empty() && !right.MiddleName.empty())
	{
		if (left.MiddleName < right.MiddleName)
			return -1;
		if (left.MiddleName > right.MiddleName)
			return 1;
	}
	
	if (leftPhoneCnt < rightPhoneCnt)
		return -1;
	if (leftPhoneCnt > rightPhoneCnt)
		return 1;
	
	for (ContactsContactSet::const_iterator liter = left.Contacts.begin(), riter = right.Contacts.begin(); liter != left.Contacts.end(); liter++, riter++)
	{
		const ContactsContactModel& lcontact = *liter;
		const ContactsContactModel& rcontact = *riter;
		if (lcontact.Type < rcontact.Type)
			return -1;
		if (lcontact.Type > rcontact.Type)
			return 1;
		if (lcontact.Identity < rcontact.Identity)
			return -1;
		if (lcontact.Identity > rcontact.Identity)
			return 1;
	}
	return 0;
}

bool operator == (const ContactModel& left, const ContactModel& right)
{
	return (compare(left,right) == 0);
}
bool operator != (const ContactModel& left, const ContactModel& right)
{
	return (compare(left,right) != 0);
}
bool operator < (const ContactModel& left, const ContactModel& right)
{
	return (compare(left,right) < 0);
}

int compare(const ContactsContactModel& left, const ContactsContactModel& right)
{
	if (left.Type < right.Type)
		return -1;
	else if (left.Type > right.Type)
		return 1;
	if (left.Identity < right.Identity)
		return -1;
	if (left.Identity > right.Identity)
		return 1;
	return 0;
}

bool operator == (const ContactsContactModel& left, const ContactsContactModel& right)
{
	return (compare(left,right) == 0);
}
bool operator != (const ContactsContactModel& left, const ContactsContactModel& right)
{
	return (compare(left,right) != 0);
}
bool operator < (const ContactsContactModel& left, const ContactsContactModel& right)
{
	return (compare(left,right) < 0);
}

bool equals(const ContactsContactSet& left, const ContactsContactSet& right)
{
	for (auto iter = left.begin(); iter != left.end(); iter++)
		if (right.find(*iter) == right.end())
			return false;
	return (left.size() == right.size());
}

bool equals(const ContactModel& left, const ContactModel& right)
{
	return (left.Blocked == right.Blocked && left.DodicallId == right.DodicallId  && left.CompanyId == right.CompanyId
		&& left.FirstName == right.FirstName && left.Iam == right.Iam && left.LastName == right.LastName && left.MiddleName == right.MiddleName
		&& left.NativeId == right.NativeId && left.PhonebookId == right.PhonebookId && left.White == right.White  
		&& equals(left.Contacts, right.Contacts));
}


}
}
