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

#include "stdafx.h"

namespace dodicall
{
namespace model
{

typedef std::string ContactXmppIdType;
typedef std::set<ContactXmppIdType> ContactXmppIdSet;

enum ContactSubscriptionState
{
	ContactSubscriptionStateNone = 0,
	ContactSubscriptionStateFrom,
	ContactSubscriptionStateTo,
	ContactSubscriptionStateBoth
};

enum ContactSubscriptionStatus
{
	ContactSubscriptionStatusNew = 0,
	ContactSubscriptionStatusReaded,
	ContactSubscriptionStatusConfirmed
};

class ContactSubscriptionModel
{
public:
	ContactSubscriptionState SubscriptionState;
	bool AskForSubscription;
	ContactSubscriptionStatus SubscriptionStatus;

	ContactSubscriptionModel(ContactSubscriptionState state = ContactSubscriptionStateNone, bool ask = false, ContactSubscriptionStatus status = ContactSubscriptionStatusReaded);
	ContactSubscriptionModel(const ContactSubscriptionModel& from);
	~ContactSubscriptionModel(void);

	bool IsFromEnabled(void) const;
	bool IsToEnabled(void) const;
};


typedef std::map<ContactXmppIdType,ContactSubscriptionModel> ContactSubscriptionMap;

template <class T> T& operator << (T& stream, const ContactSubscriptionModel &result)
{
	stream << "{ SubscriptionState = " << (int)result.SubscriptionState << ", AskForSubscription = " << result.AskForSubscription << ", SubscriptionStatus = " << (int)result.SubscriptionStatus << " }";
	return stream;
}

}
}
