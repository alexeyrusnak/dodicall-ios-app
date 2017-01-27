//
//  UiLoginViewModel.m
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

#import "UiLoginPageViewModel.h"
#import "UiLogger.h"
#import "AppManager.h"
#import "ContactsManager.h"
#import "ChatsManager.h"
#import "HistoryManager.h"
#import "UiNotificationsManager.h"
#import "SystemNotificationsManager.h"


@interface UiLoginPageViewModel()

@end

@implementation UiLoginPageViewModel

- (instancetype)init {
    
    if (self = [super init]) {
        
        BOOL AutoLogin = [[AppManager app].GlobalApplicationSettingsModel.Autologin boolValue];
        
        NSString *LastLogin = [[[AppManager app] GlobalApplicationSettingsModel] LastLogin];
        NSString *LastPassword = [[[AppManager app] GlobalApplicationSettingsModel] LastPassword];
        
        if(LastLogin && LastLogin.length) {
            self.LoginText = LastLogin;
        }
        
        if(LastPassword && LastPassword.length && AutoLogin) {
            self.PasswordText = LastPassword;
        }
        
        NSString *LastSessionLogin = [[[AppManager app] UserSession] TempLogin];
        NSString *LastSessionPassword = [[[AppManager app] UserSession] TempPassword];
        
        if(LastSessionLogin && LastSessionLogin.length) {
            self.LoginText = LastSessionLogin;
        }
        if(LastSessionPassword && LastSessionPassword.length) {
            self.PasswordText = LastSessionPassword;
        }
        
        self.LastResultErrorText = @"";
        self.IsFormValid = [NSNumber numberWithInt:0];
        self.IsLoginProcessActive = [NSNumber numberWithInt:0];
        self.AppVersionText = [NSString stringWithFormat:NSLocalizedString(@"Title_AppVersion",nil), [AppManager app].AppVersion];
        
        [self BindAll];
    }
    
    return self;
}


- (void) BindAll {
    
    RAC(self, UiLanguageTextValue) = RACObserve([AppManager app].UserSettingsModel, GuiLanguage);
    
    [RACObserve(self, LoginText) subscribeNext:^(NSString *Text) {
        [AppManager app].UserSession.TempLogin = Text;
    }];
    
    [RACObserve(self, PasswordText) subscribeNext:^(NSString *Text) {
        [AppManager app].UserSession.TempPassword = Text;
    }];
    
    @weakify(self);
    
    RAC(self, IsLoginProcessActive) = [[RACObserve([[AppManager app] UserSession], IsLoginProcessActive) ignore:nil] filter:^BOOL(NSNumber *IsActive) {
        @strongify(self);
        return ([IsActive boolValue] != [[self IsLoginProcessActive] boolValue]);
    }];
    
    RACSignal *ValidLoginSignal = [[RACObserve(self, LoginText) map:^id(NSString *text) {
        
        @strongify(self);
        
        return [self CheckIsValidLoginText];
        
    }] distinctUntilChanged];
    
    RACSignal *ValidPasswordSignal = [[RACObserve(self, PasswordText) map:^id(NSString *text) {
        
        @strongify(self);
        
        return [self CheckIsValidPasswordText];
        
    }] distinctUntilChanged];
    
    RAC(self, IsFormValid) = [RACSignal combineLatest:@[ValidLoginSignal, ValidPasswordSignal] reduce:^() {
        
        @strongify(self);
         return [self CheckIsValidForm];
    }];
    
    [[RACSignal combineLatest:@[RACObserve([AppManager app].GlobalApplicationSettingsModel, Area), [RACObserve([AppManager app].UserSession, ServerAreas) deliverOnMainThread]]] subscribeNext:^(id x) {
        
        @strongify(self);
        NSMutableString *AppVersionText = [NSMutableString stringWithString:@""];
        [AppVersionText appendFormat:NSLocalizedString(@"Title_AppVersion",nil), [AppManager app].AppVersionShort];
        
        if([AppManager app].GlobalApplicationSettingsModel.Area != 0) {
            
            AppVersionText = [NSMutableString stringWithFormat:NSLocalizedString(@"Title_AppVersionExtended",nil), [AppManager app].AppVersion, [[AppManager app].Core GetLibVersion], [[AppManager app].UserSession GetServerAreaName]];
            
            //[AppVersionText appendFormat:@" %@", [[AppManager app].UserSession GetServerAreaName]];
        }
        
        self.AppVersionText = AppVersionText;
    }];
    
    [[[RACObserve([[AppManager app] UserSession], LastLoginResult) ignore:nil] deliverOnMainThread]subscribeNext:^(ObjC_BaseResult *LoginResult) {
        
        @strongify(self);
        [self FinishLoginProcessWithResult:LoginResult];
    }];
}


- (void) ExecuteLoginProcess {
    
    [UiLogger WriteLogInfo:@"LoginPageViewModel: Execute login process"];
    
    self.LastResultSuccess = @YES;
    self.LastResultErrorText = @"";
    
    self.IsLoginProcessActive = @1;
    
    [[[AppManager app] UserSession] ExecuteLoginProcess];
}


- (void) FinishLoginProcessWithResult:(ObjC_BaseResult *)Result {
    
    [UiLogger WriteLogInfo:@"LoginPageViewModel: Finish login process"];
    
    self.IsLoginProcessActive = @0;
    
    if([Result.Success boolValue]) {
        
        [UiLogger WriteLogInfo:@"LoginPageViewModel: Login process finished with success"];
        
        self.LastResultSuccess = @YES;
        self.LastResultErrorText = @"";
    }
    
    else {
        
        self.LastResultSuccess = @NO;
        
        switch (Result.ErrorCode) {
            case ResultErrorSystem:
                self.LastResultErrorText = NSLocalizedString(@"ErrorAlert_ServerIsNotAvailable", nil);
                break;
                
            case ResultErrorNoNetwork:
                self.LastResultErrorText = NSLocalizedString(@"ErrorAlert_NoNetwork", nil);
                break;
                
            default:
                self.LastResultErrorText = NSLocalizedString(@"ErrorAlert_InvalidCredentials", nil);
                break;
        }
        
        [UiLogger WriteLogInfo:@"LoginPageViewModel: Login process finished with error"];
        [UiLogger WriteLogDebug:[CoreHelper ResultErrorCodeDescription:Result.ErrorCode]];
    }
}


- (void) ExecuteUiLanguageTapProcess {
    [[[AppManager app] NavRouter] ShowPreferenceLanguageSelectView];
}


- (void) ExecuteRegistrationTapProcess {
     //[[[AppManager app] NavRouter] ShowPreferenceWebView:NSLocalizedString(@"Url_UiInfoRegistration", nil) withTitle:NSLocalizedString(@"Title_UiInfoRegistration", nil)];
    
    [[[AppManager app] NavRouter] OpenUrlInExternalBrowser:[[AppManager app].UserSession GetRegistrationUrl]];
    
}


- (void) ExecuteForgotPasswordProcess {
    
    //[[[AppManager app] NavRouter] ShowPreferenceWebView:NSLocalizedString(@"Url_UiInfoForgotPassword", nil) withTitle:NSLocalizedString(@"Title_UiInfoForgotPassword", nil)];
    
    [[[AppManager app] NavRouter] OpenUrlInExternalBrowser:[[AppManager app].UserSession GetForgotPasswordUrl]];
    
}


- (NSNumber *) CheckIsValidLoginText {
    return (self.LoginText.length > 3)?[NSNumber numberWithInt:1]:[NSNumber numberWithInt:0];
}


- (NSNumber *) CheckIsValidPasswordText {
    return (self.PasswordText.length > 3)?[NSNumber numberWithInt:1]:[NSNumber numberWithInt:0];
}


- (NSNumber *) CheckIsValidForm {
    return ([[self CheckIsValidLoginText] integerValue] > 0 && [[self CheckIsValidPasswordText] integerValue] > 0)?[NSNumber numberWithInt:1]:[NSNumber numberWithInt:0];
}


//- (void) ExecuteAutologinProcess {
//    
//    [UiLogger WriteLogInfo:@"LoginPageViewModel: Check autologin"];
//    
//    if(![self.IsFormValid boolValue] || [self.IsLoginProcessActive boolValue]) {
//        return;
//    }
//    
//    self.IsLoginProcessActive = @1;
//    
//    [[[AppManager Manager] UserSession] ExecuteAutologinProcess];
//}


@end
