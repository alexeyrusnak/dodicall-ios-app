//
//  CallbackManager.m
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

#import "CallbackManager.h"
#import <ReactiveCocoa/ReactiveCocoa.h>

#import "ContactsManager.h"
#import "ChatsManager.h"
#import "HistoryManager.h"

static CallbackManager *CallbackManagerSingleton = nil;
static dispatch_once_t CallbackManagerOnceToken;

@interface CallbackManager ()

@property (strong, nonatomic) NSNumber *ContactsUpdatePending;
@property (strong, nonatomic) NSSet *ContactsSubscriptiosIds;
@property (strong, nonatomic) NSSet *ChatIds;
@property (strong, nonatomic) NSSet *ChatMessagesIds;
@property (strong, nonatomic) NSSet *HistoryIds;

//These are queues for THIS manager only, used to syncronize events callbacks
@property (strong,nonatomic) dispatch_queue_t ChatsQueue;
@property (strong,nonatomic) dispatch_queue_t ContactsQueue;
@property (strong,nonatomic) dispatch_queue_t HistoryQueue;

@property (strong, nonatomic) NSNumber *Active;

@end


@implementation CallbackManager

#pragma mark - Lifecycle
+ (instancetype) Manager
{
    dispatch_once(&CallbackManagerOnceToken, ^{
        CallbackManagerSingleton = [CallbackManager new];
    });
    return CallbackManagerSingleton;
}

+ (instancetype) ManagerForCallBack
{
    if(CallbackManagerSingleton)
    {
        return [self Manager];
    }
    
    return nil;
}

+ (void) Destroy
{
    if(CallbackManagerSingleton)
    {
        CallbackManagerSingleton.ChatsQueue = nil;
        CallbackManagerSingleton.ContactsQueue = nil;
        CallbackManagerSingleton.HistoryQueue = nil;
        CallbackManagerSingleton = nil;
        CallbackManagerOnceToken = 0;
    }
}

- (void) SetActive:(BOOL) Active
{
    self.Active = [NSNumber numberWithBool:Active];
}

- (instancetype) init
{
    if(self = [super init]) {
        _ContactsUpdatePending = @NO;
        _ContactsSubscriptiosIds = [NSSet new];
        _ChatIds = [NSSet new];
        _ChatMessagesIds = [NSSet new];
        
        _ChatsQueue = dispatch_queue_create("CallbackChatsQueue", DISPATCH_QUEUE_SERIAL);
        _ContactsQueue = dispatch_queue_create("CallbackContactsQueue", DISPATCH_QUEUE_SERIAL);
        _HistoryQueue = dispatch_queue_create("CallbackHistoryQueue", DISPATCH_QUEUE_SERIAL);
        
        [self BindAll];
    }
    return self;
}

- (void)BindAll {
#ifdef CallbackAggregation
    
    //Contacts
    RACSignal *ContactCallback = RACObserve(self, ContactsUpdatePending);
    
    @weakify(self);
    
    [[[ContactCallback
        filter:^BOOL(NSNumber *ShouldSend) {
            return [ShouldSend boolValue];
        }]
        subscribeOn:[RACScheduler schedulerWithPriority:RACSchedulerPriorityHigh]]
        subscribeNext:^(id x) {
            
            dispatch_wait([ContactsManager Manager].DispatchGroup, DISPATCH_TIME_FOREVER);
            
            dispatch_async(self.ContactsQueue, ^{
                [[ContactsManager ManagerForCallBack] PerformContactsChangedEvent];
                self.ContactsUpdatePending = @NO;
            });
            
        }];
    
    //Chats
    //
    //@abstract
    //Divide Chats and ChatMessages to separate Queues?
    //If no, which priority?
    
    RACSignal *ChatCallbackSignal = RACObserve(self, ChatIds);
    RACSignal *ChatMessagesCallbackSignal = RACObserve(self, ChatMessagesIds);
    
    [[[RACSignal
        combineLatest:@[ChatCallbackSignal, ChatMessagesCallbackSignal]]
        deliverOn:[RACScheduler schedulerWithPriority:RACSchedulerPriorityHigh]]
        subscribeNext:^(RACTuple *Tuple) {
            
            dispatch_wait([ChatsManager Manager].DispatchGroup, DISPATCH_TIME_FOREVER);
            
            @strongify(self);
        
            dispatch_async(self.ChatsQueue, ^{
                
                NSArray *Chats = [self.ChatIds allObjects];
                NSArray *Messages = [self.ChatMessagesIds allObjects];
                
                if([Chats count])
                {
                    [[ChatsManager ManagerForCallBack] PerformChatsChangedEvent:[Chats mutableCopy]];
                    self.ChatIds = [NSSet new];
                }
                else if([Messages count])
                {
                    [[ChatsManager ManagerForCallBack] PerformMessagesChangedEvent:[Messages mutableCopy]];
                    self.ChatMessagesIds = [NSSet new];
                }
            });

        }];
    
    //History
    RACSignal *HistoryCallbackSignal = RACObserve(self, HistoryIds);
    
    [[HistoryCallbackSignal
        deliverOn:[RACScheduler schedulerWithPriority:RACSchedulerPriorityHigh]]
        subscribeNext:^(id x) {
            dispatch_wait([HistoryManager Manager].DispatchGroup, DISPATCH_TIME_FOREVER);
            @strongify(self);
            
            dispatch_async(self.HistoryQueue, ^{
                
                NSArray *HistoryIds = [self.HistoryIds allObjects];
                
                if([HistoryIds count])
                {
                    [[HistoryManager Manager] PerformHistoryChangedEvent:[HistoryIds mutableCopy]];
                    self.HistoryIds = [NSSet new];
                }
            });
        }];
    
    
    //ContactsSubscription
    RACSignal *ContactsSubscriptionCallbackSignal = RACObserve(self, ContactsSubscriptiosIds);
    
    [[[ContactsSubscriptionCallbackSignal throttle:1 afterAllowing:1 withStrike:2]
      deliverOn:[RACScheduler schedulerWithPriority:RACSchedulerPriorityHigh]]
     subscribeNext:^(id x) {
         dispatch_wait([ContactsManager Manager].DispatchGroup, DISPATCH_TIME_FOREVER);
         @strongify(self);
         
         dispatch_async(self.ContactsQueue, ^{
             
             NSArray *ContactsSubscriptiosIds = [self.ContactsSubscriptiosIds allObjects];
             
             if([ContactsSubscriptiosIds count])
             {
                 [[ContactsManager Manager] PerformSubscriptionsChangedEvent:[ContactsSubscriptiosIds mutableCopy]];
                 self.ContactsSubscriptiosIds = [NSSet new];
             }
         });
     }];
#endif
    
}

#pragma mark - Contacts
- (void)HandleContacts {
#ifdef CallbackAggregation
    dispatch_async(self.ContactsQueue, ^{
        self.ContactsUpdatePending = @YES;
    });
#else
    [[ContactsManager ManagerForCallBack] PerformContactsChangedEvent];
#endif
}

#pragma mark - ContactsSubscriprions
- (void)HandleContactsSubscriptions:(NSArray *)Ids
{
#ifdef CallbackAggregation
    dispatch_async(self.ContactsQueue, ^{
        NSMutableSet *NewIds = [NSMutableSet setWithArray:Ids];
        [NewIds unionSet:self.ContactsSubscriptiosIds];
        self.ContactsSubscriptiosIds = NewIds;
    });
#else
    [[ChatsManager ManagerForCallBack] PerformSubscriptionsChangedEvent:[Ids mutableCopy]];
#endif
}

#pragma mark - Chats
- (void)HandleChats:(NSArray *)Ids {
#ifdef CallbackAggregation
    dispatch_async(self.ChatsQueue, ^{
        NSMutableSet *NewIds = [NSMutableSet setWithArray:Ids];
        [NewIds unionSet:self.ChatIds];
        self.ChatIds = NewIds;
    });
#else
    [[ChatsManager ManagerForCallBack] PerformChatsChangedEvent:[Ids mutableCopy]];
#endif
}

- (void)HandleChatMessages:(NSArray *)Ids {
#ifdef CallbackAggregation
    dispatch_async(self.ChatsQueue, ^{
        NSMutableSet *NewIds = [NSMutableSet setWithArray:Ids];
        [NewIds unionSet:self.ChatMessagesIds];
        self.ChatMessagesIds = NewIds;
    });
#else
    [[ChatsManager ManagerForCallBack] PerformMessagesChangedEvent:[Ids mutableCopy]];
#endif
}

- (void)HandleHistory:(NSArray *)Ids {
#ifdef CallbackAggregation
    dispatch_async(self.HistoryQueue, ^{
        NSMutableSet *NewIds = [NSMutableSet setWithArray:Ids];
        [NewIds unionSet:self.HistoryIds];
        self.HistoryIds = NewIds;
    });
#else
    [[HistoryManager Manager] PerformHistoryChangedEvent:[Ids mutableCopy]];
#endif
}
@end
