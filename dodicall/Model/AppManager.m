//
//  AppManager.m
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

#import "AppManager.h"
#include "TargetConditionals.h"
#import "NSBundle+Language.h"
#import "UiLogger.h"
#import "ContactsManager.h"
#import "ChatsManager.h"
#import "SystemNotificationsManager.h"
#import "CallsManager.h"
#import "AudioManager.h"
#import "UsageHandler.h"
#import "HistoryManager.h"
#import "CallbackManager.h"

static AppManager* AppManagerSingleton = nil;

@interface AppManager ()

@property NSMutableDictionary *CallBacksStats;

@end

@implementation AppManager
{
    BOOL AllInited;
}

@synthesize AppName;
@synthesize AppVersion;
@synthesize AppVersionShort;
@synthesize Device;
@synthesize Core;
@synthesize UserSettingsModel;
@synthesize GlobalApplicationSettingsModel;
@synthesize DeviceSettingsModel;

//@synthesize UiLanguage;
@synthesize UiUserStatus;
@synthesize UiUserTetxStatus;

@synthesize TempCodecs;

+ (instancetype) Manager
{
    return [self app];
}

+ (instancetype) app
{
    
    static dispatch_once_t AppManagerSingletonOnceToken;
    
    dispatch_once(&AppManagerSingletonOnceToken, ^{
        
        AppManagerSingleton = [[AppManager alloc] init];
        
        AppManagerSingleton.AppSerialQueue = dispatch_queue_create("AppSerialQueue", DISPATCH_QUEUE_SERIAL);
        AppManagerSingleton.ManagerScheduler = [[RACTargetQueueScheduler alloc]initWithName:@"AppManagerScheduler" queue:AppManagerSingleton.AppSerialQueue];
        
        AppManagerSingleton.ViewModelQueue = dispatch_queue_create("AppViewModelQueue", DISPATCH_QUEUE_SERIAL);
        AppManagerSingleton.ViewModelScheduler = [[RACTargetQueueScheduler alloc]initWithName:@"AppViewModelScheduler" queue:AppManagerSingleton.ViewModelQueue];
        
    });
    
    [AppManagerSingleton InitAll];
    
    return AppManagerSingleton;
}

- (void) InitAll
{
    
    if(!AllInited)
    {
        AllInited = YES;
        
        self.CallBacksStats = [[NSMutableDictionary alloc] init];
        
        self.IsAppActiveSignal = RACObserve(self, IsAppActive);
        
        self.IsAppActive = [NSNumber numberWithInt:1];
        
        // Core setup
        Core = [Dodicall_Bridge getInstance];
        
        // App directories
        NSString *DocDir = [[NSBundle mainBundle] resourcePath];
        NSString *CachesDir = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES)[0];
        NSString *TempDir = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES)[0];
        
        CachesDir = [CachesDir stringByAppendingString:@"/AppData"];
        TempDir = [TempDir stringByAppendingString:@"/TempData"];
        
        
        if (![[NSFileManager defaultManager] fileExistsAtPath:CachesDir])
            [[NSFileManager defaultManager] createDirectoryAtPath:CachesDir withIntermediateDirectories:NO attributes:nil error:nil];
        
        if (![[NSFileManager defaultManager] fileExistsAtPath:TempDir])
            [[NSFileManager defaultManager] createDirectoryAtPath:TempDir withIntermediateDirectories:NO attributes:nil error:nil];

        
        // Core name and version setup
        AppName = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleDisplayName"];
        AppVersion = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"];
        AppVersionShort = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
        [Core SetupApplicationModel: AppName : AppVersion];
        
        // Core device model setup
        Device = [[DeviceModel alloc] init];
        NSDictionary * DeviceInfo = [Device GetDeviceInfo];
        [Core SetupDeviceModel :
         [DeviceInfo objectForKey:@"Uuid"] :
         [DeviceInfo objectForKey:@"Mobile"] :
         [DeviceInfo objectForKey:@"Platform"] :
         [DeviceInfo objectForKey:@"Model"] :
         [DeviceInfo objectForKey:@"Version"]:
                         DocDir:
                      CachesDir:
                        TempDir
         ];
        
        [UiLogger WriteLogInfo:@"==== Application init ===="];
        [UiLogger WriteLogDebug:[NSString stringWithFormat:@"DocDir: %@",DocDir]];
        [UiLogger WriteLogDebug:[NSString stringWithFormat:@"CachesDir: %@",CachesDir]];
        [UiLogger WriteLogDebug:[NSString stringWithFormat:@"DeviceInfo: %@",[DeviceInfo debugDescription]]];
        
        // Global application settings model
        [self GetGlobalApplicationSettings];
        
        // Global user settings settings model
        [self GetUserSettingsModel:NO];
        
        // Global application settings model
        //DeviceSettingsModel = [Core GetDeviceSettings];
        
        // User session
        self.UserSession = [[UserSessionManager alloc] init];
        
        // Navigation router
        self.NavRouter = [UiNavRouter NavRouter]; //[[UiNavRouter alloc] init];
        
        // App language
        [self SetUiLanguage];
        
        // Set Ui skin
        [self SetTheme:NO];
        
        // Setup Callback function
        [UiLogger WriteLogInfo:@"Setup Callback function"];
        [self.Core SetupCallbackFunction:(ICallback*)self];
        
        //[SystemNotificationsManager SystemNotifications];
        
        //Setup managers
        [AudioManager Manager];
        [SystemNotificationsManager Manager];
        [ContactsManager Manager];
        [ChatsManager Manager];
        [HistoryManager Manager];
        [CallbackManager Manager];
        [UiNotificationsManager Manager];
        [CallsManager Manager];
        
        if([self.UserSession ExecuteAutologinProcess])
        {
            [self.UserSession ExecuteLoginProcess:NO];
            [self.NavRouter ShowContactsTabPage];
            
            if([[UIApplication sharedApplication] applicationState] != UIApplicationStateBackground)
                [self.NavRouter PreloadAllTabs];
            
        }
        else
        {
            [self.NavRouter ShowLoginPage];
        }
    }
    
}

- (void) ApplicaionPause
{
    if(self.Core) {
        //DMC-2011
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [UiLogger WriteLogDebug:@"AppManager: Start Pause"];
            [self.Core Pause];
            [UiLogger WriteLogDebug:@"AppManager: End Pause"];
        });
    }
    
    self.IsAppActive = [NSNumber numberWithInt:0];
}

- (void) ApplicaionResume
{
    if(self.Core) {
        //DMC-2011
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [UiLogger WriteLogDebug:@"AppManager: Start Resume"];
            [self.Core Resume];
            [UiLogger WriteLogDebug:@"AppManager: End Resume"];
        });
    }
    
    self.IsAppActive = [NSNumber numberWithInt:1];
}

- (void) SaveUserSettingsModel
{   dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [UiLogger WriteLogInfo:@"Save user settigs into bridge"];
        [UiLogger WriteLogDebug:[NSString stringWithFormat:@"UserSettingsModel: %@", [CoreHelper UserSettingsModelDescription:UserSettingsModel]]];
        [Core SaveUserSettings:UserSettingsModel];
        [UiLogger WriteLogInfo:@"User settigs saved"];
    });
}

- (void) GetUserSettingsModel
{
    [self GetUserSettingsModel:YES];
}

- (void) GetUserSettingsModel:(BOOL) ShoudGetRealSettings
{
    [UiLogger WriteLogInfo:@"Get user settigs from bridge"];
    
    UserSettingsModel = [Core GetUserSettings:ShoudGetRealSettings];
    
    
    if([UserSettingsModel.GuiLanguage isEqualToString:@""] && GlobalApplicationSettingsModel.DefaultGuiLanguage && ![GlobalApplicationSettingsModel.DefaultGuiLanguage isEqualToString:@""] )
        UserSettingsModel.GuiLanguage = self.GlobalApplicationSettingsModel.DefaultGuiLanguage;
    
    if([UserSettingsModel.GuiThemeName isEqualToString:@""] && GlobalApplicationSettingsModel.DefaultGuiTheme && ![GlobalApplicationSettingsModel.DefaultGuiTheme isEqualToString:@""] )
        UserSettingsModel.GuiThemeName = self.GlobalApplicationSettingsModel.DefaultGuiTheme;

    
    if([UserSettingsModel.GuiLanguage isEqualToString:@""])
    {
        NSString * SystemLanguage = [[[[NSLocale preferredLanguages] objectAtIndex:0] uppercaseString] componentsSeparatedByString:@"-"][0];
        
        if([UiSupportedLanguages containsObject:SystemLanguage])
        {
            
            NSInteger LangIndex = [UiSupportedLanguages indexOfObject: SystemLanguage];
            
            UserSettingsModel.GuiLanguage = [[UiSupportedLanguages objectAtIndex:LangIndex] copy];
            
        }
        else
        {
            UserSettingsModel.GuiLanguage = UiLanguageDefault;
        }
        
        if([SystemLanguage isEqualToString:UiLanguageRu])
            UserSettingsModel.GuiLanguage = UiLanguageRu;
        
        if([SystemLanguage isEqualToString:UiLanguageEn])
            UserSettingsModel.GuiLanguage = UiLanguageEn;
    }
    
    if([UserSettingsModel.GuiThemeName isEqualToString:@""])
        UserSettingsModel.GuiThemeName = UiStyleDefault;
    
    if(!UserSettingsModel.GuiFontSize || UserSettingsModel.GuiFontSize < 11)
        UserSettingsModel.GuiFontSize = 15;
    
    [UiLogger WriteLogDebug:[NSString stringWithFormat:@"UserSettingsModel: %@", [CoreHelper UserSettingsModelDescription:UserSettingsModel]]];
    
}

- (void) UpdateUserSettingsModel
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [UiLogger WriteLogInfo:@"Update user settigs from bridge"];
        
        ObjC_UserSettingsModel *UpdatedUserSettings = [Core GetUserSettings];
        
        
        UserSettingsModel.UserBaseStatus = UpdatedUserSettings.UserBaseStatus;
        
        UserSettingsModel.UserExtendedStatus = UpdatedUserSettings.UserExtendedStatus;
    });
}

- (void) SaveDeviceSettingsModel
{
    
}

- (void) GetDeviceSettingsModel
{
    DeviceSettingsModel = [Core GetDeviceSettings];
}

- (void) SaveGlobalApplicationSettings
{
    
}

- (void) GetGlobalApplicationSettings
{
    [UiLogger WriteLogInfo:@"Get global application settings from bridge"];
    
    GlobalApplicationSettingsModel = [Core GetGlobalApplicationSettings];
    
    if(!GlobalApplicationSettingsModel.LastLogin)
        GlobalApplicationSettingsModel.LastLogin = @"";
    
    if(!GlobalApplicationSettingsModel.LastPassword)
        GlobalApplicationSettingsModel.LastPassword = @"";

    [UiLogger WriteLogDebug:[NSString stringWithFormat:@"GlobalApplicationSettings: %@", [CoreHelper GlobalApplicationSettingsDescription:GlobalApplicationSettingsModel]]];
}

- (void) SetUiLanguage
{
    [UiLogger WriteLogInfo:@"Setup language"];
    
    NSString *_Language = [[AppManager app].UserSettingsModel.GuiLanguage lowercaseString];
    [UiLogger WriteLogDebug:[NSString stringWithFormat:@"GuiLanguage: %@", _Language]];
    
    [[NSUserDefaults standardUserDefaults] setObject:[NSArray arrayWithObjects:_Language, nil] forKey:@"AppleLanguages"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    [NSBundle setLanguage:_Language];
    
    [self.NavRouter Reset];
    
}

- (void) SetTheme
{
    [self SetTheme:YES];
}

- (void) SetTheme: (BOOL) Reset
{
    [UiLogger WriteLogInfo:@"Setup application theme"];
    [UiLogger WriteLogDebug:[NSString stringWithFormat:@"GuiThemeName: %@", [AppManager app].UserSettingsModel.GuiThemeName]];
    
    [NUISettings initWithStylesheet:[AppManager app].UserSettingsModel.GuiThemeName];
    
    if(Reset)
        [self.NavRouter Reset];
}

- (void) Callback : (NSString*) ModelName
                  : (NSMutableArray*) Arr
{
    if(!self.UserSession || !self.UserSession.IsUserAuthorized)
    {
        if(![ModelName isEqualToString:UiCoreCallbackModelNameLoggedIn])
            return;
    }
    
//    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
//        
//        if(![self.CallBacksStats objectForKey:ModelName])
//            [self.CallBacksStats setObject:@0 forKey:ModelName];
//        
//        NSInteger Stats = [[self.CallBacksStats objectForKey:ModelName] integerValue] + 1;
//        [self.CallBacksStats setObject:[NSNumber numberWithInteger:Stats] forKey:ModelName];
//        
//        [UiLogger WriteLogInfo:[NSString stringWithFormat:@"Callback:%@ stats:%ld",ModelName,(long)Stats]];
//        
//        [UsageHandler LogUsage];
//    });
    
    dispatch_async(self.AppSerialQueue, ^{
        
        if(![self.CallBacksStats objectForKey:ModelName])
            [self.CallBacksStats setObject:@0 forKey:ModelName];
        
        NSInteger Stats = [[self.CallBacksStats objectForKey:ModelName] integerValue] + 1;
        [self.CallBacksStats setObject:[NSNumber numberWithInteger:Stats] forKey:ModelName];
        
        [UiLogger WriteLogInfo:[NSString stringWithFormat:@"Callback:%@ stats:%ld",ModelName,(long)Stats]];

        if([ModelName isEqualToString:UiCoreCallbackModelNameContacts])
        {
            [[CallbackManager ManagerForCallBack] HandleContacts];
        }
        
        else if([ModelName isEqualToString:UiCoreCallbackModelNameContactsPresence])
        {
            [[ContactsManager ManagerForCallBack] PerformXmppStatusesChangedEvent: Arr];
        }
        
        else if([ModelName isEqualToString:UiCoreCallbackModelNamePresenceOffline])
        {
            [[ContactsManager ManagerForCallBack] PerformXmppPresenceOfflineEvent];
        }
        
        else if([ModelName isEqualToString:UiCoreCallbackModelNameContactSubscriptions])
        {
            [[CallbackManager ManagerForCallBack] HandleContactsSubscriptions:Arr];
        }
        
        else if([ModelName isEqualToString:UiCoreCallbackModelNameNetworkStateChanged])
        {
            [[UiNotificationsManager NotificationsManager] PerformNetworkStateChangeEvent];
        }
        
        else if([ModelName isEqualToString:UiCoreCallbackModelNameChats])
        {
            [[CallbackManager ManagerForCallBack] HandleChats:Arr];
        }
        
        else if([ModelName isEqualToString:UiCoreCallbackModelNameChatMessages])
        {
            [[CallbackManager ManagerForCallBack] HandleChatMessages:Arr];
        }
        
        else if([ModelName isEqualToString:UiCoreCallbackModelNameUserSettings])
        {
            [self UpdateUserSettingsModel];
        }
        else if([ModelName isEqualToString:UiCoreCallbackModelNameCalls])
        {
            [CallsManager Manager].CallsList = [self.Core GetAllCalls];
            
        }
        else if([ModelName isEqualToString:UiCoreCallbackModelNameHistory])
        {
            [[CallbackManager ManagerForCallBack] HandleHistory:Arr];
            
        }
        else if([ModelName isEqualToString:UiCoreCallbackModelNameLoggedIn])
        {
            [[AppManager app].UserSession setIsUserLoggedInAndServersReady:YES];
            
        }
        else if([ModelName isEqualToString:UiCoreCallbackModelNameDeviceSettingsUpdated])
        {
            [[AppManager app].UserSession setDeviceSettingsUpdated:YES];
            
        }
        else if([ModelName isEqualToString:UiCoreCallbackModelNameAccountDataUpdated])
        {
            [[AppManager app].UserSession setAccountDataUpdated:YES];
            
        }
        else if([ModelName isEqualToString:UiCoreCallbackModelNameLogout])
        {
            [[AppManager app].UserSession ExecuteLogoutProcess:NO];
            
        }
        
        [UsageHandler LogUsage];

        
    });
}

#pragma mark App delegates

- (void) PerformDidRegisterForRemoteNotificationsWithDeviceToken:(NSData *)DevToken
{
    [[SystemNotificationsManager Manager] PerformDidRegisterForRemoteNotificationsWithDeviceToken:DevToken];
}

- (void) PerformDidFailToRegisterForRemoteNotificationsWithError:(NSError *)err
{
    [[SystemNotificationsManager Manager] PerformDidFailToRegisterForRemoteNotificationsWithError:err];
}

- (void) PerformDidReceiveSystemLocalNotfification: (UILocalNotification *) LocalNotfification
{
    [[SystemNotificationsManager SystemNotifications] PerformDidReceiveSystemLocalNotfification: LocalNotfification];
}

- (void) PerformDidReceiveSystemRemoteNotfification: (NSDictionary *) RemoteNotfification
{
    [[SystemNotificationsManager SystemNotifications] PerformDidReceiveSystemRemoteNotfification: (NSDictionary *) RemoteNotfification];
}

- (void) PerformHandleActionOfSystemRemoteNotfificationWithIdentifier:(NSString *) Identifier AndAction: (NSDictionary *) RemoteNotfification withResponseInfo:(NSDictionary *)ResponseInfo completionHandler:(void(^)())CompletionHandler
{
    [[SystemNotificationsManager SystemNotifications] PerformHandleActionOfSystemRemoteNotfificationWithIdentifier:Identifier AndAction:RemoteNotfification withResponseInfo:ResponseInfo completionHandler:CompletionHandler];
}

- (void) PerformHandleActionOfSystemLocalNotfificationWithIdentifier:(NSString *) Identifier AndAction: (UILocalNotification *) LocalNotfification withResponseInfo:(NSDictionary *)ResponseInfo completionHandler:(void(^)())CompletionHandler
{
    [[SystemNotificationsManager SystemNotifications] PerformHandleActionOfSystemLocalNotfificationWithIdentifier:Identifier AndAction:LocalNotfification withResponseInfo:ResponseInfo completionHandler:CompletionHandler];
}

@end
