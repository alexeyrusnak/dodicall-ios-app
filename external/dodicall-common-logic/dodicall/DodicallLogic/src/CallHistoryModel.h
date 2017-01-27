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
#include "CallModel.h"

namespace dodicall
{
namespace dbmodel
{

//using model::PeerModel;
//using model::CallDirection;
//using model::VoipEncryptionType;


enum HistorySourceType 
{
	HistorySourcePhoneBook = 0x1,
	HistorySourceOthers = 0x2,
	HistorySourceAny = HistorySourcePhoneBook + HistorySourceOthers
};
enum HistoryStatusType 
{
	HistoryStatusSuccess = 0x10,
	HistoryStatusAborted = 0x20,
	HistoryStatusMissed = 0x40,
	HistoryStatusDeclined = 0x80,
	HistoryStatusAny = HistoryStatusSuccess + HistoryStatusAborted + HistoryStatusMissed + HistoryStatusDeclined
};
enum HistoryAddressType 
{
	HistoryAddressTypePhone = 0x1000,
	HistoryAddressTypeSip11 = 0x2000,
	HistoryAddressTypeSip4 = 0x4000,
	HistoryAddressTypeAny = HistoryAddressTypePhone + HistoryAddressTypeSip11 + HistoryAddressTypeSip4
};

// TODO: убрать в пользу VoipEncryptionType?
enum HistoryEncryption 
{
	HistoryEncryptionNone = 0x100000,
	HistoryEncryptionSrtp = 0x200000,
	HistoryEncryptionAny = HistoryEncryptionNone + HistoryEncryptionSrtp
};

enum HistoryFilterSelector
{
	HistoryFilterAny = HistorySourceAny + HistoryStatusAny + HistoryAddressTypeAny + HistoryEncryptionAny
};
HistoryFilterSelector MakeHistoryFilter(HistorySourceType, HistoryStatusType, HistoryAddressType, HistoryEncryption);

enum CallEndMode
{
	CallEndModeNormal,
	CallEndModeCancel
};

class DODICALLLOGICAPI CallDbModel : public model::CallModel
{
public:
	CallEndMode	EndMode;
	DateType StartTime;
	HistoryStatusType HistoryStatus;
	bool Readed;

	CallDbModel() : Readed(false) {}

	HistoryStatusType GetHistoryStatus() const;
	HistoryAddressType GetHistoryAddressType() const;
	HistoryEncryption GetHistoryEncryption() const;
	HistorySourceType GetHistorySource() const;
};

typedef std::vector<CallDbModel> CallDbModelList;

typedef std::string CallHistoryPeerIdType;	// model::PeerModel can be implicitely converted to CallHistoryPeerIdType

class DODICALLLOGICAPI HistoryFilterModel
{
public:
	HistoryFilterSelector Selector;
	boost::optional<DateType> FromTime;
	boost::optional<DateType> ToTime;
	std::vector<CallHistoryPeerIdType>	Peers;

	HistoryFilterModel(HistoryFilterSelector = HistoryFilterAny);
};

class DODICALLLOGICAPI CallHistoryEntryModel
{
public:
	model::CallDirection Direction;
	model::VoipEncryptionType Encription;
	int DurationSec;
	CallEndMode	EndMode;
	DateType StartTime;
	HistoryStatusType HistoryStatus;
	HistoryAddressType AddressType;
	HistorySourceType HistorySource;
	model::CallIdType Id;					// Unique. Do use as param to call ApplicationVoipApi::SetCallHistoryEntryReaded(id)

	HistoryStatusType GetHistoryStatus() const;
	HistoryAddressType GetHistoryAddressType() const;
	HistoryEncryption GetHistoryEncryption() const;
	HistorySourceType GetHistorySource() const;
};

class DODICALLLOGICAPI CallStatisticsModel
{
public:
	int NumberOfIncomingSuccessfulCalls;
	int NumberOfOutgoingSuccessfulCalls;
	int NumberOfIncomingUnsuccessfulCalls;
	int NumberOfOutgoingUnsuccessfulCalls;
	int NumberOfMissedCalls;
	bool HasOutgoingEncryptedCall : 1;
	bool HasIncomingEncryptedCall : 1;
	bool WasConference : 1;

	CallStatisticsModel();
	void Add(const CallDbModel&, bool);
	void Add(const CallStatisticsModel&);
};
typedef std::vector<CallHistoryEntryModel> CallHistoryEntryList;

class DODICALLLOGICAPI CallHistoryPeerModel : public model::PeerModel
{
public:
	CallStatisticsModel Statistics;
	CallHistoryEntryList DetailsList;

	CallHistoryPeerModel(const model::PeerModel& base) : model::PeerModel(base) {}
	CallHistoryPeerModel() : model::PeerModel() {}
};

typedef std::vector<CallHistoryPeerModel> CallHistoryPeerList;

class DODICALLLOGICAPI CallHistoryModel
{
public:
	CallHistoryPeerList Peers;
	int TotalMissed;

	CallHistoryModel(): TotalMissed(0) {}
};

CallHistoryEntryModel MakeFrom(const CallDbModel&);

}	//namespace dodicall::dbmodel

}	//namespace dodicall
