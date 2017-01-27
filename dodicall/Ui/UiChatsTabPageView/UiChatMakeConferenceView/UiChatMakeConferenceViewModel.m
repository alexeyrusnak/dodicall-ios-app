//
//  UiChatMakeConferenceViewModel.m
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

#import "UiChatMakeConferenceViewModel.h"
#import "UiLogger.h"
#import "ChatsManager.h"
#import "ContactsManager.h"

@implementation UiChatMakeConferenceViewModel

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        self.ThreadSafeChatUsersRows = [NSMutableArray new];
        
        self.DataReloadStages = [NSMutableArray new];
        
        self.SelectedContacts = [[NSMutableArray alloc] init];
        
        self.DisabledContacts = [[NSMutableArray alloc] init];
        
        @weakify(self);
        
        
        [[[[RACObserve(self, ChatData) ignore:nil] skip:1]
            deliverOn:[ChatsManager Manager].ViewModelScheduler]
            subscribeNext:^(ObjC_ChatModel *ChatData) {
            
                @strongify(self);
            
                self.IsActive = [ChatData.Active copy];
            
                if(ChatData.Title && ChatData.Title.length)
                    self.Title = ChatData.Title;
            
                [self ReloadData:NO];
            }];
        
        [[[[RACObserve(self, ChatData) ignore:nil] take:1]
            deliverOn:[ChatsManager Manager].ViewModelScheduler]subscribeNext:^(ObjC_ChatModel *ChatData) {
            
                @strongify(self);
            
                self.IsActive = [ChatData.Active copy];
            
                if(ChatData.Title && ChatData.Title.length)
                    self.Title = ChatData.Title;
            
                [self ReloadData:YES];
            }];
        
        [[[ChatsManager Chats].ChatUpdateSignal
            deliverOn:[ChatsManager Manager].ViewModelScheduler]subscribeNext:^(ChatUpdateSignalObject *Signal) {
            
                @strongify(self);
            
                if([Signal.ChatId isEqualToString:self.ChatData.Id ] && (Signal.State == ChatsMessagesUpdatingStateListLoadingFinishedSuccess || Signal.State == ChatsUpdatingStateUpdated)) {
                    
                    ObjC_ChatModel *UpdatedChat = [[ChatsManager Chats] GetChatById:Signal.ChatId];
                    
                    if(UpdatedChat) {
                        self.ChatData = [ChatsManager CopyChat:UpdatedChat];
                    }
                }
                
                if([Signal.ChatId isEqualToString:self.ChatData.Id] && (Signal.State == ChatsUpdatingStateIdChanged)) {
                    
                    ObjC_ChatModel *ChatData = [ChatsManager CopyChat:self.ChatData];
                    ChatData.Id = [Signal.NewChatId copy];
                    self.ChatData = ChatData;
                    
                }
            }];
        
        [RACObserve(self, SelectedContacts) subscribeNext:^(NSMutableArray *SelectedContacts) {
            
            @strongify(self);
            
            self.SelectedContactsCount = [NSNumber numberWithInteger:[SelectedContacts count]];
        }];
        
    }
    
    return self;
}

- (void) ReloadData:(BOOL) SetAllSelected
{
    if(self.ChatData.Contacts && [self.ChatData.Contacts count] > 0)
    {
        NSMutableArray *rowsArray = [NSMutableArray new];
        
        for (ObjC_ContactModel *Contact in [self.ChatData.Contacts copy])
        {
            
            UiChatMakeConferenceUsersRowViewModel *RowModel = [[UiChatMakeConferenceUsersRowViewModel alloc] init];
            
            if(![Contact.Iam boolValue])
            {
                [RowModel setContactData:Contact];
                [RowModel setTitle:[ContactsManager GetContactTitle:Contact]];
                [RowModel setXmppId:[ContactsManager GetXmppIdOfContact:Contact]];
                
                ContactDescriptionStatusModel *ContactDescriptionStatus = [ContactsManager GetContactDescriptionStatusModel:Contact];
                [RowModel setStatus:ContactDescriptionStatus.Status];
                [RowModel setDescription:ContactDescriptionStatus.Description];
                
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
                
                
                @weakify(RowModel);
                [[RACObserve([ContactsManager Contacts], XmppStatuses) deliverOn:[ContactsManager Manager].ViewModelScheduler] subscribeNext:^(NSMutableArray *StatusesArray) {
                    @strongify(RowModel);
                    for(NSString *XmppId in StatusesArray) {
                        if([XmppId isEqualToString: RowModel.XmppId ]) {
                            ContactDescriptionStatusModel *ContactDescriptionStatus = [ContactsManager GetContactDescriptionStatusModel:Contact];
                            [RowModel setStatus:ContactDescriptionStatus.Status];
                            [RowModel setDescription:ContactDescriptionStatus.Description];
                        }
                    }
                }];
                
                if(SetAllSelected)
                    [self AddToSelected:RowModel];
                
                [self SetSelected:RowModel];
                
                RAC(RowModel, AvatarPath) = [[ContactsManager Manager] AvatarSignalForContactUpdate:[[RACSignal empty] startWith:Contact] WithDoNextBlock:^(NSString * Path) {
                    [RowModel setAvatarPath:Path];
                }];
                
                [rowsArray addObject:RowModel];
            }
        }
        
        [self.DataReloadStages addObject:rowsArray];
        
        self.DataReloaded = @(YES);
    }
}

- (void) SetDisabled:(UiChatMakeConferenceUsersRowViewModel *) RowModel
{
    [RowModel setIsDisabled:[NSNumber numberWithBool:NO]];
    
    if(self.DisabledContacts && [self.DisabledContacts count] > 0)
    {
        for (ObjC_ContactModel *Contact in self.DisabledContacts) {
            
            if([ContactsManager AreContactsEqualsByIds:Contact :RowModel.ContactData] /*Contact.Id == RowModel.ContactData.Id*/)
            {
                [RowModel setIsDisabled:[NSNumber numberWithBool:YES]];
                
                break;
            }
            
        }
    }
}

- (void) SetSelected:(UiChatMakeConferenceUsersRowViewModel *) RowModel
{
    [RowModel setIsSelected:[NSNumber numberWithBool:NO]];
    
    if(self.SelectedContacts && [self.SelectedContacts count] > 0)
    {
        for (ObjC_ContactModel *Contact in self.SelectedContacts) {
            
            if([ContactsManager AreContactsEqualsByIds:Contact :RowModel.ContactData])
            {
                [RowModel setIsSelected:[NSNumber numberWithBool:YES]];
                
                break;
            }
            
        }
    }
}

- (void) AddToSelected:(UiChatMakeConferenceUsersRowViewModel *) RowModel
{
    BOOL HasContact = NO;
    
    for (ObjC_ContactModel *Contact in self.SelectedContacts) {
        
        if([ContactsManager AreContactsEqualsByIds:Contact :RowModel.ContactData])
        {
            HasContact = YES;
            
            break;
        }
        
    }
    
    if(!HasContact)
    {
        [self.SelectedContacts addObject:RowModel.ContactData];
    }
    
    [self SetSelected:RowModel];
    
    self.SelectedContactsCount = [NSNumber numberWithInteger:[self.SelectedContacts count]];
}

- (void) RemoveFromSelected:(UiChatMakeConferenceUsersRowViewModel *) RowModel
{
    for (ObjC_ContactModel *Contact in self.SelectedContacts) {
        
        if([ContactsManager AreContactsEqualsByIds:Contact :RowModel.ContactData])
        {
            [self.SelectedContacts removeObject:Contact];
            
            break;
        }
        
    }
    
    [self SetSelected:RowModel];
    
    self.SelectedContactsCount = [NSNumber numberWithInteger:[self.SelectedContacts count]];
}

- (void) RevertSelected:(UiChatMakeConferenceUsersRowViewModel *) RowModel
{
    if([RowModel.IsSelected boolValue])
    {
        [self RemoveFromSelected:RowModel];
    }
    else
    {
        [self AddToSelected:RowModel];
    }
}

- (void) StartConference
{
    
}

@end
