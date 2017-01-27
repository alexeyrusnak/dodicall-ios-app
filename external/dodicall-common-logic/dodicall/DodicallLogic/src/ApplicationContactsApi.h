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

#include "ApplicationMessengerApi.h"

#include "UniversalProcessors.h"
#include "UniversalContainers.h"

#include "ContactModel.h" 

namespace dodicall
{

using namespace dbmodel;

double const SECONDSINHOUR = 3600000;

class DODICALLLOGICAPI ApplicationContactsApi: virtual public ApplicationMessengerApi, virtual public ApplicationServerApi
{
private:
	mutable boost::optional<SafeContainer<ContactModel, ContactModelSet>> mAllContactsCache;
	mutable bool mDbContactsCached;
	mutable SafeContainer<ContactModel, ContactModelSet> mUpdatedContactsCache;
	mutable SafeContainer<ContactModel, ContactModelSet> mDeletedContactsCache;

	typedef std::map<ContactDodicallIdType, ContactModel> RetrievedDirectoryContactMap;
	mutable SafeContainer<ContactModel, RetrievedDirectoryContactMap> mRetrievedDirectoryContacts;
	mutable SafeContainer<ContactModel, RetrievedDirectoryContactMap> mRetrievedByNumberDirectoryContacts;

	mutable boost::recursive_mutex mMutex;

	DelayedCaller mNotifyer;

	bool mDirectoryContactsSyncInProgress;
	SafeContainer<ContactDodicallIdType, ContactDodicallIdSet> mDirectoryContactsSyncNeeded;
	AutoInterruptableThreadPtr mDirectoryContactsSynchronizer;
	bool mNativeContactsSyncInProgress;
	bool mNativeContactsSyncNeeded;
	
	AutoInterruptableThreadPtr mNativeContactsSynchronizer;

	SafeContainer<ContactXmppIdType, ContactXmppIdSet> mContactAsks;
	AutoInterruptableThreadPtr mContactAsksSynchronizer;
	bool mContactAsksSyncInProgress;
	
	mutable boost::mutex mContactsMutex;
    
	SafeContainer<ContactDodicallIdType, ContactDodicallIdSet> mContactIdsWithDownloadedAvatars;
	mutable SafeContainer<ContactDodicallIdType, ContactDodicallIdSet> mContactIdsWithPermanentAvatars;

	SafeContainer<ContactXmppIdType, ContactXmppIdSet> mDeadXmppIds;

protected:
	mutable DelayedProcessor<ContactDodicallIdType> mAvatarDownloader;
	mutable DelayedProcessor<ContactDodicallIdType> mAsyncContactsUpdater;
	mutable DelayedProcessor<ContactDodicallIdType> mAsyncContactsUpdaterByXmppId;

public:
	ContactModel GetAccountData(bool format = false, bool useCache = true);

	bool GetAllContacts(ContactModelSet& result);
	ContactModel GetContactByIdFromCache(const ContactIdType& id);
	void RetrieveChangedContacts(ContactModelSet& updated, ContactModelSet& deleted) const;

	ContactModel SaveContact(ContactModel contact);
	bool DeleteContact(ContactModel contact);

	bool AnswerSubscriptionRequest(const ContactModel& contact, bool accept);

	void CachePhonebookContacts(const ContactModelSet& contacts, bool all = true);

	ContactModel RetriveContactByNumber(std::string number, bool prepare = true);

	void GetSubscriptionStatusesByXmppIds(const ContactXmppIdSet& ids, ContactSubscriptionMap& result) const;
    
    void DownloadAvatarForContactsWithDodicallIds(const ContactDodicallIdSet &contactIds);

protected:
	ApplicationContactsApi(void);
	~ApplicationContactsApi(void);

	void StartDirectoryContactsSynchronization(const char* dodicallId = 0);
	void StartNativeContactsSynchronization(void);
	void InterruptContactsSynchronization(void);
	bool ProcessDodicallContacts(ContactDodicallIdSet ids, const ContactDodicallIdSet& changedIds);
	bool ProcessNativeContacts(ContactModelSet contacts);

	void ProcessSubscriptionAsk(const ContactXmppIdType& xmppId);
	void RemoveSubscriptionAsk(const ContactXmppIdType& xmppId);

	ContactModel RetriveContactByDodicallId(const ContactDodicallIdType& id, bool forceServer = false);
	ContactModel GetContactByNumberFromCache(const std::string& number);
	ContactModel GetContactByPhonebookId(const PhonebookIdType& id) const;
	ContactModel RetriveContactByNumberLocal(const std::string& number, bool prepare = true);
	ContactModel RetrieveDirectoryContactByNumberIfNeeded(const std::string& number);
	ContactModel RetriveContactByNumberInternal(std::string number, bool prepare = true);

	ContactModel GetContactByXmppId(const ContactXmppIdType& id) const;
	void GetContactsByXmppIds(ContactXmppIdSet xmppIds, ContactModelSet& result) const;

	ContactsContactModel UnifyContactsContactPhone(const ContactsContactModel& ccm, bool format = false) const;
	void UnifyContactPhones(ContactModel& contact, bool format = false) const;

	void PrepareDodicallContacts(ContactModelSet &contacts);
    
    void PrepareRequestedContact(ContactModel& contact);
    void PrepareRequestedContacts(ContactModelSet& contacts);

	void QueryAvatarForPermanentContact(const ContactModel& contact) const;
	void QueryAvatarForPermanentContacts(const ContactModelSet& contacts) const;

	void Clear(void);

private:
	SafeContainer<ContactModel, ContactModelSet>& GetContactsCache(void) const;
	void CacheContact(ContactModel contact);
	void RemoveFromCache(const ContactModel& contact);

	void GetAllNativeContactsFromCache(ContactModelSet& result);

	bool SaveNativeContacts(const ContactModelSet& contacts, const ContactModelSet& unsynchronizedContacts);
	bool RetrieveAndSaveDirectoryContacts(const ContactDodicallIdSet& ids, const ContactDodicallIdSet& changedIds, const ContactModelSet& unsynchronizedContacts);

	boost::optional<ContactModel> FindDirectoryContactByNumberInCache(const std::string& number) const;
	bool IsNumberIn(const ContactsContactSet& contactsContact, const std::string& number) const;

	virtual ContactModel RetriveContactByXmppId(const ContactXmppIdType& id);
	virtual void RetriveContactsByXmppIds(ContactXmppIdSet xmppIds);

	static bool IsContactExpired(const ContactModel& contact);

	void DirectoryContactsSyncFunc(void);
	void NativeContactsSyncFunc(void);
	void ContactAsksProcessFunc(void);
    
	boost::filesystem::path GetAvatarPathForContact(const ContactModel& contact) const;
    void DownloadAvatarAndNotify(const ContactDodicallIdType &ContactId);

	template <class LS, class SS, class LW> boost::optional<ContactModel> RetrieveDirectoryContact(LS localSearcher, SS serverSearcher, LW localWriter, bool reSearch = false) const
	{
		boost::optional<ContactModel> contact = localSearcher();
		if (contact)
		{
			if ((posix_time_now() - contact->LastModifiedDate).total_seconds() > SECONDSINHOUR)
				reSearch = true;
		}
		else
			reSearch = true;
		
		if (reSearch)
		{
			boost::optional<ContactModel> found = serverSearcher();
			if (found)
			{
				contact = *found;
				contact->LastModifiedDate = posix_time_now();
				localWriter(*contact);
			}
		}
		return contact;
	}
};

LoggerStream operator << (LoggerStream s, const ContactsContactModel& contact);
LoggerStream operator << (LoggerStream s, const ContactModel& contact);

}
