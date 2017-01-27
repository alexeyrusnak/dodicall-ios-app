//
//  ChatsManager.h
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
#import "AppManager.h"
#import "ObjC_ChatModel.h"
#import "ObjC_ChatMessageModel.h"

#define P2PENABLED

typedef NS_ENUM(NSInteger, ChatsListLoadingState)
{
    ChatsListLoadingStateNone,
    ChatsListLoadingStateInProgress,
    ChatsListLoadingStateFinishedSuccess,
    ChatsListLoadingStateFinishedFail,
    ChatsListLoadingStateUpdated
};

typedef NS_ENUM(NSInteger, ChatsUpdatingState)
{
    ChatsUpdatingStateStateNone,
    ChatsUpdatingStateAdded,
    ChatsUpdatingStateUpdated,
    ChatsUpdatingStateRemoved,
    ChatsUpdatingStateIdChanged
};

typedef NS_ENUM(NSInteger, ChatsMessagesUpdatingState)
{
    ChatsMessagesUpdatingStateNone,
    ChatsMessagesUpdatingStateListLoading,
    ChatsMessagesUpdatingStateListLoadingFinishedSuccess,
    ChatsMessagesUpdatingStateListLoadingFinishedFail,
    ChatsMessagesUpdatingStateListUpdated,
    ChatsMessagesUpdatingStateMessageAdded,
    ChatsMessagesUpdatingStateMessageUpdated,
    ChatsMessagesUpdatingStateMessageRemoved
};

typedef NS_ENUM(NSInteger, ChatsMessageDeliveryStatus)
{
    ChatsMessageDeliveryStatusNone,
    ChatsMessageDeliveryStatusSended,
    ChatsMessageDeliveryStatusDeliveredToServer
};


@interface ChatUpdateSignalObject : NSObject

@property ChatsUpdatingState State;

@property NSString *ChatId;

@property NSString *NewChatId;

- (instancetype)initWithChatId:(NSString *) ChatId AndState:(ChatsUpdatingState) State;
- (instancetype)initWithChatId:(NSString *) ChatId State:(ChatsUpdatingState) State AndNewChatId:(NSString *)NewChatId;

@end



@interface ChatMessagesUpdateSignalObject : NSObject

@property ChatsMessagesUpdatingState State;

@property NSString *ChatId;

- (instancetype)initWithChatId:(NSString *) ChatId AndState:(ChatsMessagesUpdatingState) State;

@end

@interface ChatsManager : NSObject

+ (instancetype) Manager;

+ (instancetype) ManagerForCallBack;

+ (instancetype) Chats;

+ (void) Destroy;

- (void) SetActive:(BOOL) Active;

@property dispatch_group_t DispatchGroup;
@property dispatch_queue_t ViewModelQueue;
@property RACTargetQueueScheduler *ViewModelScheduler;
@property RACTargetQueueScheduler *ManagerScheduler;


#pragma mark - Chats list

@property NSArray *ChatsList;

@property ChatsListLoadingState ChatsListState;

@property RACSignal *ChatsListStateSignal;

@property ChatUpdateSignalObject *ChatUpdate;

@property RACSignal *ChatUpdateSignal;

@property NSNumber *NewMessagesCount;

- (void) GetAllChats;

- (ObjC_ChatModel *) GetChatById:(ChatIdType) ChatId;

- (void) PerformChatsChangedEvent:(NSMutableArray *) ChatsIds;

- (void) GetOrCreateP2PChatWithContact:(ObjC_ContactModel *) Contact AndReturnItInCallback:(void (^)(ObjC_ChatModel *)) Callback;

- (void) GetOrCreateMultiChatWithContacts:(NSArray *) Contacts AndReturnItInCallback:(void (^)(ObjC_ChatModel *)) Callback;

- (void) GetOrLoadFromCoreChatById:(ChatIdType) ChatId AndReturnItInCallback:(void (^)(ObjC_ChatModel *)) Callback;

- (void) ClearChats:(NSMutableArray <ChatIdType> *) ChatIds;

+ (void) SetChatReadedWithLastUnreadMessageId:(NSString *) MessageId InChatId:(NSString *) ChatId;

+ (void) UpdateChat:(NSString *)chatId WithNew:(NSArray *)new AndRevokeUsers:(NSArray *)revoke;

+ (void) UpdateChat:(ObjC_ChatModel *)Chat Title:(NSString *)Title;

+ (void) ForceChatSync:(ChatIdType)ChatId;

#pragma mark - Chats messages

@property NSDictionary *ChatsMessages;

@property ChatMessagesUpdateSignalObject *ChatMessagesUpdate;

@property RACSignal *ChatMessagesUpdateSignal;

- (void) FetchChatMessages:(ChatIdType) ChatId;

- (void) PerformMessagesChangedEvent:(NSMutableArray *) MessagesIds;

- (NSMutableArray<ObjC_ChatMessageModel *> *) GetChatMessages:(ChatIdType) ChatId;

+ (void) SendMessage: (NSString *)MessageText ToChat:(ChatIdType) ChatId;

+ (void) SendMessageOrWaitChat: (NSString *)MessageText ToChat:(ChatIdType) ChatId;

#pragma mark - Chats helpers

+ (NSString *) GetTitleOfChat:(ObjC_ChatModel *) Chat;

+ (NSString *) GetMessageSenderFirstAndLastName:(ObjC_ChatMessageModel *) Message;

+ (NSString *) MessageNotificationToText:(ObjC_ChatMessageModel *) Message;

+ (NSString *) MessageToText:(ObjC_ChatMessageModel *) Message;

+ (ObjC_ChatMessageModel *) CreateNewTextMessage:(NSString *) MessageText WithId:(NSString *) Id InChatId:(NSString *) ChatId;

+ (ChatsMessageDeliveryStatus) GetMessageDeliveryStatus:(ObjC_ChatMessageModel *) Message;

+ (ObjC_ChatMessageModel *) CopyMessageModel: (ObjC_ChatMessageModel *) Message;

+ (BOOL) CompareMessageModel: (ObjC_ChatMessageModel *) FirstMessage WithMessageModel: (ObjC_ChatMessageModel *) SecondMessage;

+ (ObjC_ChatModel *) CreateFakeNewChatModel;

+ (ObjC_ChatModel *) CopyChat: (ObjC_ChatModel *) Chat;

+ (BOOL) IsChatP2P:(ObjC_ChatModel *)ChatModel;

#pragma mark - Dummy
- (void) DummyInvite:(NSMutableArray *)Invite AndRevoke:(NSMutableArray *)Revoke InChat:(NSString *)ChatId;

- (void) DeleteMessages:(NSArray<NSString *> *)MessagesIds WithChatId: (NSString *) ChatId;

- (void) UpdateMessage:(ObjC_ChatMessageModel *)Message WithNewText:(NSString *) Text;

@end
