//
//  UserSessionModel.m
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

#import "UserSessionManager.h"
#import "AppManager.h"
#import "UiLogger.h"
#import "UiCallsNavRouter.h"

#import "ContactsManager.h"
#import "ChatsManager.h"
#import "HistoryManager.h"
#import "SystemNotificationsManager.h"
#import "CallsManager.h"
#import "AudioManager.h"
#import "UiNotificationsManager.h"
#import "CallbackManager.h"



//TODO  //NSURL *AppStoreURL = [NSURL URLWithString:[NSString stringWithFormat:@"http://itunes.apple.com/lookup?bundleId=%@", AppID]];
//#define AppStoreLookupURL @"https://peaceful-bayou-36807.herokuapp.com/json"
#define AppStoreLookupURL @"https://itunes.apple.com/lookup?bundleId=com.dodidone.dodicall2"
#define AppStoreAppUrl @"itms-apps://itunes.apple.com/us/app/dodicall/id1141482068"


#define NoUpdateUsers @[@"alexei.rusnak@it-grad.ru"]

@implementation ObjC_ServerAreaModel
@end

@interface UserSessionManager ()

@property UIBackgroundTaskIdentifier BGLoginTask;


@end

@implementation UserSessionManager

//@synthesize IsUserAuthorized;

- (instancetype)init
{
    self = [super init];
    if (self) {
        
        self.IsUserAuthorized = NO;
        
        self.IsUserAuthorizedSignal = RACObserve(self, IsUserAuthorizedSignal);
        
        self.ServerAreas = [[NSMutableArray alloc] init];
        
        self.IsCurrentVerisonActual = @(YES);
        
        [self GetAreas];
        
        [self BindAll];
        
    }
    return self;
}

- (void) BindAll {
    @weakify(self);
    
    
    RACSignal *ContactUpdateSignal =
    [[RACObserve([ContactsManager Manager], ContactUpdate)
        filter:^BOOL(ContactUpdateSignalObject *Update) {
            @strongify(self);
            return (Update.State == ContactUpdatingStateUpdated) && [Update.Contact.DodicallId isEqualToString:self.MyProfile.DodicallId];
        }]
        map:^id(ContactUpdateSignalObject *Update) {
            return Update.Contact;
        }];

    RAC(self, MyProfile) = ContactUpdateSignal;
    
    RAC(self.MyProfile, AvatarPath) = [[ContactsManager Manager] AvatarSignalForContactUpdate:RACObserve(self, MyProfile) WithDoNextBlock:^(NSString *Path) {
        self.MyProfile.AvatarPath = Path;
    }];
    
    [[RACObserve(self, IsUserLoggedInAndServersReady) filter:^BOOL(id value) {
        return [value boolValue];
    }] subscribeNext:^(id x) {
        @strongify(self);
        [self GetBalance];
        [self GetMyProfile:nil];
        [[AppManager app] GetDeviceSettingsModel];
    }];
    
    [[RACObserve(self, DeviceSettingsUpdated) filter:^BOOL(id value) {
        return [value boolValue];
    }] subscribeNext:^(id x) {
        [[AppManager app] GetDeviceSettingsModel];
    }];
}


- (void) GetBalance
{
    [UiLogger WriteLogInfo:@"UserSessionModel:GetBalance"];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        
        ObjC_BalanceResult *Balance = [[AppManager app].Core GetBalance];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            
            NSString * BalanceString;
            
            if(Balance.Success)
            {
                
                if([Balance.HasBalance boolValue])
                {
                    self.IsBalanceAvailable = YES;
                    
                    NSString *Currency;
                    
                    switch (Balance.BalanceCurrency) {
                        case CurrencyEur:
                            Currency = NSLocalizedString(@"Title_CurrencyEur", nil);
                            break;
                        case CurrencyUsd:
                            Currency = NSLocalizedString(@"Title_CurrencyUsd", nil);
                            break;
                            
                        default:
                            Currency = NSLocalizedString(@"Title_CurrencyRuble", nil);
                            break;
                    }
                    
                    BalanceString = [NSString stringWithFormat:@"%0.02f %@", Balance.BalanceValue, Currency];
                }
                else
                {
                    self.IsBalanceAvailable = NO;
                    
                    BalanceString = NSLocalizedString(@"Title_NotAvailable", nil);
                }
                
                
            }
            else
            {
                BalanceString = NSLocalizedString(@"Title_NotAvailable", nil);
            }
            
            [self setBalanceString:BalanceString];
            
            [UiLogger WriteLogDebug:[NSString stringWithFormat:@"UserSessionModel:GetBalance %@", BalanceString]];
            
            
        });
    });
}

- (void) UpdateBalance
{
    [UiLogger WriteLogInfo:@"UserSessionModel:UpdateBalance"];
    
    if(self.IsBalanceAvailable)
    {
        [self GetBalance];
    }
}

- (void) GetMyProfile:(void (^)(ObjC_ContactModel *))Callback
{
    if(self.MyProfile && self.MyProfile.DodicallId.length > 0)
    {
        if(Callback)
        {
            Callback(self.MyProfile);
        }
        
        return;
    }
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        [UiLogger WriteLogInfo:@"UserSessionModel:GetMyProfile"];
        
        self.MyProfile = [[AppManager app].Core GetAccountData];
        
        [UiLogger WriteLogDebug:[NSString stringWithFormat:@"UserSessionModel:GetMyProfile: %@", [CoreHelper ContactModelDescription:self.MyProfile]]];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            
            if(Callback)
            {
                Callback(self.MyProfile);
            }
            
        });
    });
}

/*
- (BOOL) IsTestArea
{
    return [[AppManager app].GlobalApplicationSettingsModel Area] == ServerAreaTest ? YES : NO;
}
 */

- (NSString *) GetAccUrl
{
    //[self GetAreas];
    
    NSInteger Index = [[AppManager app].GlobalApplicationSettingsModel Area];
    
    NSString * Url = NSLocalizedString(@"Url_UiInfoBalance", nil);
    
    if(self.ServerAreas && Index < [self.ServerAreas count])
    {
        Url = [((ObjC_ServerAreaModel*)self.ServerAreas[Index]).AccUrl copy];
    }
    
    return Url;
}

- (NSString *) GetServerAreaName
{
    NSString *Title = @"";
    
    //[self GetAreas];
    
    NSInteger Index = [[AppManager app].GlobalApplicationSettingsModel Area];
    
    if(self.ServerAreas && Index < [self.ServerAreas count])
    {
        Title = [((ObjC_ServerAreaModel*)self.ServerAreas[Index]).Title copy];
    }
    
    return Title;
}

- (NSString *) GetBalanceInfoUrl
{
    
    NSString * Url = [self GetAccUrl];
    
    Url = [Url stringByAppendingString:NSLocalizedString(@"Url_UiInfoBalanceRelative", nil)];
    
    return Url;
    
    //return [self IsTestArea] ? NSLocalizedString(@"Url_UiInfoBalanceTestArea", nil) : NSLocalizedString(@"Url_UiInfoBalance", nil);
}

- (NSString *) GetRegistrationUrl
{
    NSString * Url = [self GetAccUrl];
    
    NSInteger index = [[AppManager app].GlobalApplicationSettingsModel Area];
    
    if(self.ServerAreas && index < [self.ServerAreas count]) {
        Url = [Url stringByAppendingString:((ObjC_ServerAreaModel *)[self.ServerAreas objectAtIndex:index]).RegistrationUrl];
    }
    
    Url = [Url stringByReplacingOccurrencesOfString:@"${LANG}" withString:NSLocalizedString(@"Lang_code", nil)];
    Url = [Url stringByReplacingOccurrencesOfString:@"${COUNTRY}" withString:NSLocalizedString(@"Country_code", nil)];
    
    
    return Url;
}

- (NSString *) GetForgotPasswordUrl
{
    
    NSString * Url = [self GetAccUrl];
    
    NSInteger index = [[AppManager app].GlobalApplicationSettingsModel Area];
    
    if(self.ServerAreas && index < [self.ServerAreas count]) {
        Url = [Url stringByAppendingString:((ObjC_ServerAreaModel *)[self.ServerAreas objectAtIndex:index]).ForgotPasswordUrl];
    }
    
    Url = [Url stringByReplacingOccurrencesOfString:@"${LANG}" withString:NSLocalizedString(@"Lang_code", nil)];
    Url = [Url stringByReplacingOccurrencesOfString:@"${COUNTRY}" withString:NSLocalizedString(@"Country_code", nil)];
    
    
    return Url;
}

- (void) GetAreas
{
    
    /*
    if([self.ServerAreas count] > 0)
        return;
     */
     
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        NSMutableArray <ObjC_AreaInfo *> *ServerAreas = [[AppManager app].Core RetrieveAreas];
        
        
        dispatch_async(dispatch_get_main_queue(), ^{
            
            NSMutableArray <ObjC_ServerAreaModel *> *Areas = [[NSMutableArray alloc] init];
            
            for(NSInteger i = 0; i < [ServerAreas count]; i++)
            {
                ObjC_AreaInfo *AreaInfo = ServerAreas[i];
                
                if(AreaInfo)
                {
                    ObjC_ServerAreaModel *Area = [[ObjC_ServerAreaModel alloc] init];
                    
                    Area.Key = [NSNumber numberWithInteger:i];
                    
                    Area.Title = [[AppManager app].UserSettingsModel.GuiLanguage isEqualToString:UiLanguageRu] ? [AreaInfo.NameRu copy] : [AreaInfo.NameEn copy];
                    
                    Area.AccUrl = [AreaInfo.AccUrl copy];
                    
                    Area.RegistrationUrl = [AreaInfo.Reg copy];
                    Area.ForgotPasswordUrl = [AreaInfo.ForgotPwd copy];
                    
                    [Areas addObject:Area];
                }
            }
            
            self.ServerAreas = Areas;
            
        });
    });
}

#pragma mark Updates

- (void) StartCheckingUpdates {
    
    if([NoUpdateUsers containsObject:self.CurrentUsername])
        return;
    
    //Manually check update
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
       [self CheckUpdate];
    });
    
    //Create signal for periodical checking AppStore version (every hour)
    //Save version to NSUSerDefaults and update local flag if appropriate
    RACSignal *CheckSignal = [RACSignal interval:3600 onScheduler:[RACScheduler schedulerWithPriority:RACSchedulerPriorityLow]];
    
    @weakify(self);
    [[[CheckSignal
        takeUntil:[[RACObserve(self, IsCurrentVerisonActual)
                    ignore:nil]
                    filter:^BOOL(NSNumber *Actual) {
                        return ![Actual boolValue];
                    }]]
        deliverOn:[RACScheduler schedulerWithPriority:RACSchedulerPriorityLow]]
        subscribeNext:^(id x) {
            @strongify(self);
            [self CheckUpdate];
        }];
    
    
    //If current version is too old, show alert
    [[[[RACObserve(self, IsCurrentVerisonActual)
        ignore:nil]
        filter:^BOOL(NSNumber *Actual) {
            return ![Actual boolValue] && ([UiCallsNavRouter NavRouter].CurrentCallView == nil) && ([UiNavRouter NavRouter].UpdateAlertView == nil);
        }]
        deliverOnMainThread]
        subscribeNext:^(id x) {
            
            __block void (^AlertAction)();
            
            AlertAction = ^void() {
                [[UIApplication sharedApplication] openURL:[NSURL URLWithString:AppStoreAppUrl]];
                [[UiNavRouter NavRouter] ShowVersionAlertWithAction:AlertAction];
            };
            
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [[UiNavRouter NavRouter] ShowVersionAlertWithAction:AlertAction];
            });
        }];
}

- (void) CheckUpdate {
    
    if([NoUpdateUsers containsObject:self.CurrentUsername])
        return;
    
    //Get local app version
    NSDictionary *InfoDictionary = [[NSBundle mainBundle] infoDictionary];
    
    //Get AppStore version from NSUserDefaults, if it was saved during last run or periodical check
    NSString *UserDefaultsVersion = [[NSUserDefaults standardUserDefaults] stringForKey:@"LastAppStoreVersion"];
    
    //Compare `first` and `second` digits
    self.IsCurrentVerisonActual = @([self IsVersionActualWithNew:UserDefaultsVersion]);
    
    if(![self.IsCurrentVerisonActual boolValue])
        return;
    
    NSString *AppID = InfoDictionary[@"CFBundleIdentifier"];
    
    //TODO: Switch to real apple url
    //Get AppStore version
    //NSURL *AppStoreURL = [NSURL URLWithString:[NSString stringWithFormat:@"http://itunes.apple.com/lookup?bundleId=%@", AppID]];
    NSURL *AppStoreURL = [NSURL URLWithString:[NSString stringWithFormat:AppStoreLookupURL]];
    NSData *AppStoreData = [NSData dataWithContentsOfURL:AppStoreURL];
    
    if(AppStoreData) {
        
        NSDictionary *AppStoreDict = [NSJSONSerialization JSONObjectWithData:AppStoreData options:0 error:nil];
        
        if (AppStoreDict && AppStoreDict[@"resultCount"] && [AppStoreDict[@"resultCount"] integerValue] == 1){
            
            NSString *AppStoreVersion = AppStoreDict[@"results"][0][@"version"];
            //Save AppStore version to NSUserDefaults
            if(AppStoreVersion && AppStoreVersion.length>0)
                [[NSUserDefaults standardUserDefaults] setObject:AppStoreVersion forKey:@"LastAppStoreVersion"];
            
            //Compare `first` and `second` digits
            self.IsCurrentVerisonActual = @([self IsVersionActualWithNew:AppStoreVersion]);
            
        }
    }
    
}

- (BOOL) IsVersionActualWithNew:(NSString *)NewVersion {
    NSDictionary *InfoDictionary = [[NSBundle mainBundle] infoDictionary];
    NSString *CurrentVersion = InfoDictionary[@"CFBundleShortVersionString"];
    
    if(NewVersion && NewVersion.length>0 && CurrentVersion && CurrentVersion.length > 0) {
    
        NSString *FirstNewDigits = [NewVersion componentsSeparatedByString:@"."][0];
        NSString *FirstCurrentDigit = [CurrentVersion componentsSeparatedByString:@"."][0];
        
        if([FirstNewDigits integerValue] && [FirstCurrentDigit integerValue] && [FirstCurrentDigit integerValue] < [FirstNewDigits integerValue]) {
            return NO;
        }
        
        NSString *SecondNewDigits = [NewVersion componentsSeparatedByString:@"."][1];
        NSString *SecondCurrentDigit = [CurrentVersion componentsSeparatedByString:@"."][1];
        
        if([SecondNewDigits integerValue] && [SecondCurrentDigit integerValue] && [SecondCurrentDigit integerValue] < [SecondNewDigits integerValue]) {
            return NO;
        }
    }
    return YES;
}

- (void) LogOut
{
    [[AppManager app].Core ClearSavedPassword];
    
    exit(0);
}

-(void) ExecuteLoginProcess
{
    [self ExecuteLoginProcess:YES];
}

-(void) ExecuteLoginProcess:(BOOL) ShouldRealLogin
{
    
    dispatch_queue_t ExecuteLoginProcessQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0);
    
    if([[UIApplication sharedApplication] applicationState] == UIApplicationStateBackground)
    {
        if(self.BGLoginTask && self.BGLoginTask != UIBackgroundTaskInvalid)
        {
            [UiLogger WriteLogInfo:[NSString stringWithFormat:@"UserSessionManager: End login background task, remaining backgronud time: %f", [[UIApplication sharedApplication] backgroundTimeRemaining]]];
            
            [[UIApplication sharedApplication] endBackgroundTask:self.BGLoginTask];
            
            self.BGLoginTask = UIBackgroundTaskInvalid;
        }
        
        [UiLogger WriteLogInfo:@"UserSessionManager: Execute login background task"];
        self.BGLoginTask = [[UIApplication sharedApplication] beginBackgroundTaskWithName:@"LoginTask" expirationHandler:^
                            {
                                
                                [[UIApplication sharedApplication]endBackgroundTask:self.BGLoginTask];
                                
                                self.BGLoginTask = UIBackgroundTaskInvalid;
                                
                            }];
        
        ExecuteLoginProcessQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0);
        
    }
    
    
    dispatch_async(ExecuteLoginProcessQueue, ^{
        
        [UiLogger WriteLogInfo:@"UserSessionManager: Start login process"];
        
        
        self.IsLoginProcessActive = @1;
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if([[[AppManager app] NavRouter] IsCurrentViewLogin])
                [[[AppManager app] NavRouter] ShowPageProcess];
        });
        
        BOOL LoginSuccess;
        ObjC_BaseResult *LoginResult;
        
        if(ShouldRealLogin)
        {
            NSString *Login = self.TempLogin;
            NSString *Password = self.TempPassword;
            NSInteger Area = [[AppManager app].GlobalApplicationSettingsModel Area];
    
        
            LoginResult = [[AppManager app].Core Login:Login:Password:Area];
            
            LoginSuccess = [[LoginResult Success] boolValue];
            
            if(LoginSuccess)
            {
                self.CurrentUsername = Login;
            }
            
            
        }
        else
        {
            LoginSuccess = YES;
        }
        
        
        
        if(LoginSuccess) {
            
            self.IsUserAuthorized = YES;
            
            //Setup managers
            
            [[AudioManager Manager] SetActive:YES];
            [[UiNotificationsManager Manager] SetActive:YES];
            
            [[ContactsManager Manager] SetActive:YES];
            [[ContactsManager Manager] GetAllContacts];
            
            [[SystemNotificationsManager Manager] SetActive:YES];
            [[SystemNotificationsManager Manager] SetupSystemNotificationsSettings];
            [[SystemNotificationsManager Manager] RegisterForSystemNotifications];
            
            [[ContactsManager Manager] StartCachingPhoneBookContacts];
            
            [[ChatsManager Manager] SetActive:YES];
            [[ChatsManager Manager] GetAllChats];
            
            [[HistoryManager Manager] SetActive:YES];
            [[HistoryManager Manager] LoadHistoryStatisticsList];
            
            [[CallbackManager Manager] SetActive:YES];
            [[CallsManager Manager] SetActive:YES];
            
            //[self GetBalance];
            //[self GetMyProfile:nil];
            self.TempLogin = @"";
            self.TempPassword = @"";
            
            // Get user settings and save language
            NSString* Language = [AppManager app].UserSettingsModel.GuiLanguage;
            [[AppManager app] GetUserSettingsModel];
            [AppManager app].UserSettingsModel.GuiLanguage = Language;
            [[AppManager app] SaveUserSettingsModel];
            
            
            // Set Ui theme
            [[AppManager app] SetTheme:NO];
            //[[AppManager app] GetDeviceSettingsModel];
            [[AppManager app] GetGlobalApplicationSettings];
            
            @weakify(self);
            
            dispatch_async(dispatch_get_main_queue(), ^{
                
                @strongify(self);
                
                [[[AppManager app] NavRouter] HidePageProcess];
                
                if(self.IsUserAuthorized)
                {
                    if([[[AppManager app] NavRouter] IsCurrentViewLogin])
                    [[[AppManager app] NavRouter] ShowContactsTabPage];
                
                    self.IsUserAuthorizedAndGuiReady = YES;
                    
                    if([[UIApplication sharedApplication] applicationState] != UIApplicationStateBackground)
                        [[[AppManager app] NavRouter] PreloadAllTabs];
                }
                
                
                
            });
            
            [self StartCheckingUpdates];
            
//            if(self.BGLoginTask && self.BGLoginTask != UIBackgroundTaskInvalid)
//            {
//                RACSignal *ContactsManagerReady = [[[[ContactsManager Manager].ContactsListStateSignal filter:^BOOL(NSNumber *State) {
//                    
//                    return [State integerValue] == ContactsListLoadingStateFinishedSuccess || [State integerValue] == ContactsListLoadingStateUpdated || [State integerValue] == ContactsListLoadingStateFinishedFail;
//                    
//                }] deliverOn:[ContactsManager Manager].ViewModelScheduler] take:1];
//                
//                RACSignal *ChatsManagerReady =  [[[[ChatsManager Manager].ChatsListStateSignal filter:^BOOL(NSNumber *State) {
//                    
//                    return ([State integerValue] == ChatsListLoadingStateFinishedSuccess || [State integerValue] == ChatsListLoadingStateUpdated || [State integerValue] == ChatsListLoadingStateFinishedFail);
//                    
//                }] deliverOn:[ChatsManager Manager].ViewModelScheduler] take:1];
//                
//                
//                RACSignal *HistoryManagerReady =  [[[[HistoryManager Manager].HistoryStatisticsListUpdatingStateSignal filter:^BOOL(NSNumber *State) {
//                    
//                    return ([State integerValue] == HistoryStatisticsListUpdatingReady || [State integerValue] == HistoryStatisticsListUpdatingStateUpdated || [State integerValue] == HistoryStatisticsListUpdatingFailed);
//                    
//                }] deliverOn:[HistoryManager Manager].ViewModelScheduler] take:1];
//                
//                
//                [[[[[RACSignal combineLatest:@[ContactsManagerReady, ChatsManagerReady, HistoryManagerReady]] ignore:nil] deliverOn:[ChatsManager Manager].ViewModelScheduler] take:1] subscribeNext:^(id x) {
//                    
//                    if(self.BGLoginTask && self.BGLoginTask != UIBackgroundTaskInvalid)
//                    {
//                        [UiLogger WriteLogInfo:[NSString stringWithFormat:@"UserSessionManager: End login background task, remaining backgronud time: %f", [[UIApplication sharedApplication] backgroundTimeRemaining]]];
//                        
//                        [[UIApplication sharedApplication]endBackgroundTask:self.BGLoginTask];
//                        
//                        self.BGLoginTask = UIBackgroundTaskInvalid;
//                    }
//                }];
//            }
            
        }
        else
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                
                [[[AppManager app] NavRouter] HidePageProcess];
                
                if(![[[AppManager app] NavRouter] IsCurrentViewLogin])
                    [self ExecuteLogoutProcess];
                
            });
            
            if(self.BGLoginTask && self.BGLoginTask != UIBackgroundTaskInvalid)
            {
                [UiLogger WriteLogInfo:[NSString stringWithFormat:@"UserSessionManager: End login background task, remaining backgronud time: %f", [[UIApplication sharedApplication] backgroundTimeRemaining]]];
                
                [[UIApplication sharedApplication]endBackgroundTask:self.BGLoginTask];
                
                self.BGLoginTask = UIBackgroundTaskInvalid;
            }
            
        }
        
        if(ShouldRealLogin)
            self.LastLoginResult = LoginResult;
        
        self.IsLoginProcessActive = @0;

        
        [UiLogger WriteLogInfo:@"UserSessionManager: End login process"];
    });
    
}

- (BOOL) ExecuteAutologinProcess
{
    
    [UiLogger WriteLogInfo:@"UserSessionMager: Check autologin"];
    
    return [[AppManager app].Core TryAutoLogin];
    
    /*
    if(![[[[AppManager app] GlobalApplicationSettingsModel] Autologin] boolValue]) {
        return NO;
    }
    
    NSString *LastLogin = [[[AppManager app] GlobalApplicationSettingsModel] LastLogin];
    NSString *LastPassword = [[[AppManager app] GlobalApplicationSettingsModel] LastPassword];
    
    if(LastLogin && LastLogin.length) {
        self.TempLogin = LastLogin;
    }
    
    if(LastPassword && LastPassword.length) {
        self.TempPassword = LastPassword;
    }
 
    if(self.TryAutologinAttemptsUsed)
        return NO;
    
    [AppManager app].UserSession.TryAutologinAttemptsUsed = YES;
    
    if(!self.TempPassword.length || !self.TempLogin.length)
        return NO;
    
    [UiLogger WriteLogInfo:@"UserSessionMager: Execute autologin"];  
    
    //[self ExecuteLoginProcess];
    
    return YES;
     */
}

- (void) ExecuteLogoutProcess
{
    [self ExecuteLogoutProcess:YES];
}

- (void) ExecuteLogoutProcess:(BOOL) ShouldRealLogout
{
    [UiLogger WriteLogInfo:@"UserSessionMager: Execute logout process"];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        
        //TODO: proper logout with BL
        
        [SystemNotificationsManager Manager].PushToken = nil;
        //[SystemNotificationsManager Manager].VoipPushToken = nil; DMC-5592
        
        [UiNotificationsManager Manager].AppIconBadgeCounter = [NSNumber numberWithInt:0];
        [UIApplication sharedApplication].applicationIconBadgeNumber = 0;
        
        if(ShouldRealLogout)
        {
            [[AppManager app].Core Logout];
            [[AppManager app].Core ClearSavedPassword];
        }
        
        [[AppManager app] GetGlobalApplicationSettings];
        
        self.IsUserAuthorized = NO;
        self.IsUserAuthorizedAndGuiReady = NO;
        self.IsUserLoggedInAndServersReady = NO;
        self.DeviceSettingsUpdated = NO;
        self.AccountDataUpdated = NO;
        self.TempPassword = nil;
        self.MyProfile = nil;
        self.IsBalanceAvailable = NO;
        
        
        [[CallbackManager Manager] SetActive:NO];
        [[AudioManager Manager] SetActive:NO];
        [[CallsManager Manager] SetActive:NO];
        [[ChatsManager Manager] SetActive:NO];
        [[HistoryManager Manager] SetActive:NO];
        [[ContactsManager Manager] SetActive:NO];
        [[SystemNotificationsManager Manager] SetActive:NO];
        [[UiNotificationsManager Manager] SetActive:NO];
        
        [[[AppManager app] NavRouter] Reset];
        [[[AppManager app] NavRouter] ShowLoginPage];
        
    });
    
}



@end
