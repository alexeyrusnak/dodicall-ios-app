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

#include "ApplicationContactsApi.h"

#include "UniversalProcessors.h"

#include "CallsModel.h"
#include "CallHistoryModel.h"
#include "VoipAccountModel.h"
#include "SoundDeviceModel.h"
#include "WavePlayer.h"

#include "ResultTypes.h"

#include <linphone/linphonecore.h>
#include "MiscUtils.h"

namespace dodicall
{

using namespace model;

enum CallOptions
{
	CallOptionsDefault = 1
};

class LinphoneCallRef: public MiscUtils::RefObject<LinphoneCall>
{
public:
	explicit LinphoneCallRef(LinphoneCall* call): MiscUtils::RefObject<LinphoneCall>(call, linphone_call_ref, linphone_call_unref) {}
};
typedef boost::shared_ptr<LinphoneCallRef> LinphoneCallRefPtr;

class DODICALLLOGICAPI ApplicationVoipApi: virtual public ApplicationContactsApi
{
private:
	LinphoneCore* mLc;

	mutable boost::recursive_mutex mMutex;
	DateType mIterateControlTime, mIterateLastTime;
	int mIterateCounter;

	std::deque<char> mDtmfDueue;

	class CallUserData
	{
	public:
		ContactModel Contact;
		CallIdType VirtualId;
        bool ShouldSendPushAboutMissedCall;

		CallUserData(const ContactModel& contact, const CallIdType& virtualId = "", const bool shouldSendPushAboutMissedCall = true);
	};

	class VirtualCall
	{
	public:
		const ContactModel Contact;
		const ContactsContactModel Identity;
		const CallIdType VirtualId;
		CallIdType SipId;
		boost::posix_time::ptime StartCallTime;
		boost::posix_time::ptime LastRealCallTime;
		DateType RingingStartTime;

		VirtualCall(const ContactModel& contact, const ContactsContactModel& identity);

		friend inline bool operator < (const VirtualCall& c1, const VirtualCall& c2)
		{
			return c1.VirtualId < c2.VirtualId;
		};
	};
	typedef std::set<VirtualCall> VirtualCallSet;
	VirtualCallSet mVirtualCalls;
	WavePlayerPtr mVirtualMusicPlayer;

	mutable DelayedProcessor<std::string> mCallsNotifyer;
	mutable DelayedProcessor<std::string> mCallHistoryNotifyer;
	mutable DelayedProcessor<std::string> mCallContactsRetriever;

	DateType mDelayedNotificationTime;

    bool WaitingForErrorTone;

public:
	bool Iterate(void);

	bool RetrieveVoipAccounts(VoipAccountModelList& result) const;
	void RefreshRegistration(void);

	bool StartCallToContact(ContactModel contact, CallOptions = CallOptionsDefault);
	bool StartCallToContactUrl(ContactModel contact, ContactsContactModel url, CallOptions = CallOptionsDefault);
	bool StartCallToContactUrl(ContactModel contact, std::string url, CallOptions = CallOptionsDefault);
	bool StartCallToUrl(std::string url, CallOptions = CallOptionsDefault);

	bool TransferCallToUrl(const CallIdType& callId, const std::string& url);
	bool TransferCall(const CallIdType& callId, const CallIdType& destId);

	bool GetCallHistory(CallHistoryModel&, const HistoryFilterModel&, bool loadDetails = true);		// Peers[] + (optional)History[]
	int	GetNumberOfMissedCalls(void) const;
	bool SetCallHistoryReaded(const HistoryFilterModel& filter);							// any matching to filter

	bool GetAllCalls(CallsModel& allCalls);			// current from divice

	bool AcceptCall(const CallIdType& callId, CallOptions);
	bool HangupCall(CallIdType callId);
	bool PauseCall(const CallIdType& callId) const;
	bool ResumeCall(const CallIdType& callId) const;
	void EnableMicrophone(bool enable) const;
	bool IsMicrophoneEnabled() const;

	bool PlayDtmf(char number);
	bool StopDtmf(void);

	DeviceSettingsModel GetDeviceSettings(void) const;
	bool GetSoundDevices(SoundDeviceModelSet&) const;
	bool SetPlaybackDevice(DeviceId) const;
	bool SetCaptureDevice(DeviceId) const;
	bool SetRingDevice(DeviceId) const;

	// levels: range 0..100; returns prev level. If out of range then just returns current level
	// for example: int GetPlaybackLevel() const { returns SetPlaybackLevel(-1); }
	// !!! ALL Set...Level() methods are deprecated by internal APIs (assuming to use system controls)
	int SetPlaybackLevel(int) const;
	int SetCaptureLevel(int) const;
	int SetRingLevel(int) const;

	static int ComparePeerIds(const std::string& left, const std::string& right);

protected:
	bool Prepare(void);
	void Start(void);
	void Stop(void);
	void Pause(void);
	void Resume(void);
	
	void TurnVoipSocket(bool on);

	void EnableCodecs();
	void ApplyVoipSettings(const UserSettingsModel& settings);

	void RecallToContact(const ContactModel& contact);
    
    void LoadMissedCallsFromServer();

	bool YetActiveCalls(LinphoneCore *lc = NULL, LinphoneCall *exceptCall = NULL, bool withVirtuals = true);

	ApplicationVoipApi(void);
	~ApplicationVoipApi(void);

private:
	void SetupAudio();
	void SetupVideo();
	void RegisterAccounts();

	bool EnableCodec(const CodecSettingModel& codec);

	bool DtmfIterate(void);

	LinphoneCallRefPtr StartCallToContactUrlInternal(ContactModel contact, ContactsContactModel url, CallOptions options, VirtualCall* pVirtualCall = NULL);
	LinphoneCallRefPtr StartCallToUrlInternal(std::string url, CallOptions options, bool checkActive = true);

	VirtualCall* CreateVirtualCall(const ContactModel& contact, const ContactsContactModel& url);
	bool StartVirtualCall(VirtualCall* pVirtualCall, LinphoneCall* call);
	void StopVirtualCall(const VirtualCall* pVirtualCall);
	void StopVirtualCallMusic(void);

	VirtualCall* FindVirtualById(const CallIdType& callId) const;
	VirtualCall* GetVirtualOfRealCall(const CallIdType& callId) const;

	void CheckVirtualCalls(void);
	
	CallModel LinphoneCallToModel(LinphoneCall* call);
	void RetrieveCallContactAndNotify(const CallIdType& callId);

	void UpdateHistory(LinphoneCallLog*, const CallModel&, bool blocked);
    void UpdateHistory(const CallDbModel &callModel);
    void UpdateHistory(const std::vector<CallDbModel> &callModels);
    
    void SendPushNotificationAboutMissedCall(std::string callId, std::string callIdentity);

	static int ComparePeers(const PeerModel& lPeer, const PeerModel& rPeer);
	static bool ExamineHistoryFilter(const HistoryFilterModel& f, const CallDbModel& h);


	static LinphoneCall* FindLinphoneCallById(LinphoneCore* lc, const CallIdType& callId);
	static std::string GetCallIdentity(LinphoneCall* call);
	static CallAddressType GetCallRemoteAddressType(LinphoneCall* call);
	static bool HangupCall(LinphoneCore* lc, LinphoneCall* call);
	
	static void SetCallUserData(LinphoneCall* call, const CallUserData& userData);
	static CallUserData* GetCallUserData(LinphoneCall* call);
	static void ClearCallUserData(LinphoneCall* call);

	static void LinphoneOnRegistrationChanged(LinphoneCore *lc, LinphoneProxyConfig *cfg, LinphoneRegistrationState state, const char *message);
	static void LinphoneOnCallStateChanged(LinphoneCore *lc, LinphoneCall *call, LinphoneCallState cstate, const char *msg);
	static void LinphoneOnCallStatisticsUpdated(LinphoneCore *lc, LinphoneCall *call, const LinphoneCallStats *stats);
	static void LinphoneOnCallEncryptionStateChanged(LinphoneCore *lc, LinphoneCall *call, bool_t on, const char *authentication_token);
	static void LinphoneOnNotificationReceived (LinphoneCore *lc, LinphoneEvent *lev, const char *notified_event, const LinphoneContent *body);
	static void LinphoneOnLog (OrtpLogLevel level, const char *format, va_list args);
    static void LinphoneOnSpeakerOn(LinphoneCore *lc, bool_t on);

	static const MSList* GetAvailableAudioCodecs(LinphoneCore* lc);
	static const MSList* GetAvailableVideoCodecs(LinphoneCore* lc);

	template<typename F> int CallHelper(const CallIdType& callId, F func) const;

	static void LogCall(Logger& logger, LinphoneCall *call, bool logDirection);

	friend bool model::operator < (const PeerModel& left, const PeerModel& right);
};

}
