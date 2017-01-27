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
#include "ContactSubscriptionModel.h"

namespace dodicall
{
namespace model
{

ContactSubscriptionModel::ContactSubscriptionModel(ContactSubscriptionState state, bool ask, ContactSubscriptionStatus status):
	SubscriptionState(state), AskForSubscription(ask), SubscriptionStatus(status)
{
}
ContactSubscriptionModel::ContactSubscriptionModel(const ContactSubscriptionModel& from):
	SubscriptionState(from.SubscriptionState), AskForSubscription(from.AskForSubscription), SubscriptionStatus(from.SubscriptionStatus)
{
}
ContactSubscriptionModel::~ContactSubscriptionModel(void)
{
}

bool ContactSubscriptionModel::IsFromEnabled(void) const
{
	return (this->SubscriptionState == ContactSubscriptionStateFrom || this->SubscriptionState == ContactSubscriptionStateBoth);
}
bool ContactSubscriptionModel::IsToEnabled(void) const
{
	return (this->SubscriptionState == ContactSubscriptionStateTo || this->SubscriptionState == ContactSubscriptionStateBoth);
}

}
}