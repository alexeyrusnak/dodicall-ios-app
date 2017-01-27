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
#include "CallHistoryModel.h"

namespace dodicall
{
namespace dbmodel
{

using namespace model;

HistoryFilterSelector MakeHistoryFilter(HistorySourceType src, HistoryStatusType status, HistoryAddressType addr, HistoryEncryption encr)
{
	// TODO: static_assert
	assert(!(src & ~HistorySourceAny));
	assert(!(status & ~HistoryStatusAny));
	assert(!(addr & ~HistoryAddressTypeAny));
	assert(!(encr & ~HistoryEncryptionAny));
	return static_cast<HistoryFilterSelector>(src + status + addr + encr);
}

HistoryFilterModel::HistoryFilterModel(HistoryFilterSelector sel) : Selector(sel)
{
	#pragma message("TODO HistoryFilterModel(DateTime initialisers)")
}

inline HistoryEncryption VoipToHistoryEncryption(VoipEncryptionType encription)
{
	HistoryEncryption result = HistoryEncryptionNone;
	switch (encription)
	{
	case VoipEncryptionNone:
		result = HistoryEncryptionNone;
		break;
	case VoipEncryptionSrtp:
		result = HistoryEncryptionSrtp;
		break;
	default:
		// TODO: log warning
		break;
	}
	return result;
}

HistoryStatusType CallDbModel::GetHistoryStatus() const
{
	return HistoryStatus;
}

HistoryAddressType CallDbModel::GetHistoryAddressType() const
{
	using namespace dodicall::model;
	HistoryAddressType result = HistoryAddressTypePhone;
	switch (AddressType)
	{
	case CallAddressPhone:
		result = HistoryAddressTypePhone;
		break;
	case CallAddressDodicall:
		switch (Identity.find('@'))
		{
		case 4:
			result = HistoryAddressTypeSip4;
			break;
		case 11:
			result = HistoryAddressTypeSip11;
			break;
		default:
//			assert(!("unable to resolve HistoryAddressType for (CallAddressDodicall) " + Identity).c_str());
			break;
		}
		break;
	default:
		assert(!("unexpected addressType value " + std::to_string(AddressType)).c_str());
		break;
	}
	return result;
}


HistoryEncryption CallDbModel::GetHistoryEncryption() const
{
	return VoipToHistoryEncryption(Encription);
}

HistorySourceType CallDbModel::GetHistorySource() const
{
	return Contact && !Contact->PhonebookId.empty() ? HistorySourcePhoneBook : HistorySourceOthers;
}

HistoryStatusType CallHistoryEntryModel::GetHistoryStatus() const
{
	return HistoryStatus;
}

HistoryAddressType CallHistoryEntryModel::GetHistoryAddressType() const
{
	return AddressType;
}
HistoryEncryption CallHistoryEntryModel::GetHistoryEncryption() const
{
	return dbmodel::VoipToHistoryEncryption(Encription);
}

HistorySourceType CallHistoryEntryModel::GetHistorySource() const
{
	return HistorySource;
}

CallHistoryEntryModel MakeFrom(const CallDbModel& dbModel)
{
	CallHistoryEntryModel ret = {
		dbModel.Direction,
		dbModel.Encription,
		dbModel.Duration,
		dbModel.EndMode,
		dbModel.StartTime,
		dbModel.HistoryStatus,
		dbModel.GetHistoryAddressType(),
		dbModel.GetHistorySource(),
		dbModel.Id
		//,2 //paranoic check - uncmment -> it should be compile error 
	};
	return ret;
}

CallStatisticsModel::CallStatisticsModel()
	: NumberOfIncomingSuccessfulCalls(0)
	, NumberOfOutgoingSuccessfulCalls(0)
	, NumberOfIncomingUnsuccessfulCalls(0), NumberOfMissedCalls(0)
	, NumberOfOutgoingUnsuccessfulCalls(0)
	, HasOutgoingEncryptedCall(false)
	, HasIncomingEncryptedCall(false)
	, WasConference(false)
{
}

void CallStatisticsModel::Add(const CallDbModel& call, bool doCountMissed)
{
	const bool encrypted = call.Encription != model::VoipEncryptionNone;
	assert(unsigned(call.Direction) < 2);
	assert(unsigned(call.EndMode) < 2);
	switch (call.Direction + (call.EndMode << 1))
	{
	case 0: //CallDirectionOutgoing,  CallEndModeNormal
		NumberOfOutgoingSuccessfulCalls++;
		if (encrypted)
		{
			HasOutgoingEncryptedCall = true;
		}
		break;
	case 1: //CallDirectionIngoing,  CallEndModeNormal
		NumberOfIncomingSuccessfulCalls++;
		if (encrypted)
		{
			HasIncomingEncryptedCall = true;
		}
		break;
	case 2: //CallDirectionOutgoing,  CallEndModeCancel
		NumberOfOutgoingUnsuccessfulCalls++;
		break;
	case 3: //CallDirectionIngoing,  CallEndModeCancel
		NumberOfIncomingUnsuccessfulCalls++;
		break;
	default:
		assert(!"it's impossible");
		break;
	}
	if (doCountMissed && !call.Readed && call.HistoryStatus == HistoryStatusMissed)
	{
		NumberOfMissedCalls++;
	}
	if (call.EndMode == CallEndModeNormal) {
		#pragma message("TODO: CallStatisticsModel::WasConference")
	}
}

void CallStatisticsModel::Add(const CallStatisticsModel& s)
{
	NumberOfIncomingSuccessfulCalls += s.NumberOfIncomingSuccessfulCalls;
	NumberOfOutgoingSuccessfulCalls += s.NumberOfOutgoingSuccessfulCalls;
	NumberOfIncomingUnsuccessfulCalls += s.NumberOfIncomingUnsuccessfulCalls;
	NumberOfOutgoingUnsuccessfulCalls += s.NumberOfOutgoingUnsuccessfulCalls;
	NumberOfMissedCalls += s.NumberOfMissedCalls;
	HasOutgoingEncryptedCall = HasOutgoingEncryptedCall || s.HasOutgoingEncryptedCall;
	HasIncomingEncryptedCall = HasIncomingEncryptedCall || s.HasIncomingEncryptedCall;
	WasConference = WasConference || s.WasConference;
}

}
}
/*
void TEstIsCallHistoryPeerIdsSame()
{
	dodicall::dbmodel::CallHistoryPeerIdType left  = "31,38b153e3-3dc5-49c9-880b-41bc4d7ad61f,,,1,00070207591@spb.swisstok.ru";
	dodicall::dbmodel::CallHistoryPeerIdType right = "31,38b153e3-3dc5-49c9-880b-41bc4d7ad61f,,,1,00070207591@spb.swisstok.ru";
	int result = dodicall::dbmodel::IsCallHistoryPeerIdsSame(left, right);
	left = "0,38b153e3-3dc5-49c9-880b-41bc4d7ad61f,,,1,00070207591@spb.swisstok.ru";
	right = "31,38b153e3-3dc5-49c9-880b-41bc4d7ad61f,,,1,00070207591@spb.swisstok.ru";
	result = dodicall::dbmodel::IsCallHistoryPeerIdsSame(left, right);
	result = 0;
}
*/