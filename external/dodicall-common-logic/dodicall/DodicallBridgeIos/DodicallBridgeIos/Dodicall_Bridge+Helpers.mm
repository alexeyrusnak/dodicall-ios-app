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
//  Dodicall_Bridge+Helpers.m
//  DodicallBridgeIos


#import "Dodicall_Bridge+Helpers.h"
#import "ObjC_ContactSubscription.h"
#import "ObjC_HistoryStatisticsModel.h"
#import "ObjC_HistoryCallModel.h"



@implementation Dodicall_Bridge (Helpers)

- (std::string) convert_to_std_string: (NSString*) str {
    std::string cpp_str ([str UTF8String], [str lengthOfBytesUsingEncoding:NSUTF8StringEncoding]);
    
    return cpp_str;
}

- (NSString*) convert_to_obj_c_str: (std::string) std_str {
    NSString* resultStringObject = [NSString stringWithUTF8String:std_str.c_str()];
    
    return resultStringObject;
}


- (ObjC_ContactModel*) convert_to_obj_c_contact: (dodicall::dbmodel::ContactModel const &) c_contact  {
    ObjC_ContactModel *objc_contact = [[ObjC_ContactModel alloc] init];
    
    objc_contact.Id = c_contact.Id;
    objc_contact.DodicallId = [self convert_to_obj_c_str:c_contact.DodicallId];
    objc_contact.PhonebookId = [self convert_to_obj_c_str:c_contact.PhonebookId];
    objc_contact.NativeId = [self convert_to_obj_c_str:c_contact.NativeId];
    objc_contact.EnterpriseId = [self convert_to_obj_c_str:c_contact.CompanyId];
    
    objc_contact.FirstName = [self convert_to_obj_c_str:c_contact.FirstName];
    objc_contact.LastName = [self convert_to_obj_c_str:c_contact.LastName];
    objc_contact.MiddleName = [self convert_to_obj_c_str:c_contact.MiddleName];
    objc_contact.Blocked = [NSNumber numberWithBool: c_contact.Blocked ? YES : NO];
    objc_contact.White = [NSNumber numberWithBool: c_contact.White ? YES : NO];
    objc_contact.Deleted = [NSNumber numberWithBool: c_contact.Deleted ? YES : NO];
    objc_contact.AvatarPath = [self convert_to_obj_c_str:c_contact.AvatarPath];
    
    objc_contact.Iam = [NSNumber numberWithBool: c_contact.Iam ? YES : NO];
    
    objc_contact.subscription = [[ObjC_ContactSubscription alloc] init];
    
    switch ( c_contact.Subscription.SubscriptionState ) {
        case dodicall::dbmodel::ContactSubscriptionStateNone:
            objc_contact.subscription.SubscriptionState =  ContactSubscriptionStateNone;
            break;
        case dodicall::dbmodel::ContactSubscriptionStateFrom:
            objc_contact.subscription.SubscriptionState =  ContactSubscriptionStateFrom;
            break;
        case dodicall::dbmodel::ContactSubscriptionStateTo:
            objc_contact.subscription.SubscriptionState =  ContactSubscriptionStateTo;
            break;
        case dodicall::dbmodel::ContactSubscriptionStateBoth:
            objc_contact.subscription.SubscriptionState =  ContactSubscriptionStateBoth;
            break;
    }
    
    objc_contact.subscription.AskForSubscription = [NSNumber numberWithBool: c_contact.Subscription.AskForSubscription ? YES : NO];
    
    if (c_contact.Subscription.SubscriptionStatus == dodicall::dbmodel::ContactSubscriptionStatusNew)
        objc_contact.subscription.SubscriptionStatus = ContactSubscriptionStatusNew;
    else if (c_contact.Subscription.SubscriptionStatus == dodicall::dbmodel::ContactSubscriptionStatusReaded)
        objc_contact.subscription.SubscriptionStatus = ContactSubscriptionStatusReaded;
    else if (c_contact.Subscription.SubscriptionStatus == dodicall::dbmodel::ContactSubscriptionStatusConfirmed)
        objc_contact.subscription.SubscriptionStatus = ContactSubscriptionStatusConfirmed;
    
    objc_contact.Contacts = [[NSMutableArray alloc] init];
    
    for (auto iterator = begin (c_contact.Contacts); iterator != end (c_contact.Contacts); ++iterator) {
        dodicall::dbmodel::ContactsContactModel c_m = *iterator;
        
        ObjC_ContactsContactModel *objc_c_m = [[ObjC_ContactsContactModel alloc] init] ;
        
        if ( c_m.Type == dodicall::dbmodel::ContactsContactSip )
            objc_c_m.Type = ContactsContactSip;
        else if ( c_m.Type == dodicall::dbmodel::ContactsContactXmpp )
            objc_c_m.Type = ContactsContactXmpp;
        else if ( c_m.Type == dodicall::dbmodel::ContactsContactPhone )
            objc_c_m.Type = ContactsContactPhone;
        
        objc_c_m.Identity = [self convert_to_obj_c_str:c_m.Identity];
        objc_c_m.Favourite = [NSNumber numberWithBool: c_m.Favourite ? YES : NO];
        objc_c_m.Manual = [NSNumber numberWithBool: c_m.Manual ? YES : NO];
        
        [objc_contact.Contacts addObject: objc_c_m];
    }
    
    return objc_contact;
}

- (dodicall::dbmodel::ContactModel) convert_to_c_contact: (ObjC_ContactModel*) contact  {
    dodicall::dbmodel::ContactModel c_contact;
    
    c_contact.Id = contact.Id;
    c_contact.DodicallId = [self convert_to_std_string:contact.DodicallId];
    c_contact.PhonebookId = [self convert_to_std_string:contact.PhonebookId];
    c_contact.NativeId = [self convert_to_std_string:contact.NativeId];
    c_contact.CompanyId = [self convert_to_std_string:contact.EnterpriseId];
    
    c_contact.FirstName = [self convert_to_std_string:contact.FirstName];
    c_contact.LastName = [self convert_to_std_string:contact.LastName];
    c_contact.MiddleName = [self convert_to_std_string:contact.MiddleName];
    c_contact.Blocked = [contact.Blocked boolValue] == YES ? true : false;
    c_contact.White = [contact.White boolValue]  == YES ? true : false;
    c_contact.Deleted = [contact.Deleted boolValue]  == YES ? true : false;
    
    c_contact.Iam = [contact.Iam boolValue] == YES ? true : false;
    
    switch ( contact.subscription.SubscriptionState ) {
        case ContactSubscriptionStateNone:
            c_contact.Subscription.SubscriptionState =  dodicall::dbmodel::ContactSubscriptionStateNone;
            break;
        case dodicall::dbmodel::ContactSubscriptionStateFrom:
            c_contact.Subscription.SubscriptionState =  dodicall::dbmodel::ContactSubscriptionStateFrom;
            break;
        case dodicall::dbmodel::ContactSubscriptionStateTo:
            c_contact.Subscription.SubscriptionState =  dodicall::dbmodel::ContactSubscriptionStateTo;
            break;
        case dodicall::dbmodel::ContactSubscriptionStateBoth:
            c_contact.Subscription.SubscriptionState =  dodicall::dbmodel::ContactSubscriptionStateBoth;
            break;
    }
    
    if ([contact.subscription.AskForSubscription boolValue] == YES)
        c_contact.Subscription.AskForSubscription = true;
    else
        c_contact.Subscription.AskForSubscription = false;
    
    if (contact.subscription.SubscriptionStatus == ContactSubscriptionStatusNew)
        c_contact.Subscription.SubscriptionStatus = dodicall::dbmodel::ContactSubscriptionStatusNew;
    else if (contact.subscription.SubscriptionStatus == dodicall::dbmodel::ContactSubscriptionStatusReaded)
        c_contact.Subscription.SubscriptionStatus = dodicall::dbmodel::ContactSubscriptionStatusReaded;
    else if (contact.subscription.SubscriptionStatus == dodicall::dbmodel::ContactSubscriptionStatusConfirmed)
        c_contact.Subscription.SubscriptionStatus = dodicall::dbmodel::ContactSubscriptionStatusConfirmed;
    
    for ( ObjC_ContactsContactModel *element in contact.Contacts ) {
        dodicall::dbmodel::ContactsContactModel c_m;
        
        if ( element.Type == ContactsContactSip )
            c_m.Type = dodicall::dbmodel::ContactsContactSip;
        else if ( element.Type == ContactsContactXmpp )
            c_m.Type = dodicall::dbmodel::ContactsContactXmpp;
        else if ( element.Type == ContactsContactPhone )
            c_m.Type = dodicall::dbmodel::ContactsContactPhone;
        
        c_m.Identity = [self convert_to_std_string:element.Identity];
        c_m.Favourite = [element.Favourite boolValue]  == YES ? true : false;
        c_m.Manual = [element.Manual boolValue]  == YES ? true : false;
        
        c_contact.Contacts.insert(c_m);
    }
    return c_contact;
}

- (dodicall::dbmodel::ContactsContactModel) convert_to_c_contactsContact: (ObjC_ContactsContactModel*) contact
{
    dodicall::dbmodel::ContactsContactModel c_m;
    
    if (contact.Type == ContactsContactSip )
        c_m.Type = dodicall::dbmodel::ContactsContactSip;
    else if (contact.Type == ContactsContactXmpp )
        c_m.Type = dodicall::dbmodel::ContactsContactXmpp;
    else if (contact.Type == ContactsContactPhone )
        c_m.Type = dodicall::dbmodel::ContactsContactPhone;
    
    c_m.Identity = [self convert_to_std_string:contact.Identity];
    c_m.Favourite = [contact.Favourite boolValue]  == YES ? true : false;
    c_m.Manual = [contact.Manual boolValue]  == YES ? true : false;
    
    return c_m;
}

- (ObjC_ChatModel*) convert_to_obj_c_chat: (dodicall::dbmodel::ChatModel const &) c_chat
{
    ObjC_ChatModel *objc_chat = [[ObjC_ChatModel alloc] init];
    
    objc_chat.Id = [self convert_to_obj_c_str : c_chat.Id];
    objc_chat.Title = [self convert_to_obj_c_str : c_chat.Title];
    time_t modified_time = dodicall::posix_time_to_time_t(c_chat.LastModifiedDate);
    objc_chat.LastModifiedDate = [NSDate dateWithTimeIntervalSince1970:modified_time];
    objc_chat.Active = [NSNumber numberWithBool: c_chat.Active ? YES : NO];
    
    objc_chat.Contacts = [[NSMutableArray alloc] init];
    
    for (auto iterator = begin (c_chat.Contacts); iterator != end (c_chat.Contacts); ++iterator) {
        ObjC_ContactModel *contact = [self convert_to_obj_c_contact: *iterator];
        
        [objc_chat.Contacts addObject: contact];
    }
    
    objc_chat.IsP2p = [NSNumber numberWithBool: c_chat.IsP2p ? YES : NO];
    
    objc_chat.TotalMessagesCount = c_chat.TotalMessagesCount;
    objc_chat.NewMessagesCount = c_chat.NewMessagesCount;
    
    if (!c_chat.LastMessage)
        objc_chat.lastMessage = nil;
    else {
        objc_chat.lastMessage = [self convert_to_obj_c_message: *c_chat.LastMessage];
    }
    
    return objc_chat;
    
}

- (ObjC_ChatMessageModel*) convert_to_obj_c_message: (dodicall::dbmodel::ChatMessageModel const &) c_message
{
    ObjC_ChatMessageModel *objc_msg = [[ObjC_ChatMessageModel alloc] init];
    
    objc_msg.Id = [self convert_to_obj_c_str : c_message.Id];
    objc_msg.chatId = [self convert_to_obj_c_str : c_message.ChatId];
    objc_msg.Sender = [self convert_to_obj_c_contact : c_message.Sender];
    objc_msg.Servered = [NSNumber numberWithBool: c_message.Servered ? YES : NO];
    time_t send_time = dodicall::posix_time_to_time_t(c_message.SendTime);
    objc_msg.SendTime = [NSDate dateWithTimeIntervalSince1970: send_time];
    objc_msg.Readed = [NSNumber numberWithBool: c_message.Readed ? YES : NO];
    objc_msg.Rownum = [NSNumber numberWithInt: c_message.Rownum];
    objc_msg.Changed = [NSNumber numberWithBool:c_message.Changed];
    objc_msg.Encrypted = [NSNumber numberWithBool:c_message.Encrypted];
    
    switch ( c_message.Type ) {
        case dodicall::ChatMessageTypeTextMessage:
            objc_msg.Type = ChatMessageTypeTextMessage;
            break;
        case dodicall::ChatMessageTypeAudioMessage:
            objc_msg.Type = ChatMessageTypeAudioMessage;
            break;
        case dodicall::ChatMessageTypeNotification:
            objc_msg.Type = ChatMessageTypeNotification;
            break;
        case dodicall::ChatMessageTypeContact:
            objc_msg.Type = ChatMessageTypeContact;
            break;
        case dodicall::ChatMessageTypeDeleter:
            objc_msg.Type = ChatMessageTypeDeleter;
            break;
        case dodicall::ChatMessageTypeSubject:
            objc_msg.Type = ChatMessageTypeSubject;
            break;
    }
    objc_msg.StringContent = [self convert_to_obj_c_str : c_message.StringContent];
    
    if ( c_message.ContactData)
        objc_msg.ContactData = [self convert_to_obj_c_contact : *c_message.ContactData];
    
    if (c_message.NotificationData) {
        objc_msg.NotificationData = [[ObjC_ChatNotificationData alloc] init];
    
        switch ( c_message.NotificationData.get().Type ) {
        case dodicall::ChatNotificationTypeCreate:
            objc_msg.NotificationData.Type = ChatNotificationTypeCreate;
            break;
        case dodicall::ChatNotificationTypeInvite:
            objc_msg.NotificationData.Type = ChatNotificationTypeInvite;
            break;
        case dodicall::ChatNotificationTypeRevoke:
            objc_msg.NotificationData.Type = ChatNotificationTypeRevoke;
            break;
        case dodicall::ChatNotificationTypeLeave:
            objc_msg.NotificationData.Type = ChatNotificationTypeLeave;
            break;
        case dodicall::ChatNotificationTypeRemove:
            objc_msg.NotificationData.Type = ChatNotificationTypeRemove;
            break;
        }
        
        objc_msg.NotificationData.Contacts= [[NSMutableArray alloc] init];
        for (auto iterator = begin ((*c_message.NotificationData).Contacts); iterator != end ((*c_message.NotificationData).Contacts); ++iterator) {
            ObjC_ContactModel *contact = [self convert_to_obj_c_contact: *iterator];
        
            [objc_msg.NotificationData.Contacts addObject: contact];
        }
    
    }
        
    return objc_msg;
    
}

- (ObjC_CallModel*) convert_to_obj_c_call: (dodicall::dbmodel::CallModel const &) c_call {
    ObjC_CallModel *objc_call = [[ObjC_CallModel alloc] init];
    objc_call.Id = [self convert_to_obj_c_str: c_call.Id];
    objc_call.Direction = c_call.Direction == dodicall::CallDirectionOutgoing ? CallDirectionOutgoing : CallDirectionIncoming;
    objc_call.Encription = c_call.Encription == dodicall::VoipEncryptionNone ? CallEncryptionNone : CallEncryptionSRTP;
    objc_call.Duration = (double)c_call.Duration;
    
    switch ( c_call.State ) {
        case ( dodicall::CallStateInitialized ):
            objc_call.State = CallStateInitialized;
            break;
        case ( dodicall::CallStateDialing ):
            objc_call.State = CallStateDialing;
            break;
        case ( dodicall::CallStateRinging ):
            objc_call.State = CallStateRinging;
            break;
        case ( dodicall::CallStateConversation ):
            objc_call.State = CallStateConversation;
            break;
        case ( dodicall::CallStateEarlyMedia ):
            objc_call.State = CallStateEarlyMedia;
            break;
        case ( dodicall::CallStatePaused ):
            objc_call.State = CallStatePaused;
            break;
        case ( dodicall::CallStateEnded ):
            objc_call.State = CallStateEnded;
            break;
    }
    
    objc_call.AddressType = c_call.AddressType == dodicall::CallAddressPhone ? CallAddressPhone : CallAddressDodicall;
    
    objc_call.Identity = [self convert_to_obj_c_str: c_call.Identity];
    if ( c_call.Contact)
        objc_call.Contact = [self convert_to_obj_c_contact : *c_call.Contact];
    
    return objc_call;
}

- (ObjC_HistoryStatisticsModel*) convert_to_obj_c_history_statistics: (dodicall::dbmodel::CallHistoryPeerModel const &) Peer
{
    ObjC_HistoryStatisticsModel *HistoryStatistics = [[ObjC_HistoryStatisticsModel alloc] init];
    
    HistoryStatistics.Id = [self convert_to_obj_c_str : Peer.GetId()];
    
    //HistoryStatistics.MasterId = [self convert_to_obj_c_str : Peer.MasterId];
    
    HistoryStatistics.Identity = [self convert_to_obj_c_str : Peer.Identity];
    
    //HistoryStatistics.LastHistoryCall = [self convert_to_obj_c_history_call:Peer.LastHistoryEntry];
    

    if(Peer.Contact)
    {
        NSMutableArray *Contacts = [[NSMutableArray alloc] init];
        
        ObjC_ContactModel *Contact = [self convert_to_obj_c_contact: *Peer.Contact];
        
        [Contacts addObject:Contact];
        
        HistoryStatistics.Contacts = Contacts;
    }
    
    
    
    HistoryStatistics.NumberOfIncomingSuccessfulCalls = [[NSNumber alloc] initWithInt:Peer.Statistics.NumberOfIncomingSuccessfulCalls];
    HistoryStatistics.NumberOfIncomingUnsuccessfulCalls = [[NSNumber alloc] initWithInt:Peer.Statistics.NumberOfIncomingUnsuccessfulCalls];
    HistoryStatistics.NumberOfMissedCalls = [[NSNumber alloc] initWithInt:Peer.Statistics.NumberOfMissedCalls];
    HistoryStatistics.NumberOfOutgoingSuccessfulCalls = [[NSNumber alloc] initWithInt:Peer.Statistics.NumberOfOutgoingSuccessfulCalls];
    HistoryStatistics.NumberOfOutgoingUnsuccessfulCalls = [[NSNumber alloc] initWithInt:Peer.Statistics.NumberOfOutgoingUnsuccessfulCalls];
    
    HistoryStatistics.HasIncomingEncryptedCall = [[NSNumber alloc] initWithBool:Peer.Statistics.HasIncomingEncryptedCall ? YES : NO];
    HistoryStatistics.HasOutgoingEncryptedCall = [[NSNumber alloc] initWithBool:Peer.Statistics.HasOutgoingEncryptedCall ? YES : NO];
    
    HistoryStatistics.WasConference = [NSNumber numberWithBool:NO];
    
    //HistoryStatistics.Readed = [[NSNumber alloc] initWithBool:Peer.Statistics.Readed ? YES : NO];
    
    return HistoryStatistics;
}

- (ObjC_HistoryCallModel*) convert_to_obj_c_history_call: (dodicall::dbmodel::CallHistoryEntryModel const &) HistoryEntry
{
    ObjC_HistoryCallModel *HistoryCall = [[ObjC_HistoryCallModel alloc] init];
    
    HistoryCall.Id = [self convert_to_obj_c_str : HistoryEntry.Id];
    
    //HistoryCall.HistoryStatisticsId = [self convert_to_obj_c_str : HistoryEntry.PeerId];
    
    //HistoryCall.MasterId = [self convert_to_obj_c_str : HistoryEntry.MasterId];
    
    time_t Date = dodicall::posix_time_to_time_t(HistoryEntry.StartTime);
    
    HistoryCall.Date = [NSDate dateWithTimeIntervalSince1970:Date];
    
    HistoryCall.DurationInSecs = [NSNumber numberWithInt:HistoryEntry.DurationSec];
    
    switch (HistoryEntry.GetHistoryStatus()) {
            
        case dodicall::HistoryStatusSuccess:
            HistoryCall.Status = CallHistoryStatusSuccess;
            break;
            
        case dodicall::HistoryStatusAborted:
            HistoryCall.Status = CallHistoryStatusAborted;
            break;
            
        case dodicall::HistoryStatusMissed:
            HistoryCall.Status = CallHistoryStatusMissed;
            break;
            
        case dodicall::HistoryStatusDeclined:
            HistoryCall.Status = CallHistoryStatusDeclined;
            break;
            
        default:
            HistoryCall.Status = CallHistoryStatusSuccess;
            break;
    }
    
    switch (HistoryEntry.GetHistoryEncryption()) {
        case dodicall::HistoryEncryptionNone:
            HistoryCall.Encryption = CallEncryptionNone;
            break;
            
        case dodicall::HistoryEncryptionSrtp:
            HistoryCall.Encryption = CallEncryptionSRTP;
            break;
            
        default:
            HistoryCall.Encryption = CallEncryptionNone;
            break;
    }
    
    switch (HistoryEntry.Direction) {
        case dodicall::CallDirectionOutgoing:
            HistoryCall.Direction = CallDirectionOutgoing;
            break;
            
        default:
            HistoryCall.Direction = CallDirectionIncoming;
            break;
    }
    
    return HistoryCall;
}

@end
