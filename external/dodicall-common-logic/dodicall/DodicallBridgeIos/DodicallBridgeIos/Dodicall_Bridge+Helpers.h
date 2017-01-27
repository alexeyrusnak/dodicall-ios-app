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
//
//  Dodicall_Bridge+Helpers.h
//  DodicallBridgeIos


#import "Dodicall_Bridge.h"
#include "Application.h"


@interface Dodicall_Bridge (Helpers)

- (std::string) convert_to_std_string: (NSString*) str;

- (NSString*) convert_to_obj_c_str: (std::string) std_str ;

- (ObjC_ContactModel*) convert_to_obj_c_contact: (dodicall::dbmodel::ContactModel const &) c_contact;

- (dodicall::dbmodel::ContactModel) convert_to_c_contact: (ObjC_ContactModel*) contact;

- (dodicall::dbmodel::ContactsContactModel) convert_to_c_contactsContact: (ObjC_ContactsContactModel*) contact;

- (ObjC_ChatModel*) convert_to_obj_c_chat: (dodicall::dbmodel::ChatModel const &) c_chat;

- (ObjC_ChatMessageModel*) convert_to_obj_c_message: (dodicall::dbmodel::ChatMessageModel const &) c_message;

- (ObjC_CallModel*) convert_to_obj_c_call: (dodicall::dbmodel::CallModel const &) c_call;

- (ObjC_HistoryStatisticsModel*) convert_to_obj_c_history_statistics: (dodicall::dbmodel::CallHistoryPeerModel const &) Peer;

- (ObjC_HistoryCallModel*) convert_to_obj_c_history_call: (dodicall::dbmodel::CallHistoryEntryModel const &) HistoryEntry;

@end
