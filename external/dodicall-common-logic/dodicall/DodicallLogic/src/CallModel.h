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

#include "ContactModel.h"
#include "DeviceSettingsModel.h"

namespace dodicall
{
namespace model
{

enum CallDirection
{
	CallDirectionOutgoing = 0,
	CallDirectionIncoming
};

enum CallState
{
	CallStateInitialized = 0,
	CallStateDialing,
	CallStateRinging,
	CallStateConversation,
	CallStateEarlyMedia,
	CallStatePaused,
	CallStateEnded
};

enum CallAddressType
{
	CallAddressPhone,
	CallAddressDodicall
};

typedef std::string CallIdType;
typedef std::set<CallIdType> CallIdSet;

class DODICALLLOGICAPI PeerModel
{
public:
	CallAddressType AddressType;
	std::string Identity;
	boost::optional<dbmodel::ContactModel> Contact;

	std::string GetId() const;
	bool FromStringPartial(std::string peerString);
};

bool operator < (const PeerModel& left, const PeerModel& right);

class DODICALLLOGICAPI CallModel : public PeerModel
{
public:
	CallIdType Id;
	CallDirection Direction;
	VoipEncryptionType Encription;
	CallState State;
	int Duration;		//seconds since connect

	// internal fields, not needed in bridge
	CallIdType SipId;

	CallModel(const char* id = 0);
	~CallModel(void);
};

inline bool operator < (const CallModel& c1, const CallModel& c2)
{
	return c1.Id < c2.Id;
}

typedef std::set<CallModel> CallModelSet;

}	//namespace dodicall::model

}	//namespace dodicall
