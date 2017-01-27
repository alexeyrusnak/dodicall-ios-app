//
//  AppManager.h
//  dodicall
//
//  Copyright (C) 2016, Telco Cloud Trading & Logistic Ltd
//
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

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import <AudioToolbox/AudioToolbox.h>

#import "NSStringHelper.h"

#import "Dodicall_Bridge.h"
#import "Dodicall_Bridge_Plus_Includes.h"
#import "Dodicall_Bridge+Network.h"

#import "DeviceModel.h"
#import "UserSessionManager.h"
#import "UiNavRouter.h"

#import <NUI/NUISettings.h>
#import <UICKeyChainStore/UICKeyChainStore.h>



#define UiStyleDefault          @"Default"
#define UiStyleLight            @"Light"
#define UiStyleDark             @"Dark"
#define UiStyleBright           @"Bright"
typedef NSString*               UiStyle;

#define UiLanguageDefault       @"EN"
#define UiLanguageRu            @"RU"
#define UiLanguageEn            @"EN"
#define UiLanguageTr            @"TR"
typedef NSString*               UiLanguage;

#define UiSupportedLanguages    @[UiLanguageRu,UiLanguageEn,UiLanguageTr]

#define UiCoreCallbackModelNameContacts                 @"Contacts"
#define UiCoreCallbackModelNameContactsPresence         @"ContactsPresence"
#define UiCoreCallbackModelNamePresenceOffline          @"PresenceOffline"
#define UiCoreCallbackModelNameContactSubscriptions     @"ContactSubscriptions"
#define UiCoreCallbackModelNameNetworkStateChanged      @"NetworkStateChanged"
#define UiCoreCallbackModelNameChats                    @"Chats"
#define UiCoreCallbackModelNameChatMessages             @"ChatMessages"
#define UiCoreCallbackModelNameUserSettings             @"UserSettings"
#define UiCoreCallbackModelNameCalls                    @"Calls"
#define UiCoreCallbackModelNameHistory                  @"History"
#define UiCoreCallbackModelNameLogout                   @"Logout"
#define UiCoreCallbackModelNameLoggedIn                 @"LoggedIn"
#define UiCoreCallbackModelNameDeviceSettingsUpdated    @"DeviceSettingsUpdated"
#define UiCoreCallbackModelNameAccountDataUpdated       @"AccountDataUpdated"
typedef NSString*                                       UiCoreCallbackModelName;

#define PushDeviceTokenKeychainKey @"PushToken"
#define VOiPPushDeviceTokenKeychainKey @"VoIPToken"


@class UiNavRouter;

@interface AppManager : NSObject <Bridge_App_Callback>

@property dispatch_queue_t AppSerialQueue;
@property RACTargetQueueScheduler *ManagerScheduler;

@property dispatch_queue_t ViewModelQueue;
@property RACTargetQueueScheduler *ViewModelScheduler;

+ (instancetype) Manager;
+ (instancetype) app;

@property NSString *AppName;
@property NSString *AppVersion;
@property NSString *AppVersionShort;


@property NSNumber *IsAppActive;
@property RACSignal *IsAppActiveSignal;

@property DeviceModel *Device;
@property UserSessionManager *UserSession;

@property Dodicall_Bridge * Core;
@property ObjC_UserSettingsModel *UserSettingsModel;
@property ObjC_GlobalApplicationSettingsModel *GlobalApplicationSettingsModel;
@property ObjC_DeviceSettingsModel *DeviceSettingsModel;

@property UiNavRouter *NavRouter;

//@property NSString *UiLanguage;

@property NSString *UiUserStatus;

@property NSString *UiUserTetxStatus;

@property NSMutableArray *TempCodecs;

- (void) ApplicaionPause;

- (void) ApplicaionResume;

- (void) SaveUserSettingsModel;

- (void) GetUserSettingsModel;

- (void) UpdateUserSettingsModel;

- (void) SaveDeviceSettingsModel;

- (void) GetDeviceSettingsModel;

- (void) SaveGlobalApplicationSettings;

- (void) GetGlobalApplicationSettings;

- (void) SetUiLanguage;

- (void) SetTheme;

- (void) SetTheme: (BOOL) Reset;

- (void) PerformDidRegisterForRemoteNotificationsWithDeviceToken:(NSData *)DevToken;

- (void) PerformDidFailToRegisterForRemoteNotificationsWithError:(NSError *)err;

- (void) PerformDidReceiveSystemLocalNotfification: (UILocalNotification *) LocalNotfification;

- (void) PerformDidReceiveSystemRemoteNotfification: (NSDictionary *) RemoteNotfification;

- (void) PerformHandleActionOfSystemRemoteNotfificationWithIdentifier:(NSString *) Identifier AndAction: (NSDictionary *) RemoteNotfification withResponseInfo:(NSDictionary *)ResponseInfo completionHandler:(void(^)())CompletionHandler;

- (void) PerformHandleActionOfSystemLocalNotfificationWithIdentifier:(NSString *) Identifier AndAction: (UILocalNotification *) LocalNotfification withResponseInfo:(NSDictionary *)ResponseInfo completionHandler:(void(^)())CompletionHandler;

@end
