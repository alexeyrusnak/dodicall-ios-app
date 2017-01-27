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
#include "ApplicationVoipApi.h"

#include "GlobalApplicationSettingsModel.h"
#include "LogManager.h"
#include "DateTimeUtils.h"
#include "StringUtils.h"

#include <linphone/linphonecore.h>
#include <linphone/linphonecore_utils.h>
#include <linphone/lpconfig.h>

//#define DENY_VIRTUALS

#define VIRTUAL_CALL_MAX_DURATION 45
#define VIRTUAL_RECALL_TIMEOUT 5
#define VIRTUAL_CALL_RINGING_MIN_DURATION 1
#define DTMF_SEND_PERIOD_MS 150
#define DTMF_PLAY_DURATION_MS 100
#define DTMF_PLAY_FOREVER -3000			// -3000 do not change! DMC-2578


#define DEBUG_SHOW_NUMBERS_IN_LOGS(x) DEBUG_ONLY_CODE(x)
#define DEBUG_ASSERT_ON_PATCHES(x)  //DEBUG_ONLY_CODE(x)

namespace dodicall
{

using namespace dbmodel;
using namespace MiscUtils;

static model::CallState LinphoneCallStateToModel(LinphoneCallState state);

class DodicallLinphoneAddress
{
	LinphoneAddress* mPAIAddress;
	LinphoneCall* const mCall;
public:
	DodicallLinphoneAddress(LinphoneCall *call);
	~DodicallLinphoneAddress();
	operator const LinphoneAddress* () const;
	void Dump(const LinphoneAddress* = 0, dodicall::LoggerStream* = 0) const;
};

DodicallLinphoneAddress::DodicallLinphoneAddress(LinphoneCall *call): mPAIAddress(0), mCall(call)
{
	assert(mCall);
	if (const LinphoneCallParams* remote = linphone_call_get_remote_params(mCall))
	{
		if (const char* pAIHeader = linphone_call_params_get_custom_header(remote, "P-Asserted-Identity"))
		{
			std::string s(pAIHeader);
			size_t n = s.find(";user");
			if (n != std::string::npos)
				s.resize(n);
			n = s.find("sip:");
			if (n != std::string::npos)
				s = s.substr(n);
			mPAIAddress = linphone_address_new(s.c_str());
		}
	}
}

DodicallLinphoneAddress::~DodicallLinphoneAddress()
{
	if (mPAIAddress) linphone_address_destroy(mPAIAddress);
}

DodicallLinphoneAddress::operator const LinphoneAddress* () const
{
	return mPAIAddress ? mPAIAddress : linphone_call_get_remote_address(mCall);
}

#define linphone_call_get_remote_address Use_DodicallLinphoneAddress_instead_of___linphone_call_get_remote_address

ApplicationVoipApi::CallUserData::CallUserData(const ContactModel& contact, const CallIdType& virtualId, const bool shouldSendPushAboutMissedCall):
	Contact(contact), VirtualId(virtualId), ShouldSendPushAboutMissedCall(shouldSendPushAboutMissedCall)
{
}

ApplicationVoipApi::VirtualCall::VirtualCall(const ContactModel& contact, const ContactsContactModel& identity):
	Contact(contact), Identity(identity),
	VirtualId(boost::lexical_cast<std::string>(boost::uuids::random_generator()())),
	StartCallTime(posix_time_now()), LastRealCallTime(time_t_to_posix_time(0)),
	RingingStartTime(time_t_to_posix_time(0))
{
}

ApplicationVoipApi::ApplicationVoipApi(void): mLc(0),
	mIterateControlTime(posix_time_now()),
	mIterateLastTime(posix_time_now()),
	mIterateCounter(0),
	mDelayedNotificationTime(time_t_to_posix_time(0)),
	WaitingForErrorTone(false),
	mCallsNotifyer([this](const std::set<std::string>& ids)
	{
		this->DoCallback("Calls",ids);
	}, 200),
	mCallHistoryNotifyer([this](const std::set<std::string>& ids)
	{
		this->DoCallback("History",ids);
	}, 500),
	mCallContactsRetriever([this](const std::set<std::string>& ids)
	{
		for (auto iter = ids.begin(); iter != ids.end(); iter++)
			this->RetrieveCallContactAndNotify(*iter);
	}, 0)
{
}
ApplicationVoipApi::~ApplicationVoipApi(void)
{
}

bool ApplicationVoipApi::Prepare(void)
{
	if (this->mLc)
		return true;

	boost::lock_guard<boost::recursive_mutex> _lock(this->mMutex);

	LinphoneCoreVTable vtable = { 0 };
	vtable.registration_state_changed = LinphoneOnRegistrationChanged;
	vtable.call_state_changed = LinphoneOnCallStateChanged;
	vtable.call_stats_updated = LinphoneOnCallStatisticsUpdated;
	vtable.call_encryption_changed = LinphoneOnCallEncryptionStateChanged;
	vtable.notify_received = LinphoneOnNotificationReceived;
	vtable.speaker_on = LinphoneOnSpeakerOn;

	/* It has to be called before linphone_core_new because there can be some log calls */
	linphone_core_enable_logs_with_cb(LinphoneOnLog);

	this->mLc = linphone_core_new(&vtable, NULL, (this->mDeviceModel.ApplicationDataPath / "linphone.config").string().c_str(), NULL);
	if (this->mLc)
	{
		linphone_core_enable_adaptive_rate_control(this->mLc, TRUE);
		this->SetupAudio();
		this->SetupVideo();

		linphone_core_set_ring(this->mLc, (this->mDeviceModel.ApplicationDataPath / "sounds" / "incoming_call.wav").string().c_str());
		linphone_core_set_ringback(this->mLc, (this->mDeviceModel.ApplicationDataPath / "sounds" / "ringback.wav").string().c_str());
		linphone_core_set_play_file(this->mLc, (this->mDeviceModel.ApplicationDataPath / "sounds" / "hold.wav").string().c_str());

		std::string certFileName = (this->mServerArea == 0) ? "server.pem" : "test.pem";
		linphone_core_set_root_ca(this->mLc, (this->mDeviceModel.ApplicationDataPath / "cert" / certFileName).string().c_str());

		linphone_core_verify_server_certificates(this->mLc, TRUE);
		// TODO: enable later!
		linphone_core_verify_server_cn(this->mLc, FALSE);

		linphone_core_set_zrtp_secrets_file(this->mLc, (this->mDeviceModel.UserDataPath / "zrtp_secrets").string().c_str());

		linphone_core_set_user_data(this->mLc, (void*)this);

		// TODO: think about this
#if TARGET_OS_IPHONE
		linphone_core_set_playback_device(this->mLc, "AU: Audio Unit Receiver");
		linphone_core_set_ringer_device(this->mLc, "AQ: Audio Queue Device");
		linphone_core_set_capture_device(this->mLc, "AU: Audio Unit Receiver");

		//In iOS we need own keepalive settings
		linphone_core_enable_keep_alive_with_period(this->mLc, TRUE, 1, 10000);

#endif
		linphone_core_start_dtmf_stream(this->mLc);

		ApplyVoipSettings(GetUserSettings());

		this->LinphoneOnSpeakerOn(this->mLc, TRUE);

		return true;
	}
	return false;
}

void ApplicationVoipApi::Start(void)
{
	boost::lock_guard<boost::recursive_mutex> _lock(this->mMutex);
	if (this->mLc)
	{
		this->EnableCodecs();
		this->RegisterAccounts();

		this->mThreadsOnlyThenLoggedIn.StartThread([this]
		{
			while (this->Iterate())
				boost::this_thread::sleep(boost::posix_time::millisec(20));
		});
		this->mThreadsOnlyThenLoggedIn.StartThread([this]
		{
			static_assert(DTMF_SEND_PERIOD_MS > DTMF_PLAY_DURATION_MS + 20, "addjust DTMF_SEND_PERIOD_MS and DTMF_PLAY_DURATION_MS to valid values");
			while (this->DtmfIterate())
				boost::this_thread::sleep(boost::posix_time::millisec(DTMF_SEND_PERIOD_MS));
		});
	}
}

void ApplicationVoipApi::Stop(void)
{
	LogManager::GetInstance().TraceLogger(LogLevelDebug) << "ApplicationVoipApi Stop start";
    boost::lock_guard<boost::recursive_mutex> _lock(this->mMutex);
	if (this->mLc)
	{
		linphone_core_terminate_all_calls(this->mLc);

		const MSList *elem;
		LinphoneProxyConfig *pc;
		for (elem=linphone_core_get_proxy_config_list(this->mLc);elem!=NULL;elem=elem->next)
		{
			pc=(LinphoneProxyConfig*)elem->data;

			linphone_proxy_config_edit(pc);
			linphone_proxy_config_enable_register(pc, FALSE);
			linphone_proxy_config_done(pc);
		}
		linphone_core_refresh_registers(this->mLc);

		linphone_core_destroy(this->mLc);
		this->mLc = 0;
	}
	this->mCallsNotifyer.Cancel();
	this->mCallHistoryNotifyer.Cancel();
	this->mCallContactsRetriever.Cancel();
    
    LogManager::GetInstance().TraceLogger(LogLevelDebug) << "ApplicationVoipApi Stop finished";
}

void ApplicationVoipApi::Pause(void)
{
#if TARGET_OS_IPHONE
	boost::lock_guard<boost::recursive_mutex> _lock(this->mMutex);
	if (this->mLc)
	{
		linphone_core_enable_keep_alive_with_period(this->mLc, FALSE, 1, 10000);

		this->RefreshRegistration();

		for (int i = 0; i < 40; i++)
		{
			bool isOk = true;
			for (const MSList* elem = linphone_core_get_proxy_config_list(this->mLc); elem != NULL; elem = elem->next)
			{
				LinphoneRegistrationState state = linphone_proxy_config_get_state((LinphoneProxyConfig*)elem->data);
				if (state == LinphoneRegistrationFailed || state == LinphoneRegistrationNone)
					isOk = false;
			}
			if (isOk)
				break;
			boost::this_thread::sleep(boost::posix_time::milliseconds(100));
		}

		linphone_core_stop_dtmf_stream(this->mLc); //На айфоне тоны начинают тормозить
	}
#endif
}

void ApplicationVoipApi::Resume(void)
{
#if TARGET_OS_IPHONE
	boost::lock_guard<boost::recursive_mutex> _lock(this->mMutex);
	if (this->mLc)
	{
		linphone_core_enable_keep_alive_with_period(this->mLc, TRUE, 1, 10000);

		this->RefreshRegistration();

		linphone_core_start_dtmf_stream(this->mLc);

		LinphoneCall *currentCall = linphone_core_get_current_call(this->mLc);
		if (currentCall && linphone_call_get_state(currentCall) == LinphoneCallIncoming)
		{
			linphone_core_restore_ring(this->mLc);
		}

		// TODO: resumeCurrentPausedCall
	}
#endif
    
    
    this->LoadMissedCallsFromServer();
    
}

void ApplicationVoipApi::TurnVoipSocket(bool on)
{
#if TARGET_OS_IPHONE
	if (this->mLc)
		linphone_core_set_voip_socket(this->mLc, (on?1:0));
	LogManager::GetInstance().TraceLogger(LogLevelDebug) << "Voip socket for sip is successfully " << (on ? "on" : "off");
#endif
}

void ApplicationVoipApi::EnableCodecs()
{
	boost::lock_guard<boost::recursive_mutex> _lock(this->mMutex);
	if (this->mLc)
	{
		CodecSettingsList settings = this->mDeviceSettings.SafeGet<CodecSettingsList>([](const DeviceSettingsModel& self) { return self.CodecSettings; });
		for (CodecSettingsList::const_iterator iter = settings.begin(); iter != settings.end(); iter++)
			this->EnableCodec(*iter);
	}
}

void ApplicationVoipApi::RefreshRegistration(void)
{
	boost::lock_guard<boost::recursive_mutex> _lock(this->mMutex);
	if (this->mLc)
		linphone_core_refresh_registers(this->mLc);
}

bool ApplicationVoipApi::RetrieveVoipAccounts(VoipAccountModelList& result) const
{
	boost::lock_guard<boost::recursive_mutex> _lock(this->mMutex);
	if (this->mLc)
	{
		const MSList* accountList = linphone_core_get_proxy_config_list(this->mLc);
		while(accountList)
		{
			const LinphoneProxyConfig* proxy = (const LinphoneProxyConfig*)accountList->data;
			VoipAccountModel account;
			account.Identity = std::string(linphone_proxy_config_get_identity(proxy));
			switch(linphone_proxy_config_get_state(proxy))
			{
			case LinphoneRegistrationNone:
			case LinphoneRegistrationCleared:
				account.State = VoipAccountRegistrationNone;
				break;
			case LinphoneRegistrationProgress:
				account.State = VoipAccountRegistrationInProgress;
				break;
			case LinphoneRegistrationOk:
				account.State = VoipAccountRegistrationOk;
				break;
			case LinphoneRegistrationFailed:
				account.State = VoipAccountRegistrationFailed;
				break;
			default:
				// TODO: log error
				break;
			}
			result.push_back(account);
			accountList = accountList->next;
		}
		return true;
	}
	return false;
}

bool ApplicationVoipApi::StartCallToContact(ContactModel contact, CallOptions options)
{
	this->UnifyContactPhones(contact);
	bool result = false;
	for (int n = 0; n < 2; n++)
	{
		const bool tryFavorites = (n == 0);
		for (ContactsContactSet::const_iterator iter = contact.Contacts.begin(); !result && iter != contact.Contacts.end(); ++iter)
		{
			if ((iter->Type == ContactsContactSip || iter->Type == ContactsContactPhone) && tryFavorites == iter->Favourite)
				result = (StartCallToContactUrlInternal(contact, *iter, options) != NULL);
		}
	}
	return result;
}

bool ApplicationVoipApi::StartCallToContactUrl(ContactModel contact, ContactsContactModel url, CallOptions options)
{
	this->UnifyContactPhones(contact);
	url = this->UnifyContactsContactPhone(url);
	bool result = (this->StartCallToContactUrlInternal(contact, url, options) != NULL);
	if (result)
		LogManager::GetInstance().TraceLogger(LogLevelDebug) << "Successfully start call to contact url " << url << " with options " << (int)options << " with contact " << contact;
	else
		LogManager::GetInstance().TraceLogger(LogLevelDebug) << "Failed start call to contact url " << url << " with options " << (int)options << " with contact " << contact;
	return result;
}
bool ApplicationVoipApi::StartCallToContactUrl(ContactModel contact, std::string url, CallOptions options)
{
	this->UnifyContactPhones(contact);
	url = this->UnFormatPhone(url);
	std::string pureUrl = CutDomain(url);
	if (pureUrl == url)
		pureUrl.clear();
	for (auto iter = contact.Contacts.begin(); iter != contact.Contacts.end(); iter++)
	{
		std::string pureIdentity = CutDomain(iter->Identity);
		if (iter->Identity == url || pureIdentity == url)
			return this->StartCallToContactUrl(contact, *iter, options);
		if (!pureUrl.empty() && pureUrl == pureIdentity)
			return this->StartCallToContactUrl(contact, *iter, options);
	}
	LogManager::GetInstance().TraceLogger(LogLevelDebug) << "Failed start call contact to url " << url << " with options " << (int)options << " and contact" << contact;
	return false;
}

bool ApplicationVoipApi::StartCallToUrl(std::string url, CallOptions options)
{
	url = this->UnFormatPhone(url);
	ContactModel contact = this->RetriveContactByNumberLocal(url, false);
	if (!contact && url.find_first_of('@') == url.npos)
		contact = this->RetriveContactByNumberLocal(url + '@' + this->mDeviceSettings.SafeGet<std::string>([](const DeviceSettingsModel& self) { return self.GetDefaultVoipSettings().Domain; }), false);
	LinphoneCallRefPtr call = NULL;
	if (bool(contact))
	{
		this->UnifyContactPhones(contact);
		ContactsContactModel contactsContact(url);
		for (auto iter = contact.Contacts.begin(); iter != contact.Contacts.end(); iter++)
		{
			if ((iter->Type == ContactsContactSip || iter->Type == ContactsContactPhone) && iter->Identity.find(url) == 0)
			{
				contactsContact = *iter;
				break;
			}
		}
		call = this->StartCallToContactUrlInternal(contact, contactsContact, options);
		if (contact.DodicallId.empty() && call)
			this->mCallContactsRetriever.Call(LinphoneCallToModel(*call).SipId);
	}
	else
	{
		call = this->StartCallToUrlInternal(url, options);
		if (call)
			this->mCallContactsRetriever.Call(LinphoneCallToModel(*call).SipId);
	}
	if ((bool)call)
		LogManager::GetInstance().TraceLogger(LogLevelDebug) << "Successfully start call to url " << url << " with options " << (int)options;
	else
		LogManager::GetInstance().TraceLogger(LogLevelDebug) << "Failed start call to url " << url << " with options " << (int)options;

	return (call != NULL);
}

bool ApplicationVoipApi::TransferCallToUrl(const CallIdType& callId, const std::string& url)
{
	Logger& logger = LogManager::GetInstance().TraceLogger;
	logger(LogLevelDebug) << "Start transfer call " << callId << " to " << url;

	boost::lock_guard<boost::recursive_mutex> _lock(this->mMutex);
	LinphoneCall *call = FindLinphoneCallById(this->mLc, callId);
	int result = -1;
	if (call)
	{
		result = linphone_core_transfer_call(this->mLc, call, this->UnFormatPhone(url).c_str());
		logger(LogLevelDebug) << "Transfer call " << callId << " to " << url << " with result " << result;
	}
	else
		logger(LogLevelError) << "Failed transfer call " << callId << " to " << url;
	return !result;
}

bool ApplicationVoipApi::TransferCall(const CallIdType& callId, const CallIdType& destId)
{
	boost::lock_guard<boost::recursive_mutex> _lock(this->mMutex);
	LinphoneCall* call(FindLinphoneCallById(this->mLc, callId));
	LinphoneCall* dest(FindLinphoneCallById(this->mLc, destId));
	const bool result = call && dest;
	if (result)
	{
		linphone_core_transfer_call_to_another(this->mLc, call, dest);
	}
	return result;
}

LoggerStream operator << (LoggerStream s, const HistoryFilterModel& filter)
{
	s << "{ Selector = " << filter.Selector << ", ";
	if ((bool)filter.FromTime)
		s << " FromTime = " << filter.FromTime << ", ";
	if ((bool)filter.ToTime)
		s << " ToTime = " << filter.ToTime << ", ";
	return s << filter.Peers << " }";
}

LoggerStream operator << (LoggerStream s, const CallHistoryModel& callHistory)
{
	return (s << "{ TotalMissedCalls = " << callHistory.TotalMissed << ", " << callHistory.Peers << " }");
}

LoggerStream operator << (LoggerStream s, const CallHistoryPeerModel& historyRecord)
{
	return (s << "{ Id = " << historyRecord.GetId() << ", Count = " << historyRecord.DetailsList.size() << " }");
}

bool ApplicationVoipApi::GetCallHistory(CallHistoryModel& result, const HistoryFilterModel& filter, bool loadHistory)
{
	Logger& logger = LogManager::GetInstance().TraceLogger;
	logger(LogLevelDebug) << "Start getting call history with" << (loadHistory ? "" : "out") << " details and filter " << filter;

	CallDbModelList history;
	const bool ret = mUserDb.GetCallHistory(history);

	if (ret)
	{
		typedef std::map<PeerModel, size_t> IndexMap;
		IndexMap indexMap;
		for (auto iter = history.begin(); iter < history.end(); ++iter)
		{
			CallDbModel& call = *iter;
			if (!call.Contact)
			{
				ContactModel contact = this->RetriveContactByNumberInternal(call.Identity);
				if ((bool)contact)
					call.Contact = contact;
			}
			else if (!call.Contact->Id)
			{
				ContactModel contact;
				if (!call.Contact->DodicallId.empty())
					contact = this->RetriveContactByDodicallId(call.Contact->DodicallId);
//              delete because broken algo when save contact into Saved
//				else if (!call.Contact->PhonebookId.empty())
//					contact = this->GetContactByPhonebookId(call.Contact->PhonebookId);
				if (!contact)
					contact = this->RetriveContactByNumberInternal(call.Identity);
				if ((bool)contact)
					call.Contact = contact;
                else
                    call.Contact = boost::optional<ContactModel>();
			}

			if (this->ExamineHistoryFilter(filter,call))
			{
                call.Identity = this->FormatPhone(call.Identity);
                
				if (call.Contact)
				{
					this->QueryAvatarForPermanentContact(*call.Contact);
					this->PrepareRequestedContact(*call.Contact);
				}

				auto insertResult = indexMap.insert(IndexMap::value_type(call, result.Peers.size()));
				const size_t peerIndex = insertResult.first->second;

				if (insertResult.second)		// was really inserted
				{
					assert(peerIndex == result.Peers.size());					// invariant of remapContacts.insert() 2
					result.Peers.push_back(CallHistoryPeerModel(call));
				}
				else
				{
					assert(peerIndex < result.Peers.size());					// invariant of remapContacts.insert() 2
				}
				CallHistoryPeerModel& peer = result.Peers[peerIndex];
				peer.Statistics.Add(call, true);
				if (loadHistory || insertResult.second)
				{
					CallHistoryEntryModel entry = MakeFrom(call);
					peer.DetailsList.push_back(entry);
				}
			}
		}
		for (auto stat : result.Peers)
			result.TotalMissed += stat.Statistics.NumberOfMissedCalls;
	}
	logger(LogLevelDebug) << "End getting call history with result " << ret << LoggerStream::endl << result;
	DEBUG_ONLY_CODE(for (auto i : result.Peers) assert(i.DetailsList.size() > 0));
	return ret;
}

int ApplicationVoipApi::GetNumberOfMissedCalls(void) const
{
	return this->mUserDb.GetNumberOfMissedCalls();
}

bool ApplicationVoipApi::SetCallHistoryReaded(const HistoryFilterModel& filter)
{
	Logger& logger = LogManager::GetInstance().TraceLogger;
	logger(LogLevelDebug) << "Start setting call history readed";

	bool result = false;
	CallHistoryModel history;
	if (this->GetCallHistory(history, filter, true))
	{
		CallIdSet ids;
		for (auto piter = history.Peers.begin(); piter != history.Peers.end(); piter++)
			for (auto citer = piter->DetailsList.begin(); citer != piter->DetailsList.end(); citer++)
				ids.insert(citer->Id);
		result = this->mUserDb.SetCallHistoryEntriesReaded(ids);
	}
	logger(LogLevelDebug) << "End setting call history readed with result = " << result;
	return result;
}

bool ApplicationVoipApi::GetAllCalls(CallsModel& allCalls)
{
	assert(allCalls.SingleCalls.empty() && allCalls.Conference.Calls.empty());	//isn't it?
	boost::lock_guard<boost::recursive_mutex> _lock(this->mMutex);
	if (this->mLc)
	{
		StackVar<CallModelSet> singleCalls(allCalls.SingleCalls);
		StackVar<CallModelSet> conference(allCalls.Conference.Calls);
		for (const MSList *calls = linphone_core_get_calls(this->mLc); calls; calls = calls->next)
		{
			LinphoneCall* call = (LinphoneCall*)calls->data;
			CallModel model = LinphoneCallToModel(call);
			if (model.State != CallStateEnded)
			{
				model.Identity = this->FormatPhone(model.Identity);
				if (model.Contact && !model.Contact->DodicallId.empty())
					this->mAvatarDownloader.Call(model.Contact->DodicallId);
				if (linphone_call_is_in_conference(call))
				{
					// TODO: redesign conference
					conference.insert(model);
				}
				else
				{
					singleCalls.insert(model);
				}
			}
		}
		for (auto iter = this->mVirtualCalls.begin(); iter != this->mVirtualCalls.end(); iter++)
			if (iter->SipId.empty() || iter->SipId == "DUMMY")
			{
				CallModel model(iter->VirtualId.c_str());
				model.Direction = CallDirectionOutgoing;
				model.Encription = VoipEncryptionNone;
				model.State = CallStateDialing;
				model.AddressType = CallAddressDodicall;
				model.Identity = iter->Identity.Identity;
                ContactModel contact = iter->Contact;
				if (contact)
				{
					this->mAvatarDownloader.Call(contact.DodicallId);
					this->PrepareRequestedContact(contact);
					model.Contact = contact;
				}
				singleCalls.insert(model);
			}
		return true;
	}
	return false;
}

bool ApplicationVoipApi::AcceptCall(const CallIdType& callId, CallOptions options)
{
	boost::lock_guard<boost::recursive_mutex> _lock(this->mMutex);
	LinphoneCall* call(FindLinphoneCallById(this->mLc, callId));
	return call && 0 == linphone_core_accept_call(this->mLc, call);
}

bool ApplicationVoipApi::HangupCall(CallIdType callId)
{
	boost::lock_guard<boost::recursive_mutex> _lock(this->mMutex);
	bool result = false;
    
    bool notifyAboutMissedCall = false;
    std::string virtualCallId;
    std::string virtualCallIdentity;
    
	if (this->mLc)
	{
		ApplicationVoipApi::VirtualCall* pVirtualCall = this->FindVirtualById(callId);
		if (pVirtualCall)
        {
            virtualCallId = pVirtualCall->VirtualId;
			callId = pVirtualCall->SipId;
            virtualCallIdentity = pVirtualCall->Identity.Identity;
            notifyAboutMissedCall = true;
            
            this->StopVirtualCall(pVirtualCall);
        }

		LinphoneCall* call(FindLinphoneCallById(this->mLc, callId));
		if (call)
        {
			result = this->HangupCall(this->mLc, call);
            notifyAboutMissedCall = false;
        }
		else
			this->mCallsNotifyer.Call(callId);
        
        if(notifyAboutMissedCall)
            this->SendPushNotificationAboutMissedCall(virtualCallId, virtualCallIdentity);
	}
	return result;
}

bool ApplicationVoipApi::PauseCall(const CallIdType& callId) const
{
	return 0 == CallHelper(callId, linphone_core_pause_call);
}

bool ApplicationVoipApi::ResumeCall(const CallIdType& callId) const
{
	return 0 == CallHelper(callId, linphone_core_resume_call);
}

void ApplicationVoipApi::EnableMicrophone(bool enable) const
{
	boost::lock_guard<boost::recursive_mutex> _lock(this->mMutex);
	if (this->mLc)
		linphone_core_enable_mic(this->mLc, enable);
}

bool ApplicationVoipApi::IsMicrophoneEnabled() const
{
	boost::lock_guard<boost::recursive_mutex> _lock(this->mMutex);
	return this->mLc && linphone_core_mic_enabled(this->mLc);
}

bool ApplicationVoipApi::PlayDtmf(char number)
{
	boost::lock_guard<boost::recursive_mutex> _lock(this->mMutex);
	if (this->mLc)
	{
		if (this->YetActiveCalls(this->mLc, NULL, false))
			mDtmfDueue.push_back(number);
		else		
			linphone_core_play_dtmf(this->mLc, number, DTMF_PLAY_FOREVER);
			
        return true;
	}
	return false;
}

bool ApplicationVoipApi::StopDtmf(void)
{
	boost::lock_guard<boost::recursive_mutex> _lock(this->mMutex);
	if (this->mLc)
	{
		linphone_core_stop_dtmf(this->mLc);
		return true;
	}
	return false;
}

DeviceSettingsModel ApplicationVoipApi::GetDeviceSettings(void) const
{
	DeviceSettingsModel result = this->mDeviceSettings;
	for (ServerSettingsList::iterator iter = result.ServerSettings.begin(); iter != result.ServerSettings.end(); iter++)
		iter->Password = "";
	boost::lock_guard<boost::recursive_mutex> _lock(this->mMutex);
	if (this->mLc)
	{
		for (auto codecModel = result.CodecSettings.begin(); codecModel != result.CodecSettings.end(); )
		{
			const MSList* codec = 0;
			switch (codecModel->Type)
			{
			case CodecTypeAudio:
				codec = this->GetAvailableAudioCodecs(this->mLc);
				break;
			case CodecTypeVideo:
				codec = this->GetAvailableVideoCodecs(this->mLc);
				break;
			default:
				// TODO: log error
				break;
			}
			for( ; codec; codec = codec->next)
			{
				const PayloadType* pt = (const PayloadType*)codec->data;
				if (!strcasecmp(pt->mime_type, codecModel->Mime.c_str()) && (codecModel->Rate == 0 || pt->clock_rate == codecModel->Rate))
					break;
			}
			if (codec)	// found: codec == codecModel (mime & speed)
				++codecModel;
			else
				codecModel = result.CodecSettings.erase(codecModel);
		}
	}
	return result;
}

bool ApplicationVoipApi::GetSoundDevices(SoundDeviceModelSet& devices) const
{
	boost::lock_guard<boost::recursive_mutex> _lock(this->mMutex);
	const char** devList = 0;
	if (mLc)
	{
		linphone_core_reload_sound_devices(mLc);
		devList = linphone_core_get_sound_devices(mLc);

		const char * ringer  = linphone_core_get_ringer_device(mLc);
		const char * playback = linphone_core_get_playback_device(mLc);
		const char * capture  = linphone_core_get_capture_device(mLc);

		for (; devList && *devList; ++devList)
		{
			SoundDeviceModel device;
			device.DevId = *devList;
			device.CanCapture = !!linphone_core_sound_device_can_capture(mLc, *devList);
			device.CanPlay = !!linphone_core_sound_device_can_playback(mLc, *devList);
			device.CurrentRinger   = ringer   && device.DevId == ringer;
			device.CurrentPlayback = playback && device.DevId == playback;
			device.CurrentCapture  = capture  && device.DevId == capture;
			devices.insert(device);
		}
	}
	return !!devList;
}

bool ApplicationVoipApi::SetPlaybackDevice(DeviceId devid) const
{
	boost::lock_guard<boost::recursive_mutex> _lock(this->mMutex);
	return mLc && !linphone_core_set_playback_device(mLc, devid.c_str());
}

bool ApplicationVoipApi::SetCaptureDevice(DeviceId devid) const
{
	boost::lock_guard<boost::recursive_mutex> _lock(this->mMutex);
	return mLc && !linphone_core_set_capture_device(mLc, devid.c_str());
}

bool ApplicationVoipApi::SetRingDevice(DeviceId devid) const
{
	boost::lock_guard<boost::recursive_mutex> _lock(this->mMutex);
	return mLc && !linphone_core_set_ringer_device(mLc, devid.c_str());
}

template <typename Get, typename Set>
int LevelHelper(Get get, Set set, LinphoneCore * lc, int level)
{
	if (!lc)
	{
		return 100;
	}
	const int prev = get(lc);
	if (prev != level && 0 <= level && level <= 100)
	{
		set(lc, level);
	}
	return prev;
}

int ApplicationVoipApi::SetPlaybackLevel(int level) const
{
	return LevelHelper(linphone_core_get_play_level, linphone_core_set_play_level, mLc, level);
}
int ApplicationVoipApi::SetCaptureLevel(int level) const
{
	return LevelHelper(linphone_core_get_rec_level, linphone_core_set_rec_level, mLc, level);
}
int ApplicationVoipApi::SetRingLevel(int level) const
{
	return LevelHelper(linphone_core_get_ring_level, linphone_core_set_ring_level, mLc, level);
}

void ApplicationVoipApi::SetupAudio()
{
	PayloadType* pt;
	const MSList* allCodecsList = this->GetAvailableAudioCodecs(this->mLc);

	// Codecs list
	MSList* availCodecsList = ms_list_copy(allCodecsList);

	// TODO: add plugin-codecs if needed

	linphone_core_set_audio_codecs(this->mLc, availCodecsList);

	for (const MSList* elem = this->GetAvailableAudioCodecs(this->mLc);elem != NULL;elem = elem->next)
	{
		pt = (PayloadType*)elem->data;
		linphone_core_enable_payload_type(this->mLc, pt, FALSE);
	}
}

void ApplicationVoipApi::ApplyVoipSettings(const UserSettingsModel& settings)
{
	if (this->mLc)
	{
		LinphoneMediaEncryption menc = LinphoneMediaEncryptionNone;
		switch (settings.VoipEncryption)
		{
		case VoipEncryptionNone:
			menc = LinphoneMediaEncryptionNone;
			break;
		case VoipEncryptionSrtp:
			menc = LinphoneMediaEncryptionSRTP;
			break;
		default:
			assert(!"unsupported VoipEncryption in settings");
		}
		linphone_core_set_media_encryption(mLc, menc);
		if (LpConfig* config = linphone_core_get_config(mLc))
		{
			linphone_core_enable_adaptive_rate_control(mLc, TRUE);
			linphone_core_enable_echo_cancellation(mLc, TRUE);
			linphone_core_enable_echo_limiter(mLc, TRUE);
			const bool echoCancellationOn = settings.EchoCancellationMode != EchoCancellationModeOff;
			lp_config_set_int(config, "sound", "echocancellation", echoCancellationOn);
			lp_config_set_int(config, "sound", "echolimiter", echoCancellationOn);
			lp_config_set_int(config, "sound", "noisegate", echoCancellationOn);
			switch (settings.EchoCancellationMode)
			{
			case EchoCancellationModeOff:
			case EchoCancellationModeSoft:
				break;	// all done by echoCancellationOn
			case EchoCancellationModeHard:
				// some more work: 
				lp_config_set_int(config, "sound", "ec_tail_len", 300);
				lp_config_set_float(config, "sound", "el_thres", 0.2f);
				lp_config_set_int(config, "sound", "el_sustain", 300);
				lp_config_set_float(config, "sound", "ng_thres", 0.15f);
				break;
			default:
				assert(!"unexpected value of EchoCancellationMode");
				break;
			}
		}
		else
		{
			assert(!"failed linphone_core_get_config");
		}
		// TODO: apply DefaultVoipServer setting
	}
}

void ApplicationVoipApi::RecallToContact(const ContactModel& contact)
{
    Logger& logger = LogManager::GetInstance().TraceLogger;
    logger(LogLevelDebug) << "Start ApplicationVoipApi::RecallToContact";
    
    boost::lock_guard<boost::recursive_mutex> _lock(this->mMutex);
	if (this->mLc)
	{
		for (auto iter = this->mVirtualCalls.begin(); iter != this->mVirtualCalls.end(); iter++)
		{
			if (iter->Contact == contact)
			{
				if (!iter->SipId.empty())
				{
					LinphoneCall* call = FindLinphoneCallById(this->mLc, iter->SipId);
					if (call && linphone_call_get_state(call) == LinphoneCallOutgoingRinging)
					{
						logger(LogLevelDebug) << "Start ApplicationVoipApi::RecallToContact: real recall";
                        
                        VirtualCall& virtualCall = (VirtualCall&)*iter;
						virtualCall.SipId.clear();
						virtualCall.LastRealCallTime = time_t_to_posix_time((time_t)0);
                        
                        CallUserData* pUserData = this->GetCallUserData(call);
                        
                        if(pUserData)
                        {
                            pUserData->ShouldSendPushAboutMissedCall = false;
                            
                            this->SetCallUserData(call, *pUserData);
                        }
						
                        linphone_core_terminate_call(this->mLc, call);
					}
				}
				break;
			}
		}
	}
    
    logger(LogLevelDebug) << "End ApplicationVoipApi::RecallToContact";
}

void ApplicationVoipApi::SetupVideo()
{
	// TODO: turn on and configure
	linphone_core_enable_video(this->mLc, FALSE, FALSE);

	PayloadType* pt;
	const MSList* allCodecsList = this->GetAvailableVideoCodecs(this->mLc);

	// Codecs list
	MSList* availCodecsList = ms_list_copy(allCodecsList);

	// TODO: add plugin-codecs if needed

	linphone_core_set_video_codecs(this->mLc, availCodecsList);

	for (const MSList* elem=this->GetAvailableVideoCodecs(this->mLc);elem!=NULL;elem=elem->next)
	{
		pt=(PayloadType*)elem->data;
		linphone_core_enable_payload_type(this->mLc,pt,FALSE);
	}
}

void ApplicationVoipApi::RegisterAccounts()
{
	ServerSettingsList settings = this->mDeviceSettings.SafeGet<ServerSettingsList>([](const DeviceSettingsModel& self) { return self.ServerSettings; });
	for (ServerSettingsList::const_iterator iter = settings.begin(); iter != settings.end(); iter++)
	{
		if (iter->ServerType != ServerTypeSip)
			continue;
		if (iter->Port > 0)
		{
			LCSipTransports transport={0};

			if (linphone_core_get_sip_transports(this->mLc, &transport))
			{
				// TODO: log warning
				continue;
			}

			std::string protocol = ServerProtocolTypeToString(iter->ProtocolType);
			if(protocol == "TLS")
			{
				transport.tls_port = iter->Port;
				transport.tcp_port = 0;
				transport.udp_port = 0;
				transport.dtls_port = 0;
			}
			else if(protocol == "TCP")
			{
				transport.tls_port = 0;
				transport.tcp_port = iter->Port;
				transport.udp_port = 0;
				transport.dtls_port = 0;
			}
			else if(protocol == "UDP")
			{
				transport.tls_port = 0;
				transport.tcp_port = 0;
				transport.udp_port = iter->Port;
				transport.dtls_port = 0;
			}
			else
			{
				// TODO: log warning
			}

			if(linphone_core_set_sip_transports(this->mLc, &transport))
			{
				// TODO: log warning
				continue;
			}
		}

		std::string identity = "sip:"+iter->AuthUserName+"@"+iter->Domain+":"+boost::lexical_cast<std::string>(iter->Port);
		LinphoneAddress* lpAddress = linphone_address_new(identity.c_str());
		if (lpAddress == NULL)
		{
			// TODO: log warning
			continue;
		}

		const char* serverAddr = linphone_address_get_username(lpAddress);

		LinphoneAuthInfo* lpInfo = linphone_auth_info_new(serverAddr,iter->Username.c_str(),iter->Password.c_str(),NULL,NULL,linphone_address_get_domain(lpAddress));
		linphone_core_add_auth_info(this->mLc,lpInfo);
		linphone_auth_info_destroy(lpInfo);

		LinphoneProxyConfig* proxy = linphone_proxy_config_new();
		linphone_proxy_config_set_identity(proxy, identity.c_str());

		std::string serverFullAddr;
		if(!iter->Server.empty())
		{
			serverFullAddr = iter->Server;
			serverFullAddr += ":";
			serverFullAddr += boost::lexical_cast<std::string>(iter->Port);
			linphone_proxy_config_set_route(proxy, serverFullAddr.c_str());
		}
		else
		{
			serverFullAddr = serverAddr;
			serverFullAddr += ":";
			serverFullAddr += boost::lexical_cast<std::string>(iter->Port);
		}
		linphone_address_destroy(lpAddress);

		linphone_proxy_config_set_server_addr(proxy,serverFullAddr.c_str());
		linphone_proxy_config_enable_register(proxy,TRUE);
		linphone_proxy_config_set_expires(proxy, 60);

		if (!linphone_core_add_proxy_config(this->mLc,proxy))
		{
			if (iter->Default)
				linphone_core_set_default_proxy(this->mLc, proxy);
		}
		else
		{
			// TODO: log warning
		}
	}
}

bool ApplicationVoipApi::EnableCodec(const CodecSettingModel& codec)
{
	if (codec.ConnectionType == ConnectionTypeCell && this->mNetworkState.Technology == NetworkTechnologyWifi ||
		codec.ConnectionType == ConnectionTypeWifi && this->mNetworkState.Technology != NetworkTechnologyWifi)
		return true;

	const MSList* availCodecsList = 0;
	switch(codec.Type)
	{
	case CodecTypeAudio:
		availCodecsList = this->GetAvailableAudioCodecs(this->mLc);
		break;
	case CodecTypeVideo:
		/* TODO: enable later
		availCodecsList = this->GetAvailableVideoCodecs(this->mLc);
		break;
		*/
		return true;
	default:
		// TODO: log error
		break;
	}
	bool result = false;
	while (availCodecsList)
	{
		const PayloadType* pt = (const PayloadType*)availCodecsList->data;
		if(!strcasecmp(pt->mime_type,codec.Mime.c_str()) && (codec.Rate == 0 || pt->clock_rate == codec.Rate))
		{
			if(linphone_core_find_payload_type(this->mLc,pt->mime_type,pt->clock_rate,LINPHONE_FIND_PAYLOAD_IGNORE_CHANNELS) != NULL)
			{
				if (!linphone_core_enable_payload_type(this->mLc,(LinphonePayloadType*)pt,(codec.Enabled?TRUE:FALSE)))
					result = true;
			}
		}
		availCodecsList=availCodecsList->next;
	}
	return result;
}

bool ApplicationVoipApi::Iterate(void)
{
	static unsigned registrationWatcher = 0;
	boost::lock_guard<boost::recursive_mutex> _lock(this->mMutex);
	if (this->mLc)
	{
		linphone_core_iterate(this->mLc);

		if ((++registrationWatcher) % 500 == 0)
		{
			const MSList* accountList = linphone_core_get_proxy_config_list(this->mLc);
			while(accountList)
			{
				LinphoneProxyConfig* proxy = (LinphoneProxyConfig*)accountList->data;
				LinphoneRegistrationState state = linphone_proxy_config_get_state(proxy);
				if (state == LinphoneRegistrationCleared || state == LinphoneRegistrationFailed)
					linphone_proxy_config_refresh_register(proxy);
				accountList = accountList->next;
			}
			registrationWatcher = 0;
		}

		this->mIterateCounter++;
		this->mIterateLastTime = posix_time_now();

		if (this->mIterateCounter % 10 == 0)
		{
			this->CheckVirtualCalls();
			if (posix_time_to_time_t(this->mDelayedNotificationTime) && this->mDelayedNotificationTime <= this->mIterateLastTime)
			{
				this->mCallsNotifyer.Call("");
				this->mDelayedNotificationTime = time_t_to_posix_time(0);
			}
		}

		int32_t duration = (this->mIterateLastTime - this->mIterateControlTime).total_seconds();
		if (duration > 60)
		{
			LogManager::GetInstance().VoipLogger(LogLevelDebug) << "Iterator was executed " << this->mIterateCounter << " times last minute";
			this->mIterateControlTime = this->mIterateLastTime;
			this->mIterateCounter = 0;
		}

		return true;
	}
	return false;
}

bool ApplicationVoipApi::DtmfIterate(void)
{
	boost::lock_guard<boost::recursive_mutex> _lock(this->mMutex);
	if (this->mLc)
	{
		if (!mDtmfDueue.empty())
		{
			//??? iOS todo ??? linphone_core_start_dtmf_stream(self->mLc);
			linphone_core_send_dtmf(this->mLc, mDtmfDueue.front());
			linphone_core_play_dtmf(this->mLc, mDtmfDueue.front(), DTMF_PLAY_DURATION_MS);
			mDtmfDueue.pop_front();
		}
	}
	return true;
}

LinphoneCallRefPtr ApplicationVoipApi::StartCallToContactUrlInternal(ContactModel contact, ContactsContactModel url, CallOptions options, VirtualCall* pVirtualCall)
{
	bool startVirtual = false;
	bool newVirtual = false;
#ifndef DENY_VIRTUALS
	if (!pVirtualCall && url.Type == ContactsContactSip)
	{
		pVirtualCall = this->CreateVirtualCall(contact, url);
		if (pVirtualCall)
		{
			newVirtual = true;
			this->mCallsNotifyer.Call(pVirtualCall->VirtualId);
		}

		std::string from = this->mApplicationServer.GetLogin();
		ContactModel iAm = this->GetAccountData(false);
		if ((bool)iAm)
		{
			std::string urlDomain = GetDomain(url.Identity);
			for (auto iter = iAm.Contacts.begin(); iter != iAm.Contacts.end(); iter++)
				if (iter->Type == ContactsContactSip)
				{
					from = iter->Identity;
					if (urlDomain.empty() || urlDomain == GetDomain(iter->Identity))
						break;
				}
		}

		PushNotificationModel notification;
		notification.AlertBody = "call";
		notification.AlertAction = AlertActionTypeAnswer;
		notification.HasAction = true;
		notification.SoundName = AlertSoundNameTypeCall;
		notification.IconBadge = 1;
		notification.ExpireInSec = VIRTUAL_CALL_MAX_DURATION - 10;
		notification.DType = dodicall::NotificationRemote;
		notification.Type = dodicall::model::ServerTypeSip;
		notification.AType = dodicall::model::PICC;			//?
		notification.MetaStruct.From = from;				//?
		notification.MetaStruct.Type = dodicall::model::UserNotificationTypeSip;

		CallbackEntityIdsList ids;
		ids.push_back(url.Identity);
		results::SendPushResult pushResult = SendPushNotificationToSipIds(ids, notification);

		startVirtual = pushResult.Sended;
	}
#endif
	boost::lock_guard<boost::recursive_mutex> _lock(this->mMutex);
	LinphoneCallRefPtr callPtr = this->StartCallToUrlInternal(url.Identity, options, !pVirtualCall);
	std::string virtualId = "";
	if (callPtr)
	{
		if (pVirtualCall)
		{
			virtualId = pVirtualCall->VirtualId;
			if (startVirtual)
				this->StartVirtualCall(pVirtualCall, *callPtr);
			else if (newVirtual)
			{
				this->StopVirtualCall(pVirtualCall);
				pVirtualCall = NULL;
			}
		}
		this->SetCallUserData(*callPtr, ApplicationVoipApi::CallUserData(contact, virtualId));
	}
	return callPtr;
}

LinphoneCallRefPtr ApplicationVoipApi::StartCallToUrlInternal(std::string url, CallOptions options, bool checkActive)
{
	boost::lock_guard<boost::recursive_mutex> _lock(this->mMutex);
	if (!this->mLc)
		return LinphoneCallRefPtr();
	if (checkActive && YetActiveCalls(this->mLc))
		return LinphoneCallRefPtr();	// TEMP ORARY !!! see DMC-2249.3
	
	LinphoneCall* call = linphone_core_invite(this->mLc, url.c_str());
	if (call)
		return LinphoneCallRefPtr(new LinphoneCallRef(call));
	return LinphoneCallRefPtr();
}

ApplicationVoipApi::VirtualCall* ApplicationVoipApi::CreateVirtualCall(const ContactModel& contact, const ContactsContactModel& url)
{
	VirtualCall virtualCall(contact, url);
	virtualCall.SipId = "DUMMY";
	ApplicationVoipApi::VirtualCall* result = NULL;

	boost::lock_guard<boost::recursive_mutex> _lock(this->mMutex);
	result = &(ApplicationVoipApi::VirtualCall&)*this->mVirtualCalls.insert(virtualCall).first;
	return result;
}

bool ApplicationVoipApi::StartVirtualCall(VirtualCall* pVirtualCall, LinphoneCall* call)
{
	boost::lock_guard<boost::recursive_mutex> _lock(this->mMutex);
	CallModel model = LinphoneCallToModel(call);
	pVirtualCall->SipId = model.SipId;

	if (this->mLc)
	{
#if TARGET_OS_IPHONE
		// TODO: fix problem with sound 
#else
		WavePlayerPtr dummy = WavePlayerPtr(new WavePlayer(this->mLc,
			(this->mDeviceModel.ApplicationDataPath / "sounds" / "virtual_call.wav").string().c_str()
		));
		this->mVirtualMusicPlayer.swap(dummy);
#endif
		return true;
	}
	return false;
}

void ApplicationVoipApi::StopVirtualCall(const VirtualCall* pVirtualCall)
{
	if (pVirtualCall)
	{
		boost::lock_guard<boost::recursive_mutex> _lock(this->mMutex);
		this->mVirtualCalls.erase(*pVirtualCall);
	}
	this->StopVirtualCallMusic();
}

void ApplicationVoipApi::StopVirtualCallMusic(void)
{
	if (this->mVirtualMusicPlayer)
	{
		WavePlayerPtr dummy;
		this->mVirtualMusicPlayer.swap(dummy);
	}
}

ApplicationVoipApi::VirtualCall* ApplicationVoipApi::FindVirtualById(const CallIdType& callId) const
{
	boost::lock_guard<boost::recursive_mutex> _lock(this->mMutex);
	for (VirtualCallSet::iterator iter = this->mVirtualCalls.begin(); iter != this->mVirtualCalls.end(); iter++)
		if (iter->VirtualId == callId)
			return const_cast<VirtualCall*>(&(*iter));
	return NULL;
}

ApplicationVoipApi::VirtualCall* ApplicationVoipApi::GetVirtualOfRealCall(const CallIdType& callId) const
{
	boost::lock_guard<boost::recursive_mutex> _lock(this->mMutex);
	for (VirtualCallSet::iterator iter = this->mVirtualCalls.begin(); iter != this->mVirtualCalls.end(); iter++)
		if (iter->SipId == callId)
			return const_cast<VirtualCall*>(&(*iter));
	return NULL;
}

void ApplicationVoipApi::CheckVirtualCalls(void)
{
	boost::lock_guard<boost::recursive_mutex> _lock(this->mMutex);
	for (VirtualCallSet::iterator iter = this->mVirtualCalls.begin(); iter != this->mVirtualCalls.end(); iter++)
	{
		ApplicationVoipApi::VirtualCall& virtualCall = (ApplicationVoipApi::VirtualCall&)*iter;
		if ((int)posix_time_to_time_t(virtualCall.RingingStartTime) > 0 && (posix_time_now() - virtualCall.RingingStartTime).total_seconds() >= VIRTUAL_CALL_RINGING_MIN_DURATION)
			this->StopVirtualCallMusic();
		if (iter->SipId.empty() && (posix_time_now() - iter->LastRealCallTime).total_seconds() > VIRTUAL_RECALL_TIMEOUT)
		{
			LinphoneCallRefPtr call = this->StartCallToContactUrlInternal(iter->Contact, iter->Identity, CallOptionsDefault, &virtualCall);
			if ((iter->LastRealCallTime - iter->StartCallTime).total_seconds() > VIRTUAL_CALL_MAX_DURATION)
			{
				CallIdType callId = virtualCall.VirtualId;
				this->StopVirtualCall(&virtualCall);
				if (!call)
					this->mCallsNotifyer.Call(callId);
			}
			else if (call)
				virtualCall.SipId = LinphoneCallToModel(*call).SipId;
			else
				virtualCall.LastRealCallTime = posix_time_now();
			break;
		}
	}
}

static model::CallState LinphoneCallStateToModel(LinphoneCallState state)
{
	dodicall::model::CallState result;
	switch (state)
	{
	case LinphoneCallIdle:
	case LinphoneCallOutgoingInit:
		result = CallStateInitialized;
		break;
	case LinphoneCallOutgoingProgress:
		result = CallStateDialing;
		break;
	case LinphoneCallIncomingReceived:
	case LinphoneCallOutgoingRinging:
		result = CallStateRinging;
		break;
	case LinphoneCallConnected:
	case LinphoneCallStreamsRunning:
	case LinphoneCallUpdatedByRemote:
	case LinphoneCallUpdating:
		result = CallStateConversation;
		break;
	case LinphoneCallOutgoingEarlyMedia:
	case LinphoneCallIncomingEarlyMedia:
	case LinphoneCallEarlyUpdatedByRemote:
	case LinphoneCallEarlyUpdating:
		result = CallStateEarlyMedia;
		break;
	case LinphoneCallPausing:
	case LinphoneCallPaused:
	case LinphoneCallResuming:
	case LinphoneCallPausedByRemote:
		result = CallStatePaused;
		break;
	case LinphoneCallRefered:
	case LinphoneCallError:
	case LinphoneCallEnd:
	case LinphoneCallReleased:
		result = CallStateEnded;
		break;
	default:
		assert(!"unexpected LinphoneCallState value");
		result = CallStateEnded;
		break;
	}
	return result;
}

CallModel ApplicationVoipApi::LinphoneCallToModel(LinphoneCall* call)
{
	CallModel result;
	LinphoneCallLog* log = linphone_call_get_call_log(call);
	if (log)
	{
		const char* id = linphone_call_log_get_call_id(log);
		if (id)
		{
			result.SipId = id;
			switch(linphone_call_get_dir(call))
			{
			case LinphoneCallOutgoing:
				result.Direction = CallDirectionOutgoing;
				break;
			case LinphoneCallIncoming:
				result.Direction = CallDirectionIncoming;
				break;
			}
			result.State = LinphoneCallStateToModel(linphone_call_get_state(call));
			result.Identity = this->GetCallIdentity(call);
			
			const LinphoneCallParams* cp = linphone_call_get_current_params(call);
			result.AddressType = GetCallRemoteAddressType(call);
			if (result.AddressType != CallAddressDodicall)
				result.Encription = VoipEncryptionNone;
			else if (cp)
			{
				void* data = linphone_call_log_get_user_data(log);						// a patch to restore prev detected encryption status 
				switch (linphone_call_params_get_media_encryption(cp))
				{
				case LinphoneMediaEncryptionNone:
					result.Encription = data ? VoipEncryptionSrtp : VoipEncryptionNone;	// use already detected, if any
					break;
				case LinphoneMediaEncryptionSRTP:
					result.Encription = VoipEncryptionSrtp;
					linphone_call_log_set_user_data(log, log);							// (avoiding allocations) any non-zero, in the case &*log
					break;
				default:
					assert(!"unsupported encription");
					break;
				}
			}

			ApplicationVoipApi::VirtualCall* pVirtualCall = this->GetVirtualOfRealCall(id);
			if (pVirtualCall && result.State == CallStateConversation 
				&& (posix_time_now() - pVirtualCall->RingingStartTime).total_seconds() < VIRTUAL_CALL_RINGING_MIN_DURATION)
				result.State = CallStateDialing;
			CallUserData* pUserData = this->GetCallUserData(call);
			if (pUserData)
			{
				result.Id = pUserData->VirtualId;
                if ((bool)pUserData->Contact)
                {
                    ContactModel contact = pUserData->Contact;
                    this->PrepareRequestedContact(contact);
                    result.Contact = contact;
                }
					
			}
			if (result.Id.empty())
			{
				if (pVirtualCall)
					result.Id = pVirtualCall->VirtualId;
				else
					result.Id = id;
			}

			result.Duration = linphone_call_get_duration(call);
		}
	}
	return result;
}

void ApplicationVoipApi::RetrieveCallContactAndNotify(const CallIdType& callId)
{
	if (this->mLc)
	{
		std::string identity;
		{
			boost::lock_guard<boost::recursive_mutex> _lock(this->mMutex);
			LinphoneCall* call(FindLinphoneCallById(this->mLc, callId));
			if (call)
				identity = this->GetCallIdentity(call);
		}
		if (!identity.empty())
		{
			identity = CutDomain(identity);
			ContactModel contact = this->RetrieveDirectoryContactByNumberIfNeeded(identity);
			if ((bool)contact)
			{
				CallModel callModel;
				{
					boost::lock_guard<boost::recursive_mutex> _lock(this->mMutex);
					LinphoneCall* call(FindLinphoneCallById(this->mLc, callId));
					if (call)
					{
						this->SetCallUserData(call, ApplicationVoipApi::CallUserData(contact));
						callModel = LinphoneCallToModel(call);
					}
				}
				if (!callModel.Id.empty())
					this->mCallsNotifyer.Call(callModel.Id);
			}
		}
	}
}

LinphoneCall* ApplicationVoipApi::FindLinphoneCallById(LinphoneCore* lc, const CallIdType& callId)
{
	LinphoneCall* result = NULL;
	assert(lc);
	const MSList *calls = linphone_core_get_calls(lc);
	while(calls)
	{
		LinphoneCall* call=(LinphoneCall*)calls->data;
		ApplicationVoipApi::CallUserData* pUserData = GetCallUserData(call);
		if (pUserData && pUserData->VirtualId == callId)
		{
			result = call;
			break;
		}
		LinphoneCallLog* log = linphone_call_get_call_log(call);
		if (log)
		{
			const char* id = linphone_call_log_get_call_id(log);
			if (id && callId == id)
			{
				result = call;
				break;
			}
		}
		calls=calls->next;
	}
	return result;
}

std::string ApplicationVoipApi::GetCallIdentity(LinphoneCall* call)
{
	std::string result;
	DodicallLinphoneAddress  address(call);
	if (address)
	{
		char* sipAddress = linphone_address_as_string_uri_only(address);
		result = sipAddress;
		if (result.find("sip:") == 0)
			result.erase(result.begin(), result.begin() + 4);
		int portIndex = result.find_first_of(':');
		if (portIndex != result.npos)
			result.erase(result.begin() + portIndex, result.end());
		// TODO: ms_free(sipAddress);
	}
	return result;
}

CallAddressType ApplicationVoipApi::GetCallRemoteAddressType(LinphoneCall* call)
{
	DodicallLinphoneAddress address(call);
	const char *username = linphone_address_get_username(address);
	if (!username)
		return CallAddressPhone;
	CallAddressType result = CallAddressDodicall;
	const bool plus = (username[0] == '+');
	if (plus)
		username++;
	int isNumber = true;
	int n = 0;
	for (const char* s = username; *s && isNumber; s++, n++)
		isNumber = isdigit(*s);
	if (!isNumber)
		result = CallAddressDodicall;
	else if (plus)
		result = CallAddressPhone;
	else
	{
		assert(isNumber && !plus);	// for notes
		switch (n)
		{
		case 1:
			//todo log error
			break;
		case 2:
		case 3:
			result = CallAddressPhone;
			break;
		case 4:
			result = CallAddressDodicall;
			break;
		default:
			if (username[0] == '0' && username[1] == '0' && username[2] == '0')
				result = CallAddressDodicall;
			else
				result = CallAddressPhone;	// похоже, все схемы нумерации запрещают начинать телефонный номер с 000. С одиночного и двойного нуля - это бывает
			break;
		}
	}
	return result;
}

bool ApplicationVoipApi::HangupCall(LinphoneCore* lc, LinphoneCall* call)
{
	LinphoneCallState state = linphone_call_get_state(call);
	if (linphone_call_get_dir(call) == LinphoneCallIncoming && state == LinphoneCallIncomingReceived)
		return (linphone_core_decline_call(lc,call,LinphoneReasonBusy) == 0);
	else if (state != LinphoneCallReleased)
		return (linphone_core_terminate_call(lc,call) == 0);
	return false;
}

bool ApplicationVoipApi::YetActiveCalls(LinphoneCore *lc, LinphoneCall *exceptCall, bool withVirtuals)
{
	boost::lock_guard<boost::recursive_mutex> _lock(this->mMutex);

	if (!lc)
		lc = this->mLc;
	if (!lc)
		return false;

	if (withVirtuals)
	{
		if (!exceptCall)
		{
			if (!this->mVirtualCalls.empty())
			{
				LogManager::GetInstance().VoipLogger(LogLevelDebug) << "Found active virtual calls : " << this->mVirtualCalls.begin()->VirtualId;
				return true;
			}
		}
		else
		{
			std::string exceptCallId = LinphoneCallToModel(exceptCall).SipId;
			for (auto iter = this->mVirtualCalls.begin(); iter != this->mVirtualCalls.end(); iter++)
				if (iter->SipId != exceptCallId)
				{
					LogManager::GetInstance().VoipLogger(LogLevelDebug) << "Found active virtual calls : " << iter->VirtualId;
					return true;
				}
		}
	}

	bool result = false;
	std::string sip2249; // TODO extra logging for bebug purpouse (see comments of 2249). Remove the line and all dependences when 2249 done
	for (const MSList *calls = linphone_core_get_calls(lc); calls; calls = calls->next)
	{
		assert(calls->data);
		if (calls->data != exceptCall)	// skiping the call
		{
			switch (LinphoneCallStateToModel(linphone_call_get_state((LinphoneCall*)calls->data)))
			{
			case CallStateDialing:
			case CallStateRinging:
			case CallStateConversation:
			{
				result = true;
				// TODO extra logging for bebug purpouse (see comments of 2249). Remove the block
				// start 2249 extras:
				DodicallLinphoneAddress remote((LinphoneCall*)calls->data);
				const char* sip = remote ? linphone_address_as_string(remote) : "<unknown>";
				sip2249 += sip;
				sip2249 += " ";
				continue;	// we need all sips for 2249...
							//end 2249 extras
			}
			break;
			}
		}
	}
	if (result)
		LogManager::GetInstance().VoipLogger(LogLevelDebug) << "Found active calls : " << sip2249;
	return result;
}

void ApplicationVoipApi::SetCallUserData(LinphoneCall* call, const ApplicationVoipApi::CallUserData& userData)
{
	ApplicationVoipApi::CallUserData* pUserData = new ApplicationVoipApi::CallUserData(userData);
	linphone_call_set_user_data(call, pUserData);
}

ApplicationVoipApi::CallUserData* ApplicationVoipApi::GetCallUserData(LinphoneCall* call)
{
	return (ApplicationVoipApi::CallUserData*)linphone_call_get_user_data(call);
}

void ApplicationVoipApi::ClearCallUserData(LinphoneCall* call)
{
	ApplicationVoipApi::CallUserData* pUserData = (ApplicationVoipApi::CallUserData*)linphone_call_get_user_data(call);
	if (pUserData)
	{
		delete pUserData;
		linphone_call_set_user_data(call, NULL);
	}
}

void ApplicationVoipApi::UpdateHistory(LinphoneCallLog* log, const CallModel& callModel, bool blocked)
{
	CallDbModel dbModel;
	static_cast<CallModel&>(dbModel) = callModel;
	LinphoneCallStatus status = linphone_call_log_get_status(log);

	if (blocked)
		status = LinphoneCallMissed;		//DMC-3011 - an attempt to get right befaviour

	switch (status)
	{
	case LinphoneCallSuccess:
		dbModel.HistoryStatus = HistoryStatusSuccess;
		break;
	case LinphoneCallAborted:
		dbModel.HistoryStatus = HistoryStatusAborted;
		break;
	case LinphoneCallMissed:
		dbModel.HistoryStatus = HistoryStatusMissed;
		break;
	case LinphoneCallDeclined:
		dbModel.HistoryStatus = HistoryStatusDeclined;
		break;
	default:
		assert(0);
		dbModel.HistoryStatus = HistoryStatusSuccess;
		break;
	}
	dbModel.EndMode = dbModel.Duration ? CallEndModeNormal : CallEndModeCancel;
	dbModel.StartTime = posix_time_now();
	if (dbModel.Direction == CallDirectionOutgoing || dbModel.EndMode == CallEndModeNormal)
		dbModel.Readed = true;
	if (dbModel.EndMode == CallEndModeCancel)
		dbModel.Encription = VoipEncryptionNone;	//3283
    this->UpdateHistory(dbModel);
}

void ApplicationVoipApi::UpdateHistory(const CallDbModel& callModel)
{
    if (mUserDb.SaveCall(callModel))
	    this->mCallHistoryNotifyer.Call(callModel.GetId());
}
void ApplicationVoipApi::UpdateHistory(const CallDbModelList& callModels)
{
    for (std::vector<CallDbModel>::const_iterator iter = callModels.begin(); iter != callModels.end(); iter++)
        this->UpdateHistory(*iter);
}

void ApplicationVoipApi::LoadMissedCallsFromServer()
{
    this->mThreadsOnlyThenLoggedIn.StartThread([this]
    {                        
        CallDbModelList calls;
        BaseResult result = GetMissedCalls(calls);
		if (result.Success)
			this->UpdateHistory(calls);
    });
}
    
void ApplicationVoipApi::SendPushNotificationAboutMissedCall(std::string callId, std::string callIdentity)
{
    
    std::string from = this->mApplicationServer.GetLogin();
    ContactModel iAm = this->GetAccountData(false);
    if ((bool)iAm)
    {
        std::string urlDomain = GetDomain(callIdentity);
        for (auto iter = iAm.Contacts.begin(); iter != iAm.Contacts.end(); iter++)
            if (iter->Type == ContactsContactSip)
            {
                from = iter->Identity;
                if (urlDomain.empty() || urlDomain == GetDomain(iter->Identity))
                    break;
            }
    }
    
    PushNotificationModel notification;
    notification.AlertBody = "missed call";
    notification.AlertAction = AlertActionTypeLook;
    notification.HasAction = true;
    notification.SoundName = AlertSoundNameTypeMessage;
    notification.IconBadge = 1;
    notification.ExpireInSec = 345600;
    notification.DType = dodicall::NotificationRemote;
    notification.Type = dodicall::model::ServerTypeSip;
    notification.AType = dodicall::model::PMICC;
    notification.MetaStruct.From = from;
    notification.MetaStruct.Type = dodicall::model::UserNotificationTypeMissedCall;
    notification.MetaStruct.CallId = callId;
    
    CallbackEntityIdsList ids;
    ids.push_back(callIdentity);
    
    ThreadHelper::StartThread([this, ids, notification]
    {
        SendPushNotificationToSipIds(ids, notification, 30L);
    });
}
	
void ApplicationVoipApi::LinphoneOnRegistrationChanged(LinphoneCore *lc, LinphoneProxyConfig *cfg, LinphoneRegistrationState state, const char *message)
{
	ApplicationVoipApi* self = (ApplicationVoipApi*)linphone_core_get_user_data(lc);
	bool status = false;
	for (const MSList* elem=linphone_core_get_proxy_config_list(lc); elem!=NULL; elem=elem->next)
	{
		LinphoneProxyConfig* pc = (LinphoneProxyConfig*)elem->data;
		if (linphone_proxy_config_get_state(pc) == LinphoneRegistrationOk)
		{
			status = true;
			break;
		}
	}
	self->ChangeVoipNetworkStatus(status);
}

void ApplicationVoipApi::LinphoneOnCallStateChanged(LinphoneCore *lc, LinphoneCall *call, LinphoneCallState state, const char *msg)
{
	ApplicationVoipApi* self = (ApplicationVoipApi*)linphone_core_get_user_data(lc);
	LinphoneCallLog* log = linphone_call_get_call_log(call);
	if (log && self)
	{
		CallModel callModel = self->LinphoneCallToModel(call);
		if (!callModel.Id.empty())
		{
			ApplicationVoipApi::VirtualCall* pVirtualCall = self->GetVirtualOfRealCall(callModel.SipId);
			const CallIdType callId = callModel.Id;

			bool notify = false;
			bool logHistory = false;
			int updateHistory = false;
			bool blocked = false;
            bool notifyAboutMissedCall = false;
            
			switch (state)
			{
			case LinphoneCallIncomingReceived:
				notify = true;
				updateHistory = true;
				if (!callModel.Contact)
				{
					ContactModel contact = self->RetriveContactByNumberLocal(self->GetCallIdentity(call), false);
					if ((bool)contact)
					{
						callModel.Contact = contact;
						self->SetCallUserData(call, ApplicationVoipApi::CallUserData(*callModel.Contact));
					}
					if (!callModel.Contact || callModel.Contact->DodicallId.empty())
						self->mCallContactsRetriever.Call(callModel.SipId);
				}
				if (callModel.Contact)								// see DMC-2587
				{
					// TODO: answer, if has virtual
					if (self->GetUserSettings().DoNotDesturbMode)		// White list on
						notify = callModel.Contact->White;		// ... and contact in white list
					else
						notify = !callModel.Contact->Blocked;
				}
				if (notify)
					notify = !self->YetActiveCalls(lc, call);	// TEMPORARY !!! see DMC-2249.2
				if (!notify)
				{
					linphone_core_decline_call(lc, call, LinphoneReasonBusy);
					blocked = true;
					logHistory = true;
				}
				break;

			case LinphoneCallConnected:
				updateHistory = true;
                break;

            case LinphoneCallOutgoingInit:
				break;

			case LinphoneCallOutgoingRinging:
				if (pVirtualCall)
					pVirtualCall->RingingStartTime = posix_time_now();
				break;

			case LinphoneCallStreamsRunning:
				if (!(pVirtualCall && posix_time_to_time_t(pVirtualCall->RingingStartTime) == 0))
					notify = true;
				else
					self->mDelayedNotificationTime = posix_time_now() + boost::posix_time::seconds(1);
				self->StopVirtualCallMusic();
				break;

			case LinphoneCallOutgoingProgress:
			case LinphoneCallPaused:
			case LinphoneCallResuming:
			case LinphoneCallPausedByRemote:
			case LinphoneCallIncomingEarlyMedia:
				notify = true;
				break;

			case LinphoneCallReleased:
				{
					LinphoneCallState prevState = linphone_call_get_prev_state(call);
					if (prevState == LinphoneCallEnd || prevState == LinphoneCallError)
						break;
					self->StopVirtualCall(pVirtualCall);
					pVirtualCall = NULL;
				}
			case LinphoneCallEnd:
			case LinphoneCallError:
				logHistory = true;
				updateHistory = true;
				if (pVirtualCall) 
				{
					LinphoneReason reason = linphone_call_get_reason(call);
					if ((reason > LinphoneReasonNone && reason != LinphoneReasonTemporarilyUnavailable) ||
						(posix_time_to_time_t(pVirtualCall->RingingStartTime) > 0 && 
						(posix_time_now() - pVirtualCall->RingingStartTime).total_seconds() > 1))
					{
						self->StopVirtualCall(pVirtualCall);
						pVirtualCall = NULL;
						notify = true;
					}
					else
					{
						pVirtualCall->SipId.clear();
						pVirtualCall->LastRealCallTime = posix_time_now();
						pVirtualCall->RingingStartTime = time_t_to_posix_time((time_t)0);
					}
                } 
				else 
				{
                    if (linphone_call_get_prev_state(call) == LinphoneCallOutgoingRinging && state == LinphoneCallError)
                        self->WaitingForErrorTone = true; /* We have to notify the app after playing an error tone */
					else
                    {
                        notify = true;
                        notifyAboutMissedCall = true;
                        
                        CallUserData* pUserData = self->GetCallUserData(call);
                        
                        if(pUserData && !pUserData->ShouldSendPushAboutMissedCall)
                            notifyAboutMissedCall = false;
                    }
                }
				self->mDelayedNotificationTime = time_t_to_posix_time(0);
				ClearCallUserData(call);
				if (self->mLc && !self->YetActiveCalls(self->mLc, NULL, false))
					linphone_core_start_dtmf_stream(self->mLc);
				break;

			case LinphoneCallOutgoingEarlyMedia:
				if (pVirtualCall)
				{
					pVirtualCall->RingingStartTime = time_t_to_posix_time((time_t)0);
					linphone_core_terminate_call(self->mLc, call);
				}
				break;

			case LinphoneCallIdle:
			case LinphoneCallPausing:
				break;
			case LinphoneCallRefered:
			case LinphoneCallUpdatedByRemote:
				{	
					// TODO: remove copypast!!!1
					ContactModel contact = self->RetriveContactByNumberLocal(self->GetCallIdentity(call));
					//assert(!contact || contact != callModel.Contact);
					if (contact != callModel.Contact)
					{
						if (contact)
						{
							callModel.Contact = contact;
							self->SetCallUserData(call, ApplicationVoipApi::CallUserData(*callModel.Contact));
						}
						else
							callModel.Contact.reset();
						if (!callModel.Contact || callModel.Contact->DodicallId.empty())
							self->mCallContactsRetriever.Call(callModel.SipId);
					}
					notify = true;
					updateHistory = true;
					logHistory = true;
				}
				break;
			case LinphoneCallUpdating:
			case LinphoneCallEarlyUpdatedByRemote:
			case LinphoneCallEarlyUpdating:
				break;
			default:
				assert(!"unexpected value of LinphoneCallState");
				break;
			}

			if (notify)
				self->mCallsNotifyer.Call(callId);
			if (updateHistory)
				self->UpdateHistory(log, callModel, blocked);
			if (logHistory)
				LogCall(LogManager::GetInstance().CallHistoryLogger, call, true);
            
            if (notifyAboutMissedCall)
            {
                LinphoneCallStatus status = linphone_call_log_get_status(log);
                LinphoneCallState prev_state = linphone_call_get_prev_state(call);
                
                if((status == LinphoneCallAborted && callModel.Direction == CallDirectionOutgoing) && (LinphoneCallOutgoingRinging == prev_state || LinphoneCallOutgoingProgress == prev_state))
                    self->SendPushNotificationAboutMissedCall((callModel.SipId.empty() ? callModel.Id: callModel.SipId), callModel.Identity);
            }
		}
	}
}

void ApplicationVoipApi::LinphoneOnCallStatisticsUpdated(LinphoneCore *lc, LinphoneCall *call, const LinphoneCallStats*)
{
	LogCall(LogManager::GetInstance().CallQualityLogger, call, false);
	// TODO: modify statistics model
}

void ApplicationVoipApi::LinphoneOnCallEncryptionStateChanged(LinphoneCore *lc, LinphoneCall *call, bool_t on, const char *authentication_token)
{
	ApplicationVoipApi* self = (ApplicationVoipApi*)linphone_core_get_user_data(lc);
	if (LinphoneCallLog* log = linphone_call_get_call_log(call))
	{
		if (const char* id = linphone_call_log_get_call_id(log))
		{
			self->mCallsNotifyer.Call(id);
		}
	}
}

void ApplicationVoipApi::LinphoneOnNotificationReceived(LinphoneCore *lc, LinphoneEvent *lev, const char *notified_event, const LinphoneContent *body)
{
	ApplicationVoipApi* self = (ApplicationVoipApi*)linphone_core_get_user_data(lc);
	// TODO: realize
}
    
void ApplicationVoipApi::LinphoneOnSpeakerOn(LinphoneCore *lc, bool_t on)
{
    ApplicationVoipApi* self = (ApplicationVoipApi*)linphone_core_get_user_data(lc);
    linphone_core_set_speaker(lc, on);
    if (self->WaitingForErrorTone && on) 
	{
		self->mCallsNotifyer.Call("");
        self->WaitingForErrorTone = false;
    }
}

void ApplicationVoipApi::LinphoneOnLog (OrtpLogLevel level, const char *format, va_list args)
{
	Logger& logger = LogManager::GetInstance().VoipLogger;
	LogLevel logLevel;
	switch(level)
	{
	case ORTP_DEBUG:
	case ORTP_TRACE:
		logLevel = LogLevelDebug;
		break;
	case ORTP_ERROR:
	case ORTP_FATAL:
		logLevel = LogLevelError;
		break;
	case ORTP_WARNING:
		logLevel = LogLevelWarning;
		break;
	case ORTP_MESSAGE:
		logLevel = LogLevelInfo;
		break;
	default:
		logger(LogLevelWarning) << "Unknown log level value";
		break;
	}

	va_list c;
	va_copy(c, args);

	int size = vsnprintf(0, 0, format, c);
	std::vector<char> buffer(size+1,0);
	if (vsnprintf(&buffer[0], size + 1, format, args) > 0)
	{
		buffer[size] = '\0';
		logger(logLevel) << &buffer[0];
	}
}

template<typename F>
int ApplicationVoipApi::CallHelper(const CallIdType& callId, F func) const
{
	boost::lock_guard<boost::recursive_mutex> _lock(this->mMutex);
	if (this->mLc)
	{
		LinphoneCall* call(FindLinphoneCallById(this->mLc, callId));
		if (call)
			return func(this->mLc, call);
	}
	return -1;
}

namespace {	// used in LogCall (just below)
	void LogCodec(LoggerStream& stream, const PayloadType* codec, std::string header)
	{
		if (codec && codec->mime_type)
		{
			stream << header << ":" << codec->mime_type << ":" << codec->normal_bitrate << ":" << codec->clock_rate << LoggerStream::endl;
		}
	}
}

void ApplicationVoipApi::LogCall(Logger& logger, LinphoneCall *call, bool logHistory)
{
	LinphoneCallLog* log = linphone_call_get_call_log(call);
	if (!log)
	{ 
		assert(!"unable to get LinphoneCallLog");
		return;
	}
	LoggerStream stream = logger(LogLevelDebug);
	std::string startTime = boost::posix_time::to_iso_extended_string(boost::posix_time::from_time_t(linphone_call_log_get_start_date(log)));
	//! Convert to form YYYY-MM-DDTHH:MM:SS where T is the date-time separator
	//                  0123456789012345678

	stream  << LoggerStream::endl
			<< startTime.substr(8,2) << "." << startTime.substr(5, 2) << "." << startTime.substr(2, 2) << " " //DD.MM.YY
			<< startTime.substr(11,8) 		//HH:MM:SS
			<< " UTC" << LoggerStream::endl;

	if (const char* id = linphone_call_log_get_call_id(log))
	{
		stream << id << LoggerStream::endl;
	}
	DodicallLinphoneAddress address(call);
	if (address)
	{
		if (char* sipAddress = linphone_address_as_string_uri_only(address))
		{
			std::string s(sipAddress);
			size_t endPos = s.find_first_of("@");
			if (endPos == std::string::npos)
			{
				endPos = s.length();
			}
			size_t begPos = s.find("sip:") == 0 ? 4 : 0;
			size_t t = (begPos * 3 + endPos + 2) / 4;
			endPos   = (begPos + endPos * 3 + 2) / 4;
			assert(endPos > t);
			DEBUG_SHOW_NUMBERS_IN_LOGS(t = endPos);	// show numbers for testers
			while (t < endPos)
			{
				s[t++] = '*';
			}
			stream << s << LoggerStream::endl;
			// TODO: ms_free(sipAddress);
		}
	}
	if (logHistory)
	{
		switch (linphone_call_get_dir(call))
		{
		case LinphoneCallOutgoing:
			stream << "outgoing" << LoggerStream::endl;
			break;
		case LinphoneCallIncoming:
			stream << "incoming" << LoggerStream::endl;
			break;
		default:
			assert(0);
			break;
		}
		int duration = linphone_call_log_get_duration(log);
		char buf[100];
		snprintf(buf, sizeof(buf), "%02d:%02d", duration / 60, duration % 60);
		stream << buf << LoggerStream::endl;
	}
	if (!logHistory)	//=logQuality
	{
		if (const LinphoneCallParams *cp = linphone_call_get_current_params(call))
		{
			LogCodec(stream, linphone_call_params_get_used_audio_codec(cp), "audio");
			LogCodec(stream, linphone_call_params_get_used_video_codec(cp), "video");
		}
		//? float quality = linphone_call_log_get_quality(log);
		float quality = linphone_call_get_current_quality(call);
		stream << (quality < 0 ? "quality unavailiable" : std::to_string(int(quality * 20)) + "%") << LoggerStream::endl;
	}
}

LoggerStream operator << (LoggerStream s, const PayloadType& pt)
{
	s << "{mime_type = " << pt.mime_type << ", clock_rate = " << pt.clock_rate << ", normal_bitrate = " << pt.normal_bitrate << ", bits_per_sample = " << (int)pt.bits_per_sample << "}" << LoggerStream::endl;
	return s;
}

template <class F> const MSList* GetAvailableCodecs(LinphoneCore* lc, F getter, const char* name)
{
	const MSList* result = getter(lc);
	static bool reported = false;
	if (!reported)
	{
		LoggerStream logger = LogManager::GetInstance().VoipLogger(LogLevelDebug);
		logger << "Available " << name << "codecs list:" << LoggerStream::endl;
		for (const MSList* codec = result; codec; codec = codec->next)
			logger << *((const PayloadType*)codec->data);
		reported = true;
	}
	return result;
}

const MSList* ApplicationVoipApi::GetAvailableAudioCodecs(LinphoneCore* lc)
{
	return GetAvailableCodecs(lc, [](LinphoneCore* lc) {return linphone_core_get_audio_codecs(lc); }, "audio");
}
const MSList* ApplicationVoipApi::GetAvailableVideoCodecs(LinphoneCore* lc)
{
	return GetAvailableCodecs(lc, [](LinphoneCore* lc) {return linphone_core_get_video_codecs(lc); }, "video");
}

int ApplicationVoipApi::ComparePeers(const PeerModel& lPeer, const PeerModel& rPeer)
{
	if (lPeer.Contact && rPeer.Contact)
	{
		if (lPeer.Contact->Id && lPeer.Contact->Id == rPeer.Contact->Id)
			return 0;
		return compare(*lPeer.Contact, *rPeer.Contact);
	}

	auto lPair = std::make_pair(lPeer.AddressType, UnFormatPhone(CutDomain(lPeer.Identity)));
	auto rPair = std::make_pair(rPeer.AddressType, UnFormatPhone(CutDomain(rPeer.Identity)));
	if (lPair < rPair)
		return -1;
	else if (rPair < lPair)
		return 1;
	return 0;
}

int ApplicationVoipApi::ComparePeerIds(const std::string& left, const std::string& right)
{
	PeerModel lPeer, rPeer;
	const bool ok = lPeer.FromStringPartial(left) && rPeer.FromStringPartial(right);	// throw asserts if something wrong
	return (ok ? ComparePeers(lPeer, rPeer) : 0);
}

bool ApplicationVoipApi::ExamineHistoryFilter(const HistoryFilterModel& f, const CallDbModel& h)
{
	using namespace std;
	using namespace std::rel_ops;
	bool selected = f.Peers.size() == 0;	// empty -> then any
	for (auto i = f.Peers.begin(); i != f.Peers.end(); ++i)
	{
		if (!ComparePeerIds(h.GetId(), *i))
		{
			selected = true;
			break;
		}
	}
	selected = selected
		&& !!(f.Selector & h.GetHistoryStatus())
		&& !!(f.Selector & h.GetHistoryAddressType())
		&& !!(f.Selector & h.GetHistoryEncryption())
		&& !!(f.Selector & h.GetHistorySource());

	if (selected && f.FromTime) {
		selected = *f.FromTime <= h.StartTime;
	}
	if (selected && f.ToTime) {
		selected = h.StartTime <= *f.ToTime;
	}
	return selected;
}

bool model::operator < (const PeerModel& left, const PeerModel& right)
{
	return ApplicationVoipApi::ComparePeers(left, right) < 0;
}

}

