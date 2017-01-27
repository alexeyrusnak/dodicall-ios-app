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

#include "ContactSubscriptionModel.h"
#include "DateTimeUtils.h"

namespace dodicall
{
namespace dbmodel
{

typedef long ContactIdType;

typedef std::string ContactDodicallIdType;
typedef std::set<ContactDodicallIdType> ContactDodicallIdSet;

typedef std::string PhonebookIdType;

typedef std::string NativeIdType;
    
typedef std::string CompanyIdType;
typedef std::set<CompanyIdType> CompanyIdsSet;

enum ContactsContactType
{
	ContactsContactSip = 1,
	ContactsContactXmpp,
	ContactsContactPhone
};

class DODICALLLOGICAPI ContactsContactModel
{
public:
	ContactsContactType Type;
	std::string Identity;
	bool Favourite;
	bool Manual;

	ContactsContactModel(const std::string& identity = "", ContactsContactType type = ContactsContactSip);

	friend DODICALLLOGICAPI bool operator == (const ContactsContactModel& left, const ContactsContactModel& right);
	friend DODICALLLOGICAPI bool operator != (const ContactsContactModel& left, const ContactsContactModel& right);
	friend DODICALLLOGICAPI bool operator < (const ContactsContactModel& left, const ContactsContactModel& right);
};

typedef std::set<ContactsContactModel> ContactsContactSet;
    
class DODICALLLOGICAPI ContactModel
{
public:
	ContactIdType Id;
	ContactDodicallIdType DodicallId;
	PhonebookIdType PhonebookId;
	NativeIdType NativeId;
    CompanyIdType CompanyId;
	
	std::string FirstName;
	std::string LastName;
	std::string MiddleName;
    std::string AvatarPath;
	
	bool Blocked;
	bool White;

	ContactsContactSet Contacts;

	model::ContactSubscriptionModel Subscription;

	bool Iam;

	bool Deleted;

	// Internal fields, not needed in bridges
	bool Synchronized;
    
    DateType LastModifiedDate;

	ContactModel(void);
	ContactModel(const ContactModel& from);
	virtual ~ContactModel(void);

	model::ContactXmppIdType GetXmppId(void) const;

	operator bool(void) const
	{
		return (this->Id || !this->PhonebookId.empty() || !this->DodicallId.empty() || !this->NativeId.empty());
	}

	friend DODICALLLOGICAPI bool operator == (const ContactModel& left, const ContactModel& right);
	friend DODICALLLOGICAPI bool operator != (const ContactModel& left, const ContactModel& right);
	friend DODICALLLOGICAPI bool operator < (const ContactModel& left, const ContactModel& right);
	
	friend bool equals(const ContactModel& left, const ContactModel& right);
};
int compare(const ContactModel& left, const ContactModel& right);

typedef std::set<ContactModel> ContactModelSet;



inline std::string ContactsContactTypeToString(ContactsContactType type)
{
	std::string result;
	switch (type)
	{
	case ContactsContactSip:
		result = "sip";
		break;
	case ContactsContactXmpp:
		result = "xmpp";
		break;
	case ContactsContactPhone:
		result = "phone";
		break;
	default:
		// TODO: log warning
		break;
	}
	return result;
}
inline ContactsContactType StringToContactsContactType(std::string type)
{
	ContactsContactType result;
	if (type == "sip")
		result = ContactsContactSip;
	else if (type == "xmpp")
		result = ContactsContactXmpp;
	else if (type == "phone")
		result = ContactsContactPhone;
	else
	{
		// TODO: log warning
	}
	return result;
}
    
}
}
