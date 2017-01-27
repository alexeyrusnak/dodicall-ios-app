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
#include "XmppHelper.h"

namespace dodicall
{

void XmppHelper::SendIqResult(xmpp_conn_t* const conn, const char* id, const char* to, const char* type)
{
    xmpp_ctx_t* ctx = xmpp_conn_get_context(conn);
    
    xmpp_stanza_t *iq = xmpp_stanza_new(ctx);
        
    xmpp_stanza_set_name(iq, "iq");
    xmpp_stanza_set_type(iq, type);
    xmpp_stanza_set_attribute(iq, "to", to);
    if (id)
		xmpp_stanza_set_id(iq, id);
        
    xmpp_send(conn, iq);

	xmpp_stanza_release(iq);
}
    
void XmppHelper::SendPresenceEx(xmpp_conn_t* const conn, const char* to, const char* type, const char* stateStr, const char* statusStr, xmpp_stanza_t* additional)
{
	xmpp_ctx_t* ctx = xmpp_conn_get_context(conn);

	xmpp_stanza_t* presence = xmpp_stanza_new(ctx);
	xmpp_stanza_t* text;

	xmpp_stanza_set_name(presence, "presence");
	xmpp_stanza_set_ns(presence, XMPP_NS_CLIENT);

	if (to && to[0])
		xmpp_stanza_set_attribute(presence,"to",to);

	if (type && type[0])
		xmpp_stanza_set_type(presence,type);

	if (stateStr && stateStr[0])
	{
		xmpp_stanza_t* show = xmpp_stanza_new(ctx);
		xmpp_stanza_set_name(show, "show");
		
		text = xmpp_stanza_new(ctx);
		xmpp_stanza_set_text(text, stateStr);

		xmpp_stanza_add_child(show,text);
		xmpp_stanza_add_child(presence,show);

		xmpp_stanza_release(text);
		xmpp_stanza_release(show);
	}

	if (statusStr && statusStr[0])
	{
		xmpp_stanza_t* status = xmpp_stanza_new(ctx);
		xmpp_stanza_set_name(status, "status");

		text = xmpp_stanza_new(ctx);
		xmpp_stanza_set_text(text, statusStr);

		xmpp_stanza_add_child(status,text);
		xmpp_stanza_add_child(presence,status);

		xmpp_stanza_release(text);
		xmpp_stanza_release(status);
	}

	if (additional)
		xmpp_stanza_add_child(presence, additional);

	xmpp_send(conn, presence);

	xmpp_stanza_release(presence);
}
    
void XmppHelper::InviteUsers(xmpp_conn_t* const conn, char const *roomJid, std::set<std::string> const &userJidList)
{
    if (userJidList.empty())
        return;
    
    xmpp_ctx_t* ctx = xmpp_conn_get_context(conn);
    
    for (auto iterator = begin (userJidList); iterator != end (userJidList); ++iterator) 
	{
        xmpp_stanza_t *message = xmpp_stanza_new(ctx);
        xmpp_stanza_t *x = xmpp_stanza_new(ctx);
        xmpp_stanza_t *invite;
            
        xmpp_stanza_set_name(message, "message");
        xmpp_stanza_set_attribute(message, "to", roomJid);
        xmpp_stanza_set_type(message, "normal");
            
        xmpp_stanza_set_name(x, "x");
        xmpp_stanza_set_ns(x, "http://jabber.org/protocol/muc#user");
            
        invite = xmpp_stanza_new(ctx);
        xmpp_stanza_set_name(invite, "invite");
        xmpp_stanza_set_attribute(invite, "to", iterator->c_str());
            
        xmpp_stanza_add_child(x,invite);
            
        xmpp_stanza_release(invite);
            
        xmpp_stanza_add_child(message,x);
        xmpp_send(conn, message);
            
        xmpp_stanza_release(x);
        xmpp_stanza_release(message);
    }
}
    
void XmppHelper::GrantRoomToUsers(xmpp_conn_t* const conn, char const *roomJid, std::set<std::string> const &userJidList, char const *affiliation, const char* id)
{
    if (userJidList.empty())
        return;
    
    xmpp_ctx_t* ctx = xmpp_conn_get_context(conn);
    
    xmpp_stanza_t *iq = xmpp_stanza_new(ctx);
    xmpp_stanza_t *query = xmpp_stanza_new(ctx);
    xmpp_stanza_t *item;
        
    xmpp_stanza_set_name(iq, "iq");
    xmpp_stanza_set_type(iq, "set");
    xmpp_stanza_set_attribute(iq, "to", roomJid);
	xmpp_stanza_set_attribute(iq, "id", id);

    xmpp_stanza_set_name(query, "query");
    xmpp_stanza_set_ns(query, "http://jabber.org/protocol/muc#admin");

    for (auto iterator = begin (userJidList); iterator != end (userJidList); ++iterator) 
	{
        item = xmpp_stanza_new(ctx);
        xmpp_stanza_set_name(item, "item");
        xmpp_stanza_set_attribute(item, "jid", iterator->c_str());
        xmpp_stanza_set_attribute(item, "affiliation", affiliation);
            
        xmpp_stanza_add_child(query,item);
            
        xmpp_stanza_release(item);
    }
    
    xmpp_stanza_add_child(iq,query);
        
    xmpp_send(conn, iq);
        
    xmpp_stanza_release(query);
    xmpp_stanza_release(iq);
}
    
void XmppHelper::NotifyRevoked (xmpp_conn_t* const conn, const char* roomJid, std::set<std::string> const &userJidList)
{
    for (auto iterator = begin (userJidList); iterator != end (userJidList); ++iterator) 
	{
        SendXmppMessage(conn, 0, "normal", iterator->c_str(), "#ChatChanged#", roomJid, "", "", true);
    }
}
    
void XmppHelper::DestroyChatRoom(xmpp_conn_t* const conn, char const *roomJid, char const *queryId) 
{
    xmpp_ctx_t* ctx = xmpp_conn_get_context(conn);
    
    xmpp_stanza_t *iq = xmpp_stanza_new(ctx);
    xmpp_stanza_t *query = xmpp_stanza_new(ctx);
    xmpp_stanza_t *destroy = xmpp_stanza_new(ctx);
        
    xmpp_stanza_set_name(iq, "iq");
    xmpp_stanza_set_type(iq, "set");
    xmpp_stanza_set_attribute(iq, "to", roomJid);
    if (queryId)
        xmpp_stanza_set_attribute(iq, "id", queryId);
        
    xmpp_stanza_set_name(query, "query");
    xmpp_stanza_set_ns(query, "http://jabber.org/protocol/muc#owner");
        
    xmpp_stanza_set_name(destroy, "destroy");
        
    xmpp_stanza_add_child(query,destroy);
    xmpp_stanza_add_child(iq,query);
        
    xmpp_send(conn, iq);
        
    xmpp_stanza_release(query);
    xmpp_stanza_release(iq);
}
    

void XmppHelper::DiscoverItems(xmpp_conn_t* const conn, const char* domain, const char* id, int limit, const char* after)
{
	xmpp_ctx_t* ctx = xmpp_conn_get_context(conn);

	xmpp_stanza_t *iq = xmpp_stanza_new(ctx);
	xmpp_stanza_t *query = xmpp_stanza_new(ctx);

	xmpp_stanza_set_name(iq, "iq");
	xmpp_stanza_set_type(iq, "get");
    if (id)
        xmpp_stanza_set_id(iq,id);
	xmpp_stanza_set_attribute(iq, "to",domain);

	if (limit > 0)
	{
		xmpp_stanza_t *set = xmpp_stanza_new(ctx);
		xmpp_stanza_t *max = xmpp_stanza_new(ctx);
		xmpp_stanza_t *maxValue = xmpp_stanza_new(ctx);

		xmpp_stanza_set_name(set, "set");
		xmpp_stanza_set_ns(set, "http://jabber.org/protocol/rsm");

		xmpp_stanza_set_name(max, "max");

		xmpp_stanza_set_text(maxValue, boost::lexical_cast<std::string>(limit).c_str());
		xmpp_stanza_add_child(max, maxValue);

		xmpp_stanza_add_child(set, max);

		if (after && after[0])
		{
			xmpp_stanza_t *aft = xmpp_stanza_new(ctx);
			xmpp_stanza_t *aftValue = xmpp_stanza_new(ctx);
			xmpp_stanza_set_name(aft, "after");
			xmpp_stanza_set_text(aftValue, after);

			xmpp_stanza_add_child(aft, aftValue);
			xmpp_stanza_add_child(set, aft);
			xmpp_stanza_release(aftValue);
			xmpp_stanza_release(aft);
		}

		xmpp_stanza_add_child(query, set);

		xmpp_stanza_release(maxValue);
		xmpp_stanza_release(max);
		xmpp_stanza_release(set);
	}

	xmpp_stanza_set_name(query, "query");
	xmpp_stanza_set_ns(query,"http://jabber.org/protocol/disco#items");
	
	xmpp_stanza_add_child(iq,query);

	xmpp_send(conn, iq);

	xmpp_stanza_release(query);
	xmpp_stanza_release(iq);
}
    
void XmppHelper::DiscoverChatRoomMembers(xmpp_conn_t* const conn, const char* jid, const char* affiliation, const char* id) 
{
    xmpp_ctx_t* ctx = xmpp_conn_get_context(conn);
    
    xmpp_stanza_t *iq = xmpp_stanza_new(ctx);
    xmpp_stanza_t *query = xmpp_stanza_new(ctx);
    xmpp_stanza_t *item = xmpp_stanza_new(ctx);
        
    xmpp_stanza_set_name(iq, "iq");
    xmpp_stanza_set_type(iq, "get");
    if (id)
        xmpp_stanza_set_id(iq,id);
    xmpp_stanza_set_attribute(iq, "to", jid);
        
    xmpp_stanza_set_name(query, "query");
    xmpp_stanza_set_ns(query,"http://jabber.org/protocol/muc#admin");
        
    xmpp_stanza_set_name(item, "item");
    xmpp_stanza_set_attribute(item, "affiliation", affiliation);
        
    xmpp_stanza_add_child(query,item);
    xmpp_stanza_add_child(iq,query);
        
    xmpp_send(conn, iq);
        
    xmpp_stanza_release(item);
    xmpp_stanza_release(query);
    xmpp_stanza_release(iq);
}

void XmppHelper::RequestTime(xmpp_conn_t* const conn, const char* to, const char* id)
{
	xmpp_ctx_t* ctx = xmpp_conn_get_context(conn);

	xmpp_stanza_t *iq = xmpp_stanza_new(ctx);
	xmpp_stanza_t *stime = xmpp_stanza_new(ctx);

	xmpp_stanza_set_name(iq, "iq");
	xmpp_stanza_set_type(iq, "get");
	xmpp_stanza_set_attribute(iq, "to", to);
	if (id)
		xmpp_stanza_set_id(iq, id);

	xmpp_stanza_set_name(stime, "time");
	xmpp_stanza_set_ns(stime, "urn:xmpp:time");

	xmpp_stanza_add_child(iq, stime);

	xmpp_send(conn, iq);

	xmpp_stanza_release(stime);
	xmpp_stanza_release(iq);
}

void XmppHelper::CreateChatRoom(xmpp_conn_t* const conn, const char* roomJid, const char* id) 
{
    xmpp_ctx_t* ctx = xmpp_conn_get_context(conn);
    
    xmpp_stanza_t* presence = xmpp_stanza_new(ctx);
    xmpp_stanza_t* x = xmpp_stanza_new(ctx);
        
    xmpp_stanza_set_name(presence, "presence");
    if (id)
        xmpp_stanza_set_id(presence,id);
    xmpp_stanza_set_attribute(presence,"to",roomJid);
        
    xmpp_stanza_set_name(x, "x");
    xmpp_stanza_set_ns(x,"http://jabber.org/protocol/muc");
        
    xmpp_stanza_add_child(presence,x);
        
    xmpp_send(conn, presence);
        
    xmpp_stanza_release(x);
    xmpp_stanza_release(presence);
}

void XmppHelper::DiscoverInfo(xmpp_conn_t* const conn, const char* jid, const char* id)
{
	xmpp_ctx_t* ctx = xmpp_conn_get_context(conn);

	xmpp_stanza_t *iq = xmpp_stanza_new(ctx);
	xmpp_stanza_t *query = xmpp_stanza_new(ctx);

	xmpp_stanza_set_name(iq, "iq");
	xmpp_stanza_set_type(iq, "get");
    if (id)
        xmpp_stanza_set_id(iq,id);
	xmpp_stanza_set_attribute(iq, "to", jid);

	xmpp_stanza_set_name(query, "query");
	xmpp_stanza_set_ns(query,"http://jabber.org/protocol/disco#info");
	
	xmpp_stanza_add_child(iq,query);

	xmpp_send(conn, iq);

	xmpp_stanza_release(query);
	xmpp_stanza_release(iq);
}

void XmppHelper::RequestConfigForm(xmpp_conn_t* const conn, const char* jid, const char* id) 
{
    xmpp_ctx_t* ctx = xmpp_conn_get_context(conn);
    
    xmpp_stanza_t *iq = xmpp_stanza_new(ctx);
    
    xmpp_stanza_set_name(iq, "iq");
    xmpp_stanza_set_type(iq, "get");
    if (id)
        xmpp_stanza_set_id(iq,id);
    xmpp_stanza_set_attribute(iq, "to", jid);
    
    xmpp_stanza_t *query = xmpp_stanza_new(ctx);
    
    xmpp_stanza_set_name(query, "query");
    xmpp_stanza_set_ns(query,"http://jabber.org/protocol/muc#owner");
    
    xmpp_stanza_add_child(iq,query);
    
    xmpp_send(conn, iq);
    
    xmpp_stanza_release(query);
    xmpp_stanza_release(iq);
}
    
void XmppHelper::RetrieveArchivePrefs(xmpp_conn_t* const conn, const char* id)
{
    xmpp_ctx_t* ctx = xmpp_conn_get_context(conn);
        
    xmpp_stanza_t *iq = xmpp_stanza_new(ctx);
    xmpp_stanza_t *prefs = xmpp_stanza_new(ctx);
        
    xmpp_stanza_set_name(iq, "iq");
    xmpp_stanza_set_type(iq, "get");
    if (id)
        xmpp_stanza_set_id(iq,id);
    
    xmpp_stanza_set_name(prefs, "prefs");
    xmpp_stanza_set_ns(prefs,"urn:xmpp:mam:1");
        
    xmpp_stanza_add_child(iq,prefs);
        
    xmpp_send(conn, iq);
        
    xmpp_stanza_release(prefs);
    xmpp_stanza_release(iq);
}

void XmppHelper::SetArchivePrefs(xmpp_conn_t* const conn, std::set<std::string> const &userJidList, const char* id)
{
    xmpp_ctx_t* ctx = xmpp_conn_get_context(conn);
        
    xmpp_stanza_t *iq = xmpp_stanza_new(ctx);
    xmpp_stanza_t *prefs = xmpp_stanza_new(ctx);
        
    xmpp_stanza_set_name(iq, "iq");
    xmpp_stanza_set_type(iq, "set");
    if (id)
        xmpp_stanza_set_id(iq,id);
    
    xmpp_stanza_set_name(prefs, "prefs");
    xmpp_stanza_set_ns(prefs,"urn:xmpp:mam:1");
    xmpp_stanza_set_attribute(prefs, "default", "roster");
    
    xmpp_stanza_t *always = xmpp_stanza_new(ctx);
    xmpp_stanza_set_name(always, "always");
    
    for (auto it = begin (userJidList); it != end (userJidList); ++it) 
	{
		xmpp_stanza_t* roomName = xmpp_stanza_new(ctx);
        xmpp_stanza_set_name(roomName, "jid");
    
		xmpp_stanza_t *roomNameText = xmpp_stanza_new(ctx);
        xmpp_stanza_set_text(roomNameText, (*it).c_str());
    
        xmpp_stanza_add_child(roomName, roomNameText);
        xmpp_stanza_add_child(always, roomName);
        
        xmpp_stanza_release(roomNameText);
        xmpp_stanza_release(roomName);
    }
    
    xmpp_stanza_add_child(prefs, always);
    xmpp_stanza_add_child(iq,prefs);
    
    xmpp_send(conn, iq);
    
    xmpp_stanza_release(always);
    xmpp_stanza_release(prefs);
    xmpp_stanza_release(iq);
}
    
void XmppHelper::QueryUserArchive(xmpp_conn_t* const conn, const char* id)
{
    xmpp_ctx_t* ctx = xmpp_conn_get_context(conn);
        
    xmpp_stanza_t *iq = xmpp_stanza_new(ctx);
    xmpp_stanza_t *query = xmpp_stanza_new(ctx);
        
    xmpp_stanza_set_name(iq, "iq");
    xmpp_stanza_set_type(iq, "set");
    if (id)
        xmpp_stanza_set_id(iq,id);
        
    xmpp_stanza_set_name(query, "query");
    xmpp_stanza_set_ns(query,"urn:xmpp:mam:1");
        
    xmpp_stanza_add_child(iq,query);
        
    xmpp_send(conn, iq);
        
    xmpp_stanza_release(query);
    xmpp_stanza_release(iq);
}
    
void XmppHelper::QueryLatestArchive(xmpp_conn_t* const conn, const char* id, const boost::posix_time::ptime &time)
{
    xmpp_ctx_t* ctx = xmpp_conn_get_context(conn);
        
    xmpp_stanza_t *iq = xmpp_stanza_new(ctx);
    xmpp_stanza_t *query = xmpp_stanza_new(ctx);
    
    xmpp_stanza_t *x = xmpp_stanza_new(ctx);
    xmpp_stanza_set_name(x, "x");
    xmpp_stanza_set_type(x, "submit");
    xmpp_stanza_set_ns(x, "jabber:x:data");
    
    AddFieldHelper(ctx,x,"FORM_TYPE","urn:xmpp:mam:1", true);

	{
		std::string strTime = boost::posix_time::to_iso_extended_string(time);
		size_t strEnd = strTime.find_first_of(',');
		if (strEnd != strTime.npos)
			strTime = strTime.substr(0, strEnd);
		strTime += "Z";
		AddFieldHelper(ctx, x, "start", strTime.c_str());
	}

    xmpp_stanza_set_name(iq, "iq");
    xmpp_stanza_set_type(iq, "set");
    if (id)
        xmpp_stanza_set_id(iq,id);
        
    xmpp_stanza_set_name(query, "query");
    xmpp_stanza_set_ns(query,"urn:xmpp:mam:1");
    
    xmpp_stanza_add_child(query,x);
        
    xmpp_stanza_add_child(iq,query);
        
    xmpp_send(conn, iq);
    
    xmpp_stanza_release(x);
    xmpp_stanza_release(query);
    xmpp_stanza_release(iq);
}
    
void XmppHelper::AddFieldHelper(xmpp_ctx_t* const ctx, xmpp_stanza_t *x, const char* var, const char* val, bool type)
{
    xmpp_stanza_t *field  = xmpp_stanza_new(ctx);
    xmpp_stanza_t *value  = xmpp_stanza_new(ctx);
    xmpp_stanza_t *text  = xmpp_stanza_new(ctx);
        
    xmpp_stanza_set_name(field, "field");
    xmpp_stanza_set_attribute(field, "var", var);
    if (type)
        xmpp_stanza_set_type(field, "hidden");
        
    xmpp_stanza_set_name(value, "value");
    xmpp_stanza_set_text(text, val);
        
    xmpp_stanza_add_child(value,text);
    xmpp_stanza_add_child(field,value);
    xmpp_stanza_add_child(x,field);
        
    xmpp_stanza_release(value);
    xmpp_stanza_release(field);
}

void XmppHelper::BulkAddFieldHelper(xmpp_ctx_t* const ctx, xmpp_stanza_t *x, const char* var, std::set<std::string> values) {
    xmpp_stanza_t *field  = xmpp_stanza_new(ctx);
    xmpp_stanza_t *value  = xmpp_stanza_new(ctx);
    xmpp_stanza_t *text  = xmpp_stanza_new(ctx);
    
    xmpp_stanza_set_name(field, "field");
    xmpp_stanza_set_attribute(field, "var", var);
    
    for (auto it = begin (values); it != end (values); ++it) {
        xmpp_stanza_set_name(value, "value");
        xmpp_stanza_set_text(text, (*it).c_str());
    
        xmpp_stanza_add_child(value,text);
        xmpp_stanza_add_child(field,value);
    }
    
    xmpp_stanza_add_child(x,field);
    
    xmpp_stanza_release(value);
    xmpp_stanza_release(field);
}

void XmppHelper::ConfigureChatRoom(xmpp_conn_t* const conn, const char* roomJid, const char* id, std::set<std::string> const &userJidList)
{
    xmpp_ctx_t* ctx = xmpp_conn_get_context(conn);
    
    xmpp_stanza_t *iq = xmpp_stanza_new(ctx);
    xmpp_stanza_t *query = xmpp_stanza_new(ctx);
    xmpp_stanza_t *x = xmpp_stanza_new(ctx);
        
    xmpp_stanza_set_name(iq, "iq");
    xmpp_stanza_set_type(iq, "set");
    if (id)
        xmpp_stanza_set_id(iq,id);
    xmpp_stanza_set_attribute(iq, "to", roomJid);
        
    xmpp_stanza_set_name(query, "query");
    xmpp_stanza_set_ns(query, "http://jabber.org/protocol/muc#owner");
        
    xmpp_stanza_set_name(x, "x");
    xmpp_stanza_set_type(x, "submit");
    xmpp_stanza_set_ns(x, "jabber:x:data");
        
    AddFieldHelper(ctx,x,"FORM_TYPE","http://jabber.org/protocol/muc#roomconfig");
    AddFieldHelper(ctx,x,"muc#roomconfig_changesubject","1");
    AddFieldHelper(ctx,x,"muc#roomconfig_allowinvites","1");
    AddFieldHelper(ctx,x,"muc#roomconfig_maxusers","30");
    AddFieldHelper(ctx,x,"muc#roomconfig_publicroom","0");
    AddFieldHelper(ctx,x,"muc#roomconfig_persistentroom","1");
    AddFieldHelper(ctx,x,"muc#roomconfig_membersonly","1");
    AddFieldHelper(ctx,x,"muc#roomconfig_whois","anyone");
     
    xmpp_stanza_add_child(query,x);
    xmpp_stanza_add_child(iq,query);
        
    xmpp_send(conn, iq);
        
    xmpp_stanza_release(query);
    xmpp_stanza_release(iq);
}
    
void XmppHelper::RetrieveRoster(xmpp_conn_t* const conn, const char* id)
{
	xmpp_ctx_t* ctx = xmpp_conn_get_context(conn);

	xmpp_stanza_t *iq = xmpp_stanza_new(ctx);
	xmpp_stanza_t *query = xmpp_stanza_new(ctx);

	xmpp_stanza_set_name(iq, "iq");
	xmpp_stanza_set_type(iq, "get");
	if (id)
		xmpp_stanza_set_id(iq,id);

	xmpp_stanza_set_name(query, "query");
	xmpp_stanza_set_ns(query,"jabber:iq:roster");
	
	xmpp_stanza_add_child(iq,query);

	xmpp_send(conn, iq);

	xmpp_stanza_release(query);
	xmpp_stanza_release(iq);
}

void XmppHelper::AddRosterItem(xmpp_conn_t* const conn, const char* jid, const char* subscription, const char* id)
{
	xmpp_ctx_t* ctx = xmpp_conn_get_context(conn);

	xmpp_stanza_t *iq = xmpp_stanza_new(ctx);
	xmpp_stanza_t *query = xmpp_stanza_new(ctx);
	xmpp_stanza_t *item = xmpp_stanza_new(ctx);

	xmpp_stanza_set_name(iq, "iq");
	xmpp_stanza_set_type(iq, "set");
	if (id)
		xmpp_stanza_set_id(iq, id);

	xmpp_stanza_set_name(query, "query");
	xmpp_stanza_set_ns(query, "jabber:iq:roster");

	xmpp_stanza_set_name(item, "item");
	xmpp_stanza_set_attribute(item, "jid", jid);
	xmpp_stanza_set_attribute(item, "subscription", subscription);

	xmpp_stanza_add_child(query, item);
	xmpp_stanza_add_child(iq, query);

	xmpp_send(conn, iq);

	xmpp_stanza_release(query);
	xmpp_stanza_release(iq);
}

void XmppHelper::RetrivePrivateData(xmpp_conn_t* const conn, const char* xmlns, const char* tagName, const char* id)
{
	xmpp_ctx_t* ctx = xmpp_conn_get_context(conn);

	xmpp_stanza_t *iq = xmpp_stanza_new(ctx);
	xmpp_stanza_t *query = xmpp_stanza_new(ctx);
	xmpp_stanza_t *request = xmpp_stanza_new(ctx);

	xmpp_stanza_set_name(iq, "iq");
	xmpp_stanza_set_type(iq, "get");
	if (id)
		xmpp_stanza_set_id(iq,id);

	xmpp_stanza_set_name(query, "query");
	xmpp_stanza_set_ns(query,"jabber:iq:private");
	
	xmpp_stanza_set_name(request, tagName);
	xmpp_stanza_set_ns(request,xmlns);

	xmpp_stanza_add_child(query,request);
	xmpp_stanza_add_child(iq,query);

	xmpp_send(conn, iq);

	xmpp_stanza_release(request);
	xmpp_stanza_release(query);
	xmpp_stanza_release(iq);
}
    
    
void XmppHelper::StorePrivateData(xmpp_conn_t* const conn, xmpp_stanza_t* data, const char* id)
{
	xmpp_ctx_t* ctx = xmpp_conn_get_context(conn);

	xmpp_stanza_t *iq = xmpp_stanza_new(ctx);
	xmpp_stanza_t *query = xmpp_stanza_new(ctx);

	xmpp_stanza_set_name(iq, "iq");
	xmpp_stanza_set_type(iq, "set");
	xmpp_stanza_set_id(iq,id);

	xmpp_stanza_set_name(query, "query");
	xmpp_stanza_set_ns(query,"jabber:iq:private");
	
	xmpp_stanza_add_child(query,data);
	xmpp_stanza_add_child(iq,query);

	xmpp_send(conn, iq);

	xmpp_stanza_release(query);
	xmpp_stanza_release(iq);
}
    
void XmppHelper::ConfirmInstantRoomCreation(xmpp_conn_t* const conn, const char* id) 
{
    xmpp_ctx_t* ctx = xmpp_conn_get_context(conn);
        
    xmpp_stanza_t *iq = xmpp_stanza_new(ctx);
    xmpp_stanza_t *query = xmpp_stanza_new(ctx);
    xmpp_stanza_t *x = xmpp_stanza_new(ctx);
        
    xmpp_stanza_set_name(iq, "iq");
    xmpp_stanza_set_type(iq, "set");
    xmpp_stanza_set_id(iq,id);
        
    xmpp_stanza_set_name(query, "query");
    xmpp_stanza_set_ns(query,"http://jabber.org/protocol/muc#owner");
    
    xmpp_stanza_set_name(x, "x");
    xmpp_stanza_set_ns(x,"jabber:x:data");
    xmpp_stanza_set_type(iq, "submit");
    
    xmpp_stanza_add_child(query,x);
    xmpp_stanza_add_child(iq,query);
        
    xmpp_send(conn, iq);
        
    xmpp_stanza_release(x);
    xmpp_stanza_release(query);
    xmpp_stanza_release(iq);
}

void XmppHelper::UploadDirectoryContactManuals(xmpp_conn_t* const conn, const char* ns, const char* data, const char* id)
{
	xmpp_ctx_t* ctx = xmpp_conn_get_context(conn);
	xmpp_stanza_t* stanza = xmpp_stanza_new(ctx);
		
	xmpp_stanza_set_name(stanza,"contact");
	xmpp_stanza_set_ns(stanza,ns);
	if (data)
	{
		xmpp_stanza_t* text = xmpp_stanza_new(ctx);
		xmpp_stanza_set_text(text,data);
		xmpp_stanza_add_child(stanza,text);
		xmpp_stanza_release(text);
	}

	StorePrivateData(conn,stanza,id);
	xmpp_stanza_release(stanza);
}

void XmppHelper::SendXmppMessage(xmpp_conn_t* const conn, const char* id, const char* type, const char* to, 
		const char* bodyStr, const char* dataStr, const char* subjectStr, const char* replaceStr, bool noStore, const char* defaultSubjectStr)
{
	xmpp_ctx_t* ctx = xmpp_conn_get_context(conn);

	xmpp_stanza_t *message = xmpp_stanza_new(ctx);

	xmpp_stanza_set_name(message, "message");
	xmpp_stanza_set_type(message, type);
	if (id && id[0])
		xmpp_stanza_set_attribute(message, "id", id);
	xmpp_stanza_set_attribute(message, "to", to);
	xmpp_stanza_set_ns(message, "jabber:client");

	if (bodyStr && bodyStr[0])
	{
		xmpp_stanza_t *body = xmpp_stanza_new(ctx);
		xmpp_stanza_t *bodyText = xmpp_stanza_new(ctx);

		xmpp_stanza_set_name(body, "body");
		xmpp_stanza_set_text(bodyText, bodyStr);

		xmpp_stanza_add_child(body, bodyText);
		xmpp_stanza_add_child(message, body);

		xmpp_stanza_release(bodyText);
		xmpp_stanza_release(body);
	}
    
    if (noStore)
    {
        xmpp_stanza_t *storage = xmpp_stanza_new(ctx);
        
        xmpp_stanza_set_name(storage, "no-store");
        xmpp_stanza_set_ns(storage,"urn:xmpp:hints");
        
        xmpp_stanza_add_child(message, storage);
        
        xmpp_stanza_release(storage);
    }

	if (dataStr && dataStr[0])
	{
		xmpp_stanza_t *data = xmpp_stanza_new(ctx);
		xmpp_stanza_t *dataText = xmpp_stanza_new(ctx);

		xmpp_stanza_set_name(data, "data");
		xmpp_stanza_set_text(dataText, dataStr);

		xmpp_stanza_add_child(data, dataText);
		xmpp_stanza_add_child(message, data);

		xmpp_stanza_release(dataText);
		xmpp_stanza_release(data);
	}

	if (subjectStr)
	{
		xmpp_stanza_t *subject = xmpp_stanza_new(ctx);
		xmpp_stanza_t *subjectText = xmpp_stanza_new(ctx);

		xmpp_stanza_set_name(subject, "subject");
		xmpp_stanza_set_text(subjectText, subjectStr);

		xmpp_stanza_add_child(subject, subjectText);
		xmpp_stanza_add_child(message, subject);

		xmpp_stanza_release(subjectText);
		xmpp_stanza_release(subject);

		if (defaultSubjectStr)
		{
			xmpp_stanza_t *subject = xmpp_stanza_new(ctx);
			xmpp_stanza_t *subjectText = xmpp_stanza_new(ctx);

			xmpp_stanza_set_name(subject, "defaultsubject");
			xmpp_stanza_set_text(subjectText, defaultSubjectStr);

			xmpp_stanza_add_child(subject, subjectText);
			xmpp_stanza_add_child(message, subject);

			xmpp_stanza_release(subjectText);
			xmpp_stanza_release(subject);
		}
	}

	if (replaceStr && replaceStr[0])
	{
		xmpp_stanza_t *replace = xmpp_stanza_new(ctx);

		xmpp_stanza_set_name(replace, "replace");
		xmpp_stanza_set_ns(replace,"urn:xmpp:message-correct:0");
		xmpp_stanza_set_attribute(replace,"id",replaceStr);

		xmpp_stanza_add_child(message, replace);

		xmpp_stanza_release(replace);
	}

	xmpp_send(conn, message);

	xmpp_stanza_release(message);
}

#ifdef use_optional_alert_for_future_usage_of_xmpp_stanza_get_text
#undef xmpp_stanza_get_text
#endif

XmppText::XmppText(xmpp_conn_t * conn, xmpp_stanza_t * const stanza)
	: mCtx(conn ? xmpp_conn_get_context(conn) : 0)
	, mText(stanza ? xmpp_stanza_get_text(stanza) : 0)
{
}

XmppText::~XmppText()
{
	if (mText && mCtx)
		xmpp_free(mCtx, const_cast<char*>(mText));
}

XmppText::operator const char* () const 
{
	return mText;
}


}
