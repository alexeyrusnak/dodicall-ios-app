//
//  CallsManager.m
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
#import "CallsManager.h"
#import "UiCallsNavRouter.h"
#import "UiLogger.h"
#import "SystemNotificationsManager.h"
#import "UiInCallStatusBar.h"
#import <CoreTelephony/CTCallCenter.h>
#import <AVFoundation/AVAudioSession.h>
#import <AVFoundation/AVAudioPlayer.h>
#include <signal.h>



static CallsManager *CallsManagerSingleton = nil;
static dispatch_once_t CallsManagerSingletonOnceToken;

@interface CallsManager()

@property CTCallCenter *CTCallCenter;
@property NSNumber *HasCTIncomingCall;

@property NSNumber *Active;

@property UIBackgroundTaskIdentifier IncomingCallBgTask;

@end

@implementation CallsManager
{
    BOOL AllInited;
}

+ (instancetype) Manager
{
    
    dispatch_once(&CallsManagerSingletonOnceToken, ^{
        
        CallsManagerSingleton = [[CallsManager alloc] init];
        
    });
    
    [CallsManagerSingleton InitAll];
    
    return CallsManagerSingleton;
}

+ (void) Destroy
{
    if(CallsManagerSingleton)
    {
        CallsManagerSingleton = nil;
        CallsManagerSingletonOnceToken = 0;
    }
};

- (void) SetActive:(BOOL) Active
{
    self.Active = [NSNumber numberWithBool:Active];
}

- (void) InitAll
{
    if(!AllInited)
    {
        AllInited = YES;
        
        self.CallsList = [ObjC_CallsModel new];
        self.ShownCalls = [NSMutableArray new];
        self.ShownCallIds = [NSMutableArray new];
        self.InCallStatusBar = [UiInCallStatusBar new];
        
        [self BindAll];
    }
}

-(void)BindAll {
    
    @weakify(self);
    
    [RACObserve(self, ShownCalls) subscribeNext:^(NSMutableArray *calls) {
        
        @strongify(self);
        
        NSMutableArray *callIds = [NSMutableArray new];
        for(ObjC_CallModel *call in calls) {
            [callIds addObject:call.Id];
        }
        self.ShownCallIds = callIds;
    }];
    
    self.CurrentIncomingCallSignal = RACObserve(self, CurrentIncomingCall);
    
    self.CurrentPausedCallSignal = RACObserve(self, CurrentPausedCall);
    
    [[[RACObserve(self, HasCTCall) ignore:nil] filter:^BOOL(NSNumber *Value) {
        
        return [Value boolValue];
        
    }] subscribeNext:^(id x) {
        
        @strongify(self);
        
        [self PauseCurrentActiveCall];
    }];
    
    [[[AppManager app].IsAppActiveSignal filter:^BOOL(NSNumber *Value) {
        
        return [Value boolValue];
        
    }] subscribeNext:^(id x) {
        
        [self ResumeCurrentPausedCall];
        
    }];
    
    
    [[RACObserve(self, CallsList) deliverOn:[RACScheduler schedulerWithPriority:RACSchedulerPriorityHigh]] subscribeNext:^(ObjC_CallsModel *Calls) {

        for(ObjC_CallModel *call in Calls.SingleCalls) {
            NSUInteger index = [self.ShownCallIds indexOfObject:call.Id];
            if(index == NSNotFound) {
             //Added EarlyMediaState
                if(call.State == CallStateRinging || call.State == CallStateDialing || call.State == CallStateEarlyMedia){
                    if(call.Direction == CallDirectionOutgoing)
                        [CallsManager ShowOutgoingCall:call];
                    else if(call.Direction == CallDirectionIncoming){
                        
                        self.CurrentIncomingCall = call;
                        
                        [CallsManager ShowIncomingCall:call];
                        
                        // Send system local notification
                        [[SystemNotificationsManager SystemNotifications] SendSystemLocalIncomingCallNotificationWithCall:call];
                        
                        // Start long background task for incoming call (DMC-2492)
                        if([UIApplication sharedApplication].applicationState == UIApplicationStateBackground)
                        {
                            if(self.IncomingCallBgTask && self.IncomingCallBgTask != UIBackgroundTaskInvalid)
                            {
                                [UiLogger WriteLogInfo:[NSString stringWithFormat:@"CallsManager: End IncomingCallBgTask, remaining backgronud time: %f", [[UIApplication sharedApplication] backgroundTimeRemaining]]];
                                
                                [[UIApplication sharedApplication] endBackgroundTask:self.IncomingCallBgTask];
                                
                                self.IncomingCallBgTask = UIBackgroundTaskInvalid;
                            }
                            
                            [UiLogger WriteLogInfo:@"CallsManager: Execute IncomingCallBgTask background task"];
                            self.IncomingCallBgTask = [[UIApplication sharedApplication] beginBackgroundTaskWithName:@"IncomingCallBgTask" expirationHandler:^
                                                {
                                                    
                                                    [[UIApplication sharedApplication]endBackgroundTask:self.IncomingCallBgTask];
                                                    
                                                    self.IncomingCallBgTask = UIBackgroundTaskInvalid;
                                                    
                                                }];
                        }
                    }
                }
                else if(call.State == CallStateConversation) {
                    
                    self.CurrentIncomingCall = nil;
                    
                    [CallsManager ShowActiveCall:call];
                    
                    [self SetupCTInteraction];
                }
                
            }
            else {
                
                ObjC_CallModel *oldCall = [self.ShownCalls objectAtIndex:index];
                
                if(oldCall.State!=call.State) {
                    if(call.State == CallStateConversation)
                    {
                        
                        [CallsManager ShowActiveCall:call];
                        
                        [self SetupCTInteraction];
                    }
                }
                
                if(oldCall.Contact != call.Contact){
                    [UiCallsNavRouter UpdateCurrentCallViewWithCall:call];
                    [CallsManager Manager].CurrentCall = call;
                }
                if(oldCall.Encription != call.Encription) {
                    [UiCallsNavRouter UpdateCurrentCallViewWithCall:call];
                    [CallsManager Manager].CurrentCall = call;
                }
                
            }
        }
        
            
        
        
        //Generate Call IDs arrays to perform comparison
        NSMutableArray *singleCallIds = [NSMutableArray new];
        for(ObjC_CallModel *call in Calls.SingleCalls) {
            [singleCallIds addObject:call.Id];
        }
        
        
        
        for(ObjC_CallModel *call in self.ShownCalls) {
            
            if(![singleCallIds containsObject:call.Id]) {
                
                if((call.State == CallStateDialing || call.State == CallStateRinging) && call.Direction == CallDirectionIncoming)
                    [[SystemNotificationsManager SystemNotifications] CancelSystemLocalIncomingCallNotification];
                
                [self RemoveCTCallCenter];
                
                [CallsManager Manager].CurrentCall = nil;
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    [UiCallsNavRouter CloseCurrentCallView];
                });
                
                if(self.IncomingCallBgTask && self.IncomingCallBgTask != UIBackgroundTaskInvalid)
                {
                    [UiLogger WriteLogInfo:[NSString stringWithFormat:@"CallsManager: End IncomingCallBgTask when call ended, remaining backgronud time: %f", [[UIApplication sharedApplication] backgroundTimeRemaining]]];
                    
                    [[UIApplication sharedApplication] endBackgroundTask:self.IncomingCallBgTask];
                    
                    self.IncomingCallBgTask = UIBackgroundTaskInvalid;
                }
            }
        }
        
        self.ShownCalls = Calls.SingleCalls;
    }];
    
    RAC(self.InCallStatusBar, Call) = RACObserve(self, CurrentCall);
    
    [[[[RACSignal combineLatest:@[RACObserve(self, CurrentCall), RACObserve(self, HasCTCall), RACObserve([UiCallsNavRouter NavRouter], IsCallViewVisible)]
            reduce:^id(ObjC_CallModel *Call, NSNumber *HasSystemCall, NSNumber *CallViewVisible){
                return @((Call != nil) && ![HasSystemCall boolValue] && ![CallViewVisible boolValue]);
            }]
            distinctUntilChanged] throttle:0.5]
            subscribeNext:^(NSNumber *ShouldShowInCallStatusBar) {
                @strongify(self);
                if([ShouldShowInCallStatusBar boolValue]) {
                    [self.InCallStatusBar ShowInView:nil WithTapCallback:nil];
                    [self.InCallStatusBar SetShouldChangeStatusBarColorBack:YES];
                }
                
                else
                    [self.InCallStatusBar HideAnimated:YES WithCompletion:nil];
            }];
    
}

- (ObjC_CallModel *) FindCallById: (NSString *) CallId
{
    ObjC_CallModel *ReturnCall;
    
    for(ObjC_CallModel *Call in [self.CallsList.SingleCalls copy])
    {
        if([Call.Id isEqualToString:CallId]) {
            
            ReturnCall = Call;
            
            break;
        }
    }
    
    return ReturnCall;
}

- (ObjC_CallModel *) GetCurrentActiveCall
{
    ObjC_CallModel *ReturnCall;
    
    for(ObjC_CallModel *Call in [self.CallsList.SingleCalls copy])
    {
        if(Call.State == CallStateConversation) {
            ReturnCall = Call;
            break;
        }
    }
    
    return ReturnCall;
}

- (void) TransferCurrentActiveCallToUrl: (NSString *) Url
{
    
    ObjC_CallModel *CurrentCall = [self GetCurrentActiveCall];
    
    if(CurrentCall && CurrentCall.State == CallStateConversation)
    {
        NSString *CurrentCallId = CurrentCall.Id;
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
            
            [[AppManager app].Core TransferCall:CurrentCallId ToUrl:Url];
            
        });
    }
    
}

- (void) TransferCurrentActiveCallToUrl: (NSString *) Url WithCallback: (void(^)(BOOL Success)) Callback
{
    ObjC_CallModel *CurrentCall = [self GetCurrentActiveCall];
    
    if(CurrentCall && CurrentCall.State == CallStateConversation)
    {
        NSString *CurrentCallId = CurrentCall.Id;
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
            
            BOOL Success = [[AppManager app].Core TransferCall:CurrentCallId ToUrl:Url];
            
            
            dispatch_async(dispatch_get_main_queue(), ^{
                Callback(Success);
            });
            
        });
    }
}

+ (void) ShowIncomingCall:(ObjC_CallModel *)call {
    
    [[CallsManager Manager] AddShownCall:call];
    [CallsManager Manager].CurrentCall = call;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [UiCallsNavRouter CreateAndShowIncomingCallViewWithCall:call];
    });
    
}
+ (void) ShowOutgoingCall: (ObjC_CallModel *)call {
    
    [[CallsManager Manager] AddShownCall:call];
    [CallsManager Manager].CurrentCall = call;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [UiCallsNavRouter CreateAndShowOutgoingCallViewWithCall:call];
    });
}

+ (void) ShowActiveCall:(ObjC_CallModel *)call {
    [[CallsManager Manager] AddShownCall:call];
    [CallsManager Manager].CurrentCall = call;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [UiCallsNavRouter CreateAndShowCurrentCallViewWithCall:call];
    });
}


+ (void) StartOutgoingCallToContact: (ObjC_ContactModel *)contact WithCallback:(void (^)(BOOL))Callback {
    
    if([[CallsManager Manager] CurrentCall])
    {
        [UiCallsNavRouter ShowCallStartError];
        Callback(NO);
    }
    else
    {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
            BOOL callStarted = [[AppManager app].Core StartCallToContact:contact :CallOptionsDefault];
            if(callStarted)
                [CallsManager Manager].CallsList = [[AppManager app].Core GetAllCalls];
            
            [UiLogger WriteLogInfo:[NSString stringWithFormat:@"CallsManager: Outgoing Start - %d", callStarted]];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                Callback(callStarted);
            });
            
        });
    }
}

+ (void) StartOutgoingCallToNumber:(NSString *)number WithCallback:(void (^)(BOOL))Callback
{
    if([[CallsManager Manager] CurrentCall])
    {
        [UiCallsNavRouter ShowCallStartError];
        Callback(NO);
    }
    else
    {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
            BOOL callStarted = [[AppManager app].Core StartCallToUrl:number :CallOptionsDefault];
            
            if(callStarted)
                [CallsManager Manager].CallsList = [[AppManager app].Core GetAllCalls];
            
            [UiLogger WriteLogInfo:[NSString stringWithFormat:@"CallsManager: Outgoing Start - %d", callStarted]];
            
            if(Callback)
            {
                dispatch_async(dispatch_get_main_queue(), ^{
                    Callback(callStarted);
                });
                
            }
            
        });
    }
}

+ (void) StartOutgoingCallToContact:(ObjC_ContactModel *)Contact ContactNumber:(ObjC_ContactsContactModel *)Number WithCallback:(void (^)(BOOL))Callback
{
    if([[CallsManager Manager] CurrentCall])
    {
        [UiCallsNavRouter ShowCallStartError];
        Callback(NO);
    }
    else
    {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
            
            BOOL callStarted = [[AppManager app].Core StartCallToContactUrl: Contact : Number : CallOptionsDefault];
            
            if(callStarted)
                [CallsManager Manager].CallsList = [[AppManager app].Core GetAllCalls];
            
            [UiLogger WriteLogInfo:[NSString stringWithFormat:@"CallsManager: Outgoing Start - %d", callStarted]];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                Callback(callStarted);
            });
            
        });
    }
}

-(void) AddShownCall:(ObjC_CallModel *)call {
    NSUInteger index = [self.ShownCallIds indexOfObject:call.Id];
    if(index == NSNotFound)
        [self.ShownCalls addObject:call];
    else
        [self.ShownCalls replaceObjectAtIndex:index withObject:call];
    
}


+ (BOOL) AcceptCall:(NSString *) CallId
{
    return [[AppManager app].Core AcceptCall:CallId :CallOptionsDefault];
}

+ (BOOL) HangupCall:(NSString *) CallId
{
    return [[AppManager app].Core HangupCall:CallId];
}

+ (void) PlayDtmf:(NSString *)Character
{
    const char* cCharacter = [Character cStringUsingEncoding:NSUTF8StringEncoding];
    
    //dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        
        [[AppManager app].Core PlayDtmf:cCharacter[0]];
        
    //});
}

+ (void) StopDtmf
{    
    //dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        
        [[AppManager app].Core StopDtmf];
        
    //});
}




+ (RACSignal *) AcceptCallSignal:(NSString *)CallId {
    return [RACSignal startLazilyWithScheduler:[RACScheduler schedulerWithPriority:RACSchedulerPriorityHigh] block:^(id<RACSubscriber> subscriber) {
        BOOL Result = [[AppManager app].Core AcceptCall:CallId :CallOptionsDefault];
        
        if(Result)
            [subscriber sendCompleted];
        else
            [subscriber sendError:[NSError errorWithDomain:@"Call not answered" code:0 userInfo:nil]];
    }];
}

+ (RACSignal *) DropCallSignal:(NSString *)CallId {
    return [RACSignal startLazilyWithScheduler:[RACScheduler schedulerWithPriority:RACSchedulerPriorityHigh] block:^(id<RACSubscriber> subscriber) {
        BOOL Result = [[AppManager app].Core HangupCall:CallId];
        
        if(Result)
            [subscriber sendCompleted];
        else
            [subscriber sendError:[NSError errorWithDomain:@"Call not dropped" code:0 userInfo:nil]];
    }];
}

#pragma mark Pause And Resume Calls

- (void) PauseCall:(ObjC_CallModel *) Call
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        
        [[AppManager app].Core PauseCall:Call.Id];
        
    });
}

- (void) ResumeCall:(ObjC_CallModel *) Call
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        
        [[AppManager app].Core ResumeCall:Call.Id];
        
    });
}

- (void) PauseCurrentActiveCall
{
    ObjC_CallModel *Call = [self GetCurrentActiveCall];
    
    if(Call)
    {
        [self PauseCall:Call];
    
        [self setCurrentPausedCall:Call];
    }
    
}

- (void) ResumeCurrentPausedCall
{
    if(self.CurrentPausedCall)
    {
        [self ResumeCall:self.CurrentPausedCall];
    }
    
    [self setCurrentPausedCall:nil];
}

- (void) HangupCurrentActiveCall
{
    ObjC_CallModel *Call = [self GetCurrentActiveCall];
    
    if(Call)
    {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
            
            [[AppManager app].Core HangupCall:Call.Id];
            
        });
        
        
    }
}

#pragma mark Core Telephony

- (void) SetupCTInteraction
{
    
    dispatch_async(dispatch_get_main_queue(), ^{
        
        [self RemoveCTCallCenter];
    
        self.CTCallCenter = [[CTCallCenter alloc] init];
        
        @weakify(self);
        
        [self.CTCallCenter setCallEventHandler: ^(CTCall* call) {
            
            @strongify(self);
            
            [self performSelectorOnMainThread:@selector(HandleCTCallInteration:)
                                   withObject:self.CTCallCenter
                                waitUntilDone:YES];
        }];
        
        
    });

    
    
}

-(void) RemoveCTCallCenter
{
    if (self.CTCallCenter != nil)
    {
        self.CTCallCenter.callEventHandler = nil;
    }
    
    self.CTCallCenter = nil;
}

- (void) HandleCTCallInteration: (id) CTCenter {

    
    CTCallCenter* CT = (CTCallCenter*) CTCenter;
    
    if ([CT currentCalls] != nil) {
        
        self.HasCTCall = @YES;
        
    }
    else
    {
        self.HasCTCall = @NO;
    }
}


@end
