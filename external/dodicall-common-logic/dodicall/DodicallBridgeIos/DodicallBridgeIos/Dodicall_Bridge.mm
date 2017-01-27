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
//  Dodicall_Bridge.mm
//
//

#import "Dodicall_Bridge.h"
#include "Application.h"
#include "Logger.h"
#import <Contacts/Contacts.h>
#import "System_Utils.h"
#import <AddressBook/AddressBook.h>
#import "Dodicall_Bridge+Network.h"

#import "Dodicall_Bridge+Helpers.h"
#import "ObjC_ContactSubscription.h"
#include "ObjC_ChatModel.h"
#include "DateTimeUtils.h"
#import "ObjC_HistoryStatisticsModel.h"
#import "ObjC_HistoryCallModel.h"



//test class, replace with own conforming to  Bridge_App_Callback protocol:
@implementation ICallback {
    
}

- (void) Callback : (NSString*) modelName
                  : (NSMutableArray*) arr {
    //NSLog(@"iOS Bridge Calback(%@)", modelName);
    if ( [modelName isEqualToString: @"Contacts"] ) {
        NSMutableArray *updated = [[NSMutableArray alloc] init];
        NSMutableArray *deleted = [[NSMutableArray alloc] init];
        [[Dodicall_Bridge getInstance] RetrieveChangedContacts: updated : deleted];
        int x = 0;
    }
    if ( [modelName isEqualToString: @"New_Message"] ) {
        int x = 0;
        //GetChatMessagesById : arr[0]
        
    }
    if ( [modelName isEqualToString: @"New_Invite"] ) {
        int x = 0;
        //GetChatMessagesById : arr[0]
        
        
    }
    
}

@end

@interface Dodicall_Bridge () {
    
    __block ABAddressBookRef m_addressbook;

    
}

@end

static ICallback *c_b = nil;

@implementation Dodicall_Bridge {
}

- (id) copyWithZone:(NSZone *)zone {
    return self;
}

static Dodicall_Bridge* _instance;
+ (void) initialize {
    if (self == [Dodicall_Bridge class]) {
        _instance = [[Dodicall_Bridge alloc] init];
    }
}

+ (id) getInstance {
    return _instance;
}
- (id)init {
    NSAssert (_instance == nil, @"Duplicate init of singleton");
    self = [super init];
    if (self) {
        [self InitNetwork];
        
        m_addressbook = ABAddressBookCreate();
        
        isABCallbackRegistered = NO;
        
        /*
        if (SYSTEM_VERSION_LESS_THAN(@"9.0"))
            [self StartCachingPhoneBookContacts_Deprecated];
        else
            [self StartCachingPhoneBookContacts];
         */
        
    }
    
    return self;
}

- (void) InitNetwork
{    
    if (!isNWStateCallbackRegistered)
    {
        [self SetupNetworkTechnologyNotifications];
        [self SetNetworkTechnology:YES];
        isNWStateCallbackRegistered = YES;
    }
    
    [self SetNetworkTechnology];
}

- (void)dealloc {
    
    CFRelease(m_addressbook);
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kReachabilityChangedNotification object:nil];
   
}


/**************************************************************************************************************/


- (void) Pause {
    dodicall::Application::GetInstance().Pause();
    if ([[UIApplication sharedApplication] setKeepAliveTimeout:600
                                                       handler:^{
                                                           
                                                           dodicall::Application::GetInstance().RefreshRegistration();
                                                           
                                                           @try {
                                                               dodicall::Application::GetInstance().Iterate();
                                                           }
                                                           @catch (NSException *exception) {
                                                               NSLog(@"Exception raised in App iterate");
                                                           }
                                                       }
         ]) {
        
    }
}

- (void) Resume {
    dodicall::Application::GetInstance().Resume();
    [self InitNetwork];
}

- (void) SetupCallbackFunction: (ICallback*) callbackObj {
    c_b = callbackObj;
    
    dodicall::Application::GetInstance().SetupCallbackFunction(DoCallback);
}

void DoCallback (const char* modelName, const std::vector<std::string>& entityIds) {
     NSString *name_str = [NSString stringWithUTF8String: modelName];
    
     NSMutableArray *arr = [[NSMutableArray alloc] init];

    for (auto iterator = begin (entityIds); iterator != end (entityIds); ++iterator) {
        std::string s = *iterator;
        
        NSString *objc_str = [NSString stringWithUTF8String: s.c_str()];
    
        [arr addObject: objc_str];
    }
    [c_b Callback: name_str : arr];
}

- (void) SetupApplicationModel: (NSString*)name : (NSString*)version {
    if ( !version )
        return;
    
    std::string const app_name = [self convert_to_std_string: name] ;
    std::string app_version = [self convert_to_std_string: version] ;
    
    dodicall::Application::GetInstance().SetupApplicationModel(app_name.c_str(), app_version.c_str());
}

- (void) SetupDeviceModel: (NSString*)  uid :
                           (NSString*)  type :
                           (NSString*)  platform :
                           (NSString*)  model :
                           (NSString*)  version :
                           (NSString*)  appDataPath :
                           (NSString*)  userDataPath :
                           (NSString*)  tempDataPath  {
    
    std::string device_id = [self convert_to_std_string: uid] ;
    std::string device_type = [self convert_to_std_string: type] ;
    std::string device_platform = [self convert_to_std_string: platform] ;
    std::string device_model = [self convert_to_std_string: model] ;
    std::string app_version = [self convert_to_std_string: version] ;
    std::string device_data_path = [self convert_to_std_string: appDataPath] ;
    std::string device_user_data_path = [self convert_to_std_string: userDataPath] ;
    std::string device_temp_data_path = [self convert_to_std_string: tempDataPath] ;
    
    dodicall::Application::GetInstance().SetupDeviceModel ( device_id.c_str(), device_type.c_str(), device_platform.c_str(), device_model.c_str(), app_version.c_str(), device_data_path.c_str(), device_user_data_path.c_str(), device_temp_data_path.c_str() );
}

- (ObjC_GlobalApplicationSettingsModel*) GetGlobalApplicationSettings {
    dodicall::GlobalApplicationSettingsModel global_app_settings = dodicall::Application::GetInstance().GetGlobalApplicationSettings();
    
    ObjC_GlobalApplicationSettingsModel *obj_c_global_app_settings = [[ObjC_GlobalApplicationSettingsModel alloc] init];
    
    obj_c_global_app_settings.LastLogin = [self convert_to_obj_c_str:global_app_settings.LastLogin];
    
    obj_c_global_app_settings.LastPassword = [self convert_to_obj_c_str:global_app_settings.LastPassword];
    
    obj_c_global_app_settings.DefaultGuiLanguage = [self convert_to_obj_c_str:global_app_settings.DefaultGuiLanguage];
    
    obj_c_global_app_settings.DefaultGuiTheme = [self convert_to_obj_c_str:global_app_settings.DefaultGuiThemeName];
    
    obj_c_global_app_settings.Autologin =  [NSNumber numberWithBool: global_app_settings.Autologin ? YES : NO];
    
    obj_c_global_app_settings.Area = (NSInteger)global_app_settings.Area;
    
    return obj_c_global_app_settings;
}

- (ObjC_DeviceSettingsModel*) GetDeviceSettings {
    dodicall::DeviceSettingsModel device_settings = dodicall::Application::GetInstance().GetDeviceSettings();
    
    ObjC_DeviceSettingsModel *obj_c_device_settings = [[ObjC_DeviceSettingsModel alloc] init];
    
    obj_c_device_settings.VoiceMailGate = [self convert_to_obj_c_str:device_settings.VoiceMailGate];
    
    obj_c_device_settings.EncryptionSettings = [[VoipEncryptionSerttingsModel alloc] init];
    
    if ( device_settings.EncryptionSettings.Type == dodicall::model::VoipEncryptionNone )
        obj_c_device_settings.EncryptionSettings.Type = VoipEncryptionNone;
    else if ( device_settings.EncryptionSettings.Type == dodicall::model::VoipEncryptionSrtp )
        obj_c_device_settings.EncryptionSettings.Type = VoipEncryptionSrtp;
    
    obj_c_device_settings.EncryptionSettings.Mandatory = [NSNumber numberWithBool: device_settings.EncryptionSettings.Mandatory ? YES : NO];
    obj_c_device_settings.EncryptionSettings.Ignore = [NSNumber numberWithBool: device_settings.EncryptionSettings.Ignore ? YES : NO];
    
    obj_c_device_settings.CodecSettings = [[NSMutableArray alloc] init];
    
    for (auto iterator = begin (device_settings.CodecSettings); iterator != end (device_settings.CodecSettings); ++iterator) {
        dodicall::model::CodecSettingModel cs_model = *iterator;
        
        CodecSettingModel *objc_cs_model = [[CodecSettingModel alloc] init];
        
        objc_cs_model.Type = cs_model.Type == dodicall::model::CodecTypeAudio ? CodecTypeAudio : CodecTypeVideo;
        objc_cs_model.ConnectionType = cs_model.ConnectionType == dodicall::model::ConnectionTypeCell ? ConnectionTypeCell : ConnectionTypeWifi;
        objc_cs_model.Name = [self convert_to_obj_c_str:cs_model.Name];
        objc_cs_model.Mime = [self convert_to_obj_c_str:cs_model.Mime];
        objc_cs_model.Rate = cs_model.Rate;
        objc_cs_model.Priority = cs_model.Priority;
        objc_cs_model.Enabled = [NSNumber numberWithBool: cs_model.Enabled ? YES : NO];
        
        [obj_c_device_settings.CodecSettings addObject: objc_cs_model];
    }
    
    obj_c_device_settings.ServerSettings = [[NSMutableArray alloc] init];
    
    for (auto iterator = begin (device_settings.ServerSettings); iterator != end (device_settings.ServerSettings); ++iterator) {
        
        dodicall::model::ServerSettingModel ss_model = *iterator;
    
        ServerSettingModel *objc_ss_model = [[ServerSettingModel alloc] init];
    
        objc_ss_model.ServerType = ss_model.ServerType == dodicall::model::ServerTypeSip ? ServerTypeSip : ServerTypeXmpp;
        
        if ( ss_model.ProtocolType == dodicall::model::ServerProtocolTypeTls )
            objc_ss_model.ProtocolType = ServerProtocolTypeTls;
        else if ( ss_model.ProtocolType == dodicall::model::ServerProtocolTypeTcp )
            objc_ss_model.ProtocolType = ServerProtocolTypeTcp;
        else if ( ss_model.ProtocolType == dodicall::model::ServerProtocolTypeUdp )
            objc_ss_model.ProtocolType = ServerProtocolTypeUdp;
        
        objc_ss_model.Server = [self convert_to_obj_c_str:ss_model.Server];
        objc_ss_model.Port = ss_model.Port;
        objc_ss_model.Domain = [self convert_to_obj_c_str:ss_model.Domain];
        objc_ss_model.Username = [self convert_to_obj_c_str:ss_model.Username ];
        objc_ss_model.Password = [self convert_to_obj_c_str:ss_model.Password];
        objc_ss_model.AuthUserName = [self convert_to_obj_c_str:ss_model.AuthUserName];
        objc_ss_model.Extension = [self convert_to_obj_c_str:ss_model.Extension];
        objc_ss_model.Default = [NSNumber numberWithBool: ss_model.Default ? YES : NO];
        
        [obj_c_device_settings.ServerSettings addObject: objc_ss_model];
    
    }
    return obj_c_device_settings;
}


- (ObjC_BaseResult*) Login: (NSString*) login :
                            (NSString*) password :
                            (NSInteger) area {
    
    std::string login_str = [self convert_to_std_string: login] ;
    std::string pwd_str = [self convert_to_std_string: password] ;
    
    dodicall::BaseResult br = dodicall::Application::GetInstance().Login(
                login_str.c_str(),
                pwd_str.c_str(),
                (int)area);
    
    ObjC_BaseResult *objc_b_r = [[ObjC_BaseResult  alloc] init];
    
    objc_b_r.Success = [NSNumber numberWithBool: br.Success ? YES : NO];
    
    switch ( br.ErrorCode ) {
        case dodicall::results::ResultErrorNo:
            objc_b_r.ErrorCode = ResultErrorNo;
            break;
        case dodicall::results::ResultErrorSystem:
            objc_b_r.ErrorCode = ResultErrorSystem;
            break;
        case dodicall::results::ResultErrorSetupNotCompleted:
            objc_b_r.ErrorCode = ResultErrorSetupNotCompleted;
            break;
        case dodicall::results::ResultErrorAuthFailed:
            objc_b_r.ErrorCode = ResultErrorAuthFailed;
            break;
        case dodicall::results::ResultErrorNoNetwork:
            objc_b_r.ErrorCode = ResultErrorNoNetwork;
            break;
    }
    return objc_b_r;
}

- (BOOL) TryAutoLogin
{
    return dodicall::Application::GetInstance().TryAutoLogin() ? YES : NO;
}

- (BOOL) GetAllContacts: (NSMutableArray*) result_list {
    dodicall::dbmodel::ContactModelSet c_result_list;
    
    bool res = dodicall::Application::GetInstance().GetAllContacts(c_result_list);
    
    if (!res)
        return NO;
    
    for (auto iterator = begin (c_result_list); iterator != end (c_result_list); ++iterator) {
         dodicall::dbmodel::ContactModel contact = *iterator;
        
         ObjC_ContactModel *objc_contact = [self convert_to_obj_c_contact: contact];
    
         [result_list addObject: objc_contact];
    }
    
    if ( result_list!= nil && [result_list count] > 0)
        return YES;
    
    return NO;
}

- (ObjC_ContactModel*) SaveContact: (ObjC_ContactModel*) contact {
    dodicall::dbmodel::ContactModel c_contact = [self convert_to_c_contact:contact];
    
    return [self convert_to_obj_c_contact: dodicall::Application::GetInstance().SaveContact(c_contact)];
}

- (BOOL) DeleteContact: (ObjC_ContactModel*) contact {
    dodicall::dbmodel::ContactModel c_contact = [self convert_to_c_contact:contact];
    
    return (dodicall::Application::GetInstance().DeleteContact(c_contact) ? YES : NO);
}

- (void) RetrieveChangedContacts: (ContactModelList) updated_list : (ContactModelList) deleted_list {
    dodicall::dbmodel::ContactModelSet m_upd_list;
    dodicall::dbmodel::ContactModelSet m_del_list;
    
    dodicall::Application::GetInstance().RetrieveChangedContacts(m_upd_list, m_del_list);
    
    // updated contacts
    for (auto iterator = begin (m_upd_list); iterator != end (m_upd_list); ++iterator) {
        dodicall::dbmodel::ContactModel contact = *iterator;
        
        ObjC_ContactModel *objc_contact = [self convert_to_obj_c_contact: contact];
        
        [updated_list addObject: objc_contact];
    }
    
    // deleted contacts
    for (auto iterator = begin (m_del_list); iterator != end (m_del_list); ++iterator) {
        dodicall::dbmodel::ContactModel contact = *iterator;
        
        ObjC_ContactModel *objc_contact = [self convert_to_obj_c_contact: contact];
        
        [deleted_list addObject: objc_contact];
    }
}


- (void) RetrieveVoipAccounts: (VoipAccountModelList*) result {
    dodicall::model::VoipAccountModelList res;
    
    dodicall::Application::GetInstance().RetrieveVoipAccounts(res);
    
     for (auto iterator = begin (res); iterator != end (res); ++iterator) {
         
        VoipAccountModel *va_m;
        
        va_m.Identity = [ self convert_to_obj_c_str: (*iterator).Identity.c_str()];
        
        switch ( (*iterator).State ) {
            case dodicall::model::VoipAccountRegistrationOk:
                va_m.State = VoipAccountRegistrationOk;
                break;
            case dodicall::model::VoipAccountRegistrationNone:
                va_m.State = VoipAccountRegistrationNone;
                break;
            case dodicall::model::VoipAccountRegistrationInProgress:
                va_m.State = VoipAccountRegistrationInProgress;
                break;
            case dodicall::model::VoipAccountRegistrationFailed:
                va_m.State = VoipAccountRegistrationFailed;
                break;
        }
        [result addObject: va_m];
    }
}


- (ObjC_BaseResult*) FindContactsInDirectory: (ContactModelList) result :
                                                (NSString*) searchPath {
    dodicall::dbmodel::ContactModelSet m_list;
    
    std::string m_searchPath = [self convert_to_std_string: searchPath];
    
    dodicall::BaseResult br = dodicall::Application::GetInstance().FindContactsInDirectory(m_list, m_searchPath.c_str());
    
    ObjC_BaseResult *objc_b_r = [[ObjC_BaseResult  alloc] init];
    
    objc_b_r.Success = [NSNumber numberWithBool: br.Success ? YES : NO];
    
    switch ( br.ErrorCode ) {
        case dodicall::results::ResultErrorNo:
            objc_b_r.ErrorCode = ResultErrorNo;
            break;
        case dodicall::results::ResultErrorSystem:
            objc_b_r.ErrorCode = ResultErrorSystem;
            break;
        case dodicall::results::ResultErrorSetupNotCompleted:
            objc_b_r.ErrorCode = ResultErrorSetupNotCompleted;
            break;
        case dodicall::results::ResultErrorAuthFailed:
            objc_b_r.ErrorCode = ResultErrorAuthFailed;
            break;
        case dodicall::results::ResultErrorNoNetwork:
            objc_b_r.ErrorCode = ResultErrorNoNetwork;
            break;
    }
            
    if ( [objc_b_r.Success boolValue] == NO)
        return objc_b_r;
    
    
    for (auto iterator = begin (m_list); iterator != end (m_list); ++iterator) {
        dodicall::dbmodel::ContactModel contact = *iterator;
        
        ObjC_ContactModel *objc_contact = [self convert_to_obj_c_contact: contact];
        
        [result addObject: objc_contact];
    }
    
    return objc_b_r;
}


- (NSMutableArray*) GetPresenceStatusesByXmppIds: (NSMutableArray*) ids {
    NSMutableArray *result = [[NSMutableArray alloc] init];    
    
    std::set<dodicall::ContactXmppIdType> m_ids;
    
    for ( NSString *element in ids ) {
        std::string id = [self convert_to_std_string:element];
        
        m_ids.insert(id);
    }
    
    dodicall::dbmodel::ContactPresenceStatusSet m_result;
    
    dodicall::Application::GetInstance().GetPresenceStatusesByXmppIds(m_ids, m_result);
    
    for (auto iterator = begin (m_result); iterator != end (m_result); ++iterator) {
        ObjC_ContactPresenceStatusModel *cp_model = [[ObjC_ContactPresenceStatusModel alloc] init];
        
        cp_model.XmppId = [self convert_to_obj_c_str: (*iterator).XmppId.c_str()];
        
        switch ( (*iterator).BaseStatus ) {
            case dodicall::dbmodel::BaseUserStatusOffline:
                cp_model.BaseStatus =  BaseUserStatusOffline;
                break;
            case dodicall::dbmodel::BaseUserStatusOnline:
                cp_model.BaseStatus =  BaseUserStatusOnline;
                break;
            case dodicall::dbmodel::BaseUserStatusAway:
                cp_model.BaseStatus =  BaseUserStatusAway;
                break;
            case dodicall::dbmodel::BaseUserStatusHidden:
                cp_model.BaseStatus =  BaseUserStatusHidden;
                break;
            case dodicall::dbmodel::BaseUserStatusDnd:
                cp_model.BaseStatus =  BaseUserStatusDnd;
                break;
        }
        
        cp_model.ExtStatus = [self convert_to_obj_c_str: (*iterator).ExtStatus.c_str()];
        
        [result addObject:cp_model];
    }
    return result;
}

- (void) GetSubscriptionStatusesByXmppIds: (NSMutableArray*) xmppIds :
                                           (NSMutableDictionary*) result {
    std::set<dodicall::ContactXmppIdType> m_ids;
                                              
    for ( NSString *element in xmppIds ) {
        std::string id = [self convert_to_std_string:element];
                                                  
        m_ids.insert(id);
    }
    
    std::map<std::string,dodicall::ContactSubscriptionModel>  c_res_map;
                                              
    dodicall::Application::GetInstance().GetSubscriptionStatusesByXmppIds(m_ids, c_res_map);
    
    for (auto iterator = begin (c_res_map); iterator != end (c_res_map); ++iterator) {
        ObjC_ContactSubscription *cp_model = [[ObjC_ContactSubscription alloc] init];
        
        switch ( (*iterator).second.SubscriptionState ) {
            case dodicall::dbmodel::ContactSubscriptionStateNone:
                cp_model.SubscriptionState =  ContactSubscriptionStateNone;
                break;
            case dodicall::dbmodel::ContactSubscriptionStateFrom:
                cp_model.SubscriptionState =  ContactSubscriptionStateFrom;
                break;
            case dodicall::dbmodel::ContactSubscriptionStateTo:
                cp_model.SubscriptionState =  ContactSubscriptionStateTo;
                break;
            case dodicall::dbmodel::ContactSubscriptionStateBoth:
                cp_model.SubscriptionState =  ContactSubscriptionStateBoth;
                break;
        }
        
        cp_model.AskForSubscription = [NSNumber numberWithBool: (*iterator).second.AskForSubscription ? YES : NO];
        
        if ((*iterator).second.SubscriptionStatus == dodicall::dbmodel::ContactSubscriptionStatusNew)
            cp_model.SubscriptionStatus = ContactSubscriptionStatusNew;
        else if ((*iterator).second.SubscriptionStatus == dodicall::dbmodel::ContactSubscriptionStatusReaded)
            cp_model.SubscriptionStatus = ContactSubscriptionStatusReaded;
        else if ((*iterator).second.SubscriptionStatus == dodicall::dbmodel::ContactSubscriptionStatusConfirmed)
            cp_model.SubscriptionStatus = ContactSubscriptionStatusConfirmed;
        
        [result setObject: cp_model forKey: [self convert_to_obj_c_str: (*iterator).first] ];
    }
}

- (BOOL) AnswerSubscriptionRequest: (ObjC_ContactModel*) contact : (BOOL) accept {
    dodicall::dbmodel::ContactModel c_contact = [self convert_to_c_contact:contact];
    
    bool c_accept = accept == YES ? true : false;
    
    return dodicall::Application::GetInstance().AnswerSubscriptionRequest(c_contact, c_accept) ? YES : NO;
}

- (ObjC_BaseResult*) FindContactsInDirectoryByXmppIds: (NSMutableArray*) xmppIds :
                                                       (NSMutableArray*) result {
    std::set<dodicall::ContactXmppIdType> c_x_ids;
    
    for ( NSString *element in xmppIds ) {
        std::string id = [self convert_to_std_string:element];
        
        c_x_ids.insert(id);
    }
    
    std::set<dodicall::dbmodel::ContactModel> c_res_set;
    
    dodicall::BaseResult br = dodicall::Application::GetInstance().FindContactsInDirectoryByXmppIds(c_x_ids, c_res_set);
    
    ObjC_BaseResult *objc_b_r = [[ObjC_BaseResult  alloc] init];
    
    objc_b_r.Success = [NSNumber numberWithBool: br.Success ? YES : NO];
    
    switch ( br.ErrorCode ) {
        case dodicall::results::ResultErrorNo:
            objc_b_r.ErrorCode = ResultErrorNo;
            break;
        case dodicall::results::ResultErrorSystem:
            objc_b_r.ErrorCode = ResultErrorSystem;
            break;
        case dodicall::results::ResultErrorSetupNotCompleted:
            objc_b_r.ErrorCode = ResultErrorSetupNotCompleted;
            break;
        case dodicall::results::ResultErrorAuthFailed:
            objc_b_r.ErrorCode = ResultErrorAuthFailed;
            break;
        case dodicall::results::ResultErrorNoNetwork:
            objc_b_r.ErrorCode = ResultErrorNoNetwork;
            break;
    }
    
    if ( [objc_b_r.Success boolValue] == NO)
        return objc_b_r;
    
    for (auto iterator = begin (c_res_set); iterator != end (c_res_set); ++iterator) {
        dodicall::dbmodel::ContactModel contact = *iterator;
        
        ObjC_ContactModel *objc_contact = [self convert_to_obj_c_contact: contact];
        
        [result addObject: objc_contact];
    }
    return objc_b_r;
}


- (BOOL) MarkSubscriptionAsOld: (NSString*) xmppId {
    std::string id = [self convert_to_std_string: xmppId];
    
    return dodicall::Application::GetInstance().MarkSubscriptionAsOld(id) ? YES : NO;
}

- (void) DownloadAvatarForContactsWithDodicallIds:(NSMutableArray *)contactIds {
    
    dodicall::ContactDodicallIdSet ids;
    
    for(NSString *contactId in contactIds) {
        std::string dodicallId = [self convert_to_std_string:contactId];
        ids.insert(dodicallId);
    }
    
    dodicall::Application::GetInstance().DownloadAvatarForContactsWithDodicallIds(ids);
}

- (void) ChangeCodecSettings: (NSMutableArray*) settings {
    dodicall::CodecSettingsList c_settings;
    
    for ( CodecSettingModel *element in settings ) {
    
        dodicall::model::CodecSettingModel cs_model;
        
        cs_model.Type = element.Type == CodecTypeAudio ? dodicall::model::CodecTypeAudio : dodicall::model::CodecTypeVideo;
        cs_model.ConnectionType = element.ConnectionType == ConnectionTypeCell ? dodicall::model::ConnectionTypeCell : dodicall::model::ConnectionTypeWifi;
        cs_model.Name = [self convert_to_std_string: element.Name];
        cs_model.Mime = [self convert_to_std_string:element.Mime];
        cs_model.Rate = element.Rate;
        cs_model.Priority = element.Priority;
        cs_model.Enabled = [element.Enabled boolValue] == YES ? true : false;
        
        c_settings.push_back(cs_model);
    
    }
    dodicall::Application::GetInstance().ChangeCodecSettings(c_settings);
}


- (void) StartCachingPhoneBookContacts {
    
    CNContactStore *store = [[CNContactStore alloc] init];
    
    if (store != nil)
        [store requestAccessForEntityType:CNEntityTypeContacts completionHandler:^(BOOL granted, NSError * _Nullable error) {
        
        // make sure the user granted us access
        
        if (!granted) {
            dispatch_async(dispatch_get_main_queue(), ^{
                // user didn't grant access;
                // so, again, tell user here why app needs permissions in order  to do it's job;
                // this is dispatched to the main queue because this request could be running on background thread
            });
            return;
        }
        
        NSError *fetchError;

        NSArray *keysToFetch =@[CNContactIdentifierKey, CNContactPhoneNumbersKey, CNContactFamilyNameKey, CNContactGivenNameKey, CNContactOrganizationNameKey];
        CNContactFetchRequest *request = [[CNContactFetchRequest alloc]initWithKeysToFetch:keysToFetch];
        
        __block std::set<dodicall::dbmodel::ContactModel> contacts;
        
        BOOL success = [store enumerateContactsWithFetchRequest:request error:&fetchError usingBlock:^(CNContact *contact, BOOL *stop) {
            
            dodicall::dbmodel::ContactModel dodicall_contact;
            
            dodicall_contact.Id = 0;
            dodicall_contact.DodicallId = "";
            
            if ( [contact isKeyAvailable: CNContactIdentifierKey ] )
                dodicall_contact.PhonebookId = [self convert_to_std_string: contact.identifier];
            
            if ( [contact isKeyAvailable: CNContactGivenNameKey ] )
                dodicall_contact.FirstName = [self convert_to_std_string: contact.givenName];
            
            if ( [contact isKeyAvailable: CNContactFamilyNameKey ] )
                dodicall_contact.LastName = [self convert_to_std_string: contact.familyName];
            
            if ( [contact isKeyAvailable: CNContactGivenNameKey ] && [contact isKeyAvailable: CNContactFamilyNameKey ] && [contact isKeyAvailable: CNContactOrganizationNameKey ] ) {
                if (dodicall_contact.FirstName.empty() && dodicall_contact.LastName.empty())
                    dodicall_contact.FirstName = [self convert_to_std_string: contact.organizationName];
            }
            
            
            if ( [contact isKeyAvailable: CNContactPhoneNumbersKey ] ) {
                for (CNLabeledValue *element in contact.phoneNumbers) {
                    dodicall::dbmodel::ContactsContactModel c_model;
                    
                    c_model.Type = dodicall::dbmodel::ContactsContactPhone;
                    
                    NSString *phone = [element.value stringValue];
                    if ([phone length] > 0) {
                        c_model.Identity = [self convert_to_std_string:phone];
                        if ( [contact isKeyAvailable: CNContactGivenNameKey ] && [contact isKeyAvailable: CNContactFamilyNameKey ] && [contact isKeyAvailable: CNContactOrganizationNameKey ] ) {
                            if (dodicall_contact.FirstName.empty() && dodicall_contact.LastName.empty())
                                dodicall_contact.FirstName = c_model.Identity;
                        }
                    }
                    dodicall_contact.Contacts.insert(c_model);
                }
            }
            
            contacts.insert(dodicall_contact);
        }];
        
        if (!success) {
            NSLog(@"error = %@", fetchError);
        }
        
        dodicall::Application::GetInstance().CachePhonebookContacts(contacts);
        
        if ( isABCallbackRegistered == NO ) {
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(addressBookDidChange:) name:CNContactStoreDidChangeNotification object:nil];
            isABCallbackRegistered = YES;
        }
    }];
   
}

-(void) addressBookDidChange:(NSNotification*)notification {
    [self StartCachingPhoneBookContacts];
}

void addressBookChanged (ABAddressBookRef abRef, CFDictionaryRef dicRef, void *context) {
    Dodicall_Bridge *self_ptr = (__bridge Dodicall_Bridge*) context;
    
    [self_ptr StartCachingPhoneBookContacts_Deprecated];
}

- (void) StartCachingPhoneBookContacts_Deprecated {
        // ( prior to iOS 9 ) :
    
        // open the default address book.
        dispatch_async(dispatch_get_main_queue(), ^{
        
     
        if (!m_addressbook) {
            NSLog(@"opening address book");
        }
    
        __block BOOL accessGranted = NO;
            
        // checking for access
        if (&ABAddressBookRequestAccessWithCompletion != NULL) {
            // @TODO: replace with better asynchronous call:
            dispatch_semaphore_t s = dispatch_semaphore_create(0);
                
                ABAddressBookRequestAccessWithCompletion(m_addressbook, ^(bool granted, CFErrorRef error) {
                    accessGranted = granted;
                    dispatch_semaphore_signal(s);
                });
                
                dispatch_semaphore_wait(s, DISPATCH_TIME_FOREVER);
        }
            
        if ( accessGranted ) {
            
        std::set<dodicall::dbmodel::ContactModel> contacts;
    
        CFArrayRef allPeople = ABAddressBookCopyArrayOfAllPeople(m_addressbook);
        CFIndex nPeople = ABAddressBookGetPersonCount(m_addressbook);
        for (int i = 0 ; i < nPeople ; i ++ ) {
            NSMutableDictionary* tempContactDic = [NSMutableDictionary new];
            
            ABRecordRef ref = CFArrayGetValueAtIndex(allPeople, i);
            
            //ABMultiValueRef phoneId;
            //phoneId = ABRecordCopyValue(ref, );
            //NSString *id_str = (__bridge  NSString *) phoneId;
            //[tempContactDic setValue:id_str forKey: @"id"];
            
            ABRecordID recordId = ABRecordGetRecordID(ref);
            NSNumber* id_number = [NSNumber numberWithInt:(int)recordId];
            
            NSString *id_str = [id_number stringValue];
            [tempContactDic setValue:id_str forKey: @"id"];
            
            ABMultiValueRef firstName, lastName;
            NSString *first_name, *last_name;
            firstName = ABRecordCopyValue(ref, kABPersonFirstNameProperty);
            lastName  = ABRecordCopyValue(ref, kABPersonLastNameProperty);
            
            ABMultiValueRef companyName;
            NSString *company_name;
            companyName = ABRecordCopyValue(ref, kABPersonOrganizationProperty);
            company_name = (__bridge  NSString *)companyName;
            [tempContactDic setValue:company_name forKey:@"company_name"];
            
            first_name = (__bridge  NSString *)firstName;
            [tempContactDic setValue:first_name forKey:@"first_name"];
            
            last_name = (__bridge  NSString *)lastName;
            [tempContactDic setValue:last_name forKey:@"last_name"];
            
            ABMultiValueRef phones;
            phones = ABRecordCopyValue(ref, kABPersonPhoneProperty);
            
            dodicall::dbmodel::ContactModel dodicall_contact;
            
            dodicall_contact.Id = 0;
            dodicall_contact.DodicallId = "";
            
            if ( [tempContactDic valueForKey: @"id" ] != nil )
                dodicall_contact.PhonebookId = [self convert_to_std_string : [tempContactDic valueForKey: @"id"] ];
            
            if ( [tempContactDic valueForKey: @"first_name" ] != nil )
                dodicall_contact.FirstName = [self convert_to_std_string : [tempContactDic valueForKey: @"first_name"] ];
            
            if ( [tempContactDic valueForKey: @"last_name" ] != nil )
                dodicall_contact.LastName =  [self convert_to_std_string : [tempContactDic valueForKey: @"last_name"] ];
            
            if ( [tempContactDic valueForKey: @"first_name" ] == nil && [tempContactDic valueForKey: @"last_name" ] == nil) {
                if ( [tempContactDic valueForKey: @"company_name" ] != nil )
                    dodicall_contact.FirstName = [self convert_to_std_string : [tempContactDic valueForKey: @"company_name"] ];
            }
            
            for( CFIndex phoneIndex = 0; phoneIndex < ABMultiValueGetCount( phones ); phoneIndex++ ) {
                NSString* aLabel = (__bridge NSString*) ABMultiValueCopyValueAtIndex( phones, phoneIndex );
                
                dodicall::dbmodel::ContactsContactModel c_model;
                
                c_model.Type = dodicall::dbmodel::ContactsContactPhone;
                
                c_model.Identity = [self convert_to_std_string: aLabel];
                
                if ( [tempContactDic valueForKey: @"first_name" ] == nil && [tempContactDic valueForKey: @"last_name" ] == nil) {
                      if (dodicall_contact.FirstName.empty() && dodicall_contact.LastName.empty())
                        dodicall_contact.FirstName = c_model.Identity;
                }
                
                dodicall_contact.Contacts.insert(c_model);
            }
            contacts.insert(dodicall_contact);
        }
            dodicall::Application::GetInstance().CachePhonebookContacts(contacts);
            
            if ( isABCallbackRegistered == NO ) {
                ABAddressBookRegisterExternalChangeCallback(m_addressbook, addressBookChanged, (__bridge void*) self);
                isABCallbackRegistered = YES;
            }
                CFRelease(allPeople);
      }
        });
  
}

- (ObjC_CreateTroubleTicketResult*) SendTroubleTicket: (NSString*) subject :
                                                       (NSString*) description :
                                                       (ObjC_LogScope*) logScope {
    
    std::string c_subject = [self convert_to_std_string: subject];
    std::string c_description = [self convert_to_std_string: description];
    
    dodicall::LogScope c_logscope;
    
    c_logscope.DatabaseLog = [logScope.DatabaseLog boolValue] == YES ? true : false;
    c_logscope.RequestsLog = [logScope.RequestsLog boolValue] == YES ? true : false;
    c_logscope.VoipLog = [logScope.VoipLog boolValue] == YES ? true : false;
    c_logscope.CallHistoryLog = [logScope.CallHistoryLog boolValue] == YES ? true : false;
    c_logscope.CallQualityLog = [logScope.CallQualityLog boolValue] == YES ? true : false;
    c_logscope.ChatLog = [logScope.ChatLog boolValue] == YES ? true : false;
    c_logscope.TraceLog = [logScope.TraceLog boolValue] == YES ? true : false;
    c_logscope.GuiLog = [logScope.GuiLog boolValue] == YES ? true : false;
    
    dodicall::CreateTroubleTicketResult c_res= dodicall::Application::GetInstance().SendTroubleTicket(c_subject.c_str(), c_description.c_str(), c_logscope);
   
    ObjC_CreateTroubleTicketResult *res = [[ObjC_CreateTroubleTicketResult alloc] init] ;
    
    res.Success = [NSNumber numberWithBool: c_res.Success ? YES : NO];
    
    switch ( c_res.ErrorCode ) {
        case dodicall::ResultErrorNo:
            res.ErrorCode = ResultErrorNo;
            break;
        case dodicall::results::ResultErrorSystem:
            res.ErrorCode = ResultErrorSystem;
            break;
        case dodicall::results::ResultErrorSetupNotCompleted:
            res.ErrorCode = ResultErrorSetupNotCompleted;
            break;
        case dodicall::results::ResultErrorAuthFailed:
            res.ErrorCode = ResultErrorAuthFailed;
            break;
        case dodicall::results::ResultErrorNoNetwork:
            res.ErrorCode = ResultErrorNoNetwork;
            break;
    }
    res.IssueId = c_res.IssueId;
    
    return res;
}


- (ObjC_BalanceResult*) GetBalance {
    dodicall::BalanceResult c_b_result = dodicall::Application::GetInstance().GetBalance();
    
    ObjC_BalanceResult *b_result = [[ObjC_BalanceResult alloc] init];
    
    b_result.Success = [NSNumber numberWithBool: c_b_result.Success ? YES : NO];
    
    switch ( c_b_result.ErrorCode ) {
        case dodicall::results::ResultErrorNo:
            b_result.ErrorCode = ResultErrorNo;
            break;
        case dodicall::results::ResultErrorSystem:
            b_result.ErrorCode = ResultErrorSystem;
            break;
        case dodicall::results::ResultErrorSetupNotCompleted:
            b_result.ErrorCode = ResultErrorSetupNotCompleted;
            break;
        case dodicall::results::ResultErrorAuthFailed:
            b_result.ErrorCode = ResultErrorAuthFailed;
            break;
        case dodicall::results::ResultErrorNoNetwork:
            b_result.ErrorCode = ResultErrorNoNetwork;
            break;
    }
    
    b_result.BalanceValue = c_b_result.BalanceValue;
    
    if ( c_b_result.BalanceCurrency == dodicall::results::CurrencyRuble )
        b_result.BalanceCurrency = CurrencyRuble;
    else if ( c_b_result.BalanceCurrency == dodicall::results::CurrencyUsd )
        b_result.BalanceCurrency = CurrencyUsd;
    else if ( c_b_result.BalanceCurrency == dodicall::results::CurrencyEur )
        b_result.BalanceCurrency = CurrencyEur;
    
    b_result.HasBalance = [NSNumber numberWithBool: c_b_result.HasBalance ? YES : NO];
    
    return b_result;
}

- (ObjC_ContactModel*) GetAccountData {
    dodicall::dbmodel::ContactModel contact = dodicall::Application::GetInstance().GetAccountData();
    
    ObjC_ContactModel *objc_contact = [self convert_to_obj_c_contact: contact];
    
    return objc_contact;
}

-(BOOL) CreateChatWithContacts: (NSMutableArray*) contacts: (ObjC_ChatModel*) result {
    
    dodicall::ContactModelSet c_List;
    
    for ( ObjC_ContactModel *element in contacts ) {
        dodicall::dbmodel::ContactModel c_contact = [self convert_to_c_contact:element];
        
        c_List.insert(c_contact);
    }
    
    dodicall::ChatModel chatModel;
    
    bool c_res = dodicall::Application::GetInstance().CreateChatWithContacts(c_List, chatModel);
    
    result.Id = [self convert_to_obj_c_str : chatModel.Id];
    
    result.Title = [self convert_to_obj_c_str : chatModel.Title];
    time_t modified_time = dodicall::posix_time_to_time_t(chatModel.LastModifiedDate);
    result.LastModifiedDate = [NSDate dateWithTimeIntervalSince1970:modified_time];
    result.Active = [NSNumber numberWithBool: chatModel.Active ? YES : NO];
    
    result.Contacts = [[NSMutableArray alloc] init];
    
    for (auto iterator = begin (chatModel.Contacts); iterator != end (chatModel.Contacts); ++iterator) {
        ObjC_ContactModel *contact = [self convert_to_obj_c_contact: *iterator];
        
        [result.Contacts addObject: contact];
    }
    
    result.TotalMessagesCount = chatModel.TotalMessagesCount;
    result.NewMessagesCount = chatModel.NewMessagesCount;
    
    if (!chatModel.LastMessage)
        result.lastMessage = nil;
    else {
        result.lastMessage = [self convert_to_obj_c_message: *chatModel.LastMessage];
    }
    
    result.IsP2p = [NSNumber numberWithBool: chatModel.IsP2p ? YES : NO];
    
    return c_res ? YES : NO;
}

- (NSString*) SendTextMessage: (NSString*) msg_id : (NSString*) chat_id : (NSString*) msg {
    std::string c_msg = [self convert_to_std_string: msg];
    
    std::string to = [self convert_to_std_string: chat_id];
    
    std::string c_id = [self convert_to_std_string: msg_id];

    std::string result = dodicall::Application::GetInstance().SendTextMessage(c_id, to, c_msg.c_str());
    return [self convert_to_obj_c_str: result];
}

- (NSString*) PregenerateMessageId {
    std::string result_str = dodicall::Application::GetInstance().PregenerateMessageId();
    
    return [self convert_to_obj_c_str: result_str];
}

- (BOOL) MarkMessagesAsReaded: (NSString*) msg_id {
    std::string c_id = [self convert_to_std_string: msg_id];
    
    return dodicall::Application::GetInstance().MarkMessagesAsReaded(c_id) ? YES : NO;
}

- (int) GetNewMessagesCount {
    return dodicall::Application::GetInstance().GetNewMessagesCount();
}

- (void) RenameChat: (NSString*) subject : (ObjC_ChatModel*) chat {
    dodicall::dbmodel::ChatModel c_chat;
    
    std::string c_subject = [self convert_to_std_string: subject];
    
    std::string to = [self convert_to_std_string: chat.Id];
   
    dodicall::Application::GetInstance().RenameChat(to.c_str(), c_subject.c_str());
}

- (NSString*) InviteAndRevokeChatMembers: (NSString*) chat_id : (NSMutableArray*) inviteList : (NSMutableArray*) revokeList {
    std::string to = [self convert_to_std_string: chat_id];

    dodicall::ContactModelSet c_inviteList;
    dodicall::ContactModelSet c_revokeList;
    
    if ( inviteList!= nil && [inviteList count] > 0) {
        for ( ObjC_ContactModel *element in inviteList ) {
            dodicall::dbmodel::ContactModel c_contact = [self convert_to_c_contact:element];
        
            c_inviteList.insert(c_contact);
        }
    }
    
    if ( revokeList!= nil && [revokeList count] > 0) {
        for ( ObjC_ContactModel *element in revokeList ) {
            dodicall::dbmodel::ContactModel c_contact = [self convert_to_c_contact:element];
        
            c_revokeList.insert(c_contact);
        }
    }
    
    std::string c_id = dodicall::Application::GetInstance().InviteAndRevokeChatMembers(to.c_str(), c_inviteList, c_revokeList);
    
    return [self convert_to_obj_c_str : c_id];

}

- (BOOL) GetAllChats : (NSMutableArray*) result_list {
    std::set<dodicall::dbmodel::ChatModel> c_result_list;
    
    bool res = dodicall::Application::GetInstance().GetAllChats(c_result_list);
    
    if (!res)
        return NO;
    
    for (auto iterator = begin (c_result_list); iterator != end (c_result_list); ++iterator) {
        dodicall::dbmodel::ChatModel chat = *iterator;
        
        ObjC_ChatModel *objc_chat = [self convert_to_obj_c_chat: chat];
        
        [result_list addObject: objc_chat];
    }
    
    if ( result_list== nil || [result_list count] == 0)
        return NO;
    
    return YES;
}

- (BOOL) GetChatsByIds : (NSMutableArray*) ids : (NSMutableArray*) result_list {
    std::set<dodicall::dbmodel::ChatModel> c_result_list;
    
    std::set<std::string> c_ids;
    
    for ( NSString *element in ids ) {
        std::string id = [self convert_to_std_string:element];
        
        c_ids.insert(id);
    }
    
    bool res = dodicall::Application::GetInstance().GetChatsByIds(c_ids, c_result_list);
    
    if (!res)
        return NO;
    
    for (auto iterator = begin (c_result_list); iterator != end (c_result_list); ++iterator) {
        dodicall::dbmodel::ChatModel chat = *iterator;
        
        ObjC_ChatModel *objc_chat = [self convert_to_obj_c_chat: chat];
        
        [result_list addObject: objc_chat];
    }
    
    if ( result_list== nil || [result_list count] == 0)
        return NO;
    
    return YES;
}

- (NSMutableArray*) GetChatMessagesById : (NSString*) chat_id {
    std::string from = [self convert_to_std_string: chat_id];
    
    std::set<dodicall::ChatMessageModel> c_messages;
    
    dodicall::Application::GetInstance().GetChatMessages(from, c_messages);
    
    NSMutableArray *messages = [[NSMutableArray alloc] init];
    
    for (auto iterator = begin (c_messages); iterator != end (c_messages); ++iterator) {
        dodicall::ChatMessageModel msg = (*iterator);
        
        ObjC_ChatMessageModel *objc_msg = [self convert_to_obj_c_message: msg];
    
        [messages addObject : objc_msg ];
    }
    return messages;
}

- (void) ForceChatSync:(ChatIdType) chatId {
    std::string identity = [self convert_to_std_string: chatId];
    dodicall::Application::GetInstance().ForceChatSync(identity);
}

- (BOOL) GetChatMessagesByIds : (NSMutableArray*) ids : (NSMutableArray*) result_list {
    std::set<std::string> c_ids;
    
    for ( NSString *element in ids ) {
        std::string id = [self convert_to_std_string:element];
        
        c_ids.insert(id);
    }
    
    std::set<dodicall::ChatMessageModel> c_messages;
    
    dodicall::Application::GetInstance().GetMessagesByIds(c_ids, c_messages);
    
    for (auto iterator = begin (c_messages); iterator != end (c_messages); ++iterator) {
        dodicall::ChatMessageModel msg = (*iterator);
        
        ObjC_ChatMessageModel *objc_msg = [self convert_to_obj_c_message: msg];
        
        [result_list addObject : objc_msg ];
    }
    
    if (result_list == nil || [result_list count] == 0)
        return NO;
    
    return YES;
    
}

- (BOOL) ExitChats : (NSMutableArray*) chat_Ids : (NSMutableArray*) failed_chat_Ids {
    std::set<std::string> c_chats;
    
    for ( NSString *element in chat_Ids ) {
        std::string room_id = [self convert_to_std_string: element];
        c_chats.insert(room_id);
    }
    
    std::set<std::string> failed_c_chats;
    
    if ( dodicall::Application::GetInstance().ExitChats(c_chats, failed_c_chats) == false )
        return NO;
    
    for (auto it = begin (failed_c_chats); it != end (failed_c_chats); ++it) {
        NSString *failed_id = [self convert_to_obj_c_str: *it];
        [failed_chat_Ids addObject : failed_id];
    }
    return YES;
}

- (BOOL) ClearChats : (NSMutableArray*) chat_Ids : (NSMutableArray*) failed_chat_Ids {
    std::set<std::string> c_chats;
    
    for ( NSString *element in chat_Ids ) {
        std::string room_id = [self convert_to_std_string: element];
        c_chats.insert(room_id);
    }
    
    std::set<std::string> failed_c_chats;
    
    if ( dodicall::Application::GetInstance().ClearChats(c_chats, failed_c_chats) == false )
        return NO;
    
    for (auto it = begin (failed_c_chats); it != end (failed_c_chats); ++it)
    {
        NSString *failed_id = [self convert_to_obj_c_str: *it];
        [failed_chat_Ids addObject : failed_id];
    }
    return YES;
}

- (void) DeleteChatMessages : (NSMutableArray*) msg_ids {
    dodicall::ChatMessageIdSet c_msg_ids;
    
    for ( NSString *element in  msg_ids ) {
        std::string id = [self convert_to_std_string:element];
        
        c_msg_ids.insert(id);
    }
    
    dodicall::Application::GetInstance().DeleteMessages(c_msg_ids);
}

- (void) ChangeMessage:(NSString *)Id Text:(NSString *)Text {
    dodicall::ChatMessageIdType c_msg_id = [self convert_to_std_string:Id];
    std::string c_text = [self convert_to_std_string:Text];
    dodicall::Application::GetInstance().CorrectMessage(c_msg_id, c_text);
}

- (BOOL) SendContactToChat: (NSString*) msg_id : (NSString*) chat_id : (ObjC_ContactModel*) contactData {
    std::string to = [self convert_to_std_string: chat_id];
    std::string c_msg_id = [self convert_to_std_string: msg_id];
    
    dodicall::dbmodel::ContactModel c_contact = [self convert_to_c_contact:contactData];
    
    return dodicall::Application::GetInstance().SendContactToChat(c_msg_id, to, c_contact) ? YES : NO;
}

- (BOOL) StartCallToContact: (ObjC_ContactModel*) contact : (CallOptions) options {
    dodicall::dbmodel::ContactModel c_contact = [self convert_to_c_contact:contact];
    
    dodicall::CallOptions c_options = dodicall::CallOptionsDefault;
    if (options == CallOptionsDefault)
        c_options = dodicall::CallOptionsDefault;
    
    return dodicall::Application::GetInstance().StartCallToContact(c_contact, c_options) ? YES : NO;
}

#pragma mark Calls

- (BOOL) StartCallToUrl: (NSString*) url: (CallOptions) options {
    std::string cpp_url = [self convert_to_std_string: url] ;
    
    dodicall::CallOptions c_options = dodicall::CallOptionsDefault;
    if (options == CallOptionsDefault)
        c_options = dodicall::CallOptionsDefault;
    
    return dodicall::Application::GetInstance().StartCallToUrl(cpp_url, c_options) ? YES : NO;
}

- (BOOL) StartCallToContactUrl:(ObjC_ContactModel*) contact : (ObjC_ContactsContactModel *) contactsContact : (CallOptions) options {
    
    dodicall::dbmodel::ContactModel c_contact = [self convert_to_c_contact:contact];
    dodicall::dbmodel::ContactsContactModel c_contactsContact = [self convert_to_c_contactsContact:contactsContact];
    
    dodicall::CallOptions c_options = dodicall::CallOptionsDefault;
    if (options == CallOptionsDefault)
        c_options = dodicall::CallOptionsDefault;
    
    return dodicall::Application::GetInstance().StartCallToContactUrl (c_contact, c_contactsContact, c_options) ? YES : NO;
}

- (ObjC_CallsModel *) GetAllCalls {
    ObjC_CallsModel *allCalls;
        allCalls = [[ObjC_CallsModel alloc ] init];
    
    dodicall::CallsModel c_calls;
    
    bool res = dodicall::Application::GetInstance().GetAllCalls(c_calls);
    
    if (!res)
        return nil;
    
    allCalls.SingleCalls = [[NSMutableArray alloc] init];
    
    for (auto it = begin (c_calls.SingleCalls); it != end (c_calls.SingleCalls); ++it) {
        dodicall::dbmodel::CallModel call = *it;
        
        ObjC_CallModel *objc_call = [self convert_to_obj_c_call: (*it)];
        
        [allCalls.SingleCalls addObject: objc_call];
    }
    
    allCalls.Conference = [[ObjC_ConferenceModel alloc] init];
    
    for (auto it = begin (c_calls.Conference.Calls); it != end (c_calls.Conference.Calls); ++it) {
        dodicall::dbmodel::CallModel call = *it;
        
        ObjC_CallModel *objc_call = [self convert_to_obj_c_call: (*it)];
        
        [allCalls.Conference.Calls addObject: objc_call];
    }
    
    return allCalls;
}

- (BOOL) AcceptCall: (NSString*) callId : (CallOptions) options {
    std::string cpp_callId = [self convert_to_std_string: callId];
    
    dodicall::CallOptions c_options = dodicall::CallOptionsDefault;
    if (options == CallOptionsDefault)
        c_options = dodicall::CallOptionsDefault;
    
    return dodicall::Application::GetInstance().AcceptCall(cpp_callId, c_options) ? YES : NO;
}
- (BOOL) HangupCall: (NSString*) callId {
    std::string cpp_callId = [self convert_to_std_string: callId];
    
    return dodicall::Application::GetInstance().HangupCall(cpp_callId) ? YES : NO;
}

- (BOOL) PauseCall: (NSString*) callId
{
    std::string cpp_callId = [self convert_to_std_string: callId];
    
    return dodicall::Application::GetInstance().PauseCall(cpp_callId) ? YES : NO;
}

- (BOOL) ResumeCall: (NSString*) callId
{
    std::string cpp_callId = [self convert_to_std_string: callId];
    
    return dodicall::Application::GetInstance().ResumeCall(cpp_callId) ? YES : NO;
}

- (void) SendReadyForCallAfterStart: (NSString*) pusherSipNumber
{
    std::string cpp_pusherSipNumber = [self convert_to_std_string: pusherSipNumber];
    
    dodicall::Application::GetInstance().SendReadyForCallAfterStart(cpp_pusherSipNumber);
}

- (ObjC_ContactModel*) RetriveContactByNumber: (NSString*) number {
    
    std::string cpp_number = [self convert_to_std_string: number];
    
    dodicall::dbmodel::ContactModel contact = dodicall::Application::GetInstance().RetriveContactByNumber(cpp_number);
    
    ObjC_ContactModel *objc_contact = [self convert_to_obj_c_contact: contact];
    
    return objc_contact;
}

- (BOOL) PlayDtmf: (char) number {
    return dodicall::Application::GetInstance().PlayDtmf(number) ? YES : NO;
}

- (BOOL) StopDtmf {
    return dodicall::Application::GetInstance().StopDtmf() ? YES : NO;
}

- (ObjC_CallForwardingSettingsModel*) RetrieveCallForwardingSettings {
    ObjC_CallForwardingSettingsModel *cfSettings = [[ObjC_CallForwardingSettingsModel alloc] init];
        
    cfSettings.stateSettingsAlways = [[ObjC_StateSettingsModel alloc] init];
    cfSettings.stateSettingsBusy = [[ObjC_StateSettingsModel alloc] init];
    cfSettings.stateSettingsNoAnswer= [[ObjC_StateSettingsExtendedModel alloc] init];
    cfSettings.stateSettingsNotReachable = [[ObjC_StateSettingsModel alloc] init];
    
    dodicall::CallForwardingSettingsModel cpp_cfSettings;
    
    dodicall::BaseResult br = dodicall::Application::GetInstance().RetrieveCallForwardingSettings(cpp_cfSettings);
    
    ObjC_BaseResult *objc_b_r = [[ObjC_BaseResult  alloc] init];
    
    objc_b_r.Success = [NSNumber numberWithBool: br.Success ? YES : NO];
    
    objc_b_r.ErrorCode = br.ErrorCode == dodicall::results::ResultErrorSystem ? ResultErrorSystem : ResultErrorNo;
    
    if ( [objc_b_r.Success boolValue] == NO)
        return cfSettings;
    
    cfSettings.stateSettingsAlways.active = [NSNumber numberWithBool: cpp_cfSettings.stateSettingsAlways.active ? YES : NO];
    cfSettings.stateSettingsAlways.destination = [self convert_to_obj_c_str: cpp_cfSettings.stateSettingsAlways.destination];
    
    cfSettings.stateSettingsBusy.active = [NSNumber numberWithBool: cpp_cfSettings.stateSettingsBusy.active ? YES : NO];
    cfSettings.stateSettingsBusy.destination = [self convert_to_obj_c_str: cpp_cfSettings.stateSettingsBusy.destination];
    
    cfSettings.stateSettingsNoAnswer.active = [NSNumber numberWithBool: cpp_cfSettings.stateSettingsNoAnswer.active ? YES : NO];
    cfSettings.stateSettingsNoAnswer.destination = [self convert_to_obj_c_str: cpp_cfSettings.stateSettingsNoAnswer.destination];
    cfSettings.stateSettingsNoAnswer.duration = cpp_cfSettings.stateSettingsNoAnswer.duration;
    
    cfSettings.stateSettingsNotReachable.active = [NSNumber numberWithBool: cpp_cfSettings.stateSettingsNotReachable.active ? YES : NO];
    cfSettings.stateSettingsNotReachable.destination = [self convert_to_obj_c_str: cpp_cfSettings.stateSettingsNotReachable.destination];
    
    return cfSettings;
}

- (ObjC_BaseResult*) SetCallForwardingSettings: (ObjC_CallForwardingSettingsModel*) cfSettings {
    if (cfSettings == nil) {
        // set default?
        cfSettings = [[ObjC_CallForwardingSettingsModel alloc] init];
        cfSettings.stateSettingsAlways = [[ObjC_StateSettingsModel alloc] init];
        cfSettings.stateSettingsBusy = [[ObjC_StateSettingsModel alloc] init];
        cfSettings.stateSettingsNoAnswer= [[ObjC_StateSettingsExtendedModel alloc] init];
        cfSettings.stateSettingsNotReachable = [[ObjC_StateSettingsModel alloc] init];
    }
    
    dodicall::CallForwardingSettingsModel cpp_cfSettings;
    
    cpp_cfSettings.stateSettingsAlways.active = [cfSettings.stateSettingsAlways.active  boolValue] == YES ? true : false;
    cpp_cfSettings.stateSettingsAlways.destination = [self convert_to_std_string: cfSettings.stateSettingsAlways.destination];
    
    cpp_cfSettings.stateSettingsBusy.active = [cfSettings.stateSettingsBusy.active  boolValue] == YES ? true : false;
    cpp_cfSettings.stateSettingsBusy.destination = [self convert_to_std_string: cfSettings.stateSettingsBusy.destination];
    
    cpp_cfSettings.stateSettingsNoAnswer.active = [cfSettings.stateSettingsNoAnswer.active boolValue] == YES ? true : false;
    cpp_cfSettings.stateSettingsNoAnswer.destination = [self convert_to_std_string: cfSettings.stateSettingsNoAnswer.destination];
    cpp_cfSettings.stateSettingsNoAnswer.duration = cfSettings.stateSettingsNoAnswer.duration;
    
    cpp_cfSettings.stateSettingsNotReachable.active = [cfSettings.stateSettingsNotReachable.active boolValue] == YES ? true : false;
    cpp_cfSettings.stateSettingsNotReachable.destination = [self convert_to_std_string: cfSettings.stateSettingsNotReachable.destination];
    
    dodicall::BaseResult br = dodicall::Application::GetInstance().SetCallForwardingSettings(cpp_cfSettings);
    
    ObjC_BaseResult *objc_b_r = [[ObjC_BaseResult  alloc] init];
    
    objc_b_r.Success = [NSNumber numberWithBool: br.Success ? YES : NO];
    
    objc_b_r.ErrorCode = br.ErrorCode == dodicall::results::ResultErrorSystem ? ResultErrorSystem : ResultErrorNo;
    
    return objc_b_r;
}

- (NSMutableArray*) RetrieveAreas {
    dodicall::ServerAreaMap areas;
    
    dodicall::Application::GetInstance().RetrieveAreas(areas);
    
    NSMutableArray *result = [[NSMutableArray alloc] init];
    
    for (auto it = begin (areas); it != end (areas); ++it) {
        ObjC_AreaInfo *areaInfo = [[ObjC_AreaInfo alloc] init];
    
        areaInfo.Url = [self convert_to_obj_c_str: (*it).second.AsUrl];
        areaInfo.AccUrl = [self convert_to_obj_c_str: (*it).second.LcUrl];
        areaInfo.NameEn = [self convert_to_obj_c_str: (*it).second.NameEn];
        areaInfo.NameRu = [self convert_to_obj_c_str: (*it).second.NameRu];
        areaInfo.Reg = [self convert_to_obj_c_str: (*it).second.Reg];
        areaInfo.ForgotPwd = [self convert_to_obj_c_str: (*it).second.ForgotPwd];
        
        [result addObject: areaInfo];
    }
    return result;
}

- (void) EnableMicrophone: (BOOL) enable {
    dodicall::Application::GetInstance().EnableMicrophone(enable == YES ? true : false);
}

- (BOOL) IsMicrophoneEnabled {
    return dodicall::Application::GetInstance().IsMicrophoneEnabled() ? YES : NO;
}

- (BOOL) GetSoundDevices: (NSMutableArray*) devices {
    
    std::set<dodicall::SoundDeviceModel> c_devices;
    
    bool res = dodicall::Application::GetInstance().GetSoundDevices(c_devices);
    
    if (!res)
        return NO;
    
    for (auto it = begin (c_devices); it != end (c_devices); ++it)  {
        ObjC_SoundDeviceModel *model = [[ObjC_SoundDeviceModel alloc] init];
        
        model.DevId = [self convert_to_obj_c_str: (*it).DevId];
        model.CanCapture = [NSNumber numberWithBool: (*it).CanCapture ? YES : NO];
        model.CanPlay = [NSNumber numberWithBool: (*it).CanPlay ? YES : NO];
        model.CurrentRinger = [NSNumber numberWithBool: (*it).CurrentRinger ? YES : NO];
        model.CurrentPlayback = [NSNumber numberWithBool: (*it).CurrentPlayback ? YES : NO];
        model.CurrentCapture = [NSNumber numberWithBool: (*it).CurrentCapture ? YES : NO];
        
        [devices addObject: model];
    }
    
    if ( devices != nil && [devices count] > 0)
        return YES;
    
    return NO;
}

- (BOOL) SetPlaybackDevice: (NSString*) device {
    std::string c_device = [self convert_to_std_string: device];
    
    return dodicall::Application::GetInstance().SetPlaybackDevice(c_device) ? YES : NO;
}

- (BOOL) SetCaptureDevice: (NSString*) device {
    std::string c_device = [self convert_to_std_string: device];
    
    return dodicall::Application::GetInstance().SetCaptureDevice(c_device) ? YES : NO;
}

- (BOOL) SetRingDevice: (NSString*) device {
    std::string c_device = [self convert_to_std_string: device];
    
    return dodicall::Application::GetInstance().SetRingDevice(c_device) ? YES : NO;
}

- (int) SetPlaybackLevel: (int) level {
    return dodicall::Application::GetInstance().SetPlaybackLevel(level);
}

- (int) SetCaptureLevel: (int) level {
    return dodicall::Application::GetInstance().SetCaptureLevel(level);
}

- (int) SetRingLevel: (int) level {
    return dodicall::Application::GetInstance().SetRingLevel(level);
}

#pragma mark History

- (BOOL) GetAllHistoryStatisticsWithFilter: (ObjC_HistoryStatisticsFilterModel*) Filter :
                                            (NSMutableArray <ObjC_HistoryStatisticsModel *> *) HistoryStatisticsList
{
    dodicall::dbmodel::CallHistoryModel CHistory;
    
    dodicall::dbmodel::HistoryFilterModel CHistoryFilter;
    if(Filter)
    {
        if(Filter.HistoryStatisticsIds && [Filter.HistoryStatisticsIds count] > 0)
        {
            std::set<std::string> c_ids;
            
            for ( NSString *Id in Filter.HistoryStatisticsIds ) {
                std::string c_Id = [self convert_to_std_string:Id];
                
                CHistoryFilter.Peers.push_back(c_Id);
            }
        }
    }
    
    bool Res = dodicall::Application::GetInstance().GetCallHistory(CHistory, CHistoryFilter);
    
    if (!Res)
        return NO;
    
    for (auto Iterator = begin (CHistory.Peers); Iterator != end (CHistory.Peers); ++Iterator) {
        
        dodicall::dbmodel::CallHistoryPeerModel Peer = *Iterator;
        
        ObjC_HistoryStatisticsModel *HistoryStatistics = [self convert_to_obj_c_history_statistics: Peer];
        
        
        NSMutableArray <ObjC_HistoryCallModel *> *HistoryCallsList = [[NSMutableArray alloc] init];
        
        for (auto SubIterator = begin (Peer.DetailsList); SubIterator != end (Peer.DetailsList); ++SubIterator) {
            
            dodicall::dbmodel::CallHistoryEntryModel HistoryEntry = *SubIterator;
            
            ObjC_HistoryCallModel *HistoryCall = [self convert_to_obj_c_history_call: HistoryEntry];
            
            [HistoryCallsList addObject:HistoryCall];
            
        }
        
        if([HistoryCallsList count] > 0)
        {
            NSSortDescriptor *SortDescriptorDate = [[NSSortDescriptor alloc] initWithKey:@"Date" ascending:NO];
        
            [HistoryCallsList sortUsingDescriptors:@[SortDescriptorDate]];
            
            HistoryStatistics.LastCallDate = HistoryCallsList[0].Date;
        }
        
        HistoryStatistics.HistoryCallsList = HistoryCallsList;
        
        [HistoryStatisticsList addObject:HistoryStatistics];
        
    }
    
    if ( HistoryStatisticsList== nil || [HistoryStatisticsList count] == 0)
        return NO;
    
    return YES;
}

- (BOOL) GetAllHistoryStatistics:(NSMutableArray <ObjC_HistoryStatisticsModel *> *) HistoryStatisticsList
{
    return [self GetAllHistoryStatisticsWithFilter:nil : HistoryStatisticsList];
}

- (BOOL) GetHistoryStatisticsByIds:(NSMutableArray <NSString *> *) Ids : (NSMutableArray <ObjC_HistoryStatisticsModel *> *) HistoryStatisticsList
{
    
    ObjC_HistoryStatisticsFilterModel *HistoryStatisticsFilter = [[ObjC_HistoryStatisticsFilterModel alloc] init];
    
    HistoryStatisticsFilter.HistoryStatisticsIds = Ids;
    
    return [self GetAllHistoryStatisticsWithFilter:HistoryStatisticsFilter : HistoryStatisticsList];
    
}

/*
- (BOOL) GetAllHistoryStatisticsFake: (NSMutableArray <ObjC_HistoryStatisticsModel *> *) HistoryStatisticsList
{
    
    //TODO: It is dummy.
    
    for(int i = 0; i <= 50; i++)
    {
        ObjC_HistoryStatisticsModel *HistoryStatistics = [[ObjC_HistoryStatisticsModel alloc] init];
        
        HistoryStatistics.Id = [NSString stringWithFormat:@"Id-%d", i];
        
        //HistoryStatistics.MasterId = [HistoryStatistics.Id copy];
        
        NSMutableArray <ObjC_HistoryCallModel *> *HistoryCallList = [[NSMutableArray alloc] init];
        
        for(int j = 0; j <= 20; j++)
        {
            ObjC_HistoryCallModel *HistoryCallModel = [[ObjC_HistoryCallModel alloc] init];
            
            HistoryCallModel.HistoryStatisticsId = [HistoryStatistics.Id copy];
            
            //HistoryCallModel.MasterId = [HistoryStatistics.Id copy];
            
            HistoryStatistics.Identity = [NSString stringWithFormat:@"Identity-%d", i];
            
            HistoryCallModel.Date = [NSDate date];
            
            HistoryCallModel.DurationInSecs = [[NSNumber alloc]initWithInt:(arc4random() % 500)];
            
            int status = arc4random() % 4;
            
            switch (status) {
                case 1:
                    HistoryCallModel.Status = CallHistoryStatusAborted;
                    break;
                    
                case 2:
                    HistoryCallModel.Status = CallHistoryStatusMissed;
                    break;
                    
                case 3:
                    HistoryCallModel.Status = CallHistoryStatusDeclined;
                    break;
                    
                default:
                    HistoryCallModel.Status = CallHistoryStatusSuccess;
                    break;
            }
            
            int encryption = arc4random() % 2;
            
            switch (encryption) {
                case 1:
                    HistoryCallModel.Encryption = CallEncryptionSRTP;
                    break;
                    
                default:
                    HistoryCallModel.Encryption = CallEncryptionNone;
                    break;
            }
            
            int direction = arc4random() % 2;
            
            switch (direction) {
                case 1:
                    HistoryCallModel.Direction = CallDirectionOutgoing;
                    break;
                    
                default:
                    HistoryCallModel.Direction = CallDirectionIncoming;
                    break;
            }
            
            [HistoryCallList addObject:HistoryCallModel];
            
            HistoryStatistics.HistoryCallsList = [HistoryCallList mutableCopy];
            
            /*
            if(j == 0)
                HistoryStatistics.LastHistoryCall = HistoryCallModel;
             /
        }
        
        
        ObjC_ContactModel *Contact = [[ObjC_ContactModel alloc] init];
        
        
        
        int contactIdType = arc4random() % 5;
        
        switch (contactIdType) {
            case 1:
                Contact.Id = 0;
                Contact.PhonebookId = [NSString stringWithFormat:@"DodicallId-%d", i];
                break;
            
            case 2:
                Contact.Id = i;
                Contact.NativeId = [NSString stringWithFormat:@"NativeId-%d", i];
                break;
            
            case 3:
                Contact.Id = 0;
                Contact.DodicallId = [NSString stringWithFormat:@"DodicallId-%d", i];
                break;
                
            case 4:
                Contact.Id = -1;
                break;
                
            default:
                Contact.Id = i;
                Contact.DodicallId = [NSString stringWithFormat:@"DodicallId-%d", i];
                break;
        }
        
        
        
        Contact.FirstName = [NSString stringWithFormat:@"FirstName-%d", i];
        Contact.LastName = [NSString stringWithFormat:@"LastName-%d", i];
        
        NSMutableArray *ContactContacts = [[NSMutableArray alloc] init];
        
        ObjC_ContactsContactModel *ContactContact = [[ObjC_ContactsContactModel alloc] init];
        
        ContactContact.Type = ContactsContactSip;
        
        ContactContact.Identity = [NSString stringWithFormat:@"test-sip-%d", i];
        
        [ContactContacts addObject:ContactContact];
        
        if(Contact.DodicallId && Contact.DodicallId.length > 0)
        {
            ContactContact = [[ObjC_ContactsContactModel alloc] init];
            
            ContactContact.Type = ContactsContactXmpp;
            
            ContactContact.Identity = @"00070207590-spb.swisstok.ru@swisstok.ru";
            
            [ContactContacts addObject:ContactContact];
        }
        
        
        if(Contact.Id != -1)
        {
            NSMutableArray *Contacts = [[NSMutableArray alloc] init];
        
            [Contacts addObject:Contact];
        
            HistoryStatistics.Contacts = Contacts;
        }
        
        
        
        HistoryStatistics.NumberOfIncomingSuccessfulCalls = [[NSNumber alloc]initWithInt:(arc4random() % 50)];
        HistoryStatistics.NumberOfIncomingUnsuccessfulCalls = [[NSNumber alloc]initWithInt:(arc4random() % 50)];
        HistoryStatistics.NumberOfMissedCalls = [[NSNumber alloc]initWithInt:(arc4random() % 5)];
        HistoryStatistics.NumberOfOutgoingSuccessfulCalls = [[NSNumber alloc]initWithInt:(arc4random() % 50)];
        HistoryStatistics.NumberOfOutgoingUnsuccessfulCalls = [[NSNumber alloc]initWithInt:(arc4random() % 50)];
        
        HistoryStatistics.HasIncomingEncryptedCall = [[NSNumber alloc]initWithInt:(arc4random() % 2)];
        HistoryStatistics.HasOutgoingEncryptedCall = [[NSNumber alloc]initWithInt:(arc4random() % 2)];
        
        HistoryStatistics.WasConference = [NSNumber numberWithBool:NO];
        
        //HistoryStatistics.Readed = [[NSNumber alloc]initWithInt:(arc4random() % 2)];
        
        [HistoryStatisticsList addObject:HistoryStatistics];
    }
    
    
    if ( HistoryStatisticsList== nil || [HistoryStatisticsList count] == 0)
        return NO;
    
    return YES;
}
*/

- (BOOL) SetCallHistoryReadedWithFilter: (ObjC_HistoryStatisticsFilterModel*) Filter
{
    dodicall::dbmodel::HistoryFilterModel CHistoryFilter;
    if(Filter)
    {
        if(Filter.HistoryStatisticsIds && [Filter.HistoryStatisticsIds count] > 0)
        {
            std::set<std::string> c_ids;
            
            for ( NSString *Id in Filter.HistoryStatisticsIds ) {
                std::string c_Id = [self convert_to_std_string:Id];
                
                CHistoryFilter.Peers.push_back(c_Id);
            }
        }
    }
    
    bool Res = dodicall::Application::GetInstance().SetCallHistoryReaded(CHistoryFilter);
    return (Res ? YES : NO);
}

- (BOOL) SetCallHistoryReaded: (NSString *) Id
{
    ObjC_HistoryStatisticsFilterModel *HistoryStatisticsFilter = [[ObjC_HistoryStatisticsFilterModel alloc] init];
    
    [HistoryStatisticsFilter.HistoryStatisticsIds addObject:Id];
    
    return [self SetCallHistoryReadedWithFilter: HistoryStatisticsFilter];
}

- (BOOL) SetAllCallHistoryReaded
{
    return [self SetCallHistoryReadedWithFilter: nil];
}

- (BOOL) CompareHistoryStatisticsIds: (NSString*) Id1 : (NSString*) Id2
{
    std::string cpp_str1 ([Id1 UTF8String], [Id1 lengthOfBytesUsingEncoding:NSUTF8StringEncoding]);
    
    std::string cpp_str2 ([Id2 UTF8String], [Id2 lengthOfBytesUsingEncoding:NSUTF8StringEncoding]);
    
    BOOL Result = (dodicall::ApplicationVoipApi::ComparePeerIds(cpp_str1, cpp_str2) == 0) ? YES : NO;
    
    return Result;
}

#pragma mark CallTransfer

- (BOOL) TransferCall: (NSString *) CallId ToUrl: (NSString *) Url
{
    
    std::string cpp_CallId ([CallId UTF8String], [CallId lengthOfBytesUsingEncoding:NSUTF8StringEncoding]);
    std::string cpp_Url ([Url UTF8String], [Url lengthOfBytesUsingEncoding:NSUTF8StringEncoding]);
    
    bool Res = dodicall::Application::GetInstance().TransferCallToUrl(cpp_CallId, cpp_Url);
    
    return Res ? YES : NO;
}

- (BOOL) ClearSavedPassword
{
    bool Res = dodicall::Application::GetInstance().ClearSavedPassword();
    
    return Res ? YES : NO;
}

- (void) Logout
{
    dodicall::Application::GetInstance().Logout();
}

- (NSString *) GetLibVersion
{
    
    return [self convert_to_obj_c_str: dodicall::Application::GetInstance().GetLibVersion()];
}

- (void) method_for_tests {
    
    

    
}




@end
