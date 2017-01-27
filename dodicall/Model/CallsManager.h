//
//  CallsManager.h
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

@class ObjC_CallsModel;
@class ObjC_CallModel;
@class ObjC_ContactModel;
@class UiInCallStatusBar;

@interface CallsManager : NSObject

@property ObjC_CallsModel *CallsList;

@property NSMutableArray *ShownCalls;
@property NSMutableArray *ShownCallIds;

@property ObjC_CallModel *CurrentIncomingCall;
@property RACSignal *CurrentIncomingCallSignal;

@property ObjC_CallModel *CurrentPausedCall;
@property RACSignal *CurrentPausedCallSignal;

@property ObjC_CallModel *CurrentCall;
@property NSNumber *HasCTCall;
@property UiInCallStatusBar *InCallStatusBar;

+ (instancetype) Manager;
+ (void) Destroy;
- (void) SetActive:(BOOL) Active;

+ (void) StartOutgoingCallToContact: (ObjC_ContactModel *)contact WithCallback:(void (^)(BOOL))Callback;
+ (void) StartOutgoingCallToNumber:(NSString *)number WithCallback:(void (^)(BOOL))Callback;
+ (void) StartOutgoingCallToContact:(ObjC_ContactModel *)Contact ContactNumber:(ObjC_ContactsContactModel *)Number WithCallback:(void (^)(BOOL))Callback;
+ (BOOL) AcceptCall:(NSString *) CallId;
+ (BOOL) HangupCall:(NSString *) CallId;

+ (void) PlayDtmf:(NSString *)Character;
+ (void) StopDtmf;

- (ObjC_CallModel *) FindCallById: (NSString *) CallId;
- (ObjC_CallModel *) GetCurrentActiveCall;

- (void) TransferCurrentActiveCallToUrl: (NSString *) Url;
- (void) TransferCurrentActiveCallToUrl: (NSString *) Url WithCallback: (void(^)(BOOL Success)) Callback;


+ (RACSignal *) AcceptCallSignal:(NSString *)CallId;
+ (RACSignal *) DropCallSignal:(NSString *)CallId;

#pragma mark Pause And Resume Calls

- (void) PauseCall:(ObjC_CallModel *) Call;

- (void) ResumeCall:(ObjC_CallModel *) Call;

- (void) PauseCurrentActiveCall;

- (void) ResumeCurrentPausedCall;

- (void) HangupCurrentActiveCall;


@end
