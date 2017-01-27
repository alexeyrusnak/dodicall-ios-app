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
#include "UserDbAccessor.h"

#include "LogManager.h"

#include "DateTimeUtils.h"

namespace dodicall
{

UserDbAccessor::UserDbAccessor(void)
{
	const bool primary = true;
	const bool mandatory = true;
	const bool autoincrement = true;
	const bool unique = true;

	DBTableMetaModel contactsMeta = DBTableMetaModel("CONTACTS", boost::assign::list_of
		(DBFieldMetaModel("ID", DBFieldTypeInteger, 0, mandatory, primary, autoincrement))
		(DBFieldMetaModel("DODICALL_ID_CRYPTED", DBFieldTypeText, 96))
		(DBFieldMetaModel("PHONE_BOOK_ID_CRYPTED", DBFieldTypeText, 96))
		(DBFieldMetaModel("NATIVE_ID", DBFieldTypeText, 48))
		(DBFieldMetaModel("ENTERPRISE_ID_CRYPTED", DBFieldTypeText, 96))
		(DBFieldMetaModel("FIRST_NAME_CRYPTED", DBFieldTypeText, 0))
		(DBFieldMetaModel("LAST_NAME_CRYPTED", DBFieldTypeText, 0))
		(DBFieldMetaModel("MIDDLE_NAME_CRYPTED", DBFieldTypeText, 0))
		(DBFieldMetaModel("UPDATED", DBFieldTypeDatetime, 0, mandatory, false, false))
		(DBFieldMetaModel("BLOCKED", DBFieldTypeInteger, 1, mandatory, false, false))
		(DBFieldMetaModel("WHITE", DBFieldTypeInteger, 1, mandatory, false, false))
		(DBFieldMetaModel("IAM", DBFieldTypeInteger, 1, mandatory, false, false, "0"))
		, boost::assign::list_of
		(DBTableIndexMetaModel(unique, boost::assign::list_of(std::string("DODICALL_ID_CRYPTED"))))
		(DBTableIndexMetaModel(unique, boost::assign::list_of(std::string("PHONE_BOOK_ID_CRYPTED"))))
		(DBTableIndexMetaModel(unique, boost::assign::list_of(std::string("NATIVE_ID"))))
		, boost::assign::list_of
		(std::string("DODICALL_ID_CRYPTED NOT NULL OR NATIVE_ID NOT NULL"))
		(std::string("FIRST_NAME_CRYPTED NOT NULL OR LAST_NAME_CRYPTED NOT NULL OR MIDDLE_NAME_CRYPTED NOT NULL"))
	);
	this->mModel.Tables.push_back(contactsMeta);
	contactsMeta.Name = "CONTACTS_CACHE";
	this->mModel.Tables.push_back(contactsMeta);

	DBTableMetaModel contactContactsMeta = DBTableMetaModel("CONTACT_CONTACTS", boost::assign::list_of
		(DBFieldMetaModel("CONTACT_ID", DBFieldTypeInteger, 0, mandatory, false, false, 0, "CONTACTS(ID) ON UPDATE CASCADE ON DELETE CASCADE"))
		(DBFieldMetaModel("TYPE", DBFieldTypeInteger, 0, mandatory))
		(DBFieldMetaModel("IDENTITY_CRYPTED", DBFieldTypeText, 0, mandatory))
		(DBFieldMetaModel("FAVOURITE", DBFieldTypeInteger, 1, mandatory, false, false))
		(DBFieldMetaModel("MANUAL", DBFieldTypeInteger, 1, mandatory, false, false))
		, boost::assign::list_of
		(DBTableIndexMetaModel(unique, boost::assign::list_of(std::string("CONTACT_ID"))(std::string("TYPE"))(std::string("IDENTITY_CRYPTED"))))
	);
	this->mModel.Tables.push_back(contactContactsMeta);
	contactContactsMeta.Name = "CONTACT_CONTACTS_CACHE";
	contactContactsMeta.Fields.at(0).ForeignTo = "CONTACTS_CACHE(ID) ON UPDATE CASCADE ON DELETE CASCADE";
	this->mModel.Tables.push_back(contactContactsMeta);

	this->mModel.Tables.push_back(DBTableMetaModel("UNSYNCHRONIZED_CONTACTS",boost::assign::list_of
		(DBFieldMetaModel("CONTACT_ID",DBFieldTypeInteger,0,false,false,false,0,"CONTACTS(ID) ON UPDATE CASCADE ON DELETE CASCADE"))
		(DBFieldMetaModel("DODICALL_ID_CRYPTED",DBFieldTypeText,96))
		(DBFieldMetaModel("NATIVE_ID",DBFieldTypeText,48))
		, boost::assign::list_of
			(DBTableIndexMetaModel(unique,boost::assign::list_of(std::string("CONTACT_ID"))))
			(DBTableIndexMetaModel(unique,boost::assign::list_of(std::string("DODICALL_ID_CRYPTED"))))
			(DBTableIndexMetaModel(unique,boost::assign::list_of(std::string("NATIVE_ID"))))
		, boost::assign::list_of
			(std::string("CONTACT_ID NOT NULL OR DODICALL_ID_CRYPTED NOT NULL OR NATIVE_ID NOT NULL"))
	));

	this->mModel.Views.push_back(DBViewMetaModel("CONTACTS_VIEW","select C.*, case when U.CONTACT_ID IS NULL then 1 else 0 end SYNCHRONIZED, 0 DBID from CONTACTS C left outer join UNSYNCHRONIZED_CONTACTS U on c.ID = U.CONTACT_ID WHERE C.IAM = 0"));
	this->mModel.Views.push_back(DBViewMetaModel("CONTACTS_CACHE_VIEW", "select 0 ID, DODICALL_ID_CRYPTED, PHONE_BOOK_ID_CRYPTED,\
		NATIVE_ID, ENTERPRISE_ID_CRYPTED, FIRST_NAME_CRYPTED, LAST_NAME_CRYPTED, MIDDLE_NAME_CRYPTED, UPDATED, BLOCKED, WHITE, IAM, 0 SYNCHRONIZED, ID DBID from CONTACTS_CACHE"));

	this->mModel.Tables.push_back(DBTableMetaModel("CALLS"
		, boost::assign::list_of
			(DBFieldMetaModel("ID", DBFieldTypeText, 0, mandatory, primary, false))
			(DBFieldMetaModel("DIRECTION", DBFieldTypeInteger, 0, mandatory))
			(DBFieldMetaModel("ENCRYPTION", DBFieldTypeInteger, 0, mandatory))
			(DBFieldMetaModel("HISTORY_STATUS", DBFieldTypeInteger, 0, mandatory))
			(DBFieldMetaModel("READED", DBFieldTypeInteger, 0, mandatory))
			(DBFieldMetaModel("END_MODE", DBFieldTypeInteger, 0, mandatory))
			(DBFieldMetaModel("ADDRESS_TYPE", DBFieldTypeInteger, 1, mandatory, false, false))
			(DBFieldMetaModel("DURATION", DBFieldTypeInteger, 0, mandatory, false, false))
			(DBFieldMetaModel("START_TIME", DBFieldTypeDatetime, 0, mandatory, false, false))
			(DBFieldMetaModel("IDENTITY_CRYPTED", DBFieldTypeText, 0, mandatory))
			(DBFieldMetaModel("CONTACT_ID",DBFieldTypeInteger, 0, false, false, false, 0, "CONTACTS(ID) ON UPDATE CASCADE ON DELETE CASCADE"))
			(DBFieldMetaModel("PHONEBOOK_ID_CRYPTED", DBFieldTypeText, 0))
			(DBFieldMetaModel("DODICALL_ID_CRYPTED", DBFieldTypeText, 96))
	));

	this->mModel.Tables.push_back(DBTableMetaModel("CHATS",boost::assign::list_of
		(DBFieldMetaModel("ID_CRYPTED",DBFieldTypeText,128,mandatory,primary))
		(DBFieldMetaModel("CUSTOM_TITLE_CRYPTED",DBFieldTypeText,128))
		(DBFieldMetaModel("SERVERED",DBFieldTypeInteger,1,mandatory,false,false,"1"))
		(DBFieldMetaModel("ACTIVE",DBFieldTypeInteger,1,mandatory,false,false,"1"))
		(DBFieldMetaModel("VISIBLE",DBFieldTypeInteger,1,mandatory,false,false,"1"))
        (DBFieldMetaModel("ISP2P",DBFieldTypeInteger,1,mandatory,false,false,"1"))
		(DBFieldMetaModel("LAST_CLEAR_TIME", DBFieldTypeDatetime, 0, mandatory, false, false, "0"))
        (DBFieldMetaModel("CREATION_TIME", DBFieldTypeDatetime, 0, mandatory, false, false, "0"))
		(DBFieldMetaModel("SYNCHRONIZED", DBFieldTypeInteger, 1, mandatory, false, false, "1"))
		, boost::assign::list_of
			(DBTableIndexMetaModel(false,boost::assign::list_of(std::string("VISIBLE desc"))))
			(DBTableIndexMetaModel(false, boost::assign::list_of(std::string("SERVERED"))))
	));
	this->mModel.Tables.push_back(DBTableMetaModel("CHAT_MEMBERS",boost::assign::list_of
		(DBFieldMetaModel("CHAT_ID_CRYPTED",DBFieldTypeText,128,mandatory,false,false,0,"CHATS(ID_CRYPTED) ON UPDATE CASCADE ON DELETE CASCADE"))
		(DBFieldMetaModel("MEMBER_ID_CRYPTED",DBFieldTypeText,128,mandatory))
		, boost::assign::list_of
			(DBTableIndexMetaModel(unique,boost::assign::list_of(std::string("CHAT_ID_CRYPTED"))(std::string("MEMBER_ID_CRYPTED"))))
	));
	this->mModel.Tables.push_back(DBTableMetaModel("CHAT_MESSAGES",boost::assign::list_of
		(DBFieldMetaModel("ROWNUM", DBFieldTypeInteger, 0, mandatory, primary, autoincrement))
		(DBFieldMetaModel("ID",DBFieldTypeText,128,mandatory))
		(DBFieldMetaModel("CHAT_ID_CRYPTED",DBFieldTypeText,128,mandatory,false,false,0,"CHATS(ID_CRYPTED) ON UPDATE CASCADE ON DELETE CASCADE"))
		(DBFieldMetaModel("TYPE",DBFieldTypeInteger,1,mandatory,false,false))
		(DBFieldMetaModel("SENDER_ID_CRYPTED",DBFieldTypeText,128,mandatory))
		(DBFieldMetaModel("SERVERED",DBFieldTypeInteger,1,mandatory,false,false,"0"))
		(DBFieldMetaModel("SEND_TIME",DBFieldTypeDatetime,0,false))
		(DBFieldMetaModel("READED",DBFieldTypeInteger,1,mandatory,false,false))
		(DBFieldMetaModel("STRING_CONTENT_CRYPTED",DBFieldTypeText,1024))
		(DBFieldMetaModel("EXTENDED_CONTENT_CRYPTED",DBFieldTypeText,0))
		(DBFieldMetaModel("REPLACED_ID",DBFieldTypeText,128,false,false,false,0,"CHAT_MESSAGES(ID) ON UPDATE CASCADE ON DELETE CASCADE"))
		, boost::assign::list_of
			(DBTableIndexMetaModel(unique,boost::assign::list_of(std::string("ID"))))
			(DBTableIndexMetaModel(unique,boost::assign::list_of(std::string("CHAT_ID_CRYPTED"))(std::string("REPLACED_ID"))(std::string("ROWNUM desc"))))
			(DBTableIndexMetaModel(false,boost::assign::list_of(std::string("CHAT_ID_CRYPTED"))(std::string("REPLACED_ID"))(std::string("SEND_TIME"))))
			(DBTableIndexMetaModel(false,boost::assign::list_of(std::string("CHAT_ID_CRYPTED"))(std::string("READED"))))
			(DBTableIndexMetaModel(false,boost::assign::list_of(std::string("READED"))))
			(DBTableIndexMetaModel(false,boost::assign::list_of(std::string("SERVERED"))))
	));
	this->mModel.Tables.push_back(DBTableMetaModel("UNSYNCHRONIZED_CHAT_EVENTS", boost::assign::list_of
	(DBFieldMetaModel("CHAT_ID_CRYPTED", DBFieldTypeText, 128, mandatory, false, false, 0, "CHATS(ID_CRYPTED) ON UPDATE CASCADE ON DELETE CASCADE"))
		(DBFieldMetaModel("EVENT_TYPE", DBFieldTypeInteger, 1, mandatory))
		(DBFieldMetaModel("IDENTITY_CRYPTED", DBFieldTypeText, 128, mandatory))
		, boost::assign::list_of
		(DBTableIndexMetaModel(unique, boost::assign::list_of(std::string("CHAT_ID_CRYPTED"))(std::string("IDENTITY_CRYPTED"))))
	));
                                                 
    this->mModel.Tables.push_back(DBTableMetaModel("HOLDING_COMPANIES", boost::assign::list_of
                                                   (DBFieldMetaModel("COMPANY_ID_CRYPTED", DBFieldTypeText, 128, true, true))));

	this->mModel.Views.push_back(DBViewMetaModel("HOLDING_COMPANIES_VIEW", "select COMPANY_ID_CRYPTED from HOLDING_COMPANIES union select ENTERPRISE_ID_CRYPTED from CONTACTS_CACHE where IAM = 1"));

    this->mModel.Views.push_back(DBViewMetaModel("VISIBLE_CHAT_MESSAGES_VIEW",
                                              "SELECT MES.* FROM CHAT_MESSAGES MES, CHATS CHAT \
                                              WHERE MES.CHAT_ID_CRYPTED = CHAT.ID_CRYPTED \
                                              AND CHAT.VISIBLE = 1 \
                                              AND MES.SEND_TIME > CHAT.LAST_CLEAR_TIME \
                                              ORDER BY MES.SEND_TIME, MES.ROWNUM"));
                                                 
    this->mModel.Views.push_back(DBViewMetaModel("CHAT_MESSAGES_VIEW",
                                                 "SELECT * FROM VISIBLE_CHAT_MESSAGES_VIEW \
                                                 WHERE REPLACED_ID = \"\" \
                                                 AND ID NOT IN (SELECT DISTINCT(REPLACED_ID) FROM VISIBLE_CHAT_MESSAGES_VIEW WHERE REPLACED_ID != \"\") \
                                                 UNION \
                                                 SELECT M.ROWNUM, M.ID, C.CHAT_ID_CRYPTED, C.TYPE, C.SENDER_ID_CRYPTED, C.SERVERED, M.SEND_TIME, M.READED, C.STRING_CONTENT_CRYPTED, C.EXTENDED_CONTENT_CRYPTED, C.REPLACED_ID \
                                                 FROM (SELECT * FROM VISIBLE_CHAT_MESSAGES_VIEW WHERE REPLACED_ID = \"\" ) M \
                                                 INNER JOIN (SELECT * FROM (SELECT * FROM VISIBLE_CHAT_MESSAGES_VIEW  WHERE REPLACED_ID !=\"\" ORDER BY SEND_TIME, ROWNUM) GROUP BY REPLACED_ID) C  \
                                                 ON M.CHAT_ID_CRYPTED = C.CHAT_ID_CRYPTED AND M.ID = C.REPLACED_ID"));
                                                                            

                                                                            
    this->mModel.Views.push_back(DBViewMetaModel("CHATS_VIEW","select C.*, \
                                                  (select COUNT(1) from CHAT_MESSAGES M where C.ID_CRYPTED = M.CHAT_ID_CRYPTED and M.REPLACED_ID = '' and M.SEND_TIME > C.LAST_CLEAR_TIME) TOTAL_MESSAGES_COUNT, \
                                                  (select COUNT(1) from CHAT_MESSAGES M where C.ID_CRYPTED = M.CHAT_ID_CRYPTED and M.REPLACED_ID = '' and M.SEND_TIME > C.LAST_CLEAR_TIME and M.READED = 0) NEW_MESSAGES_COUNT, \
                                                  (select MAX(SEND_TIME) from CHAT_MESSAGES M where C.ID_CRYPTED = M.CHAT_ID_CRYPTED and M.REPLACED_ID = '' and M.SEND_TIME > C.LAST_CLEAR_TIME) LAST_MODIFIED_DATE, \
                                                  (select COUNT(1) from CHAT_MEMBERS M where C.ID_CRYPTED = M.CHAT_ID_CRYPTED) MEMBERS_COUNT \
                                                  from CHATS C"));
    this->mModel.Views.push_back(DBViewMetaModel("VISIBLE_CHATS_VIEW", "select * from CHATS_VIEW where VISIBLE = 1"));



	this->mMigrationScripts.push_back(MigrationScriptType(2008006000, [this](bool afterUpgrade)
	{
		if (afterUpgrade)
			return true;
		this->SaveSetting("TraceMode", false);
		return false;
	}));
}
UserDbAccessor::~UserDbAccessor(void)
{
}

UserSettingsModel UserDbAccessor::GetUserSettings(UserSettingsModel result) const
{
	DBResult dbresult;
	if (this->Execute("select * from SETTINGS",DBValueList(),&dbresult))
	{
		for (DBRowList::const_iterator iter = dbresult.Rows.begin(); iter != dbresult.Rows.end(); iter++)
		{
			try
			{
				std::string name = iter->Values.at("NAME");
				DBValue value = iter->Values.at("VALUE");
				if (name == "Autologin")
					result.Autologin = (bool)value;
				else if (name == "UserBaseStatus")
					result.UserBaseStatus = (BaseUserStatus)(int)value;
				else if (name == "UserExtendedStatus")
					result.UserExtendedStatus = (std::string)value;
				else if (name == "DoNotDesturbMode")
					result.DoNotDesturbMode = (bool)value;
				else if (name == "DefaultVoipServer")
					result.DefaultVoipServer = (std::string)value;
				else if (name == "VoipEncryption")
					result.VoipEncryption = (VoipEncryptionType)(int)value;
				else if (name == "EchoCancellationMode")
					result.EchoCancellationMode = (EchoCancellationMode)(int)value;
				else if (name == "VideoEnabled")
					result.VideoEnabled = (bool)value;
				else if (name == "VideoSizeWifi")
					result.VideoSizeWifi = (VideoSize)(int)value;
				else if (name == "VideoSizeCell")
					result.VideoSizeCell = (VideoSize)(int)value;
				else if (name == "GuiThemeName")
					result.GuiThemeName = (std::string)value;
				else if (name == "GuiAnimation")
					result.GuiAnimation = (bool)value;
				else if (name == "GuiLanguage")
					result.GuiLanguage = (std::string)value;
				else if (name == "GuiFontSize")
					result.GuiFontSize = (int)value;
				else if (name == "TraceMode")
					result.TraceMode = (bool)value;
				else if (name == "Autostart")
					result.Autostart = (bool)value;
			}
			catch(...)
			{
				// TODO: log warning
			}
		}
	}
	return result;
}

bool UserDbAccessor::SaveUserSettings(const UserSettingsModel& settings)
{
	bool result = true;
	result = result && this->SaveSetting("Autologin", settings.Autologin);
	result = result && this->SaveSetting("UserBaseStatus",(int)settings.UserBaseStatus);
	result = result && this->SaveSetting("UserExtendedStatus",settings.UserExtendedStatus);
	result = result && this->SaveSetting("DoNotDesturbMode",settings.DoNotDesturbMode);
	result = result && this->SaveSetting("DefaultVoipServer",settings.DefaultVoipServer);
	result = result && this->SaveSetting("VoipEncryption",(int)settings.VoipEncryption);
	result = result && this->SaveSetting("EchoCancellationMode",(int)settings.EchoCancellationMode);
	result = result && this->SaveSetting("VideoEnabled",settings.VideoEnabled);
	result = result && this->SaveSetting("VideoSizeWifi",(int)settings.VideoSizeWifi);
	result = result && this->SaveSetting("VideoSizeCell",(int)settings.VideoSizeCell);
	result = result && this->SaveSetting("GuiThemeName",settings.GuiThemeName);
	result = result && this->SaveSetting("GuiAnimation",settings.GuiAnimation);
	result = result && this->SaveSetting("GuiLanguage",settings.GuiLanguage);
	result = result && this->SaveSetting("GuiFontSize",settings.GuiFontSize);
	result = result && this->SaveSetting("TraceMode",settings.TraceMode);
	result = result && this->SaveSetting("Autostart",settings.Autostart);
	return result;
}

bool UserDbAccessor::GetAllContacts(ContactModelSet& result) const
{
	DBResult dbresult;
	if (this->Execute("select * from CONTACTS_VIEW",DBValueList(),&dbresult))
	{
		this->DbResultToContactSet(dbresult,result);
		return true;
	}
	return false;
}

ContactModel UserDbAccessor::GetContactById(ContactIdType id) const
{
	ContactModel result;
	DBResult dbresult;
	if (this->Execute("select * from CONTACTS_VIEW where ID = ?",boost::assign::list_of(DBValue((int64_t)id)),&dbresult) && !dbresult.Rows.empty())
		result = this->DbRowToContactModel(*dbresult.Rows.begin());
	return result;
}

ContactModel UserDbAccessor::GetContactByDodicallId(const ContactDodicallIdType& id) const
{
	ContactModel result;
	std::string preparedId = this->Encrypt(id);
	DBResult dbresult;
	if (this->Execute("select * from CONTACTS_VIEW where DODICALL_ID_CRYPTED = ?\
						union\
					   select * from CONTACTS_CACHE_VIEW where DODICALL_ID_CRYPTED = ?\
						order by ID desc limit 1"
		, boost::assign::list_of(DBValue(preparedId))(DBValue(preparedId)), &dbresult) && !dbresult.Rows.empty())
		result = this->DbRowToContactModel(*dbresult.Rows.begin());
	return result;
}

ContactModel UserDbAccessor::GetContactByXmppId(const ContactXmppIdType& xmppId) const
{
	ContactModel result;
	std::string preparedId = this->Encrypt(xmppId);
	DBResult dbresult;
	if (this->Execute("select C.* from CONTACTS_VIEW C, CONTACT_CONTACTS CC where C.ID = CC.CONTACT_ID and CC.TYPE = 2 and CC.IDENTITY_CRYPTED = ?\
						union\
					   select C.* from CONTACTS_CACHE_VIEW C, CONTACT_CONTACTS_CACHE CC where C.DBID = CC.CONTACT_ID and CC.TYPE = 2 and CC.IDENTITY_CRYPTED = ?\
						order by ID desc limit 1"
		, boost::assign::list_of(DBValue(preparedId))(DBValue(preparedId)), &dbresult) && !dbresult.Rows.empty())
		result = this->DbRowToContactModel(*dbresult.Rows.begin());
	return result;
}

bool UserDbAccessor::GetContactsByXmppIds(const ContactXmppIdSet& xmppIds, ContactModelSet& result) const
{
	std::string params;
	DBValueList args;
	for (auto iter = xmppIds.begin(); iter != xmppIds.end(); iter++)
	{
		params += std::string((iter != xmppIds.begin() ? "," : "")) + "?";
		args.push_back(DBValue(this->Encrypt(*iter)));
	}
	{
		DBValueList argsCopy = args;
		std::copy(argsCopy.begin(), argsCopy.end(), std::back_inserter(args));
	}

	DBResult dbresult;
	if (this->Execute((std::string("select C.* from CONTACTS_VIEW C, CONTACT_CONTACTS CC where C.ID = CC.CONTACT_ID and CC.TYPE = 2 and CC.IDENTITY_CRYPTED in (") + params + ") " +
		"union " +
		"select C.* from CONTACTS_CACHE_VIEW C, CONTACT_CONTACTS_CACHE CC where C.DBID = CC.CONTACT_ID and CC.TYPE = 2 and CC.IDENTITY_CRYPTED in (" + params + ") " +
		"group by DODICALL_ID_CRYPTED order by ID desc").c_str()
		, args, &dbresult))
	{
		this->DbResultToContactSet(dbresult, result);
		return true;
	}
	return false;
}

ContactModel UserDbAccessor::GetAccountData() const
{
	ContactModel result;
	DBResult dbresult;
	if (this->Execute("select C.* from CONTACTS_CACHE_VIEW C where C.IAM = 1", DBValueList(), &dbresult) && !dbresult.Rows.empty())
	{
		result = this->DbRowToContactModel(*dbresult.Rows.begin());
		result.Synchronized = true;
	}
	return result;
}

bool UserDbAccessor::SaveContactInternal(ContactModel& contact, bool cache)
{
	const char* contactsTableName = (cache ? "CONTACTS_CACHE" : "CONTACTS");
	const char* contactContactsTableName = (cache ? "CONTACT_CONTACTS_CACHE" : "CONTACT_CONTACTS");

	ContactModel exists = this->CheckContactExists(contact, contactsTableName, contactContactsTableName);
	bool result;
	if (exists.Id)
	{
		contact.Id = exists.Id;
		contact.DodicallId = exists.DodicallId;
		contact.NativeId = exists.NativeId;
		if (contact.Blocked && contact.White)
		{
			if (exists.White)
				contact.White = false;
			else if (exists.Blocked)
				contact.Blocked = false;
		}
		result = this->UpdateContact(contact, contactsTableName, contactContactsTableName);
	}
	else
	{
		result = this->InsertContact(contact, contactsTableName, contactContactsTableName);
		if (!cache && result)
			this->Execute("update CALLS set CONTACT_ID = (select ID from CONTACTS CC where CC.DODICALL_ID_CRYPTED is not null and CC.DODICALL_ID_CRYPTED = CALLS.DODICALL_ID_CRYPTED) where (CONTACT_ID is null or CONTACT_ID = '') and DODICALL_ID_CRYPTED is not null");
	}

	if (!cache && result)
	{
		if (contact.Synchronized)
		{
			if (!contact.DodicallId.empty())
				result = this->Execute("delete from UNSYNCHRONIZED_CONTACTS where CONTACT_ID = ? or DODICALL_ID_CRYPTED = ?",boost::assign::list_of(DBValue((int64_t)contact.Id))(DBValue(this->Encrypt(contact.DodicallId))));
			else if (!contact.NativeId.empty())
				result = this->Execute("delete from UNSYNCHRONIZED_CONTACTS where CONTACT_ID = ? or NATIVE_ID = ?",boost::assign::list_of(DBValue((int64_t)contact.Id))(DBValue(contact.NativeId)));
			else
				result = this->Execute("delete from UNSYNCHRONIZED_CONTACTS where CONTACT_ID = ?",boost::assign::list_of(DBValue((int64_t)contact.Id)));
		}
		else
		{
			if (!contact.DodicallId.empty())
				result = this->Execute("insert or replace into UNSYNCHRONIZED_CONTACTS(CONTACT_ID,DODICALL_ID_CRYPTED) values(?,?)",boost::assign::list_of(DBValue((int64_t)contact.Id))(DBValue(this->Encrypt(contact.DodicallId))));
			else if (!contact.NativeId.empty())
				result = this->Execute("insert or replace into UNSYNCHRONIZED_CONTACTS(CONTACT_ID,NATIVE_ID) values(?,?)",boost::assign::list_of(DBValue((int64_t)contact.Id))(DBValue(contact.NativeId)));
		}
	}
	return result;
}

bool UserDbAccessor::SaveContact(ContactModel& contact)
{
	return this->SaveContactInternal(contact, false);
}
bool UserDbAccessor::DeleteContact(ContactModel& contact)
{
	std::string dodicallIdCrypted = this->Encrypt(contact.DodicallId);
	if (this->CheckContactExists(contact, "CONTACTS", "CONTACT_CONTACTS").Id)
	{
		bool result = true;
		if (!contact.DodicallId.empty())
			result =  this->Execute("delete from CONTACTS where ID = ? or DODICALL_ID_CRYPTED = ?",boost::assign::list_of(DBValue((int64_t)contact.Id))(DBValue(dodicallIdCrypted)));
		else if (!contact.NativeId.empty())
			result =  this->Execute("delete from CONTACTS where ID = ? or NATIVE_ID = ?",boost::assign::list_of(DBValue((int64_t)contact.Id))(DBValue(contact.NativeId)));
		else
			result =  this->Execute("delete from CONTACTS where ID = ?",boost::assign::list_of(DBValue((int64_t)contact.Id)));

		if (result && !contact.Synchronized)
		{
			if (!contact.DodicallId.empty())
				result = this->Execute("insert or replace into UNSYNCHRONIZED_CONTACTS(DODICALL_ID_CRYPTED) values(?)",boost::assign::list_of(DBValue(dodicallIdCrypted)));
			else if (!contact.NativeId.empty())
				result = this->Execute("insert or replace into UNSYNCHRONIZED_CONTACTS(NATIVE_ID) values(?)",boost::assign::list_of(DBValue(contact.NativeId)));
		}
		if (result)
		{
			this->Execute("delete from CONTACT_CONTACTS where CONTACT_ID not in (select distinct ID from CONTACTS)");
			this->Execute("update CALLS set CONTACT_ID = NULL where CONTACT_ID not in (select distinct ID from CONTACTS)");
		}

		return result;
	}
	else
	{
		if (!contact.DodicallId.empty())
			this->Execute("delete from UNSYNCHRONIZED_CONTACTS where DODICALL_ID_CRYPTED = ?",boost::assign::list_of(DBValue(dodicallIdCrypted)));
		else if (!contact.NativeId.empty())
			this->Execute("delete from UNSYNCHRONIZED_CONTACTS where NATIVE_ID = ?",boost::assign::list_of(DBValue(contact.NativeId)));
	}
	return false;
}

bool UserDbAccessor::SaveContactInCache(ContactModel contact)
{
	return this->SaveContactInternal(contact, true);
}

bool UserDbAccessor::OptimizeContactsCache(void)
{
	return this->Execute("delete from CONTACT_CONTACTS_CACHE where CONTACT_ID in (\
		select ID from CONTACTS_CACHE where DODICALL_ID_CRYPTED in (select DODICALL_ID_CRYPTED from CONTACTS where DODICALL_ID_CRYPTED is not null))")
		&& this->Execute("delete from CONTACTS_CACHE where DODICALL_ID_CRYPTED in (select DODICALL_ID_CRYPTED from CONTACTS where DODICALL_ID_CRYPTED is not null)");
}

bool UserDbAccessor::GetAllNativeContacts(ContactModelSet& nativeContacts)
{
	DBResult dbresult;
	if (this->Execute("select * from CONTACTS_VIEW where DODICALL_ID_CRYPTED IS NULL",DBValueList(),&dbresult))
	{
		this->DbResultToContactSet(dbresult,nativeContacts);
		return true;
	}
	return false;
}

// select * from CHATS C where C.MEMBERS_COUNT = 1 and exists(select * from CHAT_MEMBERS m where m.CHAT_ID_CRYPTED = C.ID_CRYPTED and m.MEMBER_ID_CRYPTED = ?)
                                                 
bool UserDbAccessor::GetUnsynchronizedNativeContacts(ContactModelSet& unsinchronizedContacts) const
{
	DBResult dbresult;
	if (this->Execute("select U.NATIVE_ID U_NATIVE_ID, C.*, case when C.ID IS NULL then 1 else 0 end DELETED from UNSYNCHRONIZED_CONTACTS U left outer join CONTACTS_VIEW C on (C.ID = U.CONTACT_ID OR C.NATIVE_ID = U.NATIVE_ID) where U.NATIVE_ID IS NOT NULL",DBValueList(),&dbresult))
	{
		this->DbResultToContactSet(dbresult,unsinchronizedContacts);
		return true;
	}
	return false;
}
bool UserDbAccessor::GetDirectoryContacts(ContactModelSet& contacts) const
{
	DBResult dbresult;
	if (this->Execute("select * from CONTACTS_VIEW where DODICALL_ID_CRYPTED IS NOT NULL",DBValueList(),&dbresult))
	{
		this->DbResultToContactSet(dbresult,contacts);
		return true;
	}
	return false;
}
bool UserDbAccessor::GetUnsynchronizedDirectoryContacts(ContactModelSet& unsinchronizedContacts) const
{
	DBResult dbresult;
	if (this->Execute("select U.DODICALL_ID_CRYPTED U_DODICALL_ID_CRYPTED, C.*, case when C.ID IS NULL then 1 else 0 end DELETED from UNSYNCHRONIZED_CONTACTS U left outer join CONTACTS_VIEW C on (C.ID = U.CONTACT_ID OR C.DODICALL_ID_CRYPTED = U.DODICALL_ID_CRYPTED) where U.DODICALL_ID_CRYPTED IS NOT NULL",DBValueList(),&dbresult))
	{
		this->DbResultToContactSet(dbresult,unsinchronizedContacts);
		return true;
	}
	return false;
}

Logger& UserDbAccessor::GetLogger(void) const
{
	return LogManager::GetInstance().UserDbLogger;
}

ContactModel UserDbAccessor::CheckContactExists(const ContactModel& contact, const char* contactsTableName, const char* contactContactsTableName) const
{
	DBResult dbresult;
	DBValueList args;
	std:: string statement = std::string("select * from ") + contactsTableName + " where ";
	if (contact.Id)
	{
		statement += "ID = ?";
		args.push_back(DBValue((int)contact.Id));
	}
	else if (!contact.DodicallId.empty())
	{
		statement += "DODICALL_ID_CRYPTED = ?";
		args.push_back(DBValue(this->Encrypt(contact.DodicallId)));
	}
	else if (!contact.NativeId.empty())
	{
		statement += "NATIVE_ID = ?";
		args.push_back(DBValue(contact.NativeId));
	}
	else if (!contact.PhonebookId.empty())
	{
		statement += "PHONE_BOOK_ID_CRYPTED = ?";
		args.push_back(DBValue(this->Encrypt(contact.PhonebookId)));
	}
	if (this->Execute(statement.c_str(),args,&dbresult) && !dbresult.Rows.empty())
		return this->DbRowToContactModel(*dbresult.Rows.begin(), contactContactsTableName);
	return ContactModel();
}
bool UserDbAccessor::InsertContact(ContactModel& contact, const char* contactsTableName, const char* contactContactsTableName)
{
	std::string statement = "FIRST_NAME_CRYPTED,LAST_NAME_CRYPTED,BLOCKED,WHITE,IAM,UPDATED"; 
	std::string values = "?,?,?,?,?,?";
	DBValueList args = boost::assign::list_of(DBValue(this->Encrypt(contact.FirstName)))(DBValue(this->Encrypt(contact.LastName)))(DBValue(contact.Blocked))(DBValue(contact.White))(DBValue(contact.Iam))(DBValue((int64_t)posix_time_to_time_t(contact.LastModifiedDate)));
	
	if (contact.Id)
	{
		statement += ",ID";
		values += ",?";
		args.push_back(DBValue((int64_t)contact.Id));
	}
	if (!contact.DodicallId.empty())
	{
		statement += ",DODICALL_ID_CRYPTED";
		values += ",?";
		args.push_back(DBValue(this->Encrypt(contact.DodicallId)));
	}
	else
	{
		if (contact.NativeId.empty())
			contact.NativeId = boost::lexical_cast<std::string>(boost::uuids::random_generator()());
		statement += ",NATIVE_ID";
		values += ",?";
		args.push_back(DBValue(contact.NativeId));
	}
	if (!contact.PhonebookId.empty())
	{
		statement += ",PHONE_BOOK_ID_CRYPTED";
		values += ",?";
		args.push_back(DBValue(this->Encrypt(contact.PhonebookId)));
	}
	if (!contact.CompanyId.empty())
	{
		statement += ",ENTERPRISE_ID_CRYPTED";
		values += ",?";
		args.push_back(DBValue(this->Encrypt(contact.CompanyId)));
	}

	if (!contact.MiddleName.empty())
	{
		statement += ",MIDDLE_NAME_CRYPTED";
		values += ",?";
		args.push_back(DBValue(this->Encrypt(contact.MiddleName)));
	}
	
	statement = std::string("insert into ") + contactsTableName + "("+statement+") values("+values+")";
	if (this->Execute(statement.c_str(),args))
	{
		contact.Id = this->GetLastInsertRowid();
		if (contact.Id)
			return this->InsertContactContacts(contact, contactContactsTableName);
	}
	return false;
}
bool UserDbAccessor::UpdateContact(ContactModel& contact, const char* contactsTableName, const char* contactContactsTableName)
{
	std::string statement = std::string("update ") + contactsTableName + " set FIRST_NAME_CRYPTED = ?, LAST_NAME_CRYPTED = ?, BLOCKED = ?, WHITE = ?, IAM = ?, UPDATED = ?"; 
	DBValueList args = boost::assign::list_of(DBValue(this->Encrypt(contact.FirstName)))(DBValue(this->Encrypt(contact.LastName)))(DBValue(contact.Blocked))(DBValue(contact.White))(DBValue(contact.Iam))(DBValue((int64_t)posix_time_to_time_t(contact.LastModifiedDate)));
	
	if (!contact.DodicallId.empty())
	{
		statement += ", DODICALL_ID_CRYPTED = ?";
		args.push_back(DBValue(this->Encrypt(contact.DodicallId)));
	}
	else
	{
		if (contact.NativeId.empty())
			contact.NativeId = boost::lexical_cast<std::string>(boost::uuids::random_generator()());
		statement += ", NATIVE_ID = ?";
		args.push_back(DBValue(contact.NativeId));
	}
	if (!contact.PhonebookId.empty())
	{
		statement += ", PHONE_BOOK_ID_CRYPTED = ?";
		args.push_back(DBValue(this->Encrypt(contact.PhonebookId)));
	}
	if (!contact.CompanyId.empty())
	{
		statement += ", ENTERPRISE_ID_CRYPTED = ?";
		args.push_back(DBValue(this->Encrypt(contact.CompanyId)));
	}

	if (!contact.MiddleName.empty())
	{
		statement += ", MIDDLE_NAME_CRYPTED = ?";
		args.push_back(DBValue(this->Encrypt(contact.MiddleName)));
	}
	
	statement += " where ID = ?";
	args.push_back(DBValue((int)contact.Id));

	if (this->Execute(statement.c_str(),args) && this->Execute((std::string("delete from ") + contactContactsTableName + " where CONTACT_ID = ?").c_str()
		, boost::assign::list_of(DBValue((int64_t)contact.Id))))
		return this->InsertContactContacts(contact, contactContactsTableName);
	return false;
}
bool UserDbAccessor::InsertContactContacts(const ContactModel& contact, const char* contactContactsTableName)
{
	bool result = true;
	for (ContactsContactSet::const_iterator iter = contact.Contacts.begin(); iter != contact.Contacts.end(); iter++)
	{
		result = result && this->Execute((std::string("insert into ") + contactContactsTableName + "(CONTACT_ID,TYPE,IDENTITY_CRYPTED,FAVOURITE,MANUAL) values(?,?,?,?,?)").c_str()
			, boost::assign::list_of(DBValue((int64_t)contact.Id))(DBValue((int)iter->Type))(DBValue(this->Encrypt(iter->Identity)))
				(DBValue(iter->Favourite))(DBValue(iter->Manual))
		);
	}
	return result;
}

bool UserDbAccessor::FillContactContacts(ContactModel& contact, const char* contactContactsTableName, int64_t internalId) const
{
	DBResult contactsDbResult;
	if (this->Execute((std::string("select * from ") + contactContactsTableName + " where CONTACT_ID = ?").c_str(), boost::assign::list_of(DBValue((int64_t)(contact.Id ? contact.Id : internalId))), &contactsDbResult))
	{
		for (DBRowList::const_iterator citer = contactsDbResult.Rows.begin(); citer != contactsDbResult.Rows.end(); citer++)
		{
			ContactsContactModel cts;
			cts.Type = (ContactsContactType)(int)citer->Values.at("TYPE");
			cts.Identity = this->Decrypt(citer->Values.at("IDENTITY_CRYPTED"));
			cts.Favourite = citer->Values.at("FAVOURITE");
			cts.Manual = citer->Values.at("MANUAL");
					
			contact.Contacts.insert(cts);
		}
		return true;
	}
	return false;
}

void UserDbAccessor::DbResultToContactSet(const DBResult& dbresult, ContactModelSet& result) const
{
	for (DBRowList::const_iterator iter = dbresult.Rows.begin(); iter != dbresult.Rows.end(); iter++)
	{
		ContactModel contact = this->DbRowToContactModel(*iter);
		result.insert(contact);
	}
}

ContactModel UserDbAccessor::DbRowToContactModel(const DBRow& row, const char* contactContactsTableName) const
{
	ContactModel result;
	result.Id = (int64_t)row.Values.at("ID");
	if (row.Values.find("U_NATIVE_ID") != row.Values.end())
		result.NativeId = (std::string)row.Values.at("U_NATIVE_ID");
	else
		result.NativeId = (std::string)row.Values.at("NATIVE_ID");
			
	if (row.Values.find("U_DODICALL_ID_CRYPTED") != row.Values.end())
		result.DodicallId = this->Decrypt((std::string)row.Values.at("U_DODICALL_ID_CRYPTED"));
	else
		result.DodicallId = this->Decrypt((std::string)row.Values.at("DODICALL_ID_CRYPTED"));
	result.PhonebookId = this->Decrypt((std::string)row.Values.at("PHONE_BOOK_ID_CRYPTED"));
	result.CompanyId = this->Decrypt((std::string)row.Values.at("ENTERPRISE_ID_CRYPTED"));
	result.FirstName = this->Decrypt((std::string)row.Values.at("FIRST_NAME_CRYPTED"));
	result.LastName = this->Decrypt((std::string)row.Values.at("LAST_NAME_CRYPTED"));
			
	result.Blocked = (bool)row.Values.at("BLOCKED");
	result.White = (bool)row.Values.at("WHITE");
	result.Iam = (bool)row.Values.at("IAM");

	if (row.Values.find("SYNCHRONIZED") != row.Values.end())
		result.Synchronized = (bool)row.Values.at("SYNCHRONIZED");
	if (row.Values.find("DELETED") != row.Values.end())
		result.Deleted = (bool)row.Values.at("DELETED");

	result.LastModifiedDate = time_t_to_posix_time((time_t)(int64_t)row.Values.at("UPDATED"));

	ContactIdType internalId = 0;
	if (row.Values.find("DBID") != row.Values.end())
		internalId = (int64_t)row.Values.at("DBID");

	if (this->FillContactContacts(result, (contactContactsTableName ? contactContactsTableName : (result.Id ? "CONTACT_CONTACTS" : "CONTACT_CONTACTS_CACHE")), internalId))
		return result;
	return ContactModel();
}
    // Chats serialization:
    
int UserDbAccessor::GetNewMessagesCount(void) const
{
	DBResult dbresult;
	if (this->Execute("select count(*) CNT from CHAT_MESSAGES_VIEW M where M.READED = 0", DBValueList(), &dbresult) && !dbresult.Rows.empty())
	{
		DBRow& row = dbresult.Rows.at(0);
		if (!row.Values.empty())
			return row.Values["CNT"];
		return 0;
	}
	return -1;
}

bool UserDbAccessor::GetAllVisibleChats(ChatDbModelSet& result) const 
{
    DBResult dbresult;
    if (this->Execute("select * from VISIBLE_CHATS_VIEW",DBValueList(),&dbresult)) 
	{
        this->DbResultToChatSet(dbresult,result);
        return true;
    }
    return false;
}

bool UserDbAccessor::GetAllP2pChats(ChatDbModelSet& result) const
{
	DBResult dbresult;
	if (this->Execute("select * from CHATS_VIEW where ISP2P = 1", DBValueList(), &dbresult))
	{
		this->DbResultToChatSet(dbresult, result);
		return true;
	}
	return false;
}

bool UserDbAccessor::GetChatsByIds(const ChatIdSet& ids, ChatDbModelSet& result, bool onlyVisible) const
{
	std::string statement;
    DBValueList args;

	for (ChatIdSet::const_iterator iter = ids.begin(); iter != ids.end(); iter++)
	{
		statement += ((iter == ids.begin()) ? "?" : ",?");
		args.push_back(DBValue(this->Encrypt(iter->c_str())));
	}

    DBResult dbresult;
    if (this->Execute((std::string("select * from ") + (onlyVisible ? "VISIBLE_" : "") + "CHATS_VIEW where ID_CRYPTED in ("+statement+")").c_str(),args,&dbresult))
	{
		this->DbResultToChatSet(dbresult,result);
		return true;
	}
    return false;
}
                                                 
bool UserDbAccessor::GetP2pChatByMemberId(ContactXmppIdType const &memberId, ChatDbModelSet& result, bool surelyActive) const
{
    DBResult dbresult;
    std::string activeCondition = surelyActive?"ACTIVE = 1 and ":"";
    if (this->Execute((std::string("select * from CHATS_VIEW C where " + activeCondition + "C.MEMBERS_COUNT = 2 and ISP2P = 1 and exists(select * from CHAT_MEMBERS m where m.CHAT_ID_CRYPTED = C.ID_CRYPTED and m.MEMBER_ID_CRYPTED = ?) limit 1")).c_str(),
                       boost::assign::list_of(DBValue(this->Encrypt(memberId.c_str()))),&dbresult))
    {
        this->DbResultToChatSet(dbresult,result);
        return true;
    }
    return false;
}

time_t UserDbAccessor::GetLastP2pMessageTime(void) const
{
	int64_t result = 0;
	DBResult dbresult;
	if (this->Execute("select max(SEND_TIME) LAST_SEND_TIME from CHAT_MESSAGES_VIEW M, CHATS C where M.CHAT_ID_CRYPTED = C.ID_CRYPTED and C.ISP2P = 1", DBValueList(), &dbresult) && !dbresult.Rows.empty())
		result = (int64_t)dbresult.Rows.at(0).Values["LAST_SEND_TIME"];
	return (time_t)result;
}

ChatDbModel UserDbAccessor::GetChatById(const ChatIdType& id, bool onlyVisible) const
{
	ChatIdSet ids;
	ids.insert(id);
	
	ChatDbModelSet chats;
	if (this->GetChatsByIds(ids,chats,onlyVisible) && !chats.empty())
		return *chats.begin();
	return ChatDbModel();
}

bool UserDbAccessor::GetActiveMultiUserChatIds(const ChatIdSet& excepts, ChatIdSet& result) const
{
	std::string statement;
    DBValueList args;
	for (ChatIdSet::const_iterator iter = excepts.begin(); iter != excepts.end(); iter++)
	{
		statement += ((iter == excepts.begin()) ? "?" : ",?");
		args.push_back(DBValue(this->Encrypt(iter->c_str())));
	}
    DBResult dbresult;
	if (this->Execute((std::string("select ID_CRYPTED from CHATS_VIEW C where ACTIVE = 1") + (excepts.empty() ? "" : ( + " and ID_CRYPTED not in (")+statement+") \
											and exists(select 1 from CHAT_MEMBERS M where M.CHAT_ID_CRYPTED = C.ID_CRYPTED)")).c_str(),args,&dbresult))
	{
		for (DBRowList::const_iterator iter = dbresult.Rows.begin(); iter != dbresult.Rows.end(); iter++)
			result.insert(this->Decrypt(iter->Values.at("ID_CRYPTED")));
		return true;
	}
    return false;
}

bool UserDbAccessor::DeactivateMultiUserChats(const ChatIdSet& ids)
{
	if (ids.empty())
		return true;

	std::string statement;
    DBValueList args;
	for (ChatIdSet::const_iterator iter = ids.begin(); iter != ids.end(); iter++)
	{
		statement += ((iter == ids.begin()) ? "?" : ",?");
		args.push_back(DBValue(this->Encrypt(iter->c_str())));
	}
    DBResult dbresult;
	return
		this->Execute((std::string("update CHATS set ACTIVE = 0 where SERVERED = 1 and VISIBLE = 1 and ISP2P = 0 and ID_CRYPTED in (") + statement + ")").c_str(), args, &dbresult)
		&&
		this->Execute((std::string("delete CHATS where VISIBLE = 0 and ID_CRYPTED in (") + statement + ")").c_str(), args, &dbresult);
}

bool UserDbAccessor::SaveChat(ChatDbModel& chat) 
{
	ChatDbModel exists = this->GetChatById(chat.Id, false);
	if (exists.Id.empty()) 
		return this->InsertChat(chat);
	int sameContacts = 0;
	for (ChatContactIdentitySet::const_iterator iter = chat.ContactXmppIds.begin(); iter != chat.ContactXmppIds.end(); iter++)
		for (ChatContactIdentitySet::const_iterator citer = exists.ContactXmppIds.begin(); citer != exists.ContactXmppIds.end(); citer++)
			if (*iter == *citer)
			{
				sameContacts++;
				break;
			}
	if (sameContacts == chat.ContactXmppIds.size() && sameContacts == exists.ContactXmppIds.size())
		chat.IsNew = false;
	return this->UpdateChat(chat);
}
    
bool UserDbAccessor::UpdateChatId(const ChatIdType& chatId, const ChatIdType& newChatId)
{
	return this->Execute("update CHATS set ID_CRYPTED = ? where ID_CRYPTED = ?",
		boost::assign::list_of(DBValue(this->Encrypt(newChatId)))(DBValue(this->Encrypt(chatId))))
		&& this->Execute("update CHAT_MEMBERS set CHAT_ID_CRYPTED = ? where CHAT_ID_CRYPTED = ?",
			boost::assign::list_of(DBValue(this->Encrypt(newChatId)))(DBValue(this->Encrypt(chatId))))
		&& this->Execute("update CHAT_MESSAGES set CHAT_ID_CRYPTED = ? where CHAT_ID_CRYPTED = ?",
			boost::assign::list_of(DBValue(this->Encrypt(newChatId)))(DBValue(this->Encrypt(chatId))));
}

bool UserDbAccessor::DeleteChat(const ChatDbModel& chat)
{
	if (!this->GetChatById(chat.Id, false).Id.empty())
	{
		std::string chatIdCrypted = this->Encrypt(chat.Id);
		this->Execute("delete from CHAT_MESSAGES where CHAT_ID_CRYPTED = ?", boost::assign::list_of(DBValue(chatIdCrypted)));
		return this->Execute("delete from CHATS where ID_CRYPTED = ?", boost::assign::list_of(DBValue(chatIdCrypted)));
	}
    return false;
}

bool UserDbAccessor::GetUnsynchronizedChatEvents(const ChatIdType& chatId, UnsynchronizedChatEventDbSet& result) const
{
	DBResult dbresult;
	if (this->Execute("select * from UNSYNCHRONIZED_CHAT_EVENTS where CHAT_ID_CRYPTED = ?", boost::assign::list_of(DBValue(this->Encrypt(chatId))), &dbresult))
	{
		this->DbResultToUnsynchronizedChatEventDbSet(dbresult, result);
		return true;
	}
	return false;
}

bool UserDbAccessor::AddUnsynchronizedChatEvent(const ChatIdType& chatId, const UnsynchronizedChatEventDbModel& evt)
{
	return this->Execute("insert or replace into UNSYNCHRONIZED_CHAT_EVENTS(CHAT_ID_CRYPTED,EVENT_TYPE,IDENTITY_CRYPTED) values(?,?,?)", boost::assign::list_of(DBValue(this->Encrypt(chatId)))(DBValue((int)evt.Type))(DBValue(this->Encrypt(evt.Identity))));
}

bool UserDbAccessor::RemoveUnsynchronizedChatEvent(const ChatIdType& chatId, const UnsynchronizedChatEventDbModel& evt)
{
	return this->Execute("delete from UNSYNCHRONIZED_CHAT_EVENTS where CHAT_ID_CRYPTED = ? and EVENT_TYPE = ? and IDENTITY_CRYPTED = ?", boost::assign::list_of(DBValue(this->Encrypt(chatId)))(DBValue((int)evt.Type))(DBValue(this->Encrypt(evt.Identity))));
}

bool UserDbAccessor::InsertChat(ChatDbModel& chat)
{
	std::string statement = "ID_CRYPTED,SERVERED,ACTIVE,VISIBLE,ISP2P,LAST_CLEAR_TIME,CREATION_TIME,CUSTOM_TITLE_CRYPTED,SYNCHRONIZED";
	std::string values = "?,?,?,?,?,?,?,?,?";

	DBValueList args = boost::assign::list_of(DBValue(this->Encrypt(chat.Id.c_str())))(DBValue(chat.Servered))(DBValue(chat.Active))
		(DBValue(chat.Visible))(DBValue(chat.IsP2P))(DBValue((int64_t)posix_time_to_time_t(chat.LastClearTime)))
		(DBValue((int64_t)posix_time_to_time_t(posix_time_now())))(DBValue(this->Encrypt(chat.CustomTitle)))(DBValue(chat.Synchronized));

	statement = "insert into CHATS(" + statement + ") values(" + values + ")";
	if (this->Execute(statement.c_str(), args))
		return InsertChatContacts(chat);
	return false;
}

bool UserDbAccessor::UpdateChat(ChatDbModel& chat)
{
	std::string preparedId = this->Encrypt(chat.Id.c_str());
	std::string statement = "update CHATS set SERVERED = ?, ACTIVE = ?, VISIBLE = ?, ISP2P = ?, LAST_CLEAR_TIME = ?, CREATION_TIME = ?, CUSTOM_TITLE_CRYPTED = ?, SYNCHRONIZED = ? where ID_CRYPTED = ?";

	DBValueList args = boost::assign::list_of(DBValue(chat.Servered))(DBValue(chat.Active))(DBValue(chat.Visible))(DBValue(chat.IsP2P))
		(DBValue((int64_t)posix_time_to_time_t(chat.LastClearTime)))(DBValue((int64_t)posix_time_to_time_t(chat.CreationDate)))
		(DBValue(this->Encrypt(chat.CustomTitle.c_str())))(DBValue(chat.Synchronized))(DBValue(preparedId));

	if (this->Execute(statement.c_str(), args))
	{
		if (chat.Synchronized)
			this->Execute("delete from UNSYNCHRONIZED_CHAT_EVENTS where CHAT_ID_CRYPTED = ?", boost::assign::list_of(preparedId));
		this->Execute("delete from CHAT_MESSAGES where CHAT_ID_CRYPTED = ? and SEND_TIME <= ?", boost::assign::list_of(DBValue(preparedId))(DBValue((int64_t)posix_time_to_time_t(chat.LastClearTime))));
		return this->InsertChatContacts(chat);
	}
	return false;
}

bool UserDbAccessor::InsertChatContacts(const ChatDbModel& chat)
{
    bool result = true;
	
	ChatIdType preparedChatId = this->Encrypt(chat.Id);
	DBValueList args = boost::assign::list_of(DBValue(preparedChatId));
	std::string params;
	for (auto iter = chat.ContactXmppIds.begin(); iter != chat.ContactXmppIds.end(); iter++)
	{
		ContactXmppIdType preparedXmppId = this->Encrypt(iter->c_str());

		result = result && this->Execute("insert or ignore into CHAT_MEMBERS(CHAT_ID_CRYPTED,MEMBER_ID_CRYPTED) values(?,?)",
			boost::assign::list_of(DBValue(preparedChatId))(DBValue(preparedXmppId)));

		params += std::string((iter == chat.ContactXmppIds.begin()) ? "" : ",") + "?";
		args.push_back(DBValue(preparedXmppId));
	}
	if (!params.empty())
		result = result && this->Execute((std::string("delete from CHAT_MEMBERS where CHAT_ID_CRYPTED = ? and MEMBER_ID_CRYPTED not in (") + params + ")").c_str(), args);
    return result;
}
    
bool UserDbAccessor::FillChatsContacts(ChatDbModelSet& chats) const
{
	std::string params;
	DBValueList args;
	for (auto iter = chats.begin(); iter != chats.end(); iter++)
	{
		params += std::string(iter == chats.begin() ? "" : ",") + "?";
		args.push_back(DBValue(this->Encrypt(iter->Id)));
	}

    DBResult contactsDbResult;
	if (this->Execute((std::string("select * from CHAT_MEMBERS where CHAT_ID_CRYPTED in (") + params + ")").c_str(), args, &contactsDbResult)) 
	{
		for (auto citer = contactsDbResult.Rows.begin(); citer != contactsDbResult.Rows.end(); citer++)
		{
			ChatIdType chatId = this->Decrypt(citer->Values.at("CHAT_ID_CRYPTED"));
			for (auto iter = chats.begin(); iter != chats.end(); iter++)
				if (iter->Id == chatId)
				{
					((ChatDbModel&)*iter).ContactXmppIds.insert(this->Decrypt(citer->Values.at("MEMBER_ID_CRYPTED")));
					break;
				}
		}
        return true;
    }
    return false;
}

bool UserDbAccessor::SaveChatMessage(ChatMessageDbModel& message)
{
    ChatMessageDbModel exists = this->GetChatMessageById(message.Id);
    ChatMessageDbModel existsGlobally = this->GetChatMessageById(message.Id, true);
    
    if (exists.Id.empty() && existsGlobally.Id.empty())
        return this->InsertChatMessage(message);
		
	message.IsNew = false;
    
	if (!message.Readed && !exists.Id.empty() && exists.Readed)
		message.Readed = exists.Readed;
    
    if (!message.Readed && !existsGlobally.Id.empty() && existsGlobally.Readed)
        message.Readed = existsGlobally.Readed;
    
	if (message.Servered && !exists.Servered && !exists.Id.empty())
		message.IsNew = true;
    
    if (message.Servered && !existsGlobally.Id.empty() && !existsGlobally.Servered)
        message.IsNew = true;
    
	return this->UpdateChatMessage(message);
}

bool UserDbAccessor::MarkMessagesAsReaded(const ChatMessageIdType& untilMessageId)
{
	return this->Execute("update CHAT_MESSAGES set READED = 1 where CHAT_ID_CRYPTED = (select CHAT_ID_CRYPTED from CHAT_MESSAGES where ID = ?) \
							and ROWNUM <= (select ROWNUM from CHAT_MESSAGES where ID = ?)", 
		boost::assign::list_of(DBValue((std::string)untilMessageId))(DBValue((std::string)untilMessageId)));
}

bool UserDbAccessor::MarkAllMessagesAsReaded(void)
{
	return this->Execute("update CHAT_MESSAGES set READED = 1 where READED = 0");
}

ChatMessageDbModel UserDbAccessor::GetChatMessageById(const ChatMessageIdType& id, bool globally)
{
    std::string dbView = globally?"VISIBLE_CHAT_MESSAGES_VIEW":"CHAT_MESSAGES_VIEW";
    DBResult dbresult;
    if (this->Execute(("select * from "+dbView+" where ID = ?").c_str(),
		boost::assign::list_of(DBValue(id)),&dbresult) && !dbresult.Rows.empty()) 
        return this->DbRowToChatMessageDbModel(*dbresult.Rows.begin());
    return ChatMessageDbModel();
}
                                                                                              
bool UserDbAccessor::InsertChatMessage(const ChatMessageDbModel &message)
{
    bool result = this->Execute("insert into CHAT_MESSAGES(ID, CHAT_ID_CRYPTED, TYPE, SENDER_ID_CRYPTED, SERVERED, SEND_TIME, READED, STRING_CONTENT_CRYPTED, EXTENDED_CONTENT_CRYPTED, REPLACED_ID) values(?,?,?,?,?,?,?,?,?,?)",
                                            boost::assign::list_of
                                            (DBValue(message.Id))
                                            (DBValue(this->Encrypt(message.ChatId)))
                                            (DBValue(message.Type))
                                            (DBValue(this->Encrypt(message.Sender)))
                                            (DBValue(message.Servered))
                                            (DBValue((int64_t)posix_time_to_time_t(message.SendTime)))
                                            (DBValue(message.Readed))
                                            (DBValue(this->Encrypt(message.StringContent)))
											(DBValue(this->Encrypt(message.ExtendedContent)))
                                            (DBValue(message.ReplacedId)));
    return result;
}
    
bool UserDbAccessor::UpdateChatMessage(const ChatMessageDbModel &message) 
{
	// DMC-5801: исправление зацикливания push-нотификаций
	if (message.Servered)
		this->Execute("update CHAT_MESSAGES set SERVERED = 1 where REPLACED_ID = ?", boost::assign::list_of(DBValue(message.Id)));
	return this->Execute("update CHAT_MESSAGES set TYPE = ?, SERVERED = ?, READED = ?, STRING_CONTENT_CRYPTED = ?, EXTENDED_CONTENT_CRYPTED = ?, REPLACED_ID = ? where ID = ?",
                         boost::assign::list_of
                         (DBValue(message.Type))
                         (DBValue(message.Servered))
                         (DBValue(message.Readed))
                         (DBValue(this->Encrypt(message.StringContent)))
                         (DBValue(this->Encrypt(message.ExtendedContent)))
                         (DBValue(message.ReplacedId))
                         (DBValue(message.Id)));
}   
    
bool UserDbAccessor::GetChatMessages(const ChatIdType& chatId, ChatMessageDbModelSet& result) const 
{
    DBResult dbresult;
    if (this->Execute("select * from CHAT_MESSAGES_VIEW where CHAT_ID_CRYPTED = ?",
		boost::assign::list_of(DBValue(this->Encrypt(chatId))),&dbresult)) 
	{
		this->DbResultToChatMessageSet(dbresult,result);
		return true;
    }
	return false;
}
                                                                                              
bool UserDbAccessor::GetChatMessagesPaged(const ChatIdType& chatId, int pageSize, ChatMessageIdType const &lastMsgId, ChatMessageDbModelList& result) const
{
    DBResult dbresult;
    if (this->Execute("select * from CHAT_MESSAGES_VIEW where CHAT_ID_CRYPTED = ? and ROWNUM < ifnull((select max(ROWNUM) from CHAT_MESSAGES where ID = ?), 4294967295) order by ROWNUM desc limit ?",
                          boost::assign::list_of(DBValue(this->Encrypt(chatId)))(DBValue(lastMsgId))(DBValue(pageSize)), &dbresult))
    {
        this->DbResultToChatMessageList(dbresult,result);
        return true;
    }
    return false;
}

ChatMessageDbModel UserDbAccessor::GetLastMessageOfChat(const ChatIdType& chatId) const
{
    DBResult dbresult;
	if (this->Execute("select * from CHAT_MESSAGES_VIEW where CHAT_ID_CRYPTED = ? order by ROWNUM desc limit 1",
		boost::assign::list_of(DBValue(this->Encrypt(chatId))),&dbresult) && !dbresult.Rows.empty())
		return this->DbRowToChatMessageDbModel(*dbresult.Rows.begin());
	return ChatMessageDbModel();
}

bool UserDbAccessor::GetLastMessagesOfAllChats(ChatMessageDbModelSet& result) const
{
	DBResult dbresult;
	if (this->Execute("select * from CHAT_MESSAGES_VIEW group by CHAT_ID_CRYPTED order by ROWNUM desc",
		DBValueList(), &dbresult))
	{
		this->DbResultToChatMessageSet(dbresult, result);
		return true;
	}
	return false;
}

bool UserDbAccessor::GetLastMessagesOfChats(const ChatIdSet& chatIds, ChatMessageDbModelSet& result) const
{
	DBValueList args;
	std::string params;
	for (auto iter = chatIds.begin(); iter != chatIds.end(); iter++)
	{
		params += std::string((iter != chatIds.begin()) ? "," : "") + "?";
		args.push_back(DBValue(this->Encrypt(*iter)));
	}
	DBResult dbresult;
	if (this->Execute((std::string("select * from CHAT_MESSAGES_VIEW where CHAT_ID_CRYPTED in (") + params + ") group by CHAT_ID_CRYPTED order by ROWNUM desc").c_str(),
		args, &dbresult))
	{
		this->DbResultToChatMessageSet(dbresult, result);
		return true;
	}
	return false;
}

bool UserDbAccessor::GetMessagesByIds(const ChatMessageIdSet& ids, ChatMessageDbModelSet& result, bool globally) const
{
	std::string statement;
    DBValueList args;
	for (ChatMessageIdSet::const_iterator iter = ids.begin(); iter != ids.end(); iter++)
	{
		statement += ((iter == ids.begin()) ? "?" : ",?");
		args.push_back(DBValue(*iter));
	}
    
    std::string dbView = globally?"VISIBLE_CHAT_MESSAGES_VIEW":"CHAT_MESSAGES_VIEW";
    DBResult dbresult;
    if (this->Execute((std::string("select * from "+dbView+" where ID in (")+statement+")").c_str(),args,&dbresult))
	{
		this->DbResultToChatMessageSet(dbresult,result);
		return true;
    }
	return false;
}

bool UserDbAccessor::GetUnsynchronizedChats(ChatDbModelSet& result) const
{
	DBResult dbresult;
	if (this->Execute("select * from CHATS_VIEW where SYNCHRONIZED = 0", DBValueList(), &dbresult))
	{
		this->DbResultToChatSet(dbresult, result);
		return true;
	}
	return false;
}

bool UserDbAccessor::GetUnserveredMessages(const ChatIdType& chatId, ChatMessageDbModelList& result) const
{
	DBResult dbresult;
    if (this->Execute("SELECT MES.* FROM CHAT_MESSAGES MES, CHATS CHAT  \
                      WHERE MES.CHAT_ID_CRYPTED = CHAT.ID_CRYPTED  \
                      AND CHAT.VISIBLE = 1  \
                      AND MES.SEND_TIME > CHAT.LAST_CLEAR_TIME \
                      AND MES.SERVERED = 0 \
                      AND MES.CHAT_ID_CRYPTED = ? \
                      ORDER BY MES.ROWNUM", boost::assign::list_of(DBValue(this->Encrypt(chatId))), &dbresult))
	{
		this->DbResultToChatMessageList(dbresult, result);
		return true;
	}
	return false;
}

bool UserDbAccessor::GetUnserveredP2pMessages(ChatMessageDbModelList& result) const
{
	DBResult dbresult;
    
    if (this->Execute("SELECT MES.* FROM CHAT_MESSAGES MES, CHATS CHAT  \
                      WHERE MES.CHAT_ID_CRYPTED = CHAT.ID_CRYPTED  \
                      AND CHAT.VISIBLE = 1  \
                      AND MES.SEND_TIME > CHAT.LAST_CLEAR_TIME \
                      AND MES.SERVERED = 0 \
                      AND CHAT.ISP2P = 1 \
                      ORDER BY ROWNUM", DBValueList(), &dbresult))
	{
		this->DbResultToChatMessageList(dbresult, result);
		return true;
	}
	return false;
}

bool UserDbAccessor::GetChatIdsWithNewMessages(ChatIdSet& chatIds) const
{
	DBResult dbresult;
	if (this->Execute("select distinct(CHAT_ID_CRYPTED) CHAT_ID_CRYPTED from CHAT_MESSAGES_VIEW where READED = 0", DBValueList(), &dbresult))
	{
		for (auto iter = dbresult.Rows.begin(); iter != dbresult.Rows.end(); iter++)
			chatIds.insert(this->Decrypt(iter->Values.at("CHAT_ID_CRYPTED")));
		return true;
	}
	return false;
}

void UserDbAccessor::DbResultToChatSet(const DBResult& dbresult, ChatDbModelSet &result) const 
{
    for (DBRowList::const_iterator iter = dbresult.Rows.begin(); iter != dbresult.Rows.end(); iter++) 
	{
        ChatDbModel chat = this->DbRowToChatDbModel(*iter);
		result.insert(chat);
    }
	if (!this->FillChatsContacts(result))
		result.clear();
}
    
ChatDbModel UserDbAccessor::DbRowToChatDbModel(const DBRow& row) const 
{
    ChatDbModel result;
	result.Id = (std::string)this->Decrypt(row.Values.at("ID_CRYPTED"));
   
	result.CustomTitle = this->Decrypt((std::string)row.Values.at("CUSTOM_TITLE_CRYPTED"));
	result.Servered = (bool)row.Values.at("SERVERED");
    result.Active = (bool)row.Values.at("ACTIVE");
	result.Visible = (bool)row.Values.at("VISIBLE");
    result.IsP2P = (bool)row.Values.at("ISP2P");
	result.LastClearTime = time_t_to_posix_time((time_t)(int64_t)row.Values.at("LAST_CLEAR_TIME"));
    result.CreationDate = time_t_to_posix_time((time_t)(int64_t)row.Values.at("CREATION_TIME"));
	result.Synchronized = (bool)row.Values.at("SYNCHRONIZED");

	result.TotalMessagesCount = (int)row.Values.at("TOTAL_MESSAGES_COUNT");
	result.NewMessagesCount = (int)row.Values.at("NEW_MESSAGES_COUNT");

	time_t lastModified = (time_t)(int64_t)row.Values.at("LAST_MODIFIED_DATE");
    
	if (lastModified)
		result.LastModifiedDate = time_t_to_posix_time(lastModified);
	else
		result.LastModifiedDate = result.GetDateOfCreation();

	return result;
}

UnsynchronizedChatEventDbModel UserDbAccessor::DbResultToUnsynchronizedChatEventDbModel(const DBRow& row) const
{
	UnsynchronizedChatEventDbModel result;
	result.Type = (UnsynchronizedChatEventType)(int)row.Values.at("EVENT_TYPE");
	result.Identity = this->Decrypt((std::string)row.Values.at("IDENTITY_CRYPTED"));
	return result;
}

void UserDbAccessor::DbResultToUnsynchronizedChatEventDbSet(const DBResult& dbresult, UnsynchronizedChatEventDbSet& result) const
{
	for (auto iter = dbresult.Rows.begin(); iter != dbresult.Rows.end(); iter++)
		result.insert(this->DbResultToUnsynchronizedChatEventDbModel(*iter));
}

ChatMessageDbModel UserDbAccessor::DbRowToChatMessageDbModel(const DBRow& row) const
{
    ChatMessageDbModel result;
	result.Rownum = (int)row.Values.at("ROWNUM");
    result.Id = (std::string)row.Values.at("ID");
	result.ChatId = this->Decrypt((std::string)row.Values.at("CHAT_ID_CRYPTED"));
    result.Type = (ChatMessageType)(int)row.Values.at("TYPE");
    result.Sender = this->Decrypt((std::string)row.Values.at("SENDER_ID_CRYPTED"));
    result.Servered = (bool)row.Values.at("SERVERED");
    result.SendTime = time_t_to_posix_time((time_t)(int64_t)row.Values.at("SEND_TIME"));
    result.Readed = (bool)row.Values.at("READED");
    result.StringContent = this->Decrypt((std::string)row.Values.at("STRING_CONTENT_CRYPTED"));
	result.ExtendedContent = this->Decrypt((std::string)row.Values.at("EXTENDED_CONTENT_CRYPTED"));
	result.ReplacedId = (std::string)row.Values.at("REPLACED_ID");
    
    if(!result.ReplacedId.empty() && result.Type == ChatMessageTypeTextMessage)
        result.Changed = true;
    else
        result.Changed = false;
    
    return result;
}
void UserDbAccessor::DbResultToChatMessageSet(const DBResult& dbresult, ChatMessageDbModelSet& result) const
{
    for (DBRowList::const_iterator citer = dbresult.Rows.begin(); citer != dbresult.Rows.end(); citer++) 
        result.insert(this->DbRowToChatMessageDbModel(*citer));
}
void UserDbAccessor::DbResultToChatMessageList(const DBResult& dbresult, ChatMessageDbModelList& result) const
{
	for (DBRowList::const_iterator citer = dbresult.Rows.begin(); citer != dbresult.Rows.end(); citer++)
		result.push_back(this->DbRowToChatMessageDbModel(*citer));
}

bool UserDbAccessor::SaveCall(const CallDbModel& call)
{
	ContactModel contact;
	std::string statement = "ID,DIRECTION,ENCRYPTION,HISTORY_STATUS,READED,END_MODE,ADDRESS_TYPE,DURATION,START_TIME,IDENTITY_CRYPTED";
	std::string values = "?,?,?,?,?,?,?,?,?,?";

	DBValueList args = boost::assign::list_of
	(DBValue(call.Id))
		(DBValue(call.Direction))
		(DBValue(call.Encription))
		(DBValue(call.HistoryStatus))
		(DBValue(call.Readed))
		(DBValue(call.EndMode))
		(DBValue(call.AddressType))
		(DBValue(call.Duration))
		(DBValue(static_cast<int64_t>(posix_time_to_time_t(call.StartTime))))
		(DBValue(this->Encrypt(call.Identity)))
		;

	if (call.Contact)
	{
		if (call.Contact->Id)
		{
			statement += ",CONTACT_ID";
			values += ",?";
			args.push_back(DBValue((int64_t)call.Contact->Id));
		}
		if (!call.Contact->DodicallId.empty())
		{
			statement += ",DODICALL_ID_CRYPTED";
			values += ",?";
			args.push_back(DBValue(this->Encrypt(call.Contact->DodicallId)));
		}
		else if (!call.Contact->PhonebookId.empty())
		{
			statement += ",PHONEBOOK_ID_CRYPTED";
			values += ",?";
			args.push_back(DBValue(this->Encrypt(call.Contact->PhonebookId)));
		}
	}

	statement = std::string("insert or replace into CALLS (") + statement + ") values (" + values + ")";
	const bool ret = this->Execute(statement.c_str(), args);
	//assert(ret && !"failed UserDbAccessor::SaveCall");
	return ret;
}
bool UserDbAccessor::DeleteCall(const CallDbModel& call)
{
	// TODO implement
	return false;
}

CallDbModel UserDbAccessor::DbRowToCallDbModel(const DBRow& row) const
{
	CallDbModel result;

	result.Id = (std::string)row.Values.at("ID");
	result.Direction = static_cast<CallDirection>((int)row.Values.at("DIRECTION"));
	result.Encription = static_cast<VoipEncryptionType>((int)row.Values.at("ENCRYPTION"));
	result.HistoryStatus = static_cast<HistoryStatusType>((int)row.Values.at("HISTORY_STATUS"));
	result.Readed = static_cast<bool>((int)row.Values.at("READED"));
	result.EndMode = static_cast<CallEndMode>((int)row.Values.at("END_MODE"));
	result.AddressType = static_cast<CallAddressType>((int)row.Values.at("ADDRESS_TYPE"));
	result.Duration = (int)row.Values.at("DURATION");
	result.StartTime = time_t_to_posix_time((time_t)(int64_t)row.Values.at("START_TIME"));
	result.Identity = this->Decrypt((std::string)row.Values.at("IDENTITY_CRYPTED"));
	
	int contactId = (int)row.Values.at("CONTACT_ID");
	std::string dodicallId = this->Decrypt((std::string)row.Values.at("DODICALL_ID_CRYPTED"));
	std::string phonebookId = this->Decrypt((std::string)row.Values.at("PHONEBOOK_ID_CRYPTED"));
	if (contactId)
		result.Contact = this->GetContactById(contactId);
	if (!result.Contact && (!dodicallId.empty() || !phonebookId.empty()))
	{
		result.Contact = ContactModel();
		result.Contact->DodicallId = dodicallId;
		result.Contact->PhonebookId = phonebookId;
	}

	return result;
}

int UserDbAccessor::GetNumberOfMissedCalls(void) const
{
	DBResult dbresult;
	if (this->Execute("select COUNT(*) CNT from CALLS where READED = 0 and HISTORY_STATUS = ?", boost::assign::list_of(DBValue((int)HistoryStatusMissed)), &dbresult))
	{
		DBRow& row = dbresult.Rows.at(0);
		if (!row.Values.empty())
			return (int)row.Values["CNT"];
		return 0;
	}
	return -1;
}

bool UserDbAccessor::GetCallHistory(CallDbModelList& result) const
{
	result.clear();
	DBResult dbresult;

	#pragma message("TODO: use FromTime & ToTime")

	if (this->Execute("select * from CALLS order BY START_TIME desc", DBValueList(), &dbresult))
	{
		for (DBRowList::const_iterator iter = dbresult.Rows.begin(); iter != dbresult.Rows.end(); ++iter)
			result.push_back(DbRowToCallDbModel(*iter));
	}
	return true;
}

bool UserDbAccessor::SetCallHistoryEntriesReaded(const CallIdSet& ids)
{
	if (ids.empty())
		return true;

	std::string params;
	DBValueList args;
	for (auto iter = ids.begin(); iter != ids.end(); iter++)
	{
		if (iter != ids.begin())
			params += ",";
		params += "?";
		args.push_back(DBValue(*iter));
	}
	return this->Execute((std::string("update CALLS set READED = 1 where ID in (") + params + ")").c_str(), args);
}
                      
bool UserDbAccessor::SetHoldingCompanyIds(CompanyIdsSet const &ids)
{
    std::string params, dparams;
    DBValueList args;
    for (auto iter = ids.begin(); iter != ids.end(); ++iter)
    {
        params += std::string(iter == ids.begin() ? "" : ",") + "(?)";
		dparams += std::string(iter == ids.begin() ? "" : ",") + "?";
        args.push_back(DBValue(this->Encrypt(*iter)));
    }
    
    return this->Execute((std::string("insert or ignore into HOLDING_COMPANIES(COMPANY_ID_CRYPTED) values ") + params).c_str(), args)
		&& this->Execute((std::string("delete from HOLDING_COMPANIES where COMPANY_ID_CRYPTED not in (") + dparams + ")").c_str(), args);
}
                      
bool UserDbAccessor::IsCompanyInMyHolding(CompanyIdType const &id) const
{
    DBResult dbresult;
	if (this->Execute("select * from HOLDING_COMPANIES_VIEW where COMPANY_ID_CRYPTED = ?",
		boost::assign::list_of(DBValue(this->Encrypt(id))), &dbresult) && !dbresult.Rows.empty())
		return true;
    return false;
}

}
