//
//  UiChatUsersViewModel.m
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

#import "UiChatUsersViewModel.h"
#import "UiLogger.h"
#import "ChatsManager.h"
#import "ContactsManager.h"
#import "UiChatUsersRowViewModel.h"

@implementation UiChatUsersViewModel

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        self.ThreadSafeChatUsersRows = [NSMutableArray new];
        self.DataReloadStages = [NSMutableArray new];
        
        @weakify(self);
        
        
        [[RACObserve(self, NewChatData.Contacts)
            deliverOn:[ChatsManager Manager].ViewModelScheduler]
            subscribeNext:^(id x) {
                @strongify(self);
                self.NumberOfContacts = [NSNumber numberWithInteger:[self.NewChatData.Contacts count]];
                [self ReloadData];
            }];
        

        
        [[[[RACObserve(self, ChatData)
            ignore:nil]
            take:1] 
            deliverOn:[ChatsManager Manager].ViewModelScheduler]
            subscribeNext:^(ObjC_ChatModel *ChatData) {
            
                @strongify(self);
                
                self.IsActive = [ChatData.Active copy];
                self.IsP2P = @([ChatsManager IsChatP2P:ChatData]);
                
                if(ChatData.Id && ChatData.Id.length)
                    self.IsNewChat = @(NO);
                else
                    self.IsNewChat = @(YES);
                
                if(ChatData.Title && ChatData.Title.length)
                    self.ChatName = ChatData.Title;
                
                ObjC_ChatModel *newChat = [ChatsManager CopyChat:ChatData];
                NSMutableArray *newContacts = [NSMutableArray new];
                
                for (ObjC_ContactModel *contact in newChat.Contacts) {
                    if(![contact.Iam boolValue])
                        [newContacts addObject:contact];
                }
                
                newChat.Contacts = newContacts;
                
                self.NewChatData = newChat;
            }];
        
        [[[ChatsManager Chats].ChatUpdateSignal
            deliverOn:[ChatsManager Manager].ViewModelScheduler]
            subscribeNext:^(ChatUpdateSignalObject *Signal) {
                @strongify(self);
                if([Signal.ChatId isEqualToString:self.NewChatData.Id ] && (Signal.State == ChatsMessagesUpdatingStateListLoadingFinishedSuccess || Signal.State == ChatsUpdatingStateUpdated)) {
                    
                    ObjC_ChatModel *UpdatedChat = [[ChatsManager Chats] GetChatById:Signal.ChatId];
                    if(UpdatedChat) {
                        [self UpdateNewChatDataWithChatModel:[ChatsManager CopyChat:UpdatedChat]];
                    }
                }
                
                if([Signal.ChatId isEqualToString:self.NewChatData.Id] && (Signal.State == ChatsUpdatingStateIdChanged)) {
                    
                    
                    ObjC_ChatModel *ChatData = [ChatsManager CopyChat:self.ChatData];
                    ChatData.Id = [Signal.NewChatId copy];
                    self.ChatData = ChatData;

                    self.NewChatData.Id = [Signal.NewChatId copy];
                    
                }
            }];
        
    }
    
    return self;
}
- (void) UpdateNewChatDataWithChatModel:(ObjC_ChatModel *)ChatData {
    
    if(ChatData.Title)
        self.ChatName = ChatData.Title;
    
    self.IsActive = [ChatData.Active copy];
    self.IsP2P = @([ChatsManager IsChatP2P:ChatData]);
    
    ObjC_ChatModel *newChat = [ChatsManager CopyChat:ChatData];
    NSMutableArray *newContacts = [NSMutableArray new];
    
    for (ObjC_ContactModel *contact in newChat.Contacts) {
        if(![contact.Iam boolValue])
            [newContacts addObject:contact];
    }
    
    newChat.Contacts = newContacts;
    
    
    
    
    self.NewChatData = newChat;
}
- (void) ReloadData
{

    if(self.NewChatData.Contacts && [self.NewChatData.Contacts count] > 0)
    {
        NSMutableArray *rowsArray = [NSMutableArray new];
        
        for (ObjC_ContactModel *Contact in self.NewChatData.Contacts)
        {
            
            UiChatUsersRowViewModel *RowModel = [[UiChatUsersRowViewModel alloc] init];
            
            [RowModel setContactData:Contact];
            [RowModel setTitle:[ContactsManager GetContactTitle:Contact]];
            [RowModel setXmppId:[ContactsManager GetXmppIdOfContact:Contact]];
            
            ContactDescriptionStatusModel *ContactDescriptionStatus = [ContactsManager GetContactDescriptionStatusModel:Contact];
            [RowModel setStatus:ContactDescriptionStatus.Status];
            [RowModel setDescription:ContactDescriptionStatus.Description];
            
            
            
            if([self.IsNewChat boolValue])
                [RowModel setCellId:@"UiContactsListCellViewNew"];
            else {
                ContactProfileType type = [ContactsManager GetContactProfileType:Contact];
                if(type == ContactProfileTypeDirectoryLocal) {
                    if([ContactsManager CheckContactIsInvite:Contact]||[ContactsManager CheckContactIsRequest:Contact])
                        [RowModel setCellId:@"UiContactsListCellViewOldNotApproved"];
                    else
                        [RowModel setCellId:@"UiContactsListCellViewOldApproved"];
                }
                else
                    [RowModel setCellId:@"UiContactsListCellViewOldNotApproved"];
                
                if([Contact.Blocked boolValue])
                    [RowModel setCellId:@"UiContactsListCellViewOldBlocked"];
            }
            
            @weakify(RowModel);
            [RACObserve([ContactsManager Contacts], XmppStatuses) subscribeNext:^(NSMutableArray *StatusesArray) {
                @strongify(RowModel);
                for(NSString *XmppId in StatusesArray) {
                    if([XmppId isEqualToString: RowModel.XmppId ]) {
                        ContactDescriptionStatusModel *ContactDescriptionStatus = [ContactsManager GetContactDescriptionStatusModel:Contact];
                        [RowModel setStatus:ContactDescriptionStatus.Status];
                        [RowModel setDescription:ContactDescriptionStatus.Description];
                    }
                }
            }];
            
            RAC(RowModel, AvatarPath) = [[ContactsManager Manager] AvatarSignalForContactUpdate:[[RACSignal empty] startWith:Contact] WithDoNextBlock:^(NSString *Path) {
                @strongify(RowModel);
                RowModel.AvatarPath = Path;
            }];
            
            [rowsArray addObject:RowModel];
        }
        
        [self.DataReloadStages addObject:rowsArray];
        
        self.DataReloaded = @(YES);
    }
}
- (void) CreateChat {
    if([self.NewChatData.Contacts count]) {
        [[ChatsManager Chats] GetOrCreateMultiChatWithContacts:self.NewChatData.Contacts AndReturnItInCallback:^(ObjC_ChatModel *Chat) {
            self.ChatData = Chat;
        }];
        
    }
}

- (BOOL) ChatChanged {

    NSMutableSet *oldIds = [NSMutableSet new];
    NSMutableSet *newIds = [NSMutableSet new];
    
    for(ObjC_ContactModel *contact in self.ChatData.Contacts) {
        if(![contact.Iam boolValue])
            [oldIds addObject:@(contact.Id)];
    }
    for(ObjC_ContactModel *contact in self.NewChatData.Contacts) {
        [newIds addObject:@(contact.Id)];
    }
    
    if(![oldIds isEqualToSet:newIds]) {
        return YES;
    }

    return NO;    
}

- (void) RemoveContact:(NSInteger)Index {
    [self.ThreadSafeChatUsersRows removeObjectAtIndex:Index];
    
    NSMutableArray *deleteContacts = [NSMutableArray new];
    [deleteContacts addObject:[self.NewChatData.Contacts objectAtIndex:Index]];
    
    //[ChatsManager UpdateChat:self.NewChatData.Id WithNew:nil AndRevokeUsers:deleteContacts];
    [[ChatsManager Manager] DummyInvite:nil AndRevoke:deleteContacts InChat:self.NewChatData.Id];
    
}

@end
