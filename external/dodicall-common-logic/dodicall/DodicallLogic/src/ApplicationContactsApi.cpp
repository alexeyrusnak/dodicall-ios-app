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
#include "ApplicationContactsApi.h"

#include "LogManager.h"

#include "DateTimeUtils.h"
#include "StringUtils.h"
#include "FilesystemHelper.h"

namespace dodicall
{
    
ApplicationContactsApi::ApplicationContactsApi(void): mDbContactsCached(false),
	mDirectoryContactsSyncInProgress(false), mNativeContactsSyncInProgress(false), mNativeContactsSyncNeeded(false), mContactAsksSyncInProgress(false),
	mNotifyer([this]
	{
		if (!this->mUpdatedContactsCache.Empty() || !this->mDeletedContactsCache.Empty())
			this->DoCallback("Contacts", CallbackEntityIdsList());
	}),
	mAsyncContactsUpdater([this](const ContactDodicallIdSet& ids)
	{
		for (auto iter = ids.begin(); iter != ids.end(); iter++)
		{
			ContactModel contact = this->RetriveContactByDodicallId(*iter, true);
			if ((bool)contact)
			{
				this->mUpdatedContactsCache.Set(contact);
				this->mNotifyer.Call();
			}
		}
	}, 100),
	mAsyncContactsUpdaterByXmppId([this](const ContactXmppIdSet& ids)
	{
		for (auto iter = ids.begin(); iter != ids.end(); iter++)
		{
			ContactModel contact = this->RetriveContactByXmppId(*iter);
			if ((bool)contact && !contact.Synchronized)
			{
                this->mUpdatedContactsCache.Set(contact);
				this->mNotifyer.Call();
			}
		}
	}, 100),
	mAvatarDownloader([this](const ContactDodicallIdSet& ids)
	{
		for (auto iter = ids.begin(); iter != ids.end(); iter++)
			this->DownloadAvatarAndNotify(*iter);
	}, 100)
{
}
ApplicationContactsApi::~ApplicationContactsApi(void)
{
}

void ApplicationContactsApi::CachePhonebookContacts(const ContactModelSet& contacts, bool all)
{
	Logger& logger = LogManager::GetInstance().TraceLogger;
	logger(LogLevelDebug) << "Start caching " << (all ? "all " : "part ") << contacts.size() <<  " phonebook contacts";

	if (all)
	{
		SafeContainer<ContactModel, ContactModelSet>& cache = this->GetContactsCache();
		cache.EraseWhere([](const ContactModel& self)
		{
			return self.DodicallId.empty() && self.NativeId.empty() && !self.PhonebookId.empty();
		});
	}
	size_t totalSize = contacts.size();
	unsigned counter = 0;
	for (ContactModelSet::const_iterator iter = contacts.begin(); iter != contacts.end(); iter++)
	{
		ContactModel contact = *iter;
		if (!contact.Deleted)
		{
			this->UnifyContactPhones(contact);
			this->CacheContact(contact);
		}
		else
			this->RemoveFromCache(contact);
		if ((++counter) % 50 == 0)
		{
			logger(LogLevelDebug) << "Cached " << counter << " of " << totalSize <<  " phonebook contacts";
			boost::this_thread::sleep(boost::posix_time::millisec(100));
		}
	}
	this->mNotifyer.Call();
	
	logger(LogLevelDebug) << "End caching " << totalSize << " phonebook contacts";
}

void ApplicationContactsApi::PrepareDodicallContacts(ContactModelSet &contacts)
{
	const SafeContainer<ContactModel, ContactModelSet>& cache = this->GetContactsCache();

	ContactModelSet result;
	for (auto itRes = begin(contacts); itRes != end(contacts);)
	{
		bool found = false;
		if (!itRes->Id)
		{
			cache.ForEach([&contacts, &result, &itRes, &found](const ContactModel& self) 
			{
				if (self.DodicallId == itRes->DodicallId)
				{
					itRes = contacts.erase(itRes);
					result.insert(self);
					found = true;
					return false;
				}
				return true;
			});
		}
		if (!found)
		{
			result.insert(*itRes);
			++itRes;
		}
	}
	this->PrepareRequestedContacts(result);
	contacts = result;
}

ContactModel ApplicationContactsApi::GetAccountData(bool format, bool useCache)
{
	boost::optional<ContactModel> result;

	std::string uid = this->mApplicationServer.GetPartyUid();
	if (useCache || uid.empty())
	{
		ContactModel cached = this->mUserDb.GetAccountData();
		if ((bool)cached)
		{
			result = cached;
			if (this->IsContactExpired(cached))
				this->mAsyncContactsUpdater.Call(cached.DodicallId);
		}
	}
	if ((!result || !*result) && !uid.empty())
	{
		result = this->RetriveContactByDodicallId(uid.c_str(), true);
		if (result && *result)
			this->mAvatarDownloader.Call(result->DodicallId);
	}
	if (result && *result)
	{
		if (format)
			this->PrepareRequestedContact(*result);
		return *result;
	}
	return ContactModel();
}

bool ApplicationContactsApi::GetAllContacts(ContactModelSet& result)
{
	Logger& logger = LogManager::GetInstance().TraceLogger;
	logger(LogLevelDebug) << "Start getting all contacts";

	const SafeContainer<ContactModel, ContactModelSet>& cache = this->GetContactsCache();
	result = cache.Copy();
	this->PrepareRequestedContacts(result);

	logger(LogLevelDebug) << "End getting all contacts" << LoggerStream::endl << result;
	return true;
}

ContactModel ApplicationContactsApi::GetContactByIdFromCache(const ContactIdType& id)
{
    Logger& logger = LogManager::GetInstance().TraceLogger;
    logger(LogLevelDebug) << "Start getting contact by id from cache";

	const SafeContainer<ContactModel, ContactModelSet>& cache = this->GetContactsCache();
	ContactModel result;
	cache.ForEach([this, &id, &result](const ContactModel& self)
	{
		if (self.Id == id)
		{
			result = self;
			this->PrepareRequestedContact(result);
			return false;
		}
		return true;
	});

	if ((bool)result)
	{
		logger(LogLevelDebug) << "End getting contact by id from cache" << LoggerStream::endl << result;
		return result;
	}

	logger(LogLevelDebug) << "End getting contact by id from cache" << LoggerStream::endl;
	return ContactModel();
}

ContactModel ApplicationContactsApi::GetContactByNumberFromCache(const std::string& number)
{
	const SafeContainer<ContactModel, ContactModelSet>& cache = this->GetContactsCache();
	ContactModel result;
	cache.ForEach([this, &result, &number](const ContactModel& self) 
	{
		if (IsNumberIn(self.Contacts, number))
		{
			result = self;
			return false;
		}
		return true;
	});
	
	if ((bool)result)
		this->PrepareRequestedContact(result);
	return result;
}

ContactModel ApplicationContactsApi::GetContactByPhonebookId(const PhonebookIdType& id) const
{
	SafeContainer<ContactModel, ContactModelSet>& cache = this->GetContactsCache();
	ContactModel result;
	cache.ForEach([&result, &id](const ContactModel& self) 
	{
		if (self.PhonebookId == id)
		{
			result = self;
			return false;
		}
		return true;
	});

	return ((bool)result) ? result : ContactModel();
}

void ApplicationContactsApi::RetrieveChangedContacts(ContactModelSet& updated, ContactModelSet& deleted) const
{
	Logger& logger = LogManager::GetInstance().TraceLogger;
	logger(LogLevelDebug) << "Start retrieving changed contacts";

	this->mUpdatedContactsCache.Swap(updated);
	this->mDeletedContactsCache.Swap(deleted);

	logger(LogLevelDebug) << "End retrieving changed contacts" << LoggerStream::endl
		<< "updated:" << LoggerStream::endl << updated << LoggerStream::endl << "deleted:" << LoggerStream::endl << deleted;
}

ContactModel ApplicationContactsApi::SaveContact(ContactModel contact)
{
	Logger& logger = LogManager::GetInstance().TraceLogger;
	logger(LogLevelDebug) << "Start save contact " << LoggerStream::endl << contact;

	this->UnifyContactPhones(contact);
	if (this->mUserDb.SaveContact(contact))
	{
		this->CacheContact(contact);
		this->mNotifyer.Call();

		if (!contact.Synchronized)
		{
			if (!contact.DodicallId.empty())
				this->StartDirectoryContactsSynchronization(contact.DodicallId.c_str());
			else
				this->StartNativeContactsSynchronization();
		}
	}
	this->PrepareRequestedContact(contact);
	logger(LogLevelDebug) << "End save contact with result " << LoggerStream::endl << contact;
	return contact;
}
bool ApplicationContactsApi::DeleteContact(ContactModel contact)
{
	Logger& logger = LogManager::GetInstance().TraceLogger;
	logger(LogLevelDebug) << "Start delete contact " << LoggerStream::endl << contact;

	bool result = this->mUserDb.DeleteContact(contact);
	if (result)
	{
		this->RemoveFromCache(contact);
        
        boost::filesystem::path avatarPath = this->GetAvatarPathForContact(contact);
        if(boost::filesystem::exists(avatarPath))
            boost::filesystem::remove(avatarPath);
        
		this->mNotifyer.Call();

		if (!contact.Synchronized)
		{
			if (!contact.DodicallId.empty())
				this->StartDirectoryContactsSynchronization(contact.DodicallId.c_str());
			else
				this->StartNativeContactsSynchronization();
		}
	}
	logger(LogLevelDebug) << "End delete contact with result " << result;
	return result;
}

bool ApplicationContactsApi::AnswerSubscriptionRequest(const ContactModel& contact, bool accept)
{
	Logger& logger = LogManager::GetInstance().TraceLogger;
	logger(LogLevelDebug) << "Start answer subscription request " << accept << LoggerStream::endl << contact;

	bool result = false;
	ContactXmppIdType xmppId = contact.GetXmppId();
	if (!xmppId.empty())
	{
		result = ApplicationMessengerApi::AnswerSubscriptionRequestIfNeeded(xmppId, accept);
		if (!accept && result && !contact.Id)
			this->RemoveFromCache(contact);
	}
	logger(LogLevelDebug) << "End answer subscription request with result " << result;
	return result;
}

void ApplicationContactsApi::StartDirectoryContactsSynchronization(const char* dodicallId)
{
	if (dodicallId)
		this->mDirectoryContactsSyncNeeded.Set(dodicallId);

	boost::lock_guard<boost::mutex> _lock(this->mContactsMutex);
	if (!this->mDirectoryContactsSyncInProgress)
	{
		this->mDirectoryContactsSyncInProgress = true;
		this->mDirectoryContactsSynchronizer = this->mThreadsOnlyThenLoggedIn.StartThread([this]
		{
			this->DirectoryContactsSyncFunc();
		});
		LogManager::GetInstance().TraceLogger(LogLevelDebug) << "Thread for directory contacts synchronization created with id = " << this->mDirectoryContactsSynchronizer->get_id();
	}
}
void ApplicationContactsApi::StartNativeContactsSynchronization()
{
	boost::lock_guard<boost::mutex> _lock(this->mContactsMutex);
	if (!this->mNativeContactsSyncInProgress)
	{
		this->mNativeContactsSyncInProgress = true;
		this->mNativeContactsSyncNeeded = false;
		this->mNativeContactsSynchronizer = this->mThreadsOnlyThenLoggedIn.StartThread([this]
		{
			this->NativeContactsSyncFunc();
		});
		LogManager::GetInstance().TraceLogger(LogLevelDebug) << "Thread for native contacts synchronization created with id = " << this->mNativeContactsSynchronizer->get_id();
	}
	else
	{
		this->mNativeContactsSyncNeeded = true;
		LogManager::GetInstance().TraceLogger(LogLevelDebug) << "Flag for native contacts synchronization is set to " << this->mNativeContactsSyncNeeded;
	}
}
void ApplicationContactsApi::InterruptContactsSynchronization(void)
{
	if (this->mDirectoryContactsSynchronizer && this->mDirectoryContactsSyncInProgress)
		this->mDirectoryContactsSynchronizer->interrupt();
	if (this->mNativeContactsSynchronizer && this->mNativeContactsSyncInProgress)
		this->mNativeContactsSynchronizer->interrupt();
	if (this->mContactAsksSynchronizer && this->mContactAsksSyncInProgress)
		this->mContactAsksSynchronizer->interrupt();

	this->mDirectoryContactsSyncNeeded.Clear();
	this->mNativeContactsSyncNeeded = false;
	this->mContactAsks.Clear();
}

bool ApplicationContactsApi::ProcessDodicallContacts(ContactDodicallIdSet ids, const ContactDodicallIdSet& changedIds)
{
	Logger& logger = LogManager::GetInstance().TraceLogger;
	logger(LogLevelDebug) << "Start process directory contacts " << LoggerStream::endl << changedIds << LoggerStream::endl;

	ContactModelSet unsynchronizedContacts;
	if (this->mUserDb.GetUnsynchronizedDirectoryContacts(unsynchronizedContacts) && !unsynchronizedContacts.empty())
	{
		logger(LogLevelDebug) << "Unsynchronized dodicall contacts detected" << LoggerStream::endl << unsynchronizedContacts;

		ContactModelSet contactsToUpload;
		for (ContactModelSet::const_iterator iter = unsynchronizedContacts.begin(); iter != unsynchronizedContacts.end(); iter++)
		{
			bool found = (ids.find(iter->DodicallId) != ids.end());
			if (iter->Deleted)
			{
				if(found)
					ids.erase(iter->DodicallId);
			}
			else if(found)
			{
				contactsToUpload.insert(*iter);
				ids.erase(iter->DodicallId);
			}
			else
				contactsToUpload.insert(*iter);
		}
		for (ContactDodicallIdSet::const_iterator iter = ids.begin(); iter != ids.end(); iter++)
		{
			ContactModel emptyContact;
			emptyContact.DodicallId = *iter;
			contactsToUpload.insert(emptyContact);
		}
		if (!this->StoreDirectoryContacts(contactsToUpload, changedIds))
			return false;
		for (ContactModelSet::const_iterator iter = contactsToUpload.begin(); iter != contactsToUpload.end(); iter++)
		{
			if (ids.find(iter->DodicallId) == ids.end())
				ids.insert(iter->DodicallId);
		}
	}
	bool res = this->RetrieveAndSaveDirectoryContacts(ids,changedIds,unsynchronizedContacts);
    
    std::vector<std::string>  blackList;
    std::vector<std::string>  whiteList;

	SafeContainer<ContactModel, ContactModelSet>& cache = this->GetContactsCache();
	cache.ForEach([&blackList, &whiteList](const ContactModel& self)
	{
		if (self.DodicallId.empty())
		{
			if (self.Blocked)
				blackList.push_back(self.DodicallId);
			if (self.White)
				whiteList.push_back(self.DodicallId);
		}
		return true;
	});

	boost::this_thread::interruption_point();

	BaseResult saveListsRes = SetWhiteAndBlackLists(blackList, whiteList);
    if ( !saveListsRes.Success )
        logger(LogLevelWarning) << "Failed to save white and black lists to stubs server with error code" << saveListsRes.ErrorCode;
    
	logger(LogLevelDebug) << "End process directory contacts with result " << res;
	return res;
}
bool ApplicationContactsApi::ProcessNativeContacts(ContactModelSet contacts)
{
	Logger& logger = LogManager::GetInstance().TraceLogger;
	logger(LogLevelDebug) << "Start process native contacts";

	ContactModelSet unsynchronizedContacts;
	if (this->mUserDb.GetUnsynchronizedNativeContacts(unsynchronizedContacts) && !unsynchronizedContacts.empty())
	{
		logger(LogLevelDebug) << "Unsynchronized native contacts detected" << LoggerStream::endl << unsynchronizedContacts;
		for (ContactModelSet::const_iterator iter = unsynchronizedContacts.begin(); iter != unsynchronizedContacts.end(); iter++)
		{
			contacts.erase(*iter);
			if(!iter->Deleted)
				contacts.insert(*iter);
		}
		if (!this->StoreNativeContacts(contacts))
			return false;
	}
	boost::this_thread::interruption_point();
	bool res = this->SaveNativeContacts(contacts,unsynchronizedContacts);
	logger(LogLevelDebug) << "End process native contacts with result " << res;
	return res;
}

void ApplicationContactsApi::ProcessSubscriptionAsk(const ContactXmppIdType& xmppId)
{
	this->mContactAsks.Set(xmppId);
	if (!this->mContactAsksSyncInProgress)
	{
		this->mContactAsksSyncInProgress = true;
		this->mContactAsksSynchronizer = this->mThreadsOnlyThenLoggedIn.StartThread([this]
		{
			this->ContactAsksProcessFunc();
		});
	}
}

void ApplicationContactsApi::RemoveSubscriptionAsk(const ContactXmppIdType& xmppId)
{
	if (this->mContactAsks.Exists(xmppId))
		this->mContactAsks.Erase(xmppId);

	SafeContainer<ContactModel, ContactModelSet>& cache = GetContactsCache();
	ContactModel found;

	cache.ForEach([this, xmppId, &found](const ContactModel& contact)
	{
		if (!contact.Id && contact.GetXmppId() == xmppId)
		{
			found = contact;
			return false;
		}
		return true;
	});
	if ((bool)found)
	{
		this->mUpdatedContactsCache.Erase(found);
		this->mDeletedContactsCache.Set(found);
		this->RemoveRosterRecord(xmppId);
		cache.Erase(found);
		this->mNotifyer.Call();
	}
}

ContactModel ApplicationContactsApi::RetriveContactByXmppId(const ContactXmppIdType& id)
{
	ContactModel contact = this->mUserDb.GetContactByXmppId(id);
	if ((bool)contact)
	{
		if (!contact.Id && this->IsContactExpired(contact))
			this->mAsyncContactsUpdater.Call(contact.DodicallId);
	}
	else
	{
		boost::optional<ContactModel> found = this->mApplicationServer.FindContactByXmppId(id.c_str());
		if (found)
		{
			if (*found)
			{
				contact = *found;
				this->mUserDb.SaveContactInCache(*found);
			}
			else
				this->mDeadXmppIds.Set(id);
		}
	}
	return contact;
}

ContactModel ApplicationContactsApi::GetContactByXmppId(const ContactXmppIdType& id) const
{
	ContactModel contact = this->mUserDb.GetContactByXmppId(id);
	if ((bool)contact)
	{
		if (!contact.Id && this->IsContactExpired(contact))
			this->mAsyncContactsUpdater.Call(contact.DodicallId);
	}
	else  if (!this->mDeadXmppIds.Exists(id))
		this->mAsyncContactsUpdaterByXmppId.Call(id);
	return contact;
}

void ApplicationContactsApi::RetriveContactsByXmppIds(ContactXmppIdSet xmppIds)
{
	ContactModelSet result;
	if (this->mUserDb.GetContactsByXmppIds(xmppIds, result))
	{
		for (auto iter = result.begin(); iter != result.end(); iter++)
		{
			if (!iter->Id && this->IsContactExpired(*iter))
				this->mAsyncContactsUpdater.Call(iter->DodicallId);
			xmppIds.erase(iter->GetXmppId());
		}
		
		for (auto iter = xmppIds.begin(); iter != xmppIds.end(); iter++)
		{
			boost::optional<ContactModel> found = this->mApplicationServer.FindContactByXmppId(iter->c_str());
			if (found)
			{
				if (*found)
				{
					result.insert(*found);
					this->mUserDb.SaveContactInCache(*found);
				}
				else
					this->mDeadXmppIds.Set(*iter);
			}
		}
	}
}

void ApplicationContactsApi::GetContactsByXmppIds(ContactXmppIdSet xmppIds, ContactModelSet& result) const
{
	if (this->mUserDb.GetContactsByXmppIds(xmppIds, result))
	{
		for (auto iter = result.begin(); iter != result.end(); iter++)
		{
			if (!iter->Id && this->IsContactExpired(*iter))
				this->mAsyncContactsUpdater.Call(iter->DodicallId);
			xmppIds.erase(iter->GetXmppId());
		}

		for (auto iter = xmppIds.begin(); iter != xmppIds.end(); iter++)
			if (!this->mDeadXmppIds.Exists(*iter))
				this->mAsyncContactsUpdaterByXmppId.Call(*iter);
	}
}

ContactModel ApplicationContactsApi::RetriveContactByDodicallId(const ContactDodicallIdType& id, bool forceServer)
{
	ContactModel contact;
	if (!forceServer)
		contact = this->mUserDb.GetContactByDodicallId(id);
	
	if ((bool)contact)
	{
		if (!contact.Id && this->IsContactExpired(contact))
			this->mAsyncContactsUpdater.Call(contact.DodicallId);
	}
	else
	{
		boost::optional<ContactModel> found = this->mApplicationServer.FindContactByDodicallId(id.c_str());
		if (found && *found)
		{
			contact = *found;
			this->mUserDb.SaveContactInCache(*found);
		}
	}
	return contact;
}

ContactModel ApplicationContactsApi::RetriveContactByNumberLocal(const std::string& number, bool prepare)
{
	std::string pureNumber = CutDomain(number);
	ContactModel contact = GetContactByNumberFromCache(number);
	if ((bool)contact)
	{
		if (contact.DodicallId.empty())
		{
			boost::optional<ContactModel> dodiContact = this->FindDirectoryContactByNumberInCache(number);
			if (!dodiContact && pureNumber != number)
				dodiContact = this->FindDirectoryContactByNumberInCache(pureNumber);
			if ((bool)dodiContact)
				contact = *dodiContact;
		}
	}
	else
	{
		boost::optional<ContactModel> dodiContact = this->FindDirectoryContactByNumberInCache(number);
		if (dodiContact)
			contact = *dodiContact;
		if (!contact && pureNumber != number)
			return this->RetriveContactByNumberLocal(pureNumber);
	}

	if ((bool)contact && prepare)
		this->PrepareRequestedContact(contact);
	return contact;
}

SafeContainer<ContactModel, ContactModelSet>& ApplicationContactsApi::GetContactsCache(void) const
{
	static boost::mutex gMutex;
	boost::lock_guard<boost::mutex> _lock(gMutex);

	if (!this->mAllContactsCache)
		this->mAllContactsCache = SafeContainer<ContactModel, ContactModelSet>();
	if (!this->mDbContactsCached && this->mUserDb.IsOpened())
	{
		ContactModelSet contacts = this->mAllContactsCache->Copy();
		this->mUserDb.GetAllContacts(contacts);
		this->mDbContactsCached = true;
		this->mAllContactsCache->Swap(contacts);
	}
	return *this->mAllContactsCache;
}

void ApplicationContactsApi::CacheContact(ContactModel contact)
{
	SafeContainer<ContactModel, ContactModelSet>& cache = this->GetContactsCache();
	cache.Set(contact);
    
	this->PrepareRequestedContact(contact);
	this->mUpdatedContactsCache.Set(contact);
	this->mDeletedContactsCache.Erase(contact);
}

void ApplicationContactsApi::RemoveFromCache(const ContactModel& contact)
{
	this->GetContactsCache().Erase(contact);
	this->mUpdatedContactsCache.Erase(contact);
	this->mDeletedContactsCache.Set(contact);
}

void ApplicationContactsApi::GetAllNativeContactsFromCache(ContactModelSet& result)
{
	const SafeContainer<ContactModel, ContactModelSet>& cache = this->GetContactsCache();
	cache.ForEach([&result](const ContactModel& self)
	{
		if (!self.NativeId.empty())
			result.insert(self);
		return true;
	});
}

bool ApplicationContactsApi::SaveNativeContacts(const ContactModelSet& contacts, const ContactModelSet& unsynchronizedContacts)
{
	ContactModelSet nativeContacts;
	this->mUserDb.GetAllNativeContacts(nativeContacts);
	
	bool result = true;
	bool containsLegacy = false;
	for (ContactModelSet::const_iterator iter = contacts.begin(); iter != contacts.end(); iter++)
	{
		if (iter->NativeId.empty())
			containsLegacy = true;
		ContactModel contact = *iter;
		contact.Synchronized = true;
		result = result && this->SaveContact(contact).Id;
		nativeContacts.erase(*iter);
	}
	for (ContactModelSet::const_iterator diter = nativeContacts.begin(); diter != nativeContacts.end(); diter++)
		if (diter->Synchronized)
			result = result && this->DeleteContact(*diter);
	for (ContactModelSet::const_iterator diter = unsynchronizedContacts.begin(); diter != unsynchronizedContacts.end(); diter++)
		if (!diter->Id)
			result = result && this->DeleteContact(*diter);

	if (containsLegacy)
	{
		nativeContacts.clear();
		this->GetAllNativeContactsFromCache(nativeContacts);
		return this->StoreNativeContacts(nativeContacts);
	}
	return result;
}

bool ApplicationContactsApi::RetrieveAndSaveDirectoryContacts(const ContactDodicallIdSet& ids, const ContactDodicallIdSet& changedIds, const ContactModelSet& unsynchronizedContacts)
{
	Logger& logger = LogManager::GetInstance().TraceLogger;
	logger(LogLevelDebug) << "Start retrieve and save directory contacts";

	ContactModelSet directoryContacts;
	this->mUserDb.GetDirectoryContacts(directoryContacts);

	bool result = true;
	ContactXmppIdSet xmppIds;
	for (ContactDodicallIdSet::const_iterator iter = ids.begin(); iter != ids.end(); iter++)
	{
		boost::this_thread::interruption_point();

		ContactModel alreadyExists;
		for (ContactModelSet::iterator diter = directoryContacts.begin(); diter != directoryContacts.end(); diter++)
		{
			if (diter->DodicallId == *iter)
			{
				alreadyExists = *diter;
				directoryContacts.erase(*diter);
				break;
			}
		}

		bool changedOne = (changedIds.empty() || changedIds.find(*iter) != changedIds.end());
		boost::optional<ContactModel> found;
		if (!changedOne)
		{
			ContactModel fromDb = this->mUserDb.GetContactByDodicallId(iter->c_str());
			if ((bool)fromDb && !this->IsContactExpired(fromDb))
				found = fromDb;
		}
		if (!found)
			found = this->mApplicationServer.FindContactByDodicallId(iter->c_str());
		
		if (found && *found)
		{
			ContactModel contact = *found;
			if (!contact.Id)
				this->ApplyDirectoryContactChanges(contact);

			if (!contact.DodicallId.empty())
				xmppIds.insert(contact.GetXmppId());

			if (!contact.Iam && !contact.DodicallId.empty() && (!alreadyExists || !equals(alreadyExists, contact) || !contact.Synchronized))
			{
				contact.Synchronized = true;
				if (!(contact = this->SaveContact(contact)))
					result = false;
			}

			ContactXmppIdType xmppId = contact.GetXmppId();
			if (!xmppId.empty())
			{
                this->SendSubscriptionRequestIfNeeded(xmppId, true);
				this->AnswerSubscriptionRequest(contact, !contact.Blocked);
			}
			if (!contact.DodicallId.empty())
				this->mAvatarDownloader.Call(contact.DodicallId);
		}
	}
	for (ContactModelSet::iterator diter = directoryContacts.begin(); diter != directoryContacts.end(); diter++)
		if (diter->Synchronized)
			result = result && this->DeleteContact(*diter);
	for (ContactModelSet::const_iterator diter = unsynchronizedContacts.begin(); diter != unsynchronizedContacts.end(); diter++)
		if (!diter->Id)
			result = result && this->DeleteContact(*diter);
	
	this->ClearRoster(xmppIds);
	
	logger(LogLevelDebug) << "End retrieve and save directory contacts";
	return result;
}

ContactModel ApplicationContactsApi::RetrieveDirectoryContactByNumberIfNeeded(const std::string& number)
{
	boost::optional<ContactModel> found = this->RetrieveDirectoryContact([this, number]
	{
		return this->FindDirectoryContactByNumberInCache(number);
	},
	[this, number]
	{
		if (number.length() > 3)
			return this->mApplicationServer.FindContactByNumber(number.c_str());
		return boost::optional<ContactModel>();
	},
	[this, number](const ContactModel& contact)
	{

		boost::unique_lock<boost::recursive_mutex> _lock(this->mMutex);
        if(contact)
            this->mRetrievedByNumberDirectoryContacts.Set(std::pair<ContactDodicallIdType, ContactModel>(number, contact));

		if (!contact.DodicallId.empty())
			this->mRetrievedDirectoryContacts.Set(std::pair<ContactDodicallIdType, ContactModel>(contact.DodicallId, contact));   
	});
	return (found ? *found : ContactModel());
}

ContactModel ApplicationContactsApi::RetriveContactByNumberInternal(std::string number, bool prepare)
{
	Logger& logger = LogManager::GetInstance().TraceLogger;
	logger(LogLevelDebug) << "Start retrieving contact by number '" << number << "'";

	number = this->UnFormatPhone(number);
	ContactModel result = this->RetriveContactByNumberLocal(number, prepare);
	if (!result || result.DodicallId.empty())
	{
		ContactModel fromDirectory = this->RetrieveDirectoryContactByNumberIfNeeded(number);
		if ((bool)fromDirectory)
		{
			result = fromDirectory;
			if (prepare)
				this->PrepareRequestedContact(result);
		}
	}
	logger(LogLevelDebug) << "End retrieving contact by number" << result;

	return result;
}

ContactModel ApplicationContactsApi::RetriveContactByNumber(std::string number, bool prepare)
{
	ContactModel result = this->RetriveContactByNumberInternal(number, prepare);
	if (!result.DodicallId.empty())
		this->mAvatarDownloader.Call(result.DodicallId);
	return result;
}

boost::optional<ContactModel> ApplicationContactsApi::FindDirectoryContactByNumberInCache(const std::string& number) const
{
	if(this->mRetrievedByNumberDirectoryContacts.Exists(number))
		return this->mRetrievedByNumberDirectoryContacts.Get(number);

	boost::optional<ContactModel> result;
	this->mRetrievedDirectoryContacts.ForEach([this, &result, &number](const std::pair<ContactDodicallIdType, ContactModel> &self)
	{
		if (IsNumberIn(self.second.Contacts, number))
		{
			result = self.second;
			return false;
		}
		return true;
	});
	return result;
}

bool ApplicationContactsApi::IsNumberIn(const ContactsContactSet& contactsContact, const std::string& number) const
{
	std::string pureNumber = CutDomain(number);
	for (auto iter = contactsContact.begin(); iter != contactsContact.end(); iter++)
		if (number == iter->Identity || !pureNumber.empty() && pureNumber == CutDomain(iter->Identity))
			return true;
	return false;
}

bool ApplicationContactsApi::IsContactExpired(const ContactModel& contact)
{
	return ((posix_time_now() - contact.LastModifiedDate).total_seconds() >= 3600);
}

ContactsContactModel ApplicationContactsApi::UnifyContactsContactPhone(const ContactsContactModel& ccm, bool format) const
{
	ContactsContactModel result = ccm;
	if (format)
		result.Identity = this->FormatPhone(result.Identity, result.Type);
	else
		result.Identity = this->UnFormatPhone(result.Identity);
	return result;
}

void ApplicationContactsApi::UnifyContactPhones(ContactModel& contact, bool format) const
{
	for (ContactsContactSet::iterator iter = contact.Contacts.begin(); iter != contact.Contacts.end();)
	{
		if (iter->Type == ContactsContactSip || iter->Type == ContactsContactPhone)
		{
			ContactsContactModel ccm = this->UnifyContactsContactPhone(*iter, format);
			if (ccm.Identity != iter->Identity)
			{
				contact.Contacts.erase(iter);
				contact.Contacts.insert(ccm);
				iter = contact.Contacts.begin();
				continue;
			}
		}
		iter++;
	}
}


void ApplicationContactsApi::PrepareRequestedContact(ContactModel& contact)
{
	bool found = false;
	ContactsContactSet::iterator citer = contact.Contacts.begin();
	while (citer != contact.Contacts.end())
	{
		if (citer->Favourite)
		{
			found = true;
			break;
		}
		citer++;
	}
	if (!found && !contact.Contacts.empty())
		((ContactsContactModel&)*contact.Contacts.begin()).Favourite = true;
	this->UnifyContactPhones(contact, true);
	this->FillContactSubscriptionStatus(contact);
    
    if(!contact.DodicallId.empty())
    {
        boost::filesystem::path avatarPath = this->GetAvatarPathForContact(contact);
        
		if (boost::filesystem::exists(avatarPath))
		{
			if (boost::filesystem::file_size(avatarPath) != 0)
				contact.AvatarPath = avatarPath.string();
			else
				contact.AvatarPath = "";
		}
    }
}

void ApplicationContactsApi::PrepareRequestedContacts(ContactModelSet& contacts)
{
	for (ContactModelSet::iterator iter = contacts.begin(); iter != contacts.end(); iter++)
		PrepareRequestedContact((ContactModel&)*iter);
}

void ApplicationContactsApi::QueryAvatarForPermanentContact(const ContactModel& contact) const
{
	if (!contact.DodicallId.empty())
	{
		if (!(contact.Id || contact.Iam))
			this->mContactIdsWithPermanentAvatars.Set(contact.DodicallId);
		this->mAvatarDownloader.Call(contact.DodicallId);
	}
}

void ApplicationContactsApi::QueryAvatarForPermanentContacts(const ContactModelSet& contacts) const
{
	for (auto iter = contacts.begin(); iter != contacts.end(); iter++)
		this->QueryAvatarForPermanentContact(*iter);
}

void ApplicationContactsApi::GetSubscriptionStatusesByXmppIds(const ContactXmppIdSet& ids, ContactSubscriptionMap& result) const
{
	Logger& logger = LogManager::GetInstance().TraceLogger;
	logger(LogLevelDebug) << "Start GetSubscriptionStatusesByXmppIds " << ids;

	SafeContainer<ContactModel, ContactModelSet>& cache = this->GetContactsCache();

	for (auto iter = ids.begin(); iter != ids.end(); iter++)
	{
		bool exists = false;
		cache.ForEach([this, &iter, &result, &exists](ContactModel self)
		{
			if (self.GetXmppId() == *iter)
			{
				this->FillContactSubscriptionStatus(self);
				result[*iter] = self.Subscription;
				exists = true;
				return false;
			}
			return false;
		});
		
		if (!exists)
		{
			boost::optional<ContactSubscriptionModel> found = this->GetRosterRecord(*iter);
			if (!found)
				result[*iter] = ContactSubscriptionModel(ContactSubscriptionStateNone);
			else
				result[*iter] = *found;
		}
	}
	logger(LogLevelDebug) << "End GetSubscriptionStatusesByXmppIds with result " << result;
}

void ApplicationContactsApi::DirectoryContactsSyncFunc(void)
{
	this->WaitForRoster();

	Logger& logger = LogManager::GetInstance().TraceLogger;

	bool firstIteration = true;
	logger(LogLevelDebug) << "Start directory contacts synchronization";

	try
	{
		while (!this->mDirectoryContactsSyncNeeded.Empty() || firstIteration)
		{
			if (firstIteration)
				firstIteration = false;

			ContactDodicallIdSet ids;
			ContactDodicallIdSet changedIds;
			this->mDirectoryContactsSyncNeeded.Swap(changedIds);

			if (this->RetrieveDirectoryContacts(ids))
			{
				boost::this_thread::interruption_point();
				if (this->ProcessDodicallContacts(ids, changedIds))
					this->mUserDb.OptimizeContactsCache();
			}
		}
		logger(LogLevelDebug) << "End directory contacts synchronization";
	}
	catch (const boost::thread_interrupted&)
	{
		logger(LogLevelDebug) << "Directory contacts synchronization interrupted";
	}
	{
		boost::lock_guard<boost::mutex> _lock(this->mContactsMutex);
		this->mDirectoryContactsSyncInProgress = false;
	}
}

void ApplicationContactsApi::NativeContactsSyncFunc(void)
{
	Logger& logger = LogManager::GetInstance().TraceLogger;

	bool firstItaration = true;
	logger(LogLevelDebug) << "Start native contacts synchronization";

	try
	{
		while (firstItaration || this->mNativeContactsSyncNeeded)
		{
			firstItaration = false;
			{
				boost::lock_guard<boost::mutex> _lock(this->mContactsMutex);
				this->mNativeContactsSyncNeeded = false;
			}
			ContactModelSet contacts;
			if (this->RetrieveNativeContacts(contacts))
			{
				boost::this_thread::interruption_point();
				this->ProcessNativeContacts(contacts);
			}
		}
		logger(LogLevelDebug) << "End native contacts synchronization";
	}
	catch (const boost::thread_interrupted&)
	{
		logger(LogLevelDebug) << "Native contacts synchronization interrupted";
	}
	{
		boost::lock_guard<boost::mutex> _lock(this->mContactsMutex);
		this->mNativeContactsSyncInProgress = false;
	}
}

void ApplicationContactsApi::ContactAsksProcessFunc(void)
{
	this->WaitForRoster();

	try
	{
		while (true)
		{
			ContactXmppIdSet asks;
			this->mContactAsks.Swap(asks);
			if (asks.empty())
				break;

			for (ContactXmppIdSet::const_iterator iter = asks.begin(); iter != asks.end(); iter++)
			{
				ContactModel contact = this->mUserDb.GetContactByXmppId(iter->c_str());
				if ((bool)contact && contact.Id)
				{
					this->AnswerSubscriptionRequest(contact, true);
					this->SendPresence();
				}
				else
				{
					boost::optional<ContactModel> found = this->mApplicationServer.FindContactByXmppId(iter->c_str());
					if (found)
						contact = *found;
					if (!contact.DodicallId.empty())
					{
						contact.Subscription.SubscriptionState = ContactSubscriptionStateTo;
						contact.Subscription.AskForSubscription = false;
						contact.Subscription.SubscriptionStatus = this->GetSubscriptionStatus(contact.GetXmppId());
						this->ChangeContactSubscriptionAndProcess(contact.GetXmppId(), contact.Subscription);
						this->CacheContact(contact);
						this->mNotifyer.Call();
					}
				}
				boost::this_thread::interruption_point();
			}
		}

	}
	catch (const boost::thread_interrupted&)
	{
	}
	{
		boost::lock_guard<boost::mutex> _lock(this->mContactsMutex);
		this->mContactAsksSyncInProgress = false;
	}
}

boost::filesystem::path ApplicationContactsApi::GetAvatarPathForContact(const ContactModel& contact) const
{
	if (contact.DodicallId.empty())
		return boost::filesystem::path("");

	boost::filesystem::path permanentPath = this->mDeviceModel.UserDataPath / "Avatars" / contact.DodicallId;
	boost::filesystem::path tempPath = this->mDeviceModel.TempDataPath / "Avatars" / contact.DodicallId;

	if (contact.Id || contact.Iam
		|| this->mContactIdsWithPermanentAvatars.Exists(contact.DodicallId))
	{
		if (boost::filesystem::exists(tempPath))
			boost::filesystem::rename(tempPath, permanentPath);
		return permanentPath;
	}
	
	if (boost::filesystem::exists(permanentPath))
		boost::filesystem::rename(permanentPath, tempPath);
	return tempPath;
}

void ApplicationContactsApi::DownloadAvatarAndNotify(const ContactDodicallIdType &ContactId) 
{
    ContactModel contact = this->RetriveContactByDodicallId(ContactId);
    
    if(contact)
    {
		bool download = (!mContactIdsWithDownloadedAvatars.Exists(contact.DodicallId));
		if (download)
		{
			boost::filesystem::path downloadPath = this->GetAvatarPathForContact(contact);

			DownloadFileResult result = this->mIssAccessor.DownloadFile("/storage-service/v1/party/" + contact.DodicallId + "/avatar", downloadPath.string());

			if (result.Success)
			{
				if (result.FileStatus == DownloadFileStatusDownloaded)
				{
					if (result.Headers.find("X-Avatar-Type") != result.Headers.end() &&
						result.Headers["X-Avatar-Type"].find("default") != std::string::npos)
					{
						time_t modifiedTime = boost::filesystem::last_write_time(downloadPath);
						std::ofstream fs;
						FilesystemHelper::OpenStream(fs, downloadPath, std::ios_base::out);
						if (fs.is_open())
						{
							fs.close();
							boost::filesystem::last_write_time(downloadPath, modifiedTime);
						}
					}

					this->PrepareRequestedContact(contact);
					this->mUpdatedContactsCache.Set(contact);

					this->mNotifyer.Call();
					LogManager::GetInstance().TraceLogger(LogLevelDebug) << "Avatar downloaded for " << LoggerStream::endl << contact;
				}
				if (result.LastModifiedProblemDetected)
					this->mContactIdsWithDownloadedAvatars.Set(contact.DodicallId);
			}
		}
		else
			LogManager::GetInstance().TraceLogger(LogLevelWarning) << "Force skip avatar downloading during LastModified problem for " << LoggerStream::endl << contact;
    }
}
    
void ApplicationContactsApi::DownloadAvatarForContactsWithDodicallIds(const ContactDodicallIdSet &contactIds)
{
    for (auto iter = contactIds.begin(); iter != contactIds.end(); iter++)
        this->mAvatarDownloader.Call(*iter);
}

void ApplicationContactsApi::Clear(void)
{
	LogManager::GetInstance().TraceLogger(LogLevelDebug) << "ApplicationContactsApi Clear start";
	this->GetContactsCache().EraseWhere([](const ContactModel& self)
	{
		return self.Id;
	});
	this->mContactAsks.Clear();
	this->mUpdatedContactsCache.Clear();
	this->mDeletedContactsCache.Clear();
	this->mRetrievedDirectoryContacts.Clear();
	// TODO: interrupt synchronization and bg threads
	this->mDbContactsCached = false;

	this->mDeviceSettings.SafeChange([](DeviceSettingsModel& self)
	{
		self.ServerSettings.clear();
		self.CodecSettings.clear();
	});

	this->mAvatarDownloader.Cancel();
    
    LogManager::GetInstance().TraceLogger(LogLevelDebug) << "ApplicationContactsApi Clear finished";
}

LoggerStream operator << (LoggerStream s, const ContactsContactModel& contact)
{
	return s << "{ Type = " << ContactsContactTypeToString(contact.Type) << ", Identity = " << contact.Identity << ", Favourite = " << contact.Favourite << " } ";
}

LoggerStream operator << (LoggerStream s, const ContactSubscriptionModel& subscription)
{
	return s << "{ State = " << (int)subscription.SubscriptionState << ", AskForSubscription = " << subscription.AskForSubscription << ", SubscriptionStatus = " << (int)subscription.SubscriptionStatus << " } ";
}

LoggerStream operator << (LoggerStream s, const ContactModel& contact)
{
	s << "Contact" << LoggerStream::endl << "{" << LoggerStream::endl;
	s << "Id = " << contact.Id << LoggerStream::endl;
	s << "DodicallId = " << contact.DodicallId << LoggerStream::endl;
	s << "PhonebookId = " << contact.PhonebookId << LoggerStream::endl;
	s << "NativeId = " << contact.NativeId << LoggerStream::endl;
	s << "FirstName = " << contact.FirstName << LoggerStream::endl;
	s << "LastName = " << contact.LastName << LoggerStream::endl;
	s << "MiddleName = " << contact.MiddleName << LoggerStream::endl;
	s << "Blocked = " << contact.Blocked << LoggerStream::endl;
	s << "White = " << contact.White << LoggerStream::endl;
	s << "Contacts" << LoggerStream::endl << contact.Contacts << LoggerStream::endl;
	s << "Iam = " << contact.Iam << LoggerStream::endl;
	s << "Synchronized = " << contact.Synchronized << LoggerStream::endl;
	s << "Deleted = " << contact.Deleted << LoggerStream::endl;
	s << "AvatarPath = " << contact.AvatarPath << LoggerStream::endl;
	s << "Subscription = " << contact.Subscription << LoggerStream::endl;
	s << "}" << LoggerStream::endl;
	return s;
}

}
