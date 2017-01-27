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
//  Dodicall_Bridge.h
//

#import <Foundation/Foundation.h>
#import "ObjC_GlobalApplicationSettingsModel.h"
#import "ObjC_DeviceSettingsModel.h"
#import "ObjC_BaseResult.h"
#import "ObjC_ContactModel.h"
#import "Bridge_App_Callback.h"
#import "VoipAccountModel.h"
#import "ObjC_ContactPresenceStatusModel.h"
#import "ObjC_NetworkStateModel.h"
#import "Internet_Availabillity.h"
#include "ObjC_ChatMessageModel.h"
#include "ObjC_CallsModel.h"
#include "ObjC_ChatModel.h"


@class ObjC_NetworkStateModel;
@class ObjC_ChatModel;
@class ObjC_HistoryStatisticsModel;
@class ObjC_HistoryCallModel;



//test class, replace with own conforming to  Bridge_App_Callback protocol:
@interface ICallback : NSObject  <Bridge_App_Callback> {
};
@end


//

@interface Dodicall_Bridge : NSObject {
    
        
    __block BOOL isABCallbackRegistered, isNWStateCallbackRegistered;
    
}

+ (id) getInstance;

- (void) InitNetwork;

- (void) Pause;

- (void) Resume;

- (void) SetupApplicationModel: (NSString*)name : (NSString*)version;

- (void) SetupDeviceModel:  (NSString*)  uid :
                            (NSString*)  type :
                            (NSString*)  platform :
                            (NSString*)  model :
                            (NSString*)  version :
                            (NSString*)  appDataPath :
                            (NSString*)  userDataPath :
                            (NSString*)  tempDataPath;

- (ObjC_GlobalApplicationSettingsModel*) GetGlobalApplicationSettings;

- (ObjC_DeviceSettingsModel*) GetDeviceSettings;


- (ObjC_BaseResult*) Login: (NSString*) login :
                            (NSString*) password :
                            (NSInteger) area;

- (BOOL) TryAutoLogin;

- (void) SetupCallbackFunction: (ICallback*) callbackObj;

- (BOOL) GetAllContacts: (NSMutableArray*) result_list;

- (ObjC_ContactModel*) SaveContact: (ObjC_ContactModel*) contact;

- (BOOL) DeleteContact: (ObjC_ContactModel*) contact;

- (void) RetrieveChangedContacts: (ContactModelList) updated_list : (ContactModelList) deleted_list;

- (void) RetrieveVoipAccounts: (VoipAccountModelList*) result;

- (ObjC_BaseResult*) FindContactsInDirectory: (ContactModelList) result :
                                                (NSString*) searchPath;

- (NSMutableArray*) GetPresenceStatusesByXmppIds: (NSMutableArray*) ids;

- (void) GetSubscriptionStatusesByXmppIds: (NSMutableArray*) xmppIds :
                                           (NSMutableDictionary*) result;

- (ObjC_BaseResult*) FindContactsInDirectoryByXmppIds: (NSMutableArray*) xmppIds :
                                                       (NSMutableArray*) result;

- (void) DownloadAvatarForContactsWithDodicallIds:(NSMutableArray *) contactIds;

- (void) ChangeCodecSettings: (NSMutableArray*) setings;

- (void) StartCachingPhoneBookContacts;

- (void) StartCachingPhoneBookContacts_Deprecated;

- (ObjC_CreateTroubleTicketResult*) SendTroubleTicket: (NSString*) subject :
                                                       (NSString*) description :
                                                       (ObjC_LogScope*) logScope;


- (BOOL) AnswerSubscriptionRequest: (ObjC_ContactModel*) contact : (BOOL) accept;

- (BOOL) GetAllChats : (NSMutableArray*) result_list;

- (BOOL) GetChatsByIds : (NSMutableArray*) ids : (NSMutableArray*) result_list;

- (BOOL) CreateChatWithContacts: (NSMutableArray*) contacts : (ObjC_ChatModel*) result;

- (NSString*) SendTextMessage: (NSString*) msg_id : (NSString*) chat_id : (NSString*) msg;

- (BOOL) MarkMessagesAsReaded: (NSString*) msg_id;

- (void) RenameChat: (NSString*) subject : (ObjC_ChatModel*) chat;

- (NSMutableArray*) GetChatMessagesById : (NSString*) chat_id;

- (BOOL) GetChatMessagesByIds : (NSMutableArray*) ids : (NSMutableArray*) result_list;

- (void) DeleteChatMessages : (NSMutableArray*) msg_ids;

- (void) ChangeMessage:(NSString *)Id Text:(NSString *)Text;

- (NSString*) InviteAndRevokeChatMembers: (NSString*) chat_id : (NSMutableArray*) inviteList : (NSMutableArray*) revokeList;

- (ObjC_BalanceResult*) GetBalance;

- (BOOL) ExitChats : (NSMutableArray*) chat_Ids : (NSMutableArray*) failed_chat_Ids;

- (BOOL) ClearChats : (NSMutableArray*) chat_Ids : (NSMutableArray*) failed_chat_Ids;

- (BOOL) SendContactToChat: (NSString*) msg_id : (NSString*) chat_id : (ObjC_ContactModel*) contactData;

- (ObjC_ContactModel*) GetAccountData;

- (BOOL) MarkSubscriptionAsOld: (NSString*) xmppId;

- (NSString*) PregenerateMessageId;

- (int) GetNewMessagesCount;

- (void) ForceChatSync:(ChatIdType) chatId;


#pragma mark Calls

- (BOOL) StartCallToContact: (ObjC_ContactModel*) contact : (CallOptions) options;

- (BOOL) StartCallToUrl: (NSString*) url : (CallOptions) options;

- (BOOL) StartCallToContactUrl:(ObjC_ContactModel*) contact : (ObjC_ContactsContactModel*) contactsContact : (CallOptions) options;

- (ObjC_CallsModel *) GetAllCalls;

- (BOOL) AcceptCall: (NSString*) callId : (CallOptions) options;

- (BOOL) HangupCall: (NSString*) callId;

- (BOOL) PauseCall: (NSString*) callId;

- (BOOL) ResumeCall: (NSString*) callId;

- (void) SendReadyForCallAfterStart: (NSString*) pusherSipNumber;



- (ObjC_ContactModel*) RetriveContactByNumber: (NSString*) number;

- (BOOL) PlayDtmf: (char) number;
- (BOOL) StopDtmf;

- (ObjC_CallForwardingSettingsModel*) RetrieveCallForwardingSettings;
- (ObjC_BaseResult*) SetCallForwardingSettings: (ObjC_CallForwardingSettingsModel*) cfSettings;

- (NSMutableArray*) RetrieveAreas;

- (void) EnableMicrophone: (BOOL) enable;
- (BOOL) IsMicrophoneEnabled;

- (BOOL) GetSoundDevices: (NSMutableArray*) devices;
- (BOOL) SetPlaybackDevice: (NSString*) device;
- (BOOL) SetCaptureDevice: (NSString*) device;
- (BOOL) SetRingDevice: (NSString*) device;

- (int) SetPlaybackLevel: (int) level ;
- (int) SetCaptureLevel: (int) level;
- (int) SetRingLevel: (int) level;


#pragma mark History

- (BOOL) GetAllHistoryStatistics: (NSMutableArray <ObjC_HistoryStatisticsModel *> *) HistoryStatisticsList;

- (BOOL) GetHistoryStatisticsByIds:(NSMutableArray <NSString *> *) Ids : (NSMutableArray <ObjC_HistoryStatisticsModel *> *) HistoryStatisticsList;

- (BOOL) SetCallHistoryReaded: (NSString *) Id;

- (BOOL) SetAllCallHistoryReaded;

- (BOOL) CompareHistoryStatisticsIds: (NSString*) Id1 : (NSString*) Id2;

#pragma mark CallTransfer

- (BOOL) TransferCall: (NSString *) CallId ToUrl: (NSString *) Url;

- (BOOL) ClearSavedPassword;

- (void) Logout;

- (NSString *) GetLibVersion;

//////////////////////////////
- (void) method_for_tests;



@end
