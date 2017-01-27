//
//  ChatsManager.m
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

#import "ChatsManager.h"
#import "ContactsManager.h"
#import "UiLogger.h"
#import "UiNotificationsManager.h"
#import "SystemNotificationsManager.h"

static ChatsManager* ChatsManagerSingleton = nil;
static dispatch_once_t ChatsManagerSingletonOnceToken;

@interface ChatsManager ()

@property dispatch_queue_t ChatsSerialQueue;

@property NSMutableArray *ChatsListMutable;

@property NSMutableDictionary *ChatsMessagesMutable;
@property NSMutableArray *MessagesToBeSendAsLocalNotification;
@property NSMutableDictionary *ChatsMessagesWaitingToBeSend;
@property UIBackgroundTaskIdentifier BGSendWaitingMessageTask;

@property NSNumber *ThrottledSignalSent;

@property NSMutableDictionary *ChatChangedIds;

@end

@implementation ChatUpdateSignalObject

- (instancetype)initWithChatId:(NSString *) ChatId AndState:(ChatsUpdatingState) State
{
    if (self = [super init]) {
        
        self.ChatId = ChatId;
        self.State = State;
        self.NewChatId = ChatId;
    }
    return self;
}
- (instancetype)initWithChatId:(NSString *) ChatId State:(ChatsUpdatingState) State AndNewChatId:(NSString *)NewChatId
{
    if (self = [super init]) {
        
        self.ChatId = ChatId;
        self.State = State;
        self.NewChatId = NewChatId;
    }
    return self;
}

@end


@implementation ChatMessagesUpdateSignalObject

- (instancetype)initWithChatId:(NSString *) ChatId AndState:(ChatsMessagesUpdatingState) State
{
    self = [super init];
    if (self) {
        
        self.ChatId = ChatId;
        
        self.State = State;
        
    }
    return self;
}

@end

@interface ChatsManager()

@property NSNumber *AllChatsFetched;

@property NSNumber *Active;

@end;

@implementation ChatsManager
{
    BOOL AllInited;
}

+ (instancetype) Manager
{
    return [self Chats];
}

+ (instancetype) ManagerForCallBack
{
    if(ChatsManagerSingleton && [ChatsManagerSingleton.AllChatsFetched boolValue])
    {
        return [self Chats];
    }
    
    return nil;
}

+ (instancetype) Chats
{
    dispatch_once(&ChatsManagerSingletonOnceToken, ^{
        
        ChatsManagerSingleton = [[ChatsManager alloc] init];
        
        ChatsManagerSingleton.ChatsSerialQueue = dispatch_queue_create("ChatsSerialQueue", DISPATCH_QUEUE_SERIAL);
        ChatsManagerSingleton.ViewModelQueue = dispatch_queue_create("ChatsViewModelQueue", DISPATCH_QUEUE_SERIAL);
        ChatsManagerSingleton.ViewModelScheduler = [[RACTargetQueueScheduler alloc]initWithName:@"ChatsViewModelScheduler" queue:ChatsManagerSingleton.ViewModelQueue];
        ChatsManagerSingleton.ManagerScheduler = [[RACTargetQueueScheduler alloc]initWithName:@"ChatsManagerScheduler" queue:ChatsManagerSingleton.ChatsSerialQueue];
        ChatsManagerSingleton.DispatchGroup = dispatch_group_create();
        
    });
    
    [ChatsManagerSingleton InitAll];
    
    return ChatsManagerSingleton;
}

+ (void) Destroy
{
    if(ChatsManagerSingleton)
    {
        ChatsManagerSingleton.ChatsSerialQueue = nil;
        ChatsManagerSingleton = nil;
        ChatsManagerSingletonOnceToken = 0;
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
        AllInited = YES;
        
        self.ChatsList = [NSArray new];
        self.ChatsListMutable = [NSMutableArray new];
        self.ChatsMessages = [NSDictionary new];
        self.ChatsMessagesMutable = [NSMutableDictionary new];
        
        self.MessagesToBeSendAsLocalNotification = [NSMutableArray new];
        self.ChatsMessagesWaitingToBeSend = [NSMutableDictionary new];
        self.ChatChangedIds = [NSMutableDictionary new];
        
        self.ChatsListState = ChatsListLoadingStateNone;
        
        self.ChatsListStateSignal = RACObserve(self, ChatsListState);
        self.ChatUpdateSignal = RACObserve(self, ChatUpdate);
        self.ChatMessagesUpdateSignal = RACObserve(self, ChatMessagesUpdate);
        
        
        @weakify(self);
        
        [[self.ChatsListStateSignal deliverOn:self.ManagerScheduler] subscribeNext:^(id x) {
            @strongify(self);
            [self CalcNewMessagesCount];
        }];
        
        [[[self.ChatsListStateSignal throttle:0.3] deliverOn:self.ManagerScheduler] subscribeNext:^(id x) {
            @strongify(self);
            [self ReSendWaitingMessages];
        }];
        
        
        //Artificial Chat Callback Signals
        
        RACSignal *ContactUpdate = [[[[ContactsManager Contacts].ContactUpdateSignal deliverOn:self.ManagerScheduler]
            filter:^BOOL(ContactUpdateSignalObject *ContactUpdate) {
                return (ContactUpdate.State != ContactUpdatingStateNone);
            }]
            map:^id(ContactUpdateSignalObject *ContactUpdate) {
            
                NSMutableArray *UpdatedChats = [NSMutableArray new];
                
                @strongify(self);
                for(ObjC_ChatModel *Chat in [self.ChatsList copy]) {
                    for(ObjC_ContactModel *Contact in [Chat.Contacts copy]) {
                        
                        if([Contact.DodicallId isEqualToString:ContactUpdate.Contact.DodicallId]) {
                            [UpdatedChats addObject:Chat.Id];
                            break;
                        }
                    }
                }
                
                return UpdatedChats;
            }];
        
        
        
        RACSignal *SubscriptionUpdate = [[[[ContactsManager Contacts].ContactSubscriptionUpdateSignal deliverOn:self.ManagerScheduler]
            filter:^BOOL(ContactSubscriptionUpdateSignalObject *SubscriptionUpdate) {
                return (SubscriptionUpdate.State != ContactSubscriptionUpdatingStateNone);
            }]
            map:^id(ContactSubscriptionUpdateSignalObject *SubscriptionUpdate) {
                @strongify(self);
                NSMutableArray *UpdatedChats = [NSMutableArray new];
                
                for(ObjC_ChatModel *Chat in [self.ChatsList copy]) {
                    for(ObjC_ContactModel *Contact in [Chat.Contacts copy]) {
                        
                        NSString *xmppId = [ContactsManager GetXmppIdOfContact:Contact];
                        if(xmppId && [xmppId isEqualToString:SubscriptionUpdate.XmppId]) {
                            [UpdatedChats addObject:Chat.Id];
                            break;
                        }
                    }
                }
                
                return UpdatedChats;
            }];
        
        
        self.ThrottledSignalSent = @(NO);
        
        [[[[[ContactUpdate merge:SubscriptionUpdate]
            combinePreviousWithStart:[NSMutableArray new]
            reduce:^id(NSMutableArray *Running, NSArray *UpdatedChats) {
                @strongify(self);
                if([self.ThrottledSignalSent boolValue])
                    Running = [NSMutableArray new];
                
                for(NSString *NewId in UpdatedChats) {
                    if(![Running containsObject:NewId])
                        [Running addObject:NewId];
                }
                
                self.ThrottledSignalSent = @(NO);
            
                return Running;
            }]
            throttle:0.3] deliverOn:self.ManagerScheduler ]
            subscribeNext:^(NSMutableArray <NSString *> *UpdatedChats) {
                @strongify(self);
                
                if(UpdatedChats && [UpdatedChats count] > 0)
                    [self PerformChatsChangedEvent:UpdatedChats];
                
                self.ThrottledSignalSent = @(YES);
            }];
        
        
        [[[[RACObserve(self, Active) ignore:nil] filter:^BOOL(NSNumber *Active) {
            return ![Active boolValue];
        }] deliverOn:self.ViewModelScheduler] subscribeNext:^(id x) {
            
            @strongify(self);
            
            self.ChatsListMutable = [NSMutableArray new];
            self.ChatsList = [NSArray new];
            
            self.ChatsListState = ChatsListLoadingStateFinishedFail;
            
            self.ChatsMessagesMutable = [NSMutableDictionary new];
            self.ChatsMessages = [NSDictionary new];

            
            self.MessagesToBeSendAsLocalNotification = [NSMutableArray new];
            self.ChatsMessagesWaitingToBeSend = [NSMutableDictionary new];
            self.ChatChangedIds = [NSMutableDictionary new];
            
            [self CalcNewMessagesCount];

            
            self.AllChatsFetched = @NO;
            
        }];

        
        
        //[self GetAllChats];
    }
}

#pragma mark - Chats list

- (void) GetAllChats
{
    
    dispatch_queue_t GetAllChatsQueue = dispatch_get_global_queue(QOS_CLASS_USER_INTERACTIVE,0);
    
    if([[UIApplication sharedApplication] applicationState] == UIApplicationStateBackground)
        GetAllChatsQueue = self.ChatsSerialQueue;
    
    dispatch_group_async(self.DispatchGroup, GetAllChatsQueue, ^{
        
        self.ChatsListState = ChatsListLoadingStateInProgress;
        
        self.AllChatsFetched = @YES;
        
        NSDate *MethodStart = [NSDate date];
        
        BOOL result = [[AppManager app].Core GetAllChats:self.ChatsListMutable];
        
        NSDate *MethodFinish = [NSDate date];
        
        NSTimeInterval ExecutionTime = [MethodFinish timeIntervalSinceDate:MethodStart];
        
        [UiLogger WriteLogInfo:[NSString stringWithFormat:@"ChatsManager:Core GetAllChats:ExecutionTime = %f", ExecutionTime]];
        
            if(result)
            {
                [UiLogger WriteLogInfo:[NSString stringWithFormat:@"ChatsManager:GetAllChats: Chats fetched: %lu", (unsigned long)[self.ChatsListMutable count]]];
                
                [self SortAllChatsByLastUpdatedDate];
                
                NSArray *ChatsImmutableCopy = [self.ChatsListMutable copy];
                
                dispatch_async(self.ViewModelQueue, ^{
                    
                    if([self.Active boolValue])
                    {
                        self.ChatsList = ChatsImmutableCopy;
                        self.ChatsListState = ChatsListLoadingStateFinishedSuccess;
                    }
                    else
                    {
                        self.ChatsList = [NSArray new];
                        self.ChatsListMutable = [NSMutableArray new];
                        self.ChatsListState = ChatsListLoadingStateFinishedFail;
                    }
                    
                });
            }
            else
            {
                [UiLogger WriteLogInfo:@"ChatsManager:GetAllChats: Failed"];
                
                dispatch_async(self.ViewModelQueue, ^{
                    self.ChatsListState = ChatsListLoadingStateFinishedFail;
                });
            }
    });
}

- (void) PerformChatsChangedEvent:(NSMutableArray *) ChatsIds
{
    NSMutableArray *ChangedChats = [[NSMutableArray alloc] init];
    
    NSMutableArray *RemovedChats = [[NSMutableArray alloc] init];
    
    dispatch_group_async(self.DispatchGroup, self.ChatsSerialQueue, ^{
        
        [[AppManager app].Core GetChatsByIds:ChatsIds:ChangedChats];
        
        for(NSString * ChatId in ChatsIds)
        {
            BOOL Found = NO;
            
            for(ObjC_ChatModel *ChangedChat in ChangedChats)
            {
                if(ChangedChat.Id && ChangedChat.Id.length && [ChangedChat.Id isEqualToString:ChatId])
                {
                    Found = YES;
                    break;
                }
            }
            
            if(!Found)
            {
                //Checks in immutable list
                ObjC_ChatModel *RemovedChat = [self GetChatById:ChatId];
                
                if(RemovedChat)
                {
                    [RemovedChats addObject:RemovedChat];
                }
            }
        }
        
        [self PerformChatsChangedEvent:ChangedChats:RemovedChats];
    });
}


- (void) PerformChatsChangedEvent: (NSMutableArray *) ChangedChats : (NSMutableArray *) RemovedChats
{
    [UiLogger WriteLogInfo:[NSString stringWithFormat:@"PerformChatsChangedEvent: ChangedChats: %lu; RemovedChats: %lu;", (unsigned long)[ChangedChats count], (unsigned long)[RemovedChats count]]];
    
    NSMutableArray<ChatUpdateSignalObject *> *UpdateSignals = [NSMutableArray new];
    NSMutableArray<ChatUpdateSignalObject *> *IdUpdateSignals = [NSMutableArray new];
    
    for (ObjC_ChatModel * Chat in ChangedChats) {
        ChatUpdateSignalObject *ChatUpdate = [self AddOrReplaceChat:Chat];
        
        if(ChatUpdate)
            [UpdateSignals addObject:ChatUpdate];
        
        NSString *OldChatId = [self.ChatChangedIds objectForKey:Chat.Id];
        
        if(OldChatId && OldChatId.length) {
            ChatUpdateSignalObject *IdUpdate = [[ChatUpdateSignalObject alloc] initWithChatId:OldChatId State:ChatsUpdatingStateIdChanged AndNewChatId:Chat.Id];
            [IdUpdateSignals addObject:IdUpdate];
            [self.ChatChangedIds removeObjectForKey:Chat.Id];
        }
    }
     
    for (ObjC_ChatModel * Chat in RemovedChats) {
        ChatUpdateSignalObject *ChatUpdate = [self RemoveChat:Chat];
        
        if(ChatUpdate)
            [UpdateSignals addObject:ChatUpdate];
    }
    
    [self SortAllChatsByLastUpdatedDate];
    
    [UiLogger WriteLogInfo:[NSString stringWithFormat:@"PerformChatsChangedEvent: Chats after sort: %lu", (unsigned long)[[ChatsManager Chats].ChatsListMutable count]]];
    
    
    NSArray *ChatsListImmutableCopy = [self.ChatsListMutable copy];
    
    
    dispatch_async(self.ViewModelQueue, ^{

        if([self.Active boolValue])
        {
            self.ChatsList = ChatsListImmutableCopy;
            
            if([IdUpdateSignals count] || [UpdateSignals count])
            {
                for(ChatUpdateSignalObject *ChatIdUpdate in IdUpdateSignals)
                {
                    [self setChatUpdate:ChatIdUpdate];
                }
                
                for(ChatUpdateSignalObject *ChatUpdate in UpdateSignals)
                {
                    [self setChatUpdate:ChatUpdate];
                }
                
                [self setChatUpdate:nil];
                
                [self setChatsListState:ChatsListLoadingStateUpdated];
            }

        }
        else
        {
            self.ChatsList = [NSArray new];
            self.ChatsListMutable = [NSMutableArray new];
            self.ChatsListState = ChatsListLoadingStateFinishedFail;
        }
        
        
    });
    
}

- (ChatUpdateSignalObject *) AddOrReplaceChat:(ObjC_ChatModel *) Chat
{
    //[UiLogger WriteLogInfo:@"AddOrReplaceChat"];
    //[UiLogger WriteLogDebug:[CoreHelper ChatModelDescription:Chat]];
    
    ChatUpdateSignalObject *ChatUpdate;
    NSInteger ChatIndex = [self FindChatIndexMutable:Chat];
    
    if(ChatIndex != NSNotFound)
    {
        [self.ChatsListMutable replaceObjectAtIndex:ChatIndex withObject:Chat];
        
        [UiLogger WriteLogInfo:[NSString stringWithFormat:@"AddOrReplaceChat:ChatsUpdatingStateUpdated: %@",Chat.Id]];
        
        ChatUpdate = [[ChatUpdateSignalObject alloc] initWithChatId:Chat.Id AndState:ChatsUpdatingStateUpdated];
    }
    else
    {
        [self.ChatsListMutable addObject:Chat];
        
        [UiLogger WriteLogInfo:[NSString stringWithFormat:@"AddOrReplaceChat:ChatsUpdatingStateAdded: %@",Chat.Id]];
        
        ChatUpdate = [[ChatUpdateSignalObject alloc] initWithChatId:Chat.Id AndState:ChatsUpdatingStateAdded];
    }
    
    return ChatUpdate;
    
}

- (ChatUpdateSignalObject *) RemoveChat:(ObjC_ChatModel *) Chat
{
    ChatUpdateSignalObject *ChatUpdate;
    NSInteger ChatIndex = [self FindChatIndexMutable:Chat];
    
    if(ChatIndex != NSNotFound)
    {
        //[UiLogger WriteLogInfo:@"RemoveChat"];
        //[UiLogger WriteLogDebug:[CoreHelper ChatModelDescription:Chat]];
        
        [self.ChatsListMutable removeObjectAtIndex:ChatIndex];
        
        [UiLogger WriteLogInfo:[NSString stringWithFormat:@"RemoveChat:ChatsUpdatingStateRemoved: %@",Chat.Id]];
        
        ChatUpdate = [[ChatUpdateSignalObject alloc] initWithChatId:Chat.Id AndState:ChatsUpdatingStateRemoved];
        
        if([self.ChatsMessagesMutable objectForKey:Chat.Id])
        {
            [self.ChatsMessagesMutable removeObjectForKey:Chat.Id];
            
            NSDictionary *ChatMessagesImmutableCopy = [self.ChatsMessagesMutable copy];
            
            dispatch_async(self.ViewModelQueue, ^{
                
                self.ChatsMessages = ChatMessagesImmutableCopy;
                
            });
            
            [self setChatMessagesUpdate:[[ChatMessagesUpdateSignalObject alloc] initWithChatId:Chat.Id AndState:ChatsMessagesUpdatingStateListUpdated]];
        }
        
        
    }
    
    return ChatUpdate;
}

//NOT USED
//- (void) RemoveChatByID:(ChatIdType) ChatId
//{
//    NSInteger ChatIndex = [self FindChatIndexById:ChatId];
//    
//    if(ChatIndex != NSNotFound)
//    {
//        [UiLogger WriteLogInfo:@"RemoveChat"];
//        //[UiLogger WriteLogDebug:[CoreHelper ChatModelDescription:Chat]];
//        
//        [self.ChatsList removeObjectAtIndex:ChatIndex];
//        
//        [UiLogger WriteLogInfo:[NSString stringWithFormat:@"RemoveChat:ChatsUpdatingStateRemoved: %@",ChatId]];
//        
//        [self setChatUpdate:[[ChatUpdateSignalObject alloc] initWithChatId:ChatId AndState:ChatsUpdatingStateRemoved]];
//        
//    }
//    
//    if([self.ChatsMessages objectForKey:ChatId])
//    {
//        [self.ChatsMessages removeObjectForKey:ChatId];
//    }
//}

- (void) SortAllChatsByLastUpdatedDate
{
    NSSortDescriptor *SortDescriptorLastModifiedDate = [[NSSortDescriptor alloc] initWithKey:@"LastModifiedDate" ascending:NO];
    
    NSSortDescriptor *SortDescriptorRownum = [[NSSortDescriptor alloc] initWithKey:@"lastMessage" ascending:NO comparator:^NSComparisonResult(ObjC_ChatMessageModel *obj1, ObjC_ChatMessageModel *obj2) {
        
        if(!obj1.Rownum || !obj2.Rownum)
            return (NSComparisonResult)NSOrderedSame;
        
        if(obj1.Rownum.integerValue == obj2.Rownum.integerValue)
            return (NSComparisonResult)NSOrderedSame;
        
        if(obj1.Rownum.integerValue > obj2.Rownum.integerValue)
            return (NSComparisonResult)NSOrderedDescending;
        else
            return (NSComparisonResult)NSOrderedAscending;
    }];
    
    NSArray *SortDescriptors = [NSArray arrayWithObjects: SortDescriptorLastModifiedDate, SortDescriptorRownum, nil];
    
    [self.ChatsListMutable sortUsingDescriptors:SortDescriptors];
}



- (NSInteger) FindChatIndex:(ObjC_ChatModel *) Chat
{
    if(Chat.Id && Chat.Id.length)
        return [self FindChatIndexById:Chat.Id InList:self.ChatsList];
    else
        return NSNotFound;
}

- (NSInteger) FindChatIndexMutable:(ObjC_ChatModel *) Chat
{
    if(Chat.Id && Chat.Id.length)
        return [self FindChatIndexById:Chat.Id InList:self.ChatsListMutable];
    else
        return NSNotFound;
}

- (NSInteger) FindChatIndexById:(ChatIdType) ChatId InList:(NSArray<ObjC_ChatModel *> *)List
{
    if(List && [List count])
    {
        for(ObjC_ChatModel *Chat in List) {
            if(Chat.Id && Chat.Id.length && [Chat.Id isEqualToString:ChatId]) {
                return [List indexOfObject:Chat];
            }
        }

    }
    
    return NSNotFound;
}


- (ObjC_ChatModel *) GetChatById:(ChatIdType) ChatId
{
    NSInteger ChatIndex = [self FindChatIndexById:ChatId InList:self.ChatsList];
    
    if(ChatIndex != NSNotFound)
        return [self.ChatsList objectAtIndex:ChatIndex];
    
    return nil;
}


- (void) CalcNewMessagesCount
{
    int Count = 0;
    
    for (ObjC_ChatModel * Chat in [self.ChatsList copy])
    {
        Count += Chat.NewMessagesCount;
    }
    
    if([self.NewMessagesCount intValue] != Count)
    {
        self.NewMessagesCount = [NSNumber numberWithInt:Count];
        
        [[UiNotificationsManager NotificationsManager] PerformChatsNewMessagesCounterChangeEvent:self.NewMessagesCount];
    }
}

- (ObjC_ChatModel *) FindP2PChatWithContact:(ObjC_ContactModel *) Contact
{
    return nil;
}

- (void) GetOrCreateP2PChatWithContact:(ObjC_ContactModel *) Contact AndReturnItInCallback:(void (^)(ObjC_ChatModel *)) Callback
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        ObjC_ChatModel *ChatModel = [[ObjC_ChatModel alloc] init];
        
        BOOL Result = [[AppManager app].Core CreateChatWithContacts:[NSMutableArray arrayWithObjects:Contact, nil]:ChatModel];
        
        dispatch_async(self.ViewModelQueue, ^{
            if(Result)
            {
                Callback(ChatModel);
            }
            else
            {
                Callback(nil);
            }
        });
    });
}

- (void) GetOrCreateMultiChatWithContacts:(NSArray *) Contacts AndReturnItInCallback:(void (^)(ObjC_ChatModel *)) Callback {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        ObjC_ChatModel *ChatModel = [[ObjC_ChatModel alloc] init];
        
        BOOL Result = [[AppManager app].Core CreateChatWithContacts:[NSMutableArray arrayWithArray:Contacts]:ChatModel];
        
        dispatch_async(self.ViewModelQueue, ^{
            if(Result)
            {
                Callback(ChatModel);
            }
            else
            {
                Callback(nil);
            }
        });
    });
}

- (void) GetOrLoadFromCoreChatById:(ChatIdType) ChatId AndReturnItInCallback:(void (^)(ObjC_ChatModel *)) Callback
{
    
    if([self GetChatById:ChatId])
    {
        Callback([self GetChatById:ChatId]);
    }
    
    else
    {
        NSMutableArray *Chats = [[NSMutableArray alloc] init];
        
        NSMutableArray *ChatsIds = [[NSMutableArray alloc] init];
        
        [ChatsIds addObject:ChatId];
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            
            [[AppManager app].Core GetChatsByIds:ChatsIds:Chats];
            
            dispatch_async(self.ViewModelQueue, ^{
                
                if(Chats && [Chats count] == 1)
                {
                    Callback([Chats objectAtIndex:0]);
                }
                else
                {
                    Callback(nil);
                }
                
            });
        
        });
    }
}

- (void) ClearChats:(NSMutableArray <ChatIdType> *) ChatIds
{
    NSMutableArray *ChangedChats = [[NSMutableArray alloc] init];
    
    NSMutableArray *RemovedChats = [[NSMutableArray alloc] init];
    
    NSMutableArray *FailedToRemoveChats = [[NSMutableArray alloc] init];
    
    
    dispatch_group_async(self.DispatchGroup, self.ChatsSerialQueue, ^{
        
        [[AppManager app].Core ClearChats:ChatIds:FailedToRemoveChats];
        
        for(NSString * ChatId in ChatIds)
        {
            if (![FailedToRemoveChats containsObject: ChatId] ) {
                
                ObjC_ChatModel *RemovedChat = [self GetChatById:ChatId];
                
                if(RemovedChat)
                {
                    [RemovedChats addObject:RemovedChat];
                }
                
            }
        }
        
        [self PerformChatsChangedEvent:ChangedChats:RemovedChats];
    });
}

+ (void) UpdateChat:(ObjC_ChatModel *)Chat Title:(NSString *)Title {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [[AppManager app].Core RenameChat:Title :Chat];
    });
}

+ (void) UpdateChat:(NSString *)chatId WithNew:(NSMutableArray *)new AndRevokeUsers:(NSMutableArray *)revoke {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [[AppManager app].Core InviteAndRevokeChatMembers:chatId :new :revoke];
    });
}

+ (void) ForceChatSync:(ChatIdType)ChatId {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [[AppManager app].Core ForceChatSync:ChatId];
    });
}
#pragma mark - Chats messages


- (void) FetchChatMessages:(ChatIdType) ChatId
{
    if([self.ChatsMessages objectForKey:ChatId])
    {
        if([self.Active boolValue])
            [self setChatMessagesUpdate:[[ChatMessagesUpdateSignalObject alloc] initWithChatId:ChatId AndState:ChatsMessagesUpdatingStateListLoadingFinishedSuccess]];
        return;
    }
    
    [self setChatMessagesUpdate:[[ChatMessagesUpdateSignalObject alloc] initWithChatId:ChatId AndState:ChatsMessagesUpdatingStateListLoading]];
    
    dispatch_group_async(self.DispatchGroup, self.ChatsSerialQueue, ^{
        
        NSMutableArray<ObjC_ChatMessageModel *> *Messages = (NSMutableArray<ObjC_ChatMessageModel *> *)[[AppManager app].Core GetChatMessagesById:ChatId];
        
        [UiLogger WriteLogInfo:[NSString stringWithFormat:@"ChatsManager:GetChatMessages: messages fetched: %lu in chat %@", (unsigned long)[Messages count], ChatId]];
        
        [self.ChatsMessagesMutable setObject:Messages forKey:ChatId];
        [self SortMessagesByDateInChat:ChatId];
        
        NSDictionary *ChatMessagesImmutableCopy = [self.ChatsMessagesMutable copy];
        
        dispatch_async(self.ViewModelQueue, ^{
            if([self.Active boolValue])
            {
                self.ChatsMessages = ChatMessagesImmutableCopy;
                [self setChatMessagesUpdate:[[ChatMessagesUpdateSignalObject alloc] initWithChatId:ChatId AndState:ChatsMessagesUpdatingStateListLoadingFinishedSuccess]];
            }
            else
            {
                self.ChatsMessages = [NSDictionary new];
                self.ChatsMessagesMutable = [NSMutableDictionary new];
            }
        });
        
    });
}


- (void) PerformMessagesChangedEvent:(NSMutableArray *) MessagesIds
{
    NSMutableArray *ChangedMessages = [NSMutableArray new];
    
    NSMutableArray *RemovedMessages = [NSMutableArray new];
    
    dispatch_group_async(self.DispatchGroup, self.ChatsSerialQueue, ^{
        
        BOOL Result = [[AppManager app].Core GetChatMessagesByIds:MessagesIds:ChangedMessages];
        
        [self PerformMessagesChangedEvent:ChangedMessages:RemovedMessages];
    });
}


- (void) PerformMessagesChangedEvent: (NSMutableArray *) ChangedMessages : (NSMutableArray *) RemovedMessages
{
    [UiLogger WriteLogInfo:[NSString stringWithFormat:@"PerformMessagesChangedEvent: ChangedMessages: %lu; RemovedMessages: %lu;", (unsigned long)[ChangedMessages count], (unsigned long)[RemovedMessages count]]];
    
    NSMutableSet *ChangedChatIds = [NSMutableSet new];
    
    NSMutableArray *ChatMessagesUpdates = [NSMutableArray new];
    
    NSMutableArray<ChatUpdateSignalObject *> *IdUpdateSignals = [NSMutableArray new];
    
    for (ObjC_ChatMessageModel * Message in ChangedMessages)
    {
        ChatMessagesUpdateSignalObject *MessageUpdate = [self AddOrReplaceMessage:Message];
        
        if(MessageUpdate)
            [ChatMessagesUpdates addObject:MessageUpdate];
        
        [ChangedChatIds addObject:Message.chatId];
        
        NSString *OldChatId = [self.ChatChangedIds objectForKey:Message.chatId];
        if(OldChatId && OldChatId.length) {
            ChatUpdateSignalObject *IdUpdate = [[ChatUpdateSignalObject alloc] initWithChatId:OldChatId State:ChatsUpdatingStateIdChanged AndNewChatId:Message.chatId];
            [IdUpdateSignals addObject:IdUpdate];
            [self.ChatChangedIds removeObjectForKey:Message.chatId];
        }
    }
    
    for (ObjC_ChatMessageModel * Message in RemovedMessages)
    {
        ChatMessagesUpdateSignalObject *MessageUpdate = [self RemoveMessage:Message];
        
        if(MessageUpdate)
            [ChatMessagesUpdates addObject:MessageUpdate];
        
        [ChangedChatIds addObject:Message.chatId];
    }
    
    
    for (ChatIdType ChatId in ChangedChatIds)
    {
        [self SortMessagesByDateInChat:ChatId];
    }
    
    NSDictionary *ChatMessagesImmutableCopy = [self.ChatsMessagesMutable copy];
    
    dispatch_async(self.ViewModelQueue, ^{
        
        if([self.Active boolValue])
        {
            self.ChatsMessages = ChatMessagesImmutableCopy;
            
            if([IdUpdateSignals count] || [ChatMessagesUpdates count])
            {
                for(ChatUpdateSignalObject *UpdateSignal in IdUpdateSignals)
                {
                    [self setChatUpdate:UpdateSignal];
                }
                
                [self setChatUpdate:nil];
                
                for(ChatMessagesUpdateSignalObject *UpdateSignal in ChatMessagesUpdates)
                {
                    [self setChatMessagesUpdate:UpdateSignal];
                }
                
                [self setChatMessagesUpdate:nil];
                
                for (ChatIdType ChatId in ChangedChatIds)
                {
                    [self setChatMessagesUpdate:[[ChatMessagesUpdateSignalObject alloc] initWithChatId:ChatId AndState:ChatsMessagesUpdatingStateListUpdated]];
                }
            }
        }
        else
        {
            self.ChatsMessages = [NSDictionary new];
            self.ChatsMessagesMutable = [NSMutableDictionary new];
        }
        
        
    });
    
}


- (ChatMessagesUpdateSignalObject *) AddOrReplaceMessage:(ObjC_ChatMessageModel *) Message
{
    
    [UiLogger WriteLogInfo:@"AddOrReplaceMessage"];
    
    NSInteger MessageIndex = [self FindMessageIndex:Message];
    
    ChatMessagesUpdateSignalObject *MessageUpdate;
    
    if(MessageIndex != NSNotFound)
    {
        [[self GetChatMessages:Message.chatId] replaceObjectAtIndex:MessageIndex withObject:Message];
        
        MessageUpdate = [[ChatMessagesUpdateSignalObject alloc] initWithChatId:Message.chatId AndState:ChatsMessagesUpdatingStateMessageUpdated];
    }
    else
    {
        if([self GetChatMessages:Message.chatId])
        {
            [[self GetChatMessages:Message.chatId] addObject:Message];
            
            MessageUpdate = [[ChatMessagesUpdateSignalObject alloc] initWithChatId:Message.chatId AndState:ChatsMessagesUpdatingStateMessageAdded];
        }
        
    }
    
    return MessageUpdate;
}


- (ChatMessagesUpdateSignalObject *) RemoveMessage:(ObjC_ChatMessageModel *) Message
{
    ChatMessagesUpdateSignalObject *MessageUpdate;
    
    NSInteger MessageIndex = [self FindMessageIndex:Message];
    
    if(MessageIndex != NSNotFound)
    {
        [UiLogger WriteLogInfo:@"RemoveMessage"];
        
        [[self GetChatMessages:Message.chatId] removeObjectAtIndex:MessageIndex];
        
        MessageUpdate = [[ChatMessagesUpdateSignalObject alloc] initWithChatId:Message.chatId AndState:ChatsMessagesUpdatingStateMessageRemoved];
    }
    
    return MessageUpdate;
}


- (NSInteger) FindMessageIndex: (ObjC_ChatMessageModel *) Message  InChatId:(ChatIdType) ChatId
{
    if(!(Message && Message.Id && Message.Id.length && ChatId && ChatId.length))
        return NSNotFound;
    
    NSArray *LocalChatMessages = [self GetChatMessages:ChatId];
    
    if(!(LocalChatMessages && LocalChatMessages.count))
        return NSNotFound;
    
    
    for(ObjC_ChatMessageModel *LocalMessage in LocalChatMessages)
    {
        if(LocalMessage.Id && LocalMessage.Id.length && [LocalMessage.Id isEqualToString:Message.Id])
            return [LocalChatMessages indexOfObject:LocalMessage];
    }
    
    return NSNotFound;
}


- (NSInteger) FindMessageIndex: (ObjC_ChatMessageModel *) Message
{
    if(Message.chatId && Message.chatId.length > 0)
        return  [self FindMessageIndex:Message InChatId:Message.chatId];
    
    return NSNotFound;
}


- (NSMutableArray<ObjC_ChatMessageModel *> *) GetChatMessages:(ChatIdType) ChatId
{
    if([self.ChatsMessagesMutable objectForKey:ChatId])
        return [self.ChatsMessagesMutable objectForKey:ChatId];
    
    return nil;
}


- (void) SortMessagesByDateInChat:(ChatIdType) ChatId
{
    if([self GetChatMessages:ChatId])
    {
        NSSortDescriptor *SortDescriptorByDate = [[NSSortDescriptor alloc] initWithKey:@"SendTime" ascending:YES];
        
        NSSortDescriptor *SortDescriptorByRowNum = [[NSSortDescriptor alloc] initWithKey:@"Rownum" ascending:YES];
        
        NSArray *SortDescriptors = [NSArray arrayWithObjects:SortDescriptorByDate, SortDescriptorByRowNum, nil];
        
        [[self GetChatMessages:ChatId] sortUsingDescriptors:SortDescriptors];
    }
}



- (void) PerformSendMessageSystemLocalNotifications
{
    
    NSSortDescriptor *SortDescriptorByDate = [[NSSortDescriptor alloc] initWithKey:@"SendTime" ascending:YES];
    
    NSArray *SortDescriptors = [NSArray arrayWithObjects:SortDescriptorByDate, nil];
    
    [self.MessagesToBeSendAsLocalNotification  sortUsingDescriptors:SortDescriptors];
    
    NSMutableArray *Messages = [self.MessagesToBeSendAsLocalNotification copy];
    
    self.MessagesToBeSendAsLocalNotification = [[NSMutableArray alloc] init];
    
    for (ObjC_ChatMessageModel *Message in Messages ) {
        
        if(![Message.Sender.Iam boolValue] && ![Message.Readed boolValue])
        {
            [ChatsManager SendMessageSystemLocalNotification:Message];
        }
        
    }
    
}


+ (void) SendMessageSystemLocalNotification: (ObjC_ChatMessageModel *)Message
{
    SystemNotificationModel *Notification = [[SystemNotificationModel alloc] init];
    
    [Notification setSystemType:SystemNotificationModelSystemTypeLocal];
    [Notification setUserType:SystemNotificationModelUserTypeXmpp];
    
    [Notification setTitle:[ChatsManager GetMessageSenderFirstAndLastName:Message]];
    [Notification setBody:[ChatsManager MessageToText:Message]];
    
    [Notification setAction:SystemNotificationModelSoundXmpp];
    [Notification setHasAction:YES];
    
    [Notification setSound:SystemNotificationModelActionXmpp];
    
    [[SystemNotificationsManager SystemNotifications] SendSystemLocalNotification:Notification];
}


+ (void) SendMessage: (NSString *)MessageText ToChat:(ChatIdType) ChatId
{
    dispatch_async([ChatsManager Chats].ChatsSerialQueue, ^{
        
        NSDate *Now = [NSDate new];
        
    
        //Update messages
        NSString * MessageId = [[AppManager app].Core PregenerateMessageId];
        
        ObjC_ChatMessageModel *Message = [self CreateNewTextMessage:MessageText WithId:MessageId InChatId:ChatId];
        
        [Message setServered:[NSNumber numberWithBool:NO]];
        
        [Message setReaded:[NSNumber numberWithBool:YES]];
        
        [Message setSendTime:Now];
        
        NSMutableArray *ChangedMessages = [NSMutableArray arrayWithObject:Message];
        
        [[ChatsManager Chats] PerformMessagesChangedEvent:ChangedMessages :nil];
        
        
        // Update chats
        ObjC_ChatModel *Chat = [[ChatsManager Chats] GetChatById:ChatId];
        
        if(Chat)
        {
            Chat.lastMessage = Message;
            
            Chat.LastModifiedDate = Now;
            
            NSMutableArray *ChangedChats = [NSMutableArray arrayWithObject:Chat];
            
            [[ChatsManager Chats] PerformChatsChangedEvent:ChangedChats:nil];
        }
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            
            [[AppManager app].Core SendTextMessage:MessageId :ChatId :MessageText];
        });
    });

}

+ (void) SendMessageOrWaitChat: (NSString *)MessageText ToChat:(ChatIdType) ChatId
{
    [UiLogger WriteLogInfo:[NSString stringWithFormat:@"ChatsManager: SendMessageOrWaitChat: ChatId: %@", ChatId]];
    [UiLogger WriteLogDebug:[NSString stringWithFormat:@"SIGNALING: Inside SendMessageOrWaitChat - %@", MessageText]];
    
    if([[UIApplication sharedApplication] applicationState] == UIApplicationStateBackground)
    { 
        [UiLogger WriteLogInfo:@"ChatsManager: Execute SendMessageOrWaitChat background task"];
        
        if([ChatsManager Chats].BGSendWaitingMessageTask && [ChatsManager Chats].BGSendWaitingMessageTask != UIBackgroundTaskInvalid)
        {
            [[UIApplication sharedApplication] endBackgroundTask:[ChatsManager Chats].BGSendWaitingMessageTask];
            [ChatsManager Chats].BGSendWaitingMessageTask = UIBackgroundTaskInvalid;
        }
        
        [ChatsManager Chats].BGSendWaitingMessageTask = [[UIApplication sharedApplication] beginBackgroundTaskWithName:@"SendMessageOrWaitChat" expirationHandler:^{
            
            [[UIApplication sharedApplication] endBackgroundTask:[ChatsManager Chats].BGSendWaitingMessageTask];
            [ChatsManager Chats].BGSendWaitingMessageTask = UIBackgroundTaskInvalid;
            
        }];
        
    }
    
    dispatch_async([ChatsManager Chats].ChatsSerialQueue, ^{
        
        [self SendMessage:MessageText ToChat:ChatId];
        [self ForceChatSync:ChatId];
        
        
//        ObjC_ChatModel *Chat;
//        
//        if([AppManager Manager].UserSession.IsXmppReady)
//            Chat = [[ChatsManager Chats] GetChatById:ChatId];
//        
//        if(Chat)
//        {
//            [self SendMessage:MessageText ToChat:ChatId];
//            [UiLogger WriteLogDebug:[NSString stringWithFormat:@"SIGNALING: Chat Exist, SendMessage - %@", MessageText]];
//        }
//        else
//        {
//            NSMutableArray <NSString *> *MessagesToSend;
//            
//            if([[ChatsManager Chats].ChatsMessagesWaitingToBeSend objectForKey:ChatId])
//            {
//                MessagesToSend = (NSMutableArray <NSString *> *)[[ChatsManager Chats].ChatsMessagesWaitingToBeSend objectForKey:ChatId];
//            }
//            else
//            {
//                MessagesToSend = [NSMutableArray new];
//                [[ChatsManager Chats].ChatsMessagesWaitingToBeSend setObject:MessagesToSend forKey:ChatId];
//            }
//            [UiLogger WriteLogDebug:[NSString stringWithFormat:@"SIGNALING: Chat NOT Exist, Save MessageSendMessage - %@", MessageText]];
//            [MessagesToSend addObject:MessageText];
//        }
//        
//        [self ForceChatSync:ChatId];

    });
}


- (void) ReSendWaitingMessages
{
    dispatch_async([ChatsManager Chats].ChatsSerialQueue, ^{
        [UiLogger WriteLogDebug:[NSString stringWithFormat:@"SIGNALING: Inside reSendWaitingMessages"]];
        for (NSString *ChatId in [[ChatsManager Chats].ChatsMessagesWaitingToBeSend allKeys])
        {
            NSMutableArray <NSString *> *MessagesToSend = (NSMutableArray <NSString *> *)[[ChatsManager Chats].ChatsMessagesWaitingToBeSend objectForKey:ChatId];
            
            if(MessagesToSend && [MessagesToSend count] > 0)
            {
                ObjC_ChatModel *Chat = [[ChatsManager Chats] GetChatById:ChatId];
            
                if(Chat)
                {
                    for (NSString *Message in [MessagesToSend copy])
                    {
                        [UiLogger WriteLogDebug:[NSString stringWithFormat:@"SIGNALING: ResendingWaitingMessage - %@", Message]];
                        [ChatsManager SendMessage:Message ToChat:ChatId];
                    }
                    
                    [[ChatsManager Chats].ChatsMessagesWaitingToBeSend setObject:[NSMutableArray new] forKey:ChatId];
                }
            }
        }
        
    });
}


+ (void) SetChatReadedWithLastUnreadMessageId:(NSString *) MessageId InChatId:(NSString *) ChatId
{
    dispatch_async([ChatsManager Chats].ChatsSerialQueue, ^{
        
        [UiLogger WriteLogInfo:[NSString stringWithFormat:@"ChatsManager:SetChatReaded:%@",ChatId]];
        
        NSArray *ChatMessages = [[ChatsManager Chats] GetChatMessages:ChatId];
        
        if(!(ChatMessages && ChatMessages.count))
            return;
        
        for(ObjC_ChatMessageModel *ChatMessage in ChatMessages) {
            [ChatMessage setReaded:[NSNumber numberWithBool:YES]];
            
            if([MessageId isEqualToString:ChatMessage.Id]) {
                ObjC_ChatModel *Chat = [[ChatsManager Chats] GetChatById:ChatId];
                
                if(Chat)
                {
                    Chat.NewMessagesCount = 0;
                    
                    if(Chat.lastMessage)
                        Chat.lastMessage.Readed = [NSNumber numberWithBool:YES];
                    
                    NSMutableArray *ChangedChats = [NSMutableArray arrayWithObject:Chat];
                    
                    [[ChatsManager Chats] PerformChatsChangedEvent:ChangedChats:nil];
                }
                break;
            }
        }
            
        [[AppManager app].Core MarkMessagesAsReaded:MessageId];
    });
}



#pragma mark - Chats helpers

+ (NSString *) GetTitleOfChat:(ObjC_ChatModel *) Chat
{
    NSString *Title = @"";
    
    if(Chat.Title && Chat.Title.length > 0)
    {
        Title = [Chat.Title copy];
    }
    else if([Chat.Contacts count] > 0)
    {
        int Index = 0;
        
        for (ObjC_ContactModel *Contact in Chat.Contacts)
        {
            if(![Contact.Iam boolValue])
            {
                if(Index > 0)
                    Title = [Title stringByAppendingString:@", "];
                
                Title = [Title stringByAppendingString:[NSString stringWithFormat:@"%@ %@",Contact.FirstName, Contact.LastName]];
                
                Index ++;
            }
        }
        
        if(Index == 0)
        {
            Title = NSLocalizedString(@"Title_ChatHasNoUsers", nil);
        }
    }
    else
    {
        Title = NSLocalizedString(@"Title_ChatHasNoName", nil);
    }
        
    
    
    return  Title;
}

+ (NSString *) GetMessageSenderFirstAndLastName:(ObjC_ChatMessageModel *) Message
{
    return [NSString stringWithFormat:@"%@ %@", Message.Sender.FirstName, Message.Sender.LastName];
}

+ (NSString *) MessageNotificationToText:(ObjC_ChatMessageModel *) Message
{
    NSString *Text = @"";
    
    if(!Message.NotificationData)
        return Text;
    
    
    NSString *ContactsString = @"";
    
    int ContactsIndex = 0;
    
    if(Message.NotificationData.Contacts && [Message.NotificationData.Contacts count] > 0)
    {

        for (ObjC_ContactModel *Contact in Message.NotificationData.Contacts)
        {
            if(ContactsIndex > 0)
                ContactsString = [ContactsString stringByAppendingString:@", "];
            
            ContactsString = [ContactsString stringByAppendingString:[NSString stringWithFormat:@"%@ %@",Contact.FirstName, Contact.LastName]];
            
            ContactsIndex ++;
        }
    }
    
    switch (Message.NotificationData.Type)
    {
        case ChatNotificationTypeInvite:
            Text = [NSString stringWithFormat:NSLocalizedString((ContactsIndex == 1) ? @"Message_ChatSystem_User%@AddedOneUser%@ToChat" :@"Message_ChatSystem_User%@AddedUsers%@ToChat", nil),[self GetMessageSenderFirstAndLastName:Message], ContactsString];
            break;
            
        case ChatNotificationTypeRevoke:
            Text = [NSString stringWithFormat:NSLocalizedString((ContactsIndex == 1) ? @"Message_ChatSystem_User%@RemovedOneUser%@FromChat" : @"Message_ChatSystem_User%@RemovedUsers%@FromChat", nil),[self GetMessageSenderFirstAndLastName:Message], ContactsString];
            break;
            
        case ChatNotificationTypeLeave:
            Text = [NSString stringWithFormat:NSLocalizedString(@"Message_ChatSystem_User%@LeavedChat", nil),[self GetMessageSenderFirstAndLastName:Message]];
            break;
            
        case ChatNotificationTypeRemove:
            Text = [NSString stringWithFormat:NSLocalizedString(@"Message_ChatSystem_User%@DeletedChat", nil),[self GetMessageSenderFirstAndLastName:Message]];
            break;
            
        case ChatNotificationTypeCreate:
            Text = [NSString stringWithFormat:NSLocalizedString(@"Message_ChatSystem_User%@CreatedChat", nil),[self GetMessageSenderFirstAndLastName:Message]];
            break;
            
        default:
            break;
    }
    
    return Text;
}

+ (NSString *) MessageToText:(ObjC_ChatMessageModel *) Message
{
    NSString *Text = @"";
    
    switch (Message.Type) {
        case ChatMessageTypeTextMessage:
            if([Message.Encrypted boolValue])
            {
                Text = NSLocalizedString(@"Message_ChatSystem_EncryptedMessage", nil);
            }
            else
            {
                Text = Message.StringContent;
            }
            
            break;
            
        case ChatMessageTypeSubject:
            Text = [NSString stringWithFormat:NSLocalizedString(@"Message_ChatSystem_User%@ChangeSubjectTo%@", nil), [self GetMessageSenderFirstAndLastName:Message], Message.StringContent];
            break;
            
        case ChatMessageTypeAudioMessage:
            Text = NSLocalizedString(@"Message_ChatSystem_AudioMessage", nil);
            break;
        
        case ChatMessageTypeNotification:
            Text = [self MessageNotificationToText:Message];
            break;
            
        case ChatMessageTypeContact:
            if(Message.ContactData)
            {
                NSString *ConatctDataTitle = [NSString stringWithFormat:@"%@ %@", Message.ContactData.FirstName, Message.ContactData.LastName];
                
                Text = [NSString stringWithFormat:NSLocalizedString(@"Message_ChatSystem_User%@SendContact%@", nil), Message.StringContent, ConatctDataTitle];
            }
            break;
            
        case ChatMessageTypeDeleter:
            Text = NSLocalizedString(@"Message_ChatSystem_MessageWasDeleted", nil);
            break;
            
        default:
            Text = Message.StringContent;
            break;
    }
    
    return  Text;
}

+ (ObjC_ChatMessageModel *) CreateNewTextMessage:(NSString *) MessageText WithId:(NSString *) Id InChatId:(NSString *) ChatId
{
    
    ObjC_ChatMessageModel *Message = [[ObjC_ChatMessageModel alloc] init];
    
    [Message setId:Id];
    
    [Message setChatId:ChatId];
    
    [Message setStringContent:MessageText];
    
    [Message setSender:[AppManager app].UserSession.MyProfile];
    
    [Message setSendTime:[NSDate date]];
    
    return Message;
}

+ (ChatsMessageDeliveryStatus) GetMessageDeliveryStatus:(ObjC_ChatMessageModel *) Message
{
    if(Message)
    {
        if(![Message.Servered boolValue] && [Message.Readed boolValue])
            return ChatsMessageDeliveryStatusSended;
        
        if([Message.Servered boolValue] && [Message.Readed boolValue])
            return ChatsMessageDeliveryStatusDeliveredToServer;
    }
    
    return  ChatsMessageDeliveryStatusNone;
}

+ (ObjC_ChatMessageModel *) CopyMessageModel: (ObjC_ChatMessageModel *) Message
{
    ObjC_ChatMessageModel *NewMessageModel = [[ObjC_ChatMessageModel alloc] init];
    
    NewMessageModel.Id = Message.Id;
    NewMessageModel.chatId = Message.chatId;
    NewMessageModel.Sender = Message.Sender;
    NewMessageModel.Servered = Message.Servered;
    NewMessageModel.SendTime = Message.SendTime;
    NewMessageModel.Readed = Message.Readed;
    NewMessageModel.Type = Message.Type;
    NewMessageModel.StringContent = Message.StringContent;
    NewMessageModel.ContactData = Message.ContactData;
    NewMessageModel.NotificationData = Message.NotificationData;
    NewMessageModel.Rownum = Message.Rownum;
    
    return NewMessageModel;
}

+ (BOOL) CompareMessageModel: (ObjC_ChatMessageModel *) FirstMessage WithMessageModel: (ObjC_ChatMessageModel *) SecondMessage
{
    //BOOL Result = NO;

    return [FirstMessage.Id isEqual: SecondMessage.Id] &&
    [FirstMessage.chatId isEqual: SecondMessage.chatId] &&
    FirstMessage.Sender == SecondMessage.Sender &&
    [FirstMessage.Servered isEqual: SecondMessage.Servered] &&
    [FirstMessage.SendTime isEqual: SecondMessage.SendTime] &&
    [FirstMessage.Readed boolValue] == [SecondMessage.Readed boolValue] &&
    FirstMessage.Type == SecondMessage.Type &&
    [FirstMessage.StringContent isEqual: SecondMessage.StringContent] &&
    FirstMessage.ContactData == SecondMessage.ContactData &&
    FirstMessage.NotificationData == SecondMessage.NotificationData &&
    [FirstMessage.Rownum intValue] == [SecondMessage.Rownum intValue];
    
    /*
    Result = [FirstMessage.Id isEqual: SecondMessage.Id];
    Result = [FirstMessage.chatId isEqual: SecondMessage.chatId];
    Result = FirstMessage.Sender == SecondMessage.Sender;
    Result = [FirstMessage.Servered isEqual: SecondMessage.Servered];
    Result = [FirstMessage.SendTime isEqual: SecondMessage.SendTime];
    Result = [FirstMessage.Readed isEqual: SecondMessage.Readed];
    Result = FirstMessage.Type == SecondMessage.Type;
    Result = [FirstMessage.StringContent isEqual: SecondMessage.StringContent];
    Result = FirstMessage.ContactData == SecondMessage.ContactData;
    Result = FirstMessage.NotificationData == SecondMessage.NotificationData;
    
    return Result;
     */
}

+ (ObjC_ChatModel *) CreateFakeNewChatModel
{
    ObjC_ChatModel *Chat = [[ObjC_ChatModel alloc] init];
    
    Chat.Title = @"";
    
    Chat.Contacts = [[NSMutableArray alloc] init];
    
    return Chat;
}

+(ObjC_ChatModel *)CopyChat:(ObjC_ChatModel *)ChatData {
    ObjC_ChatModel *returnChat = [ObjC_ChatModel new];
    
    returnChat.Id = [ChatData.Id copy];
    returnChat.IsP2p = [ChatData.IsP2p copy];
    returnChat.Title = [ChatData.Title copy];
    returnChat.LastModifiedDate = [ChatData.LastModifiedDate copy];
    returnChat.Active = [ChatData.Active copy];
    
    //returnChat.lastMessage = [ChatData.lastMessage copy]; !NO
    
    returnChat.lastMessage = [self CopyMessageModel:ChatData.lastMessage];
    
    returnChat.TotalMessagesCount = ChatData.TotalMessagesCount;
    returnChat.NewMessagesCount = ChatData.NewMessagesCount;
    
    NSMutableArray *returnContacts = [NSMutableArray new];
    for(ObjC_ContactModel *contact in ChatData.Contacts) {
        [returnContacts addObject:[ContactsManager CopyContact:contact]];
    }
    
    returnChat.Contacts = returnContacts;
    
    return returnChat;
}

+ (BOOL) IsChatP2P:(ObjC_ChatModel *)ChatModel {
#ifdef P2PENABLED
    if(!ChatModel || !ChatModel.IsP2p) {
        return NO;
    }
    return [ChatModel.IsP2p boolValue];
#else
    if(!ChatModel || !ChatModel.Contacts) {
        return NO;
    }
    
    if(ChatModel.Contacts.count > 2) {
        return NO;
    }
    else {
        return YES;
    }
#endif
}

#pragma mark - Dummy
- (void) DummyInvite:(NSMutableArray *)Invite AndRevoke:(NSMutableArray *)Revoke InChat:(NSString *)ChatId {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
#ifdef P2PENABLED
        NSString *NewChatId = [[AppManager app].Core InviteAndRevokeChatMembers:ChatId :Invite :Revoke];
        
        if(!NewChatId || !NewChatId.length)
        {
            return;
        }
        
        if(![NewChatId isEqualToString:ChatId])
        {
            //[self.ChatChangedIds setValue:ChatId forKey:NewChatId];
            
            
            dispatch_async(self.ViewModelQueue, ^{
                
                ChatUpdateSignalObject *IdUpdate = [[ChatUpdateSignalObject alloc] initWithChatId:ChatId State:ChatsUpdatingStateIdChanged AndNewChatId:NewChatId];
                
                [self setChatUpdate:IdUpdate];
                
                [self setChatUpdate:nil];
                
            });
            
            
        }
        
        
#else
        [[AppManager app].Core InviteAndRevokeChatMembers:ChatId :Invite :Revoke];
#endif
        
    });
}

- (void) DeleteMessages:(NSArray<NSString *> *)MessagesIds WithChatId: (NSString *) ChatId
{
    [UiLogger WriteLogInfo:[NSString stringWithFormat:@"ChatsManager:DeleteMessages:%@ WithChatId: %@", [MessagesIds description], ChatId]];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [[[AppManager app] Core] DeleteChatMessages:MessagesIds];
    });
}

- (void) UpdateMessage:(ObjC_ChatMessageModel *)Message WithNewText:(NSString *) Text
{
    [UiLogger WriteLogInfo:[NSString stringWithFormat:@"UpdateMessage:%@ WithNewText: %@", Message.Id, Text]];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [[[AppManager app] Core] ChangeMessage:Message.Id Text:Text];
    });
}


@end
