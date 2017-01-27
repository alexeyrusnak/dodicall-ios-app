//
//  UserSessionModel.h
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
#import <ReactiveCocoa/ReactiveCocoa.h>

@interface ObjC_ServerAreaModel : NSObject

@property NSNumber *Key;

@property NSString *Title;

@property NSString *AccUrl;

@property NSString *ForgotPasswordUrl;

@property NSString *RegistrationUrl;

@end



@class ObjC_BalanceResult;

@class ObjC_ContactModel;
@class ObjC_BaseResult;



@interface UserSessionManager : NSObject

@property ObjC_BaseResult* LastLoginResult;

@property BOOL IsUserAuthorized;

@property BOOL IsUserAuthorizedAndGuiReady;

@property BOOL IsUserLoggedInAndServersReady;

@property BOOL DeviceSettingsUpdated;

@property BOOL AccountDataUpdated;

@property RACSignal *IsUserAuthorizedSignal;

@property BOOL TryAutologinAttemptsUsed;

@property BOOL IsBalanceAvailable;

@property NSString *BalanceString;

@property NSString *TempLogin;

@property NSString *TempPassword;

@property NSNumber *IsCurrentVerisonActual;

@property NSString *CurrentUsername;

//@property ObjC_BalanceResult *Balance;

@property ObjC_ContactModel *MyProfile;

@property NSMutableArray <ObjC_ServerAreaModel *> *ServerAreas;

@property NSNumber *IsLoginProcessActive;

- (void) GetBalance;

- (void) UpdateBalance;

- (void) GetMyProfile:(void (^)(ObjC_ContactModel *))Callback;

//- (BOOL) IsTestArea;

- (NSString *) GetBalanceInfoUrl;

- (NSString *) GetRegistrationUrl;

- (NSString *) GetForgotPasswordUrl;

- (void) GetAreas;

- (NSString *) GetServerAreaName;

#pragma mark Updates

- (void) StartCheckingUpdates;

- (void) CheckUpdate;

- (void) LogOut;

- (void) ExecuteLoginProcess;

- (void) ExecuteLoginProcess:(BOOL) ShouldRealLogin;

- (BOOL) ExecuteAutologinProcess;

- (void) ExecuteLogoutProcess;

- (void) ExecuteLogoutProcess:(BOOL) ResetPassword;

@end
