//
//  SystemNotificationsManager.m
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

#import "SystemNotificationsManager.h"
#import "UiLogger.h"
#import "CoreHelper.h"
#import "AppManager.h"
#import "UiChatsTabNavRouter.h"
//#import "ObjC_CallsModel.h"
#import "CallsManager.h"
#import "ContactsManager.h"
#import "ChatsManager.h"

const int MaxSystemLocalNotificationsArrayCount = 10;

static SystemNotificationsManager* SystemNotificationsManagerSingleton = nil;
static dispatch_once_t SystemNotificationsManagerSingletonOnceToken;

@interface SystemNotificationsManager ()

@property NSInteger SystemLocalNotificationsCounter;

@property NSMutableArray *SystemLocalNotificationsArray;

@property NSMutableArray *AggregatedActions;

@property UIBackgroundTaskIdentifier SendReadyForCallBgTask;

@end



@interface SystemNotificationsManager()

@property PKPushRegistry * VoipRegistry;

@property NSNumber * Active;

@end


@implementation SystemNotificationsManager
{
    BOOL AllInited;
}

+ (instancetype) Manager
{
    return [self SystemNotifications];
}

+ (instancetype) SystemNotifications
{
    dispatch_once(&SystemNotificationsManagerSingletonOnceToken, ^{
        
        SystemNotificationsManagerSingleton = [[SystemNotificationsManager alloc] init];
        
    });
     
    [SystemNotificationsManagerSingleton InitAll];
    
    return SystemNotificationsManagerSingleton;
}

+ (void) Destroy
{
    if(SystemNotificationsManagerSingleton)
    {
        SystemNotificationsManagerSingleton = nil;
        SystemNotificationsManagerSingletonOnceToken = 0;
    }
}

- (void) SetActive:(BOOL) Active
{
    self.Active = [NSNumber numberWithBool:Active];
}

- (void) InitAll
{
    
    if (!AllInited)
    {
        [UiLogger WriteLogDebug:@"SIGNALING: Init systemNotifManager"];
        AllInited = YES;
        
        self.SystemLocalNotificationsCounter = 0;
        
        self.SystemLocalNotificationsArray = [[NSMutableArray alloc] init];

        self.SystemNotificationInProcessSignal = [[RACObserve(self, SystemNotificationInProcess) distinctUntilChanged] ignore:nil];
        
        @weakify(self);
        
        /*
        [RACObserve([AppManager app].UserSession, IsUserAuthorized) subscribeNext:^(id x) {
            
            @strongify(self);
            
            if([AppManager app].UserSession.IsUserAuthorized && self.SystemNotificationWait)
            {
                self.SystemNotificationInProcess = self.SystemNotificationWait;
                self.SystemNotificationWait = nil;
            }
            
        }];
         */
        
        
        
        RACSignal *AuthorizedSignal =
        [RACSignal
            combineLatest:@[RACObserve([AppManager app].UserSession, IsUserAuthorized), RACObserve([AppManager app].UserSession, IsUserAuthorizedAndGuiReady)]
            reduce:^id(NSNumber *Autorized, NSNumber *GuiReady){
                return @([Autorized boolValue] && [GuiReady boolValue]);
            }];
        

        RACSignal *AggregatedSystemNotificationsClickedSignal =
        [[self.SystemNotificationInProcessSignal
            takeUntil:[AuthorizedSignal
                        filter:^BOOL(NSNumber *Ready) {
                            return [Ready boolValue];
                        }]
            ]
            scanWithStart:[NSMutableArray new]
            reduce:^id(id running, id next) {
                NSMutableArray *AggregatedClicks = [running mutableCopy];
                [AggregatedClicks addObject:next];
                return AggregatedClicks;
            }];
        
        RAC(self, AggregatedActions) = AggregatedSystemNotificationsClickedSignal;
        
        RACSignal *MainProcessSignal =
        [RACSignal
            if:AuthorizedSignal
            then:self.SystemNotificationInProcessSignal
            else:[RACSignal empty]];
        
        [MainProcessSignal subscribeNext:^(SystemNotificationModel *Notfification) {
            @strongify(self);
            
            if(self.AggregatedActions && self.AggregatedActions.count)
            {
                for(SystemNotificationModel *AggregatedClick in self.AggregatedActions)
                {
                    [UiLogger WriteLogDebug:[NSString stringWithFormat:@"SIGNALING: Process performDidClickSystemNotification aggregated - %@", AggregatedClick.UserResponse]];
                    [self PerformDidClickSystemNotification: AggregatedClick];
                }
                self.AggregatedActions = nil;
            }
            else
            {
                [UiLogger WriteLogDebug:[NSString stringWithFormat:@"SIGNALING: Process performDidClickSystemNotification NOTaggregated - %@", Notfification.UserResponse]];
                [self PerformDidClickSystemNotification: Notfification];
            }
        }];
        
        
        // Init Voip Push
        self.VoipRegistry = [[PKPushRegistry alloc] initWithQueue: dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)];
        self.VoipRegistry.delegate = self;
        self.VoipRegistry.desiredPushTypes = [NSSet setWithObject:PKPushTypeVoIP];
        
        
        //[self SetupSystemNotificationsSettings];
    }
}

- (void) SetupSystemNotificationsSettings
{
    // XmppMessageCategory
    
    UIMutableUserNotificationCategory *XmppMessageCategory = [[UIMutableUserNotificationCategory alloc] init];
    
    XmppMessageCategory.identifier = SystemNotificationModelXmppMessageCategory;
    
    // XmppMessageCategoryLookAction
    
    UIMutableUserNotificationAction *XmppMessageCategoryLookAction =  [[UIMutableUserNotificationAction alloc] init];
    
    XmppMessageCategoryLookAction.identifier = SystemNotificationModelXmppMessageCategoryLookAction;
    XmppMessageCategoryLookAction.title = NSLocalizedString(SystemNotificationModelActionXmppOpen, nil);
    XmppMessageCategoryLookAction.behavior = UIUserNotificationActionBehaviorDefault;
    XmppMessageCategoryLookAction.activationMode = UIUserNotificationActivationModeForeground;
    XmppMessageCategoryLookAction.destructive = NO;
    XmppMessageCategoryLookAction.authenticationRequired = NO;
    
    // XmppMessageCategoryLookAction
    
    UIMutableUserNotificationAction *XmppMessageCategoryAnswerAction =  [[UIMutableUserNotificationAction alloc] init];
    
    XmppMessageCategoryAnswerAction.identifier = SystemNotificationModelXmppMessageCategoryAnswerAction;
    XmppMessageCategoryAnswerAction.title = NSLocalizedString(SystemNotificationModelActionXmppAnswer, nil);
    XmppMessageCategoryAnswerAction.behavior = UIUserNotificationActionBehaviorTextInput;
    XmppMessageCategoryAnswerAction.activationMode = UIUserNotificationActivationModeBackground;
    XmppMessageCategoryAnswerAction.destructive = NO;
    XmppMessageCategoryAnswerAction.authenticationRequired = NO;
    
    // Set the actions to display in the default context
    
    [XmppMessageCategory setActions:@[XmppMessageCategoryAnswerAction,XmppMessageCategoryLookAction] forContext:UIUserNotificationActionContextDefault];
    
    // Set the actions to display in a minimal context
    
    [XmppMessageCategory setActions:@[XmppMessageCategoryAnswerAction,XmppMessageCategoryLookAction] forContext:UIUserNotificationActionContextMinimal];
    
    //---
    
    // XmppMessageNoAnswerCategory
    
    UIMutableUserNotificationCategory *XmppMessageNoAnswerCategory = [[UIMutableUserNotificationCategory alloc] init];
    
    XmppMessageNoAnswerCategory.identifier = SystemNotificationModelXmppMessageNoAnswerCategory;
    
    // XmppMessageCategoryLookAction
    
    UIMutableUserNotificationAction *XmppMessageNoAnswerCategoryLookAction =  [[UIMutableUserNotificationAction alloc] init];
    
    XmppMessageNoAnswerCategoryLookAction.identifier = SystemNotificationModelXmppMessageCategoryLookAction;
    XmppMessageNoAnswerCategoryLookAction.title = NSLocalizedString(SystemNotificationModelActionXmppOpen, nil);
    XmppMessageNoAnswerCategoryLookAction.behavior = UIUserNotificationActionBehaviorDefault;
    XmppMessageNoAnswerCategoryLookAction.activationMode = UIUserNotificationActivationModeForeground;
    XmppMessageNoAnswerCategoryLookAction.destructive = NO;
    XmppMessageNoAnswerCategoryLookAction.authenticationRequired = NO;
    
    // Set the actions to display in the default context
    
    [XmppMessageNoAnswerCategory setActions:@[XmppMessageNoAnswerCategoryLookAction] forContext:UIUserNotificationActionContextDefault];
    
    // Set the actions to display in a minimal context
    
    [XmppMessageNoAnswerCategory setActions:@[XmppMessageNoAnswerCategoryLookAction] forContext:UIUserNotificationActionContextMinimal];
    
    //---
    
    // XmppMessageMucInviteCategory
    
    UIMutableUserNotificationCategory *XmppMessageMucInviteCategory = [[UIMutableUserNotificationCategory alloc] init];
    
    XmppMessageMucInviteCategory.identifier = SystemNotificationModelXmppMessageMucInviteCategory;
    
    // XmppMessageMucInviteCategoryLookAction
    
    UIMutableUserNotificationAction *XmppMessageMucInviteCategoryLookAction =  [[UIMutableUserNotificationAction alloc] init];
    
    XmppMessageMucInviteCategoryLookAction.identifier = SystemNotificationModelXmppMessageCategoryLookAction;
    XmppMessageMucInviteCategoryLookAction.title = NSLocalizedString(SystemNotificationModelActionXmppOpen, nil);
    XmppMessageMucInviteCategoryLookAction.behavior = UIUserNotificationActionBehaviorDefault;
    XmppMessageMucInviteCategoryLookAction.activationMode = UIUserNotificationActivationModeForeground;
    XmppMessageMucInviteCategoryLookAction.destructive = NO;
    XmppMessageMucInviteCategoryLookAction.authenticationRequired = NO;
    
    // XmppMessageCategoryLookAction
    
    UIMutableUserNotificationAction *XmppMessageMucInviteCategoryAnswerAction =  [[UIMutableUserNotificationAction alloc] init];
    
    XmppMessageMucInviteCategoryAnswerAction.identifier = SystemNotificationModelXmppMessageCategoryAnswerAction;
    XmppMessageMucInviteCategoryAnswerAction.title = NSLocalizedString(SystemNotificationModelActionXmppAnswer, nil);
    XmppMessageMucInviteCategoryAnswerAction.behavior = UIUserNotificationActionBehaviorTextInput;
    XmppMessageMucInviteCategoryAnswerAction.activationMode = UIUserNotificationActivationModeBackground;
    XmppMessageMucInviteCategoryAnswerAction.destructive = NO;
    XmppMessageMucInviteCategoryAnswerAction.authenticationRequired = NO;
    
    // Set the actions to display in the default context
    
    [XmppMessageMucInviteCategory setActions:@[XmppMessageMucInviteCategoryAnswerAction,XmppMessageMucInviteCategoryLookAction] forContext:UIUserNotificationActionContextDefault];
    
    // Set the actions to display in a minimal context
    
    [XmppMessageMucInviteCategory setActions:@[XmppMessageMucInviteCategoryAnswerAction,XmppMessageMucInviteCategoryLookAction] forContext:UIUserNotificationActionContextMinimal];
    
    //---
    
    // IncomingCallCategory
    
    UIMutableUserNotificationCategory *IncomingCallCategory = [[UIMutableUserNotificationCategory alloc] init];
    
    IncomingCallCategory.identifier = SystemNotificationModelIncomingCallCategory;
    
    // IncomingCallCategoryCancelAction
    
    UIMutableUserNotificationAction *IncomingCallCategoryCancelAction =  [[UIMutableUserNotificationAction alloc] init];
    
    IncomingCallCategoryCancelAction.identifier = SystemNotificationModelIncomingCallCategoryCancelAction;
    IncomingCallCategoryCancelAction.title = NSLocalizedString(SystemNotificationModelActionSipCancel, nil);
    IncomingCallCategoryCancelAction.behavior = UIUserNotificationActionBehaviorDefault;
    IncomingCallCategoryCancelAction.activationMode = UIUserNotificationActivationModeBackground;
    IncomingCallCategoryCancelAction.destructive = YES;
    IncomingCallCategoryCancelAction.authenticationRequired = NO;
    
    // IncomingCallCategoryAnswerAction
    
    UIMutableUserNotificationAction *IncomingCallCategoryAnswerAction =  [[UIMutableUserNotificationAction alloc] init];
    
    IncomingCallCategoryAnswerAction.identifier = SystemNotificationModelIncomingCallCategoryAnswerAction;
    IncomingCallCategoryAnswerAction.title = NSLocalizedString(SystemNotificationModelActionSipAnswer, nil);
    IncomingCallCategoryAnswerAction.behavior = UIUserNotificationActionBehaviorDefault;
    IncomingCallCategoryAnswerAction.activationMode = UIUserNotificationActivationModeForeground;
    IncomingCallCategoryAnswerAction.destructive = NO;
    IncomingCallCategoryAnswerAction.authenticationRequired = NO;
    
    // Set the actions to display in the default context
    
    [IncomingCallCategory setActions:@[IncomingCallCategoryAnswerAction,IncomingCallCategoryCancelAction] forContext:UIUserNotificationActionContextDefault];
    
    // Set the actions to display in a minimal context
    
    [IncomingCallCategory setActions:@[IncomingCallCategoryAnswerAction,IncomingCallCategoryCancelAction] forContext:UIUserNotificationActionContextMinimal];
    
    
    //---
    
    // PushIncomingCallCategory
    
    UIMutableUserNotificationCategory *PushIncomingCallCategory = [[UIMutableUserNotificationCategory alloc] init];
    
    PushIncomingCallCategory.identifier = SystemNotificationModelPushIncomingCallCategory;
    
    // IncomingCallCategoryCancelAction
    
    UIMutableUserNotificationAction *PushIncomingCallCategoryCancelAction =  [[UIMutableUserNotificationAction alloc] init];
    
    PushIncomingCallCategoryCancelAction.identifier = SystemNotificationModelPushIncomingCallCategoryCancelAction;
    PushIncomingCallCategoryCancelAction.title = NSLocalizedString(SystemNotificationModelActionSipCancel, nil);
    PushIncomingCallCategoryCancelAction.behavior = UIUserNotificationActionBehaviorDefault;
    PushIncomingCallCategoryCancelAction.activationMode = UIUserNotificationActivationModeBackground;
    PushIncomingCallCategoryCancelAction.destructive = YES;
    PushIncomingCallCategoryCancelAction.authenticationRequired = NO;
    
    // IncomingCallCategoryAnswerAction
    
    UIMutableUserNotificationAction *PushIncomingCallCategoryAnswerAction =  [[UIMutableUserNotificationAction alloc] init];
    
    PushIncomingCallCategoryAnswerAction.identifier = SystemNotificationModelPushIncomingCallCategoryAnswerAction;
    PushIncomingCallCategoryAnswerAction.title = NSLocalizedString(SystemNotificationModelActionSipAnswer, nil);
    PushIncomingCallCategoryAnswerAction.behavior = UIUserNotificationActionBehaviorDefault;
    PushIncomingCallCategoryAnswerAction.activationMode = UIUserNotificationActivationModeForeground;
    PushIncomingCallCategoryAnswerAction.destructive = NO;
    PushIncomingCallCategoryAnswerAction.authenticationRequired = NO;
    
    // Set the actions to display in the default context
    
    [PushIncomingCallCategory setActions:@[PushIncomingCallCategoryAnswerAction,PushIncomingCallCategoryCancelAction] forContext:UIUserNotificationActionContextDefault];
    
    // Set the actions to display in a minimal context
    
    [PushIncomingCallCategory setActions:@[PushIncomingCallCategoryAnswerAction,PushIncomingCallCategoryCancelAction] forContext:UIUserNotificationActionContextMinimal];
    
    //---
    
    // PushMissedIncomingCallCategory
    
    UIMutableUserNotificationCategory *PushMissedIncomingCallCategory = [[UIMutableUserNotificationCategory alloc] init];
    
    PushMissedIncomingCallCategory.identifier = SystemNotificationModelPushMissedIncomingCallCategory;
    
    // PushMissedIncomingCallCategoryLookAction
    
    UIMutableUserNotificationAction *PushMissedIncomingCallCategoryLookAction =  [[UIMutableUserNotificationAction alloc] init];
    
    PushMissedIncomingCallCategoryLookAction.identifier = SystemNotificationModelPushMissedIncomingCallCategoryLookAction;
    PushMissedIncomingCallCategoryLookAction.title = NSLocalizedString(SystemNotificationModelActionSipOpen, nil);
    PushMissedIncomingCallCategoryLookAction.behavior = UIUserNotificationActionBehaviorDefault;
    PushMissedIncomingCallCategoryLookAction.activationMode = UIUserNotificationActivationModeForeground;
    PushMissedIncomingCallCategoryLookAction.destructive = YES;
    PushMissedIncomingCallCategoryLookAction.authenticationRequired = NO;
    
    // PushMissedIncomingCallCategoryCallAction
    
    UIMutableUserNotificationAction *PushMissedIncomingCallCategoryCallAction =  [[UIMutableUserNotificationAction alloc] init];
    
    PushMissedIncomingCallCategoryCallAction.identifier = SystemNotificationModelPushMissedIncomingCallCategoryCallAction;
    PushMissedIncomingCallCategoryCallAction.title = NSLocalizedString(SystemNotificationModelActionSipCall, nil);
    PushMissedIncomingCallCategoryCallAction.behavior = UIUserNotificationActionBehaviorDefault;
    PushMissedIncomingCallCategoryCallAction.activationMode = UIUserNotificationActivationModeForeground;
    PushMissedIncomingCallCategoryCallAction.destructive = NO;
    PushMissedIncomingCallCategoryCallAction.authenticationRequired = NO;
    
    // Set the actions to display in the default context
    
    [PushMissedIncomingCallCategory setActions:@[PushMissedIncomingCallCategoryCallAction,PushMissedIncomingCallCategoryLookAction] forContext:UIUserNotificationActionContextDefault];
    
    // Set the actions to display in a minimal context
    
    [PushMissedIncomingCallCategory setActions:@[PushMissedIncomingCallCategoryCallAction,PushMissedIncomingCallCategoryLookAction] forContext:UIUserNotificationActionContextMinimal];
    
    //---
    
    // XmppMessageContactInviteCategory
    
    UIMutableUserNotificationCategory *XmppMessageContactInviteCategory = [[UIMutableUserNotificationCategory alloc] init];
    
    XmppMessageContactInviteCategory.identifier = SystemNotificationModelXmppMessageContactInviteCategory;
    
    // XmppMessageContactInviteCategoryLookAction
    
    UIMutableUserNotificationAction *XmppMessageContactInviteCategoryLookAction = [[UIMutableUserNotificationAction alloc] init];
    
    XmppMessageContactInviteCategoryLookAction.identifier = SystemNotificationModelXmppMessageContactInviteCategoryLookAction;
    XmppMessageContactInviteCategoryLookAction.title = NSLocalizedString(SystemNotificationModelActionXmppOpen, nil);
    XmppMessageContactInviteCategoryLookAction.behavior = UIUserNotificationActionBehaviorDefault;
    XmppMessageContactInviteCategoryLookAction.activationMode = UIUserNotificationActivationModeForeground;
    XmppMessageContactInviteCategoryLookAction.destructive = YES;
    XmppMessageContactInviteCategoryLookAction.authenticationRequired = NO;
    
    // XmppMessageContactInviteCategoryAcceptAction
    
    UIMutableUserNotificationAction *XmppMessageContactInviteCategoryAcceptAction = [[UIMutableUserNotificationAction alloc] init];
    
    XmppMessageContactInviteCategoryAcceptAction.identifier = SystemNotificationModelXmppMessageContactInviteCategoryAcceptAction;
    XmppMessageContactInviteCategoryAcceptAction.title = NSLocalizedString(SystemNotificationModelActionXmppAccept, nil);
    XmppMessageContactInviteCategoryAcceptAction.behavior = UIUserNotificationActionBehaviorDefault;
    XmppMessageContactInviteCategoryAcceptAction.activationMode = UIUserNotificationActivationModeForeground;
    XmppMessageContactInviteCategoryAcceptAction.destructive = NO;
    XmppMessageContactInviteCategoryAcceptAction.authenticationRequired = NO;
    
    // Set the actions to display in the default context
    
    [XmppMessageContactInviteCategory setActions:@[XmppMessageContactInviteCategoryAcceptAction,XmppMessageContactInviteCategoryLookAction] forContext:UIUserNotificationActionContextDefault];
    
    // Set the actions to display in a minimal context
    
    [XmppMessageContactInviteCategory setActions:@[XmppMessageContactInviteCategoryAcceptAction,XmppMessageContactInviteCategoryLookAction] forContext:UIUserNotificationActionContextMinimal];
    
    //Set categories
    
    NSSet *NotifCategories = [NSSet setWithObjects:XmppMessageCategory,XmppMessageNoAnswerCategory,IncomingCallCategory,PushIncomingCallCategory,XmppMessageMucInviteCategory,PushMissedIncomingCallCategory,XmppMessageContactInviteCategory,nil];
    
    
    UIUserNotificationType NotifTypes = UIUserNotificationTypeSound | UIUserNotificationTypeAlert | UIUserNotificationTypeBadge;
    
    UIUserNotificationSettings *NotifSettings = [UIUserNotificationSettings settingsForTypes:NotifTypes categories:NotifCategories];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [[UIApplication sharedApplication] registerUserNotificationSettings:NotifSettings];
    });
    
}

- (void) RegisterForSystemNotifications
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [[UIApplication sharedApplication] registerForRemoteNotifications];
  
    });
    
    [self RegisterForVoipNotifications];
}

- (void) PerformDidReceiveSystemLocalNotfification: (UILocalNotification *) LocalNotfification
{
    [UiLogger WriteLogInfo:[NSString stringWithFormat:@"SystemNotificationsManager:PerformUserDidClickedSystemLocalNotfification:%@",LocalNotfification]];
    
    self.SystemNotificationInProcess = [CoreHelper TransformLocalNotificationToSystemNotificationModel:LocalNotfification];
}

- (void) PerformDidReceiveSystemRemoteNotfification: (NSDictionary *) RemoteNotfification
{
    [UiLogger WriteLogInfo:[NSString stringWithFormat:@"SystemNotificationsManager:PerformUserDidClickedSystemRemoteNotfification:%@",RemoteNotfification]];
    
    self.SystemNotificationInProcess = [CoreHelper TransformRemoteNotificationToSystemNotificationModel:RemoteNotfification];
}

- (void) PerformHandleActionOfSystemRemoteNotfificationWithIdentifier:(NSString *) Identifier AndAction: (NSDictionary *) RemoteNotfification withResponseInfo:(NSDictionary *)ResponseInfo completionHandler:(void(^)())CompletionHandler
{
    [UiLogger WriteLogInfo:[NSString stringWithFormat:@"SystemNotificationsManager:PerformHandleActionOfSystemRemoteNotfificationWithIdentifier:%@ AndAction %@ WithResponseInfo %@",Identifier, RemoteNotfification, ResponseInfo]];
    
    NSMutableDictionary *ResultRemoteNotification = [NSMutableDictionary dictionaryWithDictionary:RemoteNotfification];
    
    if(ResponseInfo)
        [ResultRemoteNotification addEntriesFromDictionary:ResponseInfo];
    
    [ResultRemoteNotification setObject:Identifier forKey:SystemNotificationModelMetaUserActionKey];
    
    
    SystemNotificationModel *SystemNotificationInProcess = [CoreHelper TransformRemoteNotificationToSystemNotificationModel:ResultRemoteNotification];
    
    SystemNotificationInProcess.CompletionHandler = CompletionHandler;
    
    self.SystemNotificationInProcess = SystemNotificationInProcess;
    
    [UiLogger WriteLogDebug:[NSString stringWithFormat:@"SIGNALING: PerformHandleActionOfSystemRemoteNotfification - %@", self.SystemNotificationInProcess.UserResponse]];
}

- (void) PerformHandleActionOfSystemLocalNotfificationWithIdentifier:(NSString *) Identifier AndAction: (UILocalNotification *) LocalNotfification withResponseInfo:(NSDictionary *)ResponseInfo completionHandler:(void(^)())CompletionHandler
{
    [UiLogger WriteLogInfo:[NSString stringWithFormat:@"PerformHandleActionOfSystemLocalNotfificationWithIdentifier:%@ AndAction %@ WithResponseInfo %@",Identifier, LocalNotfification, ResponseInfo]];
    
    
    NSMutableDictionary *ResultLocalNotificationInfo = [NSMutableDictionary dictionaryWithDictionary:LocalNotfification.userInfo];
    
    if(ResponseInfo)
        [ResultLocalNotificationInfo addEntriesFromDictionary:ResponseInfo];
    
    [ResultLocalNotificationInfo setObject:Identifier forKey:SystemNotificationModelMetaUserActionKey];
    
    
    [LocalNotfification setUserInfo:ResultLocalNotificationInfo];
    
    SystemNotificationModel *SystemNotificationInProcess = [CoreHelper TransformLocalNotificationToSystemNotificationModel:LocalNotfification];
    
    SystemNotificationInProcess.CompletionHandler = CompletionHandler;
    
    self.SystemNotificationInProcess = SystemNotificationInProcess;
    
    [UiLogger WriteLogDebug:[NSString stringWithFormat:@"SIGNALING: PerformHandleActionOfSystemRemoteNotfification - %@", self.SystemNotificationInProcess.UserResponse]];
}

- (void) PerformDidClickSystemNotification: (SystemNotificationModel *) Notfification
{
    if (Notfification.UserDestinationId.length > 0 && (Notfification.UserType == SystemNotificationModelUserTypeXmpp || Notfification.UserType == SystemNotificationModelUserTypeXmppInviteToChat))
    {
        if(Notfification.UserResponse && Notfification.UserResponse.length > 0)
        {
            [ChatsManager SendMessageOrWaitChat:Notfification.UserResponse ToChat:Notfification.UserDestinationId];
        }
        
        else
        {
            [ChatsManager ForceChatSync:Notfification.UserDestinationId];
            [UiChatsTabNavRouter ShowChatViewByChatIdOrWaitChat:Notfification.UserDestinationId];
        }
        
        
    }
    
    if (Notfification.UserDestinationId.length > 0 && Notfification.UserType == SystemNotificationModelUserTypeSip)
    {
        if(/*Notfification.UserActionKey == nil || */[Notfification.UserActionKey isEqualToString:SystemNotificationModelIncomingCallCategoryAnswerAction])
        {
            [CallsManager AcceptCall:Notfification.UserDestinationId];
        }
        
        if([Notfification.UserActionKey isEqualToString:SystemNotificationModelIncomingCallCategoryCancelAction])
        {
            [CallsManager HangupCall:Notfification.UserDestinationId];
        }
        
        
        if([Notfification.UserActionKey isEqualToString:SystemNotificationModelPushIncomingCallCategoryAnswerAction])
        {
            NSString *UserDestinationId = [Notfification.UserDestinationId copy];
            
            @weakify(UserDestinationId);
            
            [[[[RACObserve([CallsManager Manager], CurrentIncomingCall) ignore:nil] take:1] timeout:10 onScheduler:[RACScheduler schedulerWithPriority:RACSchedulerPriorityHigh] ] subscribeNext:^(ObjC_CallModel *Call) {
                
                @strongify(UserDestinationId)
                
                if([UserDestinationId isEqualToString:Call.Identity])
                {
                    [CallsManager AcceptCall:Call.Id];
                }
                
            }];
            
        }
        
        if([Notfification.UserActionKey isEqualToString:SystemNotificationModelPushIncomingCallCategoryCancelAction])
        {
            NSString *UserDestinationId = [Notfification.UserDestinationId copy];
            
            @weakify(UserDestinationId);
            
            [[[[RACObserve([CallsManager Manager], CurrentIncomingCall) ignore:nil] take:1] timeout:10 onScheduler:[RACScheduler schedulerWithPriority:RACSchedulerPriorityHigh] ] subscribeNext:^(ObjC_CallModel *Call) {
                
                @strongify(UserDestinationId)
                
                if([UserDestinationId isEqualToString:Call.Identity])
                {
                    [CallsManager HangupCall:Call.Id];
                }
                
            }];

        }
    }
    
    if (Notfification.UserDestinationId.length > 0 && Notfification.UserType == SystemNotificationModelUserTypeSipMissedIncomingCall)
    {
        if([Notfification.UserActionKey isEqualToString:SystemNotificationModelPushMissedIncomingCallCategoryCallAction])
        {
            [CallsManager StartOutgoingCallToNumber:Notfification.UserDestinationId WithCallback:nil];
        }
        
        else
        {
            [[UiNavRouter NavRouter] ShowHistoryTabPage];
        }
        
    }
    
    if (Notfification.UserDestinationId.length > 0 && Notfification.UserType == SystemNotificationModelUserTypeXmppInviteContact)
    {
        
        if([Notfification.UserActionKey isEqualToString:SystemNotificationModelXmppMessageContactInviteCategoryAcceptAction])
        {
            [[UiNavRouter NavRouter] ShowOrWaitInviteWithXmppId:Notfification.UserDestinationId WithAutoAccept:YES];
        }
        
        else
        {
            [[UiNavRouter NavRouter] ShowOrWaitInviteWithXmppId:Notfification.UserDestinationId];
        }
        
    }
    
    if(Notfification.CompletionHandler)
    {
        Notfification.CompletionHandler();
        Notfification.CompletionHandler = nil;
    }
    
    [[AppManager Manager].Core InitNetwork];
}

- (NSInteger) SendSystemLocalNotification:(SystemNotificationModel *) SystemNotification
{
    self.SystemLocalNotificationsCounter++;
    SystemNotification.Id = self.SystemLocalNotificationsCounter;
    
    
    UILocalNotification *LocalNotification = [[UILocalNotification alloc] init];
    LocalNotification.alertAction = [SystemNotification.Action copy];
    LocalNotification.hasAction = SystemNotification.HasAction;
    
    if(SystemNotification.FormatedTitleBodyString && SystemNotification.FormatedTitleBodyString.length > 0)
    {
        LocalNotification.alertBody = [SystemNotification.FormatedTitleBodyString copy];
    }
    else
    {
       LocalNotification.alertBody = [[NSString stringWithFormat:@"%@\n%@",SystemNotification.Title,SystemNotification.Body] copy];
    }
    
    LocalNotification.soundName = [SystemNotification.Sound copy];
    LocalNotification.userInfo = [SystemNotification.Meta copy];
    LocalNotification.category = [SystemNotification.Categoty copy];
    
    [[UIApplication sharedApplication] presentLocalNotificationNow:LocalNotification];
    
    if([self.SystemLocalNotificationsArray count] > MaxSystemLocalNotificationsArrayCount)
    {
        [self.SystemLocalNotificationsArray removeLastObject];
    }
    
    SystemNotification.LocalNotification = LocalNotification;
    
    [self.SystemLocalNotificationsArray insertObject:SystemNotification atIndex:0];
    
    return SystemNotification.Id;
}

- (void) CancelSystemLocalNotificationWithId:(NSInteger) Id
{
    for (int i = 0; i < [self.SystemLocalNotificationsArray count]; i++)
    {
        @try
        {
            SystemNotificationModel *SystemNotification = [self.SystemLocalNotificationsArray objectAtIndex:i];
            
            if (SystemNotification.Id == Id && SystemNotification.LocalNotification)
            {
                [[UIApplication sharedApplication] cancelLocalNotification:SystemNotification.LocalNotification];
                
                [self.SystemLocalNotificationsArray removeObjectAtIndex:i];
                
                break;
            }
        }
        @catch (NSException *exception)
        {
            
        }
        
    }
}

- (void) SendSystemLocalIncomingCallNotificationWithCall:(ObjC_CallModel *) Call
{
    UIApplicationState state = [[UIApplication sharedApplication] applicationState];
    
    if(state != UIApplicationStateActive)
    {
        SystemNotificationModel *SN = [[SystemNotificationModel alloc] init];
        
        SN.Action = NSLocalizedString(SystemNotificationModelActionSipAnswer, nil);
        SN.HasAction = NO;
        
        if(Call.Contact)
        {
            SN.FormatedTitleBodyString = [NSString stringWithFormat:NSLocalizedString(@"Title_IncomingCallFrom%@", nil), [ContactsManager GetContactTitle:Call.Contact]];
        }
        else
        {
            SN.FormatedTitleBodyString = [NSString stringWithFormat:NSLocalizedString(@"Title_IncomingCallFrom%@", nil), [Call.Identity componentsSeparatedByString:@"@"][0]];
        }
        
        SN.Sound = SystemNotificationModelSoundSip;
        SN.Categoty = SystemNotificationModelIncomingCallCategory;
        
        SN.Meta = @{
                    SystemNotificationModelMeta:@{
                            SystemNotificationModelMetaType:SystemNotificationModelMetaTypeSip,
                            SystemNotificationModelMetaUserDestination:Call.Id
                            }
                    };
        
        self.CurrentIncomingCallSystemLocalNotificationId = [self SendSystemLocalNotification:SN];
    }
}

- (void) CancelSystemLocalIncomingCallNotification
{
    [self CancelSystemLocalNotificationWithId:self.CurrentIncomingCallSystemLocalNotificationId];
}

- (void) PerformDidRegisterForRemoteNotificationsWithDeviceToken:(NSData *)DevToken
{
    NSString *devTokenString = [[DevToken description] stringByReplacingOccurrencesOfString:@"<" withString:@""];
    devTokenString = [devTokenString stringByReplacingOccurrencesOfString:@">" withString:@""];
    devTokenString = [devTokenString stringByReplacingOccurrencesOfString: @" " withString: @""];
    
    self.PushToken = devTokenString;
    
    
    
    [[[[[RACSignal combineLatest:@[RACObserve(self,PushToken),RACObserve([AppManager app].UserSession, IsUserAuthorized),RACObserve([AppManager app].UserSession, IsUserLoggedInAndServersReady)] reduce:^NSString*(NSString *PushToken, NSNumber *IsUserAuthorized, NSNumber *IsUserLoggedInAndServersReady){
        
        if([IsUserAuthorized boolValue] && PushToken && [IsUserLoggedInAndServersReady boolValue])
        {
            return PushToken;
        }
        
        return nil;
        
    }] ignore:nil] distinctUntilChanged] take:1] subscribeNext:^(NSString *PushToken) {
        
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            
            NSString *KeychainToken = [UICKeyChainStore stringForKey:PushDeviceTokenKeychainKey];
            
            if(KeychainToken && KeychainToken.length) {
                if(![KeychainToken isEqualToString:PushToken]) {
                    [[AppManager app].Core RemoveRemoteNotificationsDeviceToken:KeychainToken];
                }
            }
            
            [UICKeyChainStore setString:PushToken forKey:PushDeviceTokenKeychainKey];
            
            [UiLogger WriteLogInfo:[NSString stringWithFormat:@"PerformDidRegisterForRemoteNotificationsWithDeviceToken:%@",PushToken]];
            
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                
                [[AppManager app].Core didRegisterForRemoteNotificationsWithDeviceToken: PushToken];
                
            });
            
        });
    }];
    
}

- (void) PerformDidFailToRegisterForRemoteNotificationsWithError:(NSError *)err
{
    
#ifdef TARGET_IPHONE_SIMULATOR
    
    self.PushToken = @"SIMULATOR";
    
    [[[[[RACSignal combineLatest:@[RACObserve(self,PushToken),RACObserve([AppManager app].UserSession, IsUserAuthorized),RACObserve([AppManager app].UserSession, IsUserLoggedInAndServersReady)] reduce:^NSString*(NSString *PushToken, NSNumber *IsUserAuthorized, NSNumber *IsUserLoggedInAndServersReady){
        
        if([IsUserAuthorized boolValue] && PushToken && [IsUserLoggedInAndServersReady boolValue])
        {
            return PushToken;
        }
        
        return nil;
        
    }] ignore:nil] distinctUntilChanged] take:1] subscribeNext:^(NSString *PushToken) {
        
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            
            NSString *KeychainToken = [UICKeyChainStore stringForKey:PushDeviceTokenKeychainKey];
            
            if(KeychainToken && KeychainToken.length) {
                if(![KeychainToken isEqualToString:PushToken]) {
                    [[AppManager app].Core RemoveRemoteNotificationsDeviceToken:KeychainToken];
                }
            }
            
            [UICKeyChainStore setString:PushToken forKey:PushDeviceTokenKeychainKey];
            
            [UiLogger WriteLogInfo:[NSString stringWithFormat:@"PerformDidRegisterForRemoteNotificationsWithDeviceToken:%@",PushToken]];
            
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                
                [[AppManager app].Core didRegisterForRemoteNotificationsWithDeviceToken: PushToken];
                
            });
            
        });
    }];
    
#endif
    
    [UiLogger WriteLogInfo:@"PerformDidFailToRegisterForRemoteNotificationsWithError"];
}

#pragma mark Voip Push

- (void) RegisterForVoipNotifications
{
 
    
    [[[[[RACSignal combineLatest:@[RACObserve(self,VoipPushToken),RACObserve([AppManager app].UserSession, IsUserAuthorized),RACObserve([AppManager app].UserSession, IsUserLoggedInAndServersReady)] reduce:^NSString*(NSString *VoipPushToken, NSNumber *IsUserAuthorized, NSNumber *IsUserLoggedInAndServersReady){
        
        if([IsUserAuthorized boolValue] && VoipPushToken && [IsUserLoggedInAndServersReady boolValue])
        {
            return VoipPushToken;
        }
        
        return nil;
        
    }] ignore:nil] distinctUntilChanged] take:1] subscribeNext:^(NSString *VoipPushToken) {
        
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            
            //NSString *userUuid = [[[AppManager app].Core GetAccountData].DodicallId copy];
            
            NSString *KeychainToken = [UICKeyChainStore stringForKey:VOiPPushDeviceTokenKeychainKey];
            
            if(KeychainToken && KeychainToken.length) {
                if(![KeychainToken isEqualToString:VoipPushToken]) {
                    [[AppManager app].Core RemoveRemoteVoipNotificationsDeviceToken:KeychainToken];
                }
            }
            
            [UICKeyChainStore setString:VoipPushToken forKey:VOiPPushDeviceTokenKeychainKey];
            
            [[AppManager app].Core didRegisterForRemoteVoipNotificationsWithDeviceToken: [self.VoipPushToken copy]];
            
        });
    }];
    
}

- (void)pushRegistry:(PKPushRegistry *)registry didUpdatePushCredentials: (PKPushCredentials *)credentials forType:(NSString *)type
{
    
    NSString *devTokenString = [[credentials.token description] stringByReplacingOccurrencesOfString:@"<" withString:@""];
    devTokenString = [devTokenString stringByReplacingOccurrencesOfString:@">" withString:@""];
    devTokenString = [devTokenString stringByReplacingOccurrencesOfString: @" " withString: @""];
    
    [UiLogger WriteLogInfo:[NSString stringWithFormat:@"PerformDidRegisterForRemotVoipNotificationsWithDeviceToken:%@",devTokenString]];
    
    self.VoipPushToken = [devTokenString copy];
}

- (void)pushRegistry:(PKPushRegistry *)registry didReceiveIncomingPushWithPayload:(PKPushPayload *)payload forType:(NSString *)type
{
    if([[UIApplication sharedApplication] applicationState] == UIApplicationStateBackground)
    {
        if(self.SendReadyForCallBgTask != UIBackgroundTaskInvalid)
        {
            [[UIApplication sharedApplication] endBackgroundTask:self.SendReadyForCallBgTask];
            self.SendReadyForCallBgTask = UIBackgroundTaskInvalid;
        }
        
        [UiLogger WriteLogInfo:@"SystemNotificationsManager: Execute SendReadyForCall background task"];
        self.SendReadyForCallBgTask = [[UIApplication sharedApplication] beginBackgroundTaskWithName:@"SendReadyForCallBgTask" expirationHandler:^{
            
            [UiLogger WriteLogInfo:[NSString stringWithFormat:@"SystemNotificationsManager: End SendReadyForCallBgTask by expirationHandler, remaining backgronud time: %f", [[UIApplication sharedApplication] backgroundTimeRemaining]]];
            
            [[UIApplication sharedApplication] endBackgroundTask:self.SendReadyForCallBgTask];
            self.SendReadyForCallBgTask = UIBackgroundTaskInvalid;
            
        }];
        
    }
    
    [UiLogger WriteLogInfo:[NSString stringWithFormat:@"didReceiveIncomingPushWithPayload:%@", [payload.dictionaryPayload description]]];
    
    UIApplicationState state = [[UIApplication sharedApplication] applicationState];
    
    if(state != UIApplicationStateActive && payload.dictionaryPayload)
    {
        SystemNotificationModel *Notfification = [CoreHelper TransformRemoteNotificationToSystemNotificationModel:payload.dictionaryPayload];
        
        
        if([Notfification.Categoty isEqualToString:SystemNotificationModelPushIncomingCallCategory] && Notfification.UserDestinationId && Notfification.UserDestinationId.length > 0)
        {
            
            [[[[RACObserve([AppManager app].UserSession, IsUserLoggedInAndServersReady) ignore:nil] filter:^BOOL(NSNumber *Value) {
                
                return [Value boolValue];
                
            }] take:1] subscribeNext:^(id x) {
                
                [UiLogger WriteLogInfo:@"SystemNotificationsManager: VoIP push incoming call signal"];
                
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
                    
                    [[AppManager app].Core SendReadyForCallAfterStart:Notfification.UserDestinationId];
                    
                    [[AppManager app].Core InitNetwork];
                    
                });
            }];
        }
    }
    
    //[[AppManager app] PerformDidReceiveSystemRemoteNotfification:payload.dictionaryPayload];
}

@end
