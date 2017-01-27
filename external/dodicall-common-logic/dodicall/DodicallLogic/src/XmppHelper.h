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
#include <strophe/strophe.h>

#include "MiscUtils.h"

namespace dodicall
{

class XmppHelper
{
private:
	XmppHelper() {};

public:
	static void SendIqResult(xmpp_conn_t* const conn, const char* id, const char* to, const char* type = "result");
	static void SendPresenceEx(xmpp_conn_t* const conn, const char* to, const char* type, const char* stateStr, const char* statusStr, xmpp_stanza_t* additional = 0);
	static void DiscoverItems(xmpp_conn_t* const conn, const char* domain, const char* id = 0, int limit = 0, const char* after = 0);
    static void DiscoverChatRoomMembers(xmpp_conn_t* const conn, const char* jid, const char* affiliation, const char* id = 0);

	static void RequestTime(xmpp_conn_t* const conn, const char* to, const char* id = "time");

    static void CreateChatRoom(xmpp_conn_t* const conn, const char* roomJid, const char* id = 0);
    static void ConfirmInstantRoomCreation(xmpp_conn_t* const conn, const char* id = 0);
    static void RequestConfigForm(xmpp_conn_t* const conn, const char* jid, const char* id = 0);
    static void ConfigureChatRoom(xmpp_conn_t* const conn, const char* roomJid, const char* id = 0, std::set<std::string> const &userJidList = std::set<std::string> ());
    static void AddFieldHelper(xmpp_ctx_t* const ctx, xmpp_stanza_t *x, const char* var, const char* val, bool type = false);
    static void BulkAddFieldHelper(xmpp_ctx_t* const ctx, xmpp_stanza_t *x, const char* var, std::set<std::string> values);
    
	static void DiscoverInfo(xmpp_conn_t* const conn, const char* jid, const char* id = 0);
    
    static void RetrieveArchivePrefs(xmpp_conn_t* const conn, const char* id);
    static void SetArchivePrefs(xmpp_conn_t* const conn, std::set<std::string> const &userJidList, const char* id);
    
    static void QueryUserArchive(xmpp_conn_t* const conn, const char* id);
    static void QueryLatestArchive(xmpp_conn_t* const conn, const char* id, const boost::posix_time::ptime &time);
    
	static void RetrieveRoster(xmpp_conn_t* const conn, const char* id = 0);
	static void AddRosterItem(xmpp_conn_t* const conn, const char* jid, const char* subscription, const char* id = 0);

	static void RetrivePrivateData(xmpp_conn_t* const conn, const char* xmlns, const char* tagName, const char* id = 0);
	static void StorePrivateData(xmpp_conn_t* const conn, xmpp_stanza_t* data, const char* id);
	static void UploadDirectoryContactManuals(xmpp_conn_t* const conn, const char* ns, const char* data, const char* id);
	static void SendXmppMessage(xmpp_conn_t* const conn, const char* id, const char* type, const char* to,
		const char* bodyStr, const char* dataStr, const char* subjectStr, const char* replaceStr, bool noStore = false, const char* defaultSubjectStr = 0);
    
    static void InviteUsers(xmpp_conn_t* const conn, char const *roomJid, std::set<std::string> const &userJidList);
    static void GrantRoomToUsers(xmpp_conn_t* const conn, char const *roomJid, std::set<std::string> const &userJidList, char const *affiliation, const char* id);
    static void NotifyRevoked (xmpp_conn_t* const conn, const char* roomJid, std::set<std::string> const &userJidList);

    static void DestroyChatRoom(xmpp_conn_t* const conn, char const *roomJid, char const *queryId);
};

//=========================================================
//Механизм для освобождения памяти, выделяемой при использовании xmpp_stanza_get_text
//instead of:
//	const char* text = xmpp_stanza_get_text(stanza);
//
//use:
//	XmppText text(this->mConnection, stanza);
//	... const char* use_as_c_str = text; ...

#ifndef xmpp_stanza_get_text	//Можно закомментировать этот блок макросов, не повлияет на функционалбность!!! Необязательная защита от попытки добавить еще вызовы xmpp_stanza_get_text в будущем вместо использования XmppText
#define xmpp_stanza_get_text USE_XmppText_instead_of_xmpp_stanza_get_text
#define use_optional_alert_for_future_usage_of_xmpp_stanza_get_text
#endif

class XmppText: MiscUtils::CantCopy
{
private:
	const char* mText;
	const xmpp_ctx_t * mCtx;

public:
	XmppText(xmpp_conn_t * conn, xmpp_stanza_t * const stanza);
	~XmppText();
	operator const char* () const;
};

inline bool operator != (const std::string& s, const XmppText& x)
{
	assert(x);
	return (s != static_cast<const char*>(x));
}

void free(const MiscUtils::CantCopy&);	// генерит ошибку компиляции при попытке использования free для объекта XmppText
void xmpp_free(const xmpp_ctx_t*, const MiscUtils::CantCopy&);	// аналогично для xmpp_free


}
