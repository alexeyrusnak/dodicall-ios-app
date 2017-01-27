//
//  UiChatsListViewModel.m
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

#import "UiChatsListViewModel.h"
#import "UiLogger.h"
#import "ChatsManager.h"
#import "ContactsManager.h"

@implementation UiChatsListViewModel

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        self.SelectedChats = [[NSMutableArray alloc] init];
        
        self.DisposableRacArr = [[NSMutableArray alloc] init];
        
        self.Rows = [[NSMutableArray alloc] init];
        
        self.RowsUpdateStages = [[NSMutableArray alloc] init];
        
        self.DataReloaded = [NSNumber numberWithBool:NO];
        self.DataReloadedSignal = RACObserve(self, DataReloaded);
        
        self.EditModeEnabled = [NSNumber numberWithBool:NO];
        
        self.SelectedCellsNumber = [NSNumber numberWithInt:0];
        
        @weakify(self);
        
        [[[[[ChatsManager Chats].ChatsListStateSignal
            filter:^BOOL(NSNumber *State) {
                return ([State integerValue] == ChatsListLoadingStateFinishedSuccess || [State integerValue] == ChatsListLoadingStateUpdated);
            }]
            throttle:0.3 afterAllowing:1 withStrike:1]
            deliverOn:[ChatsManager Manager].ViewModelScheduler]
            subscribeNext:^(NSNumber *State) {
                @strongify(self);
                [self ReloadData];
            }];
    }
    
    return self;
}

- (void) ReloadData
{
    
    for(RACDisposable *Disposable in self.DisposableRacArr)
    {
        [Disposable dispose];
    }
    
    self.Rows = [[NSMutableArray alloc] init];
    
    [UiLogger WriteLogInfo:[NSString stringWithFormat:@"UiChatsListViewModel:ReloadData: Chats after filters apply: %lu", (unsigned long)[[ChatsManager Chats].ChatsList count]]];
    
    for (ObjC_ChatModel *Chat in [[ChatsManager Chats].ChatsList copy]) {
        
        //[UiLogger WriteLogDebug:[CoreHelper ChatModelDescription:Chat]];
        
        /*
        if(![Chat.Active boolValue])
            continue;
         */
        
        UiChatsListRowItemViewModel * RowModel = [[UiChatsListRowItemViewModel alloc] init];
        
        [RowModel setChat:[ChatsManager CopyChat:Chat]];
        
        [RowModel setTitle:[ChatsManager GetTitleOfChat:Chat]];
        
        if(Chat.lastMessage)
        {
            [RowModel setDescription:[ChatsManager MessageToText: Chat.lastMessage]];
            
            [RowModel setIsLastMessageReaded:[Chat.lastMessage.Readed boolValue]];
            
            [RowModel PrepareDescriptionAttributedString];
        }
        else
        {
            [RowModel setDescription:@""];
            [RowModel setIsLastMessageReaded:NO];
        }
        
        
        if(Chat.NewMessagesCount > 0)
            [RowModel setCount:[NSString stringWithFormat:@"%i",Chat.NewMessagesCount]];
        
        NSDateFormatter *Formatter = [[NSDateFormatter alloc] init];
        
        Formatter.timeStyle = NSDateFormatterShortStyle;
        Formatter.dateStyle = NSDateFormatterShortStyle;
        Formatter.doesRelativeDateFormatting = YES;
        
        [Formatter setLocale:[[NSLocale alloc] initWithLocaleIdentifier:[AppManager app].UserSettingsModel.GuiLanguage/*@"en_US"*/]];
        
        [RowModel setDateTime:[Formatter stringFromDate:Chat.LastModifiedDate]];
        
        NSInteger contactsCount = 0;
        for(ObjC_ContactModel *Contact in Chat.Contacts) {
            if(![Contact.Iam boolValue])
                contactsCount++;
        }
        
        ParticipantTypeEnding participantsEndingType = [NSStringHelper GetParticipantEnding:contactsCount];
        switch (participantsEndingType) {
            case ParticipantTypeEndingOne:
                [RowModel setAddInfo:[NSString stringWithFormat:NSLocalizedString(@"Format_participants_type_1_%lu",nil) ,(unsigned long)contactsCount]];
                break;
            case ParticipantTypeEndingTwo:
                [RowModel setAddInfo:[NSString stringWithFormat:NSLocalizedString(@"Format_participants_type_2_%lu",nil) ,(unsigned long)contactsCount]];
                break;
            case ParticipantTypeEndingThree:
                [RowModel setAddInfo:[NSString stringWithFormat:NSLocalizedString(@"Format_participants_type_3_%lu",nil) ,(unsigned long)contactsCount]];
                break;
            case ParticipantTypeEndingSingle:
                [RowModel setAddInfo:[NSString stringWithFormat:NSLocalizedString(@"Format_participants_type_single_%lu",nil) ,(unsigned long)contactsCount]];
                break;
            default:
                break;
        }
        
        
        [RowModel setIsMultyUserChat:![ChatsManager IsChatP2P:Chat]];
        
        if(contactsCount > 0)
            [RowModel setIsEmptyChat:NO];
        else
            [RowModel setIsEmptyChat:YES];
        
        
        if(!RowModel.IsMultyUserChat)
        {
            for (ObjC_ContactModel *Contact in Chat.Contacts)
            {
                if (![Contact.Iam boolValue]) {
                    
                    if(Contact.DodicallId && Contact.DodicallId.length > 0)
                    {
                        [RowModel setXmppId:[ContactsManager GetXmppIdOfContact:Contact]];
                    }
                    
                    if(RowModel.XmppId)
                    {
                        [self SetStatusToModel:RowModel];
                        
                        // Observe status changed event
                        @weakify(self);
                        @weakify(RowModel);
                        
                        RACDisposable *Disposable = [RACObserve([ContactsManager Contacts], XmppStatuses) subscribeNext:^(NSMutableArray *StatusesArr) {
                            
                            @strongify(self);
                            @strongify(RowModel);
                            
                            for(NSString *XmppId in StatusesArr)
                            {
                                if([XmppId isEqualToString:RowModel.XmppId])
                                {
                                    [self SetStatusToModel:RowModel];
                                }
                            }
                            
                        }];
                        
                        [self.DisposableRacArr addObject:Disposable];
                    }
                    
                    @weakify(RowModel);
                    RAC(RowModel, AvatarPath) = [[ContactsManager Manager] AvatarSignalForContactUpdate:[[RACSignal empty] startWith:Contact] WithDoNextBlock:^(NSString *Path) {
                        @strongify(RowModel);

                        RowModel.AvatarPath = Path;
                    }];
                    
                    RowModel.P2PContact = Contact;
                    
                    break;
                }
            }
        }
        
        [self SetSelected:RowModel];
        
        [self.Rows addObject:RowModel];
        
    }
    
    if(self.SearchText.length > 0)
        [self FilterChatsWithSearchTextFilter:self.Rows withFilter:self.SearchText];
    
    [self.RowsUpdateStages addObject:self.Rows];
    
    self.DataReloaded = [NSNumber numberWithBool:YES];
    
}

- (void) SetStatusToModel:(UiChatsListRowItemViewModel *) RowModel
{
    
    //Status
    ObjC_ContactPresenceStatusModel *Status = [ContactsManager GetXmppStatusByXmppId:RowModel.XmppId];
    
    switch (Status.BaseStatus) {
            
        case BaseUserStatusOnline:
            [RowModel setStatus:@"ONLINE"];
            break;
            
        case BaseUserStatusDnd:
            [RowModel setStatus:@"DND"];
            break;
            
        case BaseUserStatusAway:
            [RowModel setStatus:@"AWAY"];
            break;
            
        case BaseUserStatusHidden:
            [RowModel setStatus:@"INVISIBLE"];
            break;
            
        default:
            [RowModel setStatus:@"OFFLINE"];
            break;
    }
}

#pragma mark Filters

- (void) SetSearchTextFilter:(NSString *)Search
{
    self.SearchText = Search;
    
    [UiLogger WriteLogInfo:[NSString stringWithFormat:@"UiChatsListViewModel: User set text filter: %@", self.SearchText]];
    
    dispatch_async([ChatsManager Manager].ViewModelQueue, ^{
        [self ReloadData];
    });
}

- (void) FilterChatsWithSearchTextFilter: (NSMutableArray *) ChatsArr withFilter: (NSString *) Search
{
    NSPredicate *SearchTextPredicate = [NSPredicate predicateWithFormat:@"(SELF.Title contains[cd] %@) OR (SELF.Description contains[cd] %@)",Search,Search];
    [ChatsArr filterUsingPredicate:SearchTextPredicate];
}


#pragma mark Edit mode

- (void) EnableEditMode: (BOOL) Enabled
{
    dispatch_async([ChatsManager Manager].ViewModelQueue, ^{
        [self setEditModeEnabled:[NSNumber numberWithBool:Enabled]];
        
        
        if(!Enabled)
        {
            [self DeselectAll];
        }
    });
}

- (void) SwitchEditMode
{
    dispatch_async([ChatsManager Manager].ViewModelQueue, ^{
        [self EnableEditMode:![self.EditModeEnabled boolValue]];
    });
}

- (void) SelectCell:(BOOL) Selected withIndexPath:(NSIndexPath *) IndexPath
{
    dispatch_async([ChatsManager Manager].ViewModelQueue, ^{
        UiChatsListRowItemViewModel *RowItem = (UiChatsListRowItemViewModel *)[self.ThreadSafeRows objectAtIndex:IndexPath.row];
        
        //[RowItem setIsSelected:Selected];
        
        if(RowItem)
        {
            if(Selected)
                [self AddToSelected:RowItem];
            else
                [self RemoveFromSelected:RowItem];
        }
    });
}

- (void) DeselectAll
{
    dispatch_async([ChatsManager Manager].ViewModelQueue, ^{
        for (int row = 0; row < [self.Rows count]; row ++)
        {
            NSIndexPath *IndexPath = [NSIndexPath indexPathForRow:row inSection:0];
            
            [self SelectCell:NO withIndexPath:IndexPath];
        }
    });
}

- (void) CalcSelectedNumber
{
    dispatch_async([ChatsManager Manager].ViewModelQueue, ^{
        int Count = 0;
        
        for (int i = 0; i < [self.Rows count]; i++) {
            
            UiChatsListRowItemViewModel *RowItem = (UiChatsListRowItemViewModel *)[self.Rows objectAtIndex:i];
            
            if([RowItem.IsSelected boolValue])
                Count++;
            
        }
        
        [self setSelectedCellsNumber:[NSNumber numberWithInt:Count]];
    });
}

- (void) SetSelected:(UiChatsListRowItemViewModel *) RowModel
{
    dispatch_async([ChatsManager Manager].ViewModelQueue, ^{
        [RowModel setIsSelected:[NSNumber numberWithBool:NO]];
        
        if(self.SelectedChats && [self.SelectedChats count] > 0)
        {
            for (ObjC_ChatModel *Chat in self.SelectedChats) {
                
                if([Chat.Id isEqualToString:RowModel.Chat.Id])
                {
                    [RowModel setIsSelected:[NSNumber numberWithBool:YES]];
                    
                    break;
                }
                
            }
        }
    });
}

- (void) AddToSelected:(UiChatsListRowItemViewModel *) RowModel
{
    dispatch_async([ChatsManager Manager].ViewModelQueue, ^{
        BOOL HasChat = NO;
        
        for (ObjC_ChatModel *Chat in self.SelectedChats) {
            
            if([Chat.Id isEqualToString:RowModel.Chat.Id])
            {
                HasChat = YES;
                
                break;
            }
            
        }
        
        if(!HasChat)
        {
            [self.SelectedChats addObject:RowModel.Chat];
        }
        
        [self SetSelected:RowModel];
        
        [self CalcSelectedNumber];
    });
    
}

- (void) RemoveFromSelected:(UiChatsListRowItemViewModel *) RowModel
{
    dispatch_async([ChatsManager Manager].ViewModelQueue, ^{
        for (ObjC_ChatModel *Chat in self.SelectedChats) {
            
            if([Chat.Id isEqualToString:RowModel.Chat.Id])
            {
                [self.SelectedChats removeObject:Chat];
                
                break;
            }
            
        }
        
        [self SetSelected:RowModel];
        
        [self CalcSelectedNumber];
    });
}

- (void) RevertSelected:(UiChatsListRowItemViewModel *) RowModel
{
    dispatch_async([ChatsManager Manager].ViewModelQueue, ^{
        if([RowModel.IsSelected boolValue])
        {
            [self RemoveFromSelected:RowModel];
        }
        else
        {
            [self AddToSelected:RowModel];
        }
    });
}

- (ObjC_ChatModel *) CreateFakeNewChatModel
{
    return [ChatsManager CreateFakeNewChatModel];
}

- (void) ClearSelectedChats
{
    dispatch_async([ChatsManager Manager].ViewModelQueue, ^{
        if(self.SelectedChats && [self.SelectedChats count] > 0)
        {
            NSMutableArray <NSString *> *ChatIds = [NSMutableArray new];
            
            for (ObjC_ChatModel *Chat in [self.SelectedChats copy])
            {
                [ChatIds addObject:[Chat.Id copy]];
            }
            
            [[ChatsManager Chats] ClearChats:ChatIds];
        }
    });
}

@end
