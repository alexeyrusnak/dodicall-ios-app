//
//  UiChatUsersSelectViewModel.m
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

#import "UiChatUsersSelectViewModel.h"
#import "UiNavRouter.h"
#import "UiChatsTabNavRouter.h"
#import "ChatsManager.h"

@interface UiChatUsersSelectViewModel ()
{
    BOOL _IsBinded;
}

@end


@implementation UiChatUsersSelectViewModel

-(instancetype)init {
    
    self = [super init];
    
    if(self)
    {
        _IsBinded = NO;
        
        [self BindAll];
    }
    
    return self;
    
}

- (void)BindAll
{
    if (_IsBinded)
        return;
    
    self.IsValid = NO;
    
    @weakify(self);
    
    self.DoneAction = [[RACCommand alloc] initWithSignalBlock:^RACSignal *(id input) {
        @strongify(self);
        return [self ExecuteDoneAction];
    }];
    
    self.BackAction = [[RACCommand alloc] initWithSignalBlock:^RACSignal *(id input) {
        @strongify(self);
        return [self ExecuteBackAction];
    }];
    
    _IsBinded = YES;
}

#pragma mark Actions
- (RACSignal *)ExecuteShowComingSoon {
    return [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        
        [UiNavRouter ShowComingSoon];
        [subscriber sendCompleted];
        
        return [RACDisposable new];
    }];
}

- (RACSignal *)ExecuteBackAction {
    return [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        
        [UiChatsTabNavRouter CloseChatUsersSelectViewWhenBackAction];
        [subscriber sendCompleted];
        
        return [RACDisposable new];
    }];
}

- (RACSignal *)ExecuteDoneAction {
    @weakify(self);
    return [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        @strongify(self);
        [self MergeAddedContactsToChatModel];
        
        if(![self.IsNewChat boolValue]) {
            [self SaveSelectedContacts];
        }
        
        [UiChatsTabNavRouter CloseChatUsersSelectViewWhenBackAction];
        
        [subscriber sendCompleted];
        
        return [RACDisposable new];
    }];
}

- (void) MergeAddedContactsToChatModel
{
    NSMutableArray <ObjC_ContactModel *> *ChatContacts = [[NSMutableArray alloc] initWithArray:self.ChatData.Contacts];
    
    for (ObjC_ContactModel *AddedContact in self.ContactsListModel.SelectedContacts) {
        
        BOOL IsExist = NO;
        
        for (ObjC_ContactModel *ChatContact in ChatContacts) {
            
            if(ChatContact.Id == AddedContact.Id)
            {
                IsExist = YES;
                break;
            }
            
        }
        
        if(!IsExist)
        {
            [ChatContacts addObject:AddedContact];
        }
        
    }
    
    self.ChatData.Contacts = ChatContacts;
}
- (void) SaveSelectedContacts {
    
    //[ChatsManager UpdateChat:self.ChatData.Id WithNew:self.ContactsListModel.SelectedContacts AndRevokeUsers:nil];
    [[ChatsManager Manager] DummyInvite:self.ContactsListModel.SelectedContacts AndRevoke:nil InChat:self.ChatData.Id];
}

- (void) Setup {
    [self.ContactsListModel setDisabledContacts:self.ChatData.Contacts];
    
    [self.ContactsListModel SetMode:UiContactsListModeMultySelectableForChat];
    [self.ContactsListModel SetFilter:UiContactsFilterDirectoryLocal];
    
    @weakify(self);
    
    [RACObserve(self.ContactsListModel, SelectedContactsCount) subscribeNext:^(NSNumber *Count) {
        
        @strongify(self);
        
        if(Count && [Count intValue] > 0)
        {
            self.IsValid = YES;
        }
        
        else
        {
            self.IsValid = NO;
        }
        
    }];
    
    [[RACObserve(self, ChatData) deliverOn:[ChatsManager Manager].ViewModelScheduler] subscribeNext:^(ObjC_ChatModel *ChatModel) {
        @strongify(self)
        
        self.IsNewChat = @(!(ChatModel.Id && ChatModel.Id.length));
        self.IsActive = [ChatModel.Active copy];
        self.ChatTitle = [ChatModel.Title copy];
        
        if([self.IsActive boolValue]||[self.IsNewChat boolValue])
            [self.ContactsListModel setSelectionBlocked:@(NO)];
        else
            [self.ContactsListModel setSelectionBlocked:@(YES)];
        
    }];
    
    [[[ChatsManager Chats].ChatUpdateSignal deliverOn:[ChatsManager Manager].ViewModelScheduler] subscribeNext:^(ChatUpdateSignalObject *Signal) {
        
        @strongify(self);
        
        if([Signal.ChatId isEqualToString:self.ChatData.Id ] && (Signal.State == ChatsMessagesUpdatingStateListLoadingFinishedSuccess || Signal.State == ChatsUpdatingStateUpdated)) {
            
            ObjC_ChatModel *UpdatedChat = [[ChatsManager Chats] GetChatById:Signal.ChatId];
            if(UpdatedChat) {
                self.ChatData = [ChatsManager CopyChat:UpdatedChat];
                [self MergeUpdatedChat];
            }
        }
//        if([Signal.ChatId isEqualToString:self.ChatData.Id] && (Signal.State == ChatsUpdatingStateIdChanged)) {
//            
//            ObjC_ChatModel *ChatData = [ChatsManager CopyChat:self.ChatData];
//            ChatData.Id = [Signal.NewChatId copy];
//            self.ChatData = ChatData;
//            
//            
//        }
        
    }];
    
}

- (void) MergeUpdatedChat {
    
    [self.ContactsListModel setDisabledContacts:self.ChatData.Contacts];
    
    
    NSMutableArray *SelectedCopy = [self.ContactsListModel.SelectedContacts mutableCopy];
    
    for(ObjC_ContactModel *ChatContact in self.ChatData.Contacts) {
        for(ObjC_ContactModel *SelectedContact in self.ContactsListModel.SelectedContacts) {
                if([ChatContact.DodicallId isEqualToString:SelectedContact.DodicallId])
                    [SelectedCopy removeObject:SelectedContact];
        }
    }
    
    [self.ContactsListModel setSelectedContacts:SelectedCopy];
    [self.ContactsListModel SetFilter:UiContactsFilterDirectoryLocal];
}

@end
