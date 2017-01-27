//
//  UiChatViewModel.m
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

#import "UiChatViewModel.h"
#import "UiLogger.h"
#import "ChatsManager.h"
#import "ContactsManager.h"

#import "LoremIpsum.h"

#import "UiChatMenuCellModel.h"
#import "NSStringHelper.h"

@implementation UiChatViewModel

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        self.EditModeEnabled = [NSNumber numberWithBool:NO];
        
        self.SelectedCellsNumber = [NSNumber numberWithInt:0];
        
        self.SelectedMessages = [[NSMutableArray alloc] init];
        
        self.AutoScrollEnabled = YES;
        
        self.ChatIsReaded = NO;
        
        self.Messages = [[NSMutableArray alloc] init];
        
        self.MessagesUpdateStages = [[NSMutableArray alloc] init];
        
        self.Sections = [[NSMutableDictionary alloc] init];
        self.SectionsKeys = [[NSMutableArray alloc] init];
        
        self.ThreadSafeSections = [[NSMutableDictionary alloc] init];
        self.ThreadSafeSectionsKeys = [[NSMutableArray alloc] init];
        
        //self.DisposableRacArr = [[NSMutableArray alloc] init];
        
        self.DataReloaded = [NSNumber numberWithBool:NO];
        
        self.DataReloadedSignal = RACObserve(self, DataReloaded);
        
        self.ChatDataSignal = [RACObserve(self, ChatData) ignore:nil];
        
        //self.XmppStatusesSignal = RACObserve([ContactsManager Contacts], XmppStatuses);

        @weakify(self);
        
        [[[ChatsManager Chats].ChatMessagesUpdateSignal
            deliverOn:[ChatsManager Manager].ViewModelScheduler]
            subscribeNext:^(ChatMessagesUpdateSignalObject *Signal) {
                @strongify(self);
            
                if([Signal.ChatId isEqualToString:self.ChatData.Id ] && (Signal.State == ChatsMessagesUpdatingStateListLoadingFinishedSuccess || Signal.State == ChatsMessagesUpdatingStateListUpdated /*Signal.State == ChatsMessagesUpdatingStateMessageUpdated || Signal.State == ChatsMessagesUpdatingStateMessageAdded*/))
                {
                    
                    [self ReloadData];
                }
            
            }];
        
        
        [[self.ChatDataSignal
            deliverOn:[ChatsManager Manager].ViewModelScheduler]
            subscribeNext:^(ObjC_ChatModel *ChatData) {
                @strongify(self);
            
                [self SetData:ChatData];
                [self SetMenuModel];
            
                [[ChatsManager Chats] FetchChatMessages:ChatData.Id];
            }];
        
        [[[ChatsManager Chats].ChatUpdateSignal
            deliverOn:[ChatsManager Manager].ViewModelScheduler]
            subscribeNext:^(ChatUpdateSignalObject *Signal) {
                @strongify(self);
                if([Signal.ChatId isEqualToString:self.ChatData.Id ] && (Signal.State == ChatsMessagesUpdatingStateListLoadingFinishedSuccess || Signal.State == ChatsUpdatingStateUpdated))
                {
                    if([[ChatsManager Chats] GetChatById:Signal.ChatId])
                    {
                        ObjC_ChatModel *Chat = [[ChatsManager Chats] GetChatById:Signal.ChatId];
                        [self SetData:[ChatsManager CopyChat:Chat]];
                        [self SetMenuModel];
                    }
                }
                
                if([Signal.ChatId isEqualToString:self.ChatData.Id ] && (Signal.State == ChatsUpdatingStateRemoved))
                {
                    self.ChatData.Active = @NO;
                    
                    self.IsActive = NO;
                    
                    self.MarkedAsDeletedAndShouldBeClosed = YES;
                }
                
                if([Signal.ChatId isEqualToString:self.ChatData.Id] && (Signal.State == ChatsUpdatingStateIdChanged)) {
                    
                    ObjC_ChatModel *ChatData = [ChatsManager CopyChat:self.ChatData];
                    ChatData.Id = [Signal.NewChatId copy];
                    self.ChatData = ChatData;
                    
                    [[ChatsManager Manager] FetchChatMessages:self.ChatData.Id];
                }
            }];
        
        
        // For p2p chat 
        [[[ContactsManager Contacts].XmppStatusesSignal deliverOn:[ChatsManager Manager].ViewModelScheduler] subscribeNext:^(NSMutableArray *StatusesArr) {
            
            
            @strongify(self);
            
            for(NSString *XmppId in StatusesArr) {
                if([XmppId isEqualToString:self.XmppId])
                    [self SetStatus];
            }
            
        }];
        
        self.ShowComingSoon = [[RACCommand alloc] initWithSignalBlock:^RACSignal *(id input) {
            @strongify(self);
            return [self ExecuteShowComingSoon];
        }];
        
        self.ShowChatSettings = [[RACCommand alloc] initWithSignalBlock:^RACSignal *(id input) {
            @strongify(self);
            return [self ExecuteShowChatSettings];
        }];
        
        self.ShowChatUsers = [[RACCommand alloc] initWithSignalBlock:^RACSignal *(id input) {
            @strongify(self);
            return [self ExecuteShowChatUsers];
        }];
        
    }
    
    return self;
}

/*
- (void) UnBindAll
{
    for(RACDisposable *Disposable in self.BindedDisposableRacArr)
    {
        [Disposable dispose];
    }
    
    self.BindedDisposableRacArr = nil;
    
    self.Messages = nil;
    self.Sections = nil;
    self.SectionsKeys = nil;
    
    self.DataReloadedSignal = nil;
    
    self.ChatDataSignal = nil;
    
    self.XmppStatusesSignal = nil;
}
 */

- (void) SetData:(ObjC_ChatModel *) ChatData
{
    [UiLogger WriteLogInfo:[NSString stringWithFormat:@"UiChatViewModel:SetData"]];
    
    [UiLogger WriteLogDebug:[CoreHelper ChatModelDescription:ChatData]];
    
    //Copy chat data attributes
    self.ChatData.Title = ChatData.Title;
    self.ChatData.LastModifiedDate = ChatData.LastModifiedDate;
    self.ChatData.Active = ChatData.Active;
    self.ChatData.Contacts = ChatData.Contacts;
    self.ChatData.lastMessage = ChatData.lastMessage;
    self.ChatData.IsP2p = ChatData.IsP2p;
    self.ChatData.TotalMessagesCount = ChatData.TotalMessagesCount;
    self.ChatData.NewMessagesCount = ChatData.NewMessagesCount;
    
    
    self.IsActive = [ChatData.Active boolValue];
    
    self.HeaderLabelText = [ChatsManager GetTitleOfChat:ChatData];
    
    self.IsP2P = [ChatsManager IsChatP2P:ChatData];
    
    
    NSInteger contactsCount = 0;
    for(ObjC_ContactModel *Contact in ChatData.Contacts) {
        if(![Contact.Iam boolValue])
            contactsCount++;
    }
    
    ParticipantTypeEnding participantsEndingType = [NSStringHelper GetParticipantEnding:contactsCount];
    switch (participantsEndingType) {
        case ParticipantTypeEndingOne:
            [self setHeaderDescrLabelText:[NSString stringWithFormat:NSLocalizedString(@"Format_participants_type_1_%lu",nil) ,(unsigned long)contactsCount]];
            break;
        case ParticipantTypeEndingTwo:
            [self setHeaderDescrLabelText:[NSString stringWithFormat:NSLocalizedString(@"Format_participants_type_2_%lu",nil) ,(unsigned long)contactsCount]];
            break;
        case ParticipantTypeEndingThree:
            [self setHeaderDescrLabelText:[NSString stringWithFormat:NSLocalizedString(@"Format_participants_type_3_%lu",nil) ,(unsigned long)contactsCount]];
            break;
        case ParticipantTypeEndingSingle:
            [self setHeaderDescrLabelText:[NSString stringWithFormat:NSLocalizedString(@"Format_participants_type_single_%lu",nil) ,(unsigned long)contactsCount]];
            break;
        default:
            break;
    }
    
    
    if(contactsCount == 0)
        [self setIsEmptyChat:YES];
    else
        [self setIsEmptyChat:NO];
    

    
    if(self.IsP2P)
    {
        for (ObjC_ContactModel *Contact in ChatData.Contacts)
        {
            if (![Contact.Iam boolValue]) {
                
                if(Contact.DodicallId && Contact.DodicallId.length > 0)
                {
                    [self setXmppId:[ContactsManager GetXmppIdOfContact:Contact]];
                }
                
                if(self.XmppId)
                {
                    [self SetStatus];
                }
                
                /*
                @weakify(self);
                [[[[ContactsManager Contacts].XmppStatusesSignal
                  takeUntil:[self.ChatDataSignal skip:1]]
                  merge:[[ChatsManager Chats].ChatUpdateSignal skip:1]]
                  subscribeNext:^(NSMutableArray *StatusesArr){
                     @strongify(self);
                     if([StatusesArr containsObject:self.XmppId])
                         [self SetStatus];
                 }];
                 */
                
                break;
            }
        }
    }
}

- (void) ReloadData
{
    //[self.Messages removeAllObjects];
    
    //self.DataReloaded = [NSNumber numberWithBool:NO];
    
//    for(RACDisposable *Disposable in self.DisposableRacArr)
//    {
//        [Disposable dispose];
//    }
//    
//    [self.DisposableRacArr removeAllObjects];
    
    self.Sections = [[NSMutableDictionary alloc] init];
    self.SectionsKeys = [[NSMutableArray alloc] init];
    
    
    [UiLogger WriteLogInfo:[NSString stringWithFormat:@"UiChatViewModel:ReloadData: Messages after filters apply: %lu", (unsigned long)[[[ChatsManager Chats] GetChatMessages:self.ChatData.Id] count]]];
    
    int i = 0;
    
    BOOL HasSectionNew = NO;
    
    for (ObjC_ChatMessageModel *ChatMessage in [[[ChatsManager Chats] GetChatMessages:self.ChatData.Id] copy]) {
        
        UiChatViewMessagesCellModel * MessageModel;
        
        if(i < [self.Messages count])
        {
           MessageModel = [self.Messages objectAtIndex:i];
        }
        else
        {
            MessageModel = [[UiChatViewMessagesCellModel alloc] init];

        }
        
        [self PrepareMessageModel:MessageModel WithChatMessage:ChatMessage];
        
        if(!self.ChatIsReaded && (![ChatMessage.Readed boolValue] || HasSectionNew))
        {
            [MessageModel setSectionKey:@"new"];
            
            HasSectionNew = YES;
        }
        
        if(!self.IsP2P && [MessageModel.MessageDirection isEqualToString:UiChatMessageDirectionTypeIncoming] && ChatMessage.Sender)
        {
            [MessageModel setSenderXmppId:[ContactsManager GetXmppIdOfContact:ChatMessage.Sender]];
            
            if(MessageModel.SenderXmppId)
            {
                [self SetStatusToMessageModel:MessageModel];
            }
            
            @weakify(self);
            @weakify(MessageModel);
            
           [[ContactsManager Contacts].XmppStatusesSignal subscribeNext:^(NSMutableArray *StatusesArr) {
                
                @strongify(self);
                @strongify(MessageModel);
                
                for(NSString *XmppId in StatusesArr)
                {
                    if([XmppId isEqualToString:MessageModel.SenderXmppId])
                    {
                        
                        [self SetStatusToMessageModel:MessageModel];
                    }
                }
                
            }];
            
        }
        
        [self SetSelected:MessageModel];
        
        [self AddToSection:MessageModel];
        
        if(i < [self.Messages count])
        {
            [self.Messages replaceObjectAtIndex:i withObject:MessageModel];
        }
        else
        {
            [self.Messages addObject:MessageModel];
            
        }
       
        i++;
    }
    
    [self ResetDeliverStatusesOfMessagesInAllSections];
    
    NSDictionary *MessagesStage = @{@"Sections":self.Sections, @"SectionsKeys":self.SectionsKeys};
    
    [self.MessagesUpdateStages addObject:MessagesStage];
    
    self.DataReloaded = [NSNumber numberWithBool:YES];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        
        __weak id _self = self;
        
        if(self.SetChatReadedTimer)
            [self.SetChatReadedTimer invalidate];
        
        self.SetChatReadedTimer = [NSTimer scheduledTimerWithTimeInterval:1.0
                                                                   target:_self
                                                                 selector:@selector(SetChatReaded)
                                                                 userInfo:nil
                                                                  repeats:NO];
        
    });
}

- (void) SetMessageModelSectionKey:(UiChatViewMessagesCellModel *) MessageModel
{
    NSDateFormatter *GroupFormatter = [[NSDateFormatter alloc] init];
    
    GroupFormatter.timeStyle = NSDateFormatterNoStyle;
    GroupFormatter.dateStyle = NSDateFormatterShortStyle;
    GroupFormatter.doesRelativeDateFormatting = YES;
    
    [GroupFormatter setLocale:[[NSLocale alloc] initWithLocaleIdentifier:[AppManager app].UserSettingsModel.GuiLanguage]];
    
    
    [MessageModel setSectionKey:[GroupFormatter stringFromDate:MessageModel.MessageData.SendTime]];
}

- (void) SetMessageModelTime:(UiChatViewMessagesCellModel *) MessageModel
{
    NSDateFormatter *TimeFormatter = [[NSDateFormatter alloc] init];
    
    TimeFormatter.timeStyle = NSDateFormatterShortStyle;
    TimeFormatter.dateStyle = NSDateFormatterNoStyle;
    TimeFormatter.doesRelativeDateFormatting = YES;
    
    [TimeFormatter setLocale:[[NSLocale alloc] initWithLocaleIdentifier:[AppManager app].UserSettingsModel.GuiLanguage]];
    
    [MessageModel setMessageTime:[TimeFormatter stringFromDate:MessageModel.MessageData.SendTime]];
}

- (void) PrepareMessageModel:(UiChatViewMessagesCellModel *) MessageModel WithChatMessage:(ObjC_ChatMessageModel *) ChatMessage
{
    BOOL ShouldReset = NO;
    
    if(MessageModel.IsMultyChatMessage == self.IsP2P)
        ShouldReset = YES;

    ObjC_ChatMessageModel * OldMessageData;
    
    if(MessageModel.MessageData)
    {
        OldMessageData = MessageModel.MessageData;
    }
    
    if(!OldMessageData || ![ChatsManager CompareMessageModel:ChatMessage WithMessageModel:OldMessageData])
    {
        ShouldReset = YES;
    }
    
    if(ShouldReset)
    {
        //NSLog(@"========NOT EQUAL========");
        
        [MessageModel setIsMultyChatMessage:!self.IsP2P];
        
        [MessageModel setMessageData: [ChatsManager CopyMessageModel:ChatMessage]];
        
        if(ChatMessage.Type == ChatMessageTypeNotification || ChatMessage.Type == ChatMessageTypeSubject)
        {
            [MessageModel setMessageType:UiChatMessageTypeInfoText];
        }
        else
        {
            [MessageModel setMessageType:UiChatMessageTypeText];
        }
        
        [MessageModel setMessageSenderTitle:[ChatsManager GetMessageSenderFirstAndLastName:ChatMessage]];
        
        [MessageModel setIsReaded:[ChatMessage.Readed boolValue]];
        
        if(!MessageModel.IsReaded)
            self.LastUnreadedMessageId = [ChatMessage.Id copy];
        
        if([ChatMessage.Sender.Iam boolValue])
        {
            [MessageModel setMessageDirection:UiChatMessageDirectionTypeOutgoing];
        }
        else
        {
            [MessageModel setMessageDirection:UiChatMessageDirectionTypeIncoming];
        }
        
        
        [self SetMessageModelTime:MessageModel];
        
        
        [MessageModel setMessageText:[ChatsManager MessageToText:ChatMessage]];
        
        if(MessageModel.MessageText.length == 0)
            [MessageModel setMessageText:@"  "];
        
        [MessageModel PrepareAttributedString];
        
        [MessageModel setDeliveryStatus:[NSNumber numberWithInt:[ChatsManager GetMessageDeliveryStatus:ChatMessage]]];
        
        
        [MessageModel setWasEdited:ChatMessage.Changed];

        MessageModel.AvatarPath = [[ContactsManager Manager] AvatarPathForContact:ChatMessage.Sender];
        
        [[[RACObserve([ContactsManager Manager], AvatarUpdate)
            filter:^BOOL(ContactAvatarUpdateSignalObject *Update) {
                return [Update.ContactId isEqualToString:ChatMessage.Sender.DodicallId];
            }]
            map:^id(ContactAvatarUpdateSignalObject *Update) {
                return Update.AvatarPath;
            }]
            subscribeNext:^(NSString *Path) {
                MessageModel.AvatarPath = Path;
            }];
        
        [MessageModel CalcMessageTextViewSize];
        
        [MessageModel CalcCellHeight];
        
        
        [self SetMessageModelSectionKey: MessageModel];
        
        
        
    }
    
    if([MessageModel.SectionKey isEqual:@"new"])
    {
        [self SetMessageModelSectionKey: MessageModel];
    }
    
    /*
    else
    {
        NSLog(@"========EQUAL========");
    }
     */
    
}

- (void) AddToSection:(UiChatViewMessagesCellModel *) Model
{
    
    NSString *SectionKey = Model.SectionKey;
    
    NSMutableArray *Rows = [self.Sections objectForKey:SectionKey];
    
    if(!Rows)
    {
        Rows = [[NSMutableArray alloc] init];
        [self.Sections setObject:Rows forKey:SectionKey];
        
        
        UiChatViewMessagesHeaderCellModel *Group = [[UiChatViewMessagesHeaderCellModel alloc] init];
        
        if([SectionKey isEqualToString: @"new"])
        {
            Group.Type = UiChatViewMessagesHeaderCellModelTypeNewMessages;
            Group.Key = SectionKey;
            Group.Title = NSLocalizedString(@"Title_UnreadMessages", nil);
        }
        else
        {
            Group.Type = UiChatViewMessagesHeaderCellModelTypeDate;
            Group.Key = SectionKey;
            Group.Title = SectionKey;
        }
        
        [self.SectionsKeys addObject:Group];
        
    }
    
    [Rows addObject:Model];
    
    if([Model.MessageDirection isEqualToString:UiChatMessageDirectionTypeOutgoing] && Model.DeliveryStatus && [Model.DeliveryStatus intValue] > ChatsMessageDeliveryStatusNone)
    {
        [(UiChatViewMessagesHeaderCellModel *)[self.SectionsKeys lastObject] setSectionDeliveryStatus:[Model.DeliveryStatus copy]];
    }
}

- (void) SetStatus
{
    
    //Status
    ObjC_ContactPresenceStatusModel *Status = [ContactsManager GetXmppStatusByXmppId:self.XmppId];
    
    switch (Status.BaseStatus) {
            
        case BaseUserStatusOnline:
            [self setStatus:@"ONLINE"];
            break;
            
        case BaseUserStatusDnd:
            [self setStatus:@"DND"];
            break;
            
        case BaseUserStatusAway:
            [self setStatus:@"AWAY"];
            break;
            
        case BaseUserStatusHidden:
            [self setStatus:@"INVISIBLE"];
            break;
            
        default:
            [self setStatus:@"OFFLINE"];
            break;
    }
}

- (void) SetStatusToMessageModel:(UiChatViewMessagesCellModel *) MessageModel
{
    
    //Status
    ObjC_ContactPresenceStatusModel *Status = [ContactsManager GetXmppStatusByXmppId:MessageModel.SenderXmppId];
    
    switch (Status.BaseStatus) {
            
        case BaseUserStatusOnline:
            [MessageModel setStatus:@"ONLINE"];
            break;
            
        case BaseUserStatusDnd:
            [MessageModel setStatus:@"DND"];
            break;
            
        case BaseUserStatusAway:
            [MessageModel setStatus:@"AWAY"];
            break;
            
        case BaseUserStatusHidden:
            [MessageModel setStatus:@"INVISIBLE"];
            break;
            
        default:
            [MessageModel setStatus:@"OFFLINE"];
            break;
    }
}

- (void) SendTextMessage
{
    self.AutoScrollEnabled = YES;
    
    NSString *Text = [self.FooterInputText copy];
    
    [self setFooterInputText:@""];
    
    [ChatsManager SendMessage:Text ToChat:self.ChatData.Id];
    
}

- (void) SetChatReaded
{
    [UiLogger WriteLogInfo:[NSString stringWithFormat:@"UiChatViewModel:SetChatReaded:%@",self.ChatData.Id]];
    
    if(self.LastUnreadedMessageId && self.LastUnreadedMessageId.length > 0)
    {
        [ChatsManager SetChatReadedWithLastUnreadMessageId:self.LastUnreadedMessageId InChatId:[self.ChatData.Id copy]];
        
        self.LastUnreadedMessageId = nil;
    }
    
    self.ChatIsReaded = YES;
}

- (void) ResetDeliverStatusesOfMessagesInAllSections
{
    for(UiChatViewMessagesHeaderCellModel *Section in self.SectionsKeys)
    {
        NSMutableArray *Rows = [self.Sections objectForKey:Section.Key];
        
        int _PreviousOutgoingMessageIndex = -1;
        
        for (int i = 0; i <= [Rows count] - 1; i++) {
            
            UiChatViewMessagesCellModel *MessageModel = Rows[i];
            
            if([MessageModel.MessageDirection isEqualToString:UiChatMessageDirectionTypeOutgoing])
            {
                if(_PreviousOutgoingMessageIndex == -1)
                    _PreviousOutgoingMessageIndex = i;
                
                UiChatViewMessagesCellModel *PreviousMessageModel = Rows[_PreviousOutgoingMessageIndex];
                
                if(_PreviousOutgoingMessageIndex < i && [MessageModel.DeliveryStatus intValue] == [PreviousMessageModel.DeliveryStatus integerValue] )
                {
                    PreviousMessageModel.DeliveryStatus = nil;
                }
                
                _PreviousOutgoingMessageIndex = i;
                
            }
            
        }
    }
}

/*
- (void) PrepareToDestroy
{
    if(self.SetChatReadedTimer)
        [self.SetChatReadedTimer invalidate];
    
    for(RACDisposable *Disposable in self.DisposableRacArr)
    {
        [Disposable dispose];
    }
    
    [self.DisposableRacArr removeAllObjects];
    
    self.DataReloadedSignal = nil;
    
    self.ChatDataSignal = nil;
    
    //self.XmppStatusesSignal = nil;
}
 */
- (void) SetMenuModel {
    NSMutableArray *newModel = [NSMutableArray new];
    UiChatMenuCellModel *cellModel = [UiChatMenuCellModel new];
    
    //TODO: Switch to P2P?
    if(self.ChatData.Contacts.count > 2) {
        cellModel.Title = NSLocalizedString(@"ChatMenu_StartConference", nil);
        cellModel.ImageName = @"conference_chat_menu";
        cellModel.SelectCommand = self.ShowComingSoon;
        [newModel addObject:cellModel];
    }
    
    cellModel = [UiChatMenuCellModel new];
    cellModel.Title = NSLocalizedString(@"ChatMenu_Settings", nil);
    cellModel.ImageName = @"gear_chat_menu";
    cellModel.SelectCommand = self.ShowChatSettings;
    [newModel addObject:cellModel];
    
    cellModel = [UiChatMenuCellModel new];
    cellModel.Title = NSLocalizedString(@"ChatMenu_EditMessages", nil);
    cellModel.ImageName = @"pencil_chat_menu";
    cellModel.SelectCommand = self.ShowComingSoon;
    [newModel addObject:cellModel];
    
    if(![self IsP2P]) {
        cellModel = [UiChatMenuCellModel new];
        cellModel.Title = NSLocalizedString(@"ChatMenu_LeaveChat", nil);
        cellModel.ImageName = @"leave_chat_menu";
        cellModel.SelectCommand = self.ShowComingSoon;
        [newModel addObject:cellModel];
    }
    
    self.MenuRowModels = newModel;
}

- (RACSignal *)ExecuteShowComingSoon {
    return [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        [UiNavRouter ShowComingSoon];
        [subscriber sendCompleted];
        
        return [RACDisposable new];
    }];
}

- (RACSignal *)ExecuteShowChatSettings {
    return [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        [UiChatsTabNavRouter ShowChatSettings];
        [subscriber sendCompleted];
        
        return [RACDisposable new];
    }];
}
- (RACSignal *)ExecuteShowChatUsers {
    return [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        [UiChatsTabNavRouter ShowChatUserSettingsForChat:[ChatsManager CopyChat:self.ChatData]];
        [subscriber sendCompleted];
        
        return [RACDisposable new];
    }];
}


#pragma mark Edit mode

- (void) EnableEditMode:(BOOL) Enabled
{
    if(!Enabled)
    {
        self.SelectedMessages = [NSMutableArray new];
    }
    
    [self setEditModeEnabled:[NSNumber numberWithBool:Enabled]];
    
    dispatch_async([ChatsManager Manager].ViewModelQueue, ^{
        [self ReloadData];
        [self CalcSelectedNumber];
    });
}

- (void) DisableEditMode
{
    [self EnableEditMode:NO];
}

- (void) SwitchEditMode
{
    [self EnableEditMode:![self.EditModeEnabled boolValue]];
}

- (void) SetSelected:(UiChatViewMessagesCellModel *) RowModel
{
    [RowModel setIsSelected:[NSNumber numberWithBool:NO]];
    
    if(self.SelectedMessages && [self.SelectedMessages count] > 0)
    {
        for (ObjC_ChatMessageModel *Message in self.SelectedMessages) {
            
            if([Message.Id isEqualToString:RowModel.MessageData.Id])
            {
                [RowModel setIsSelected:[NSNumber numberWithBool:YES]];
                
                break;
            }
            
        }
    }
}

- (BOOL) CanEditSelectCellWithModel:(UiChatViewMessagesCellModel *) RowItem
{
    BOOL CanEdit = NO;
    
    if([RowItem.MessageDirection isEqualToString:UiChatMessageDirectionTypeOutgoing] && [RowItem.MessageType isEqualToString:UiChatMessageTypeText])
    {
        if(RowItem.MessageData.Type != ChatMessageTypeDeleter)
        {
            
            NSTimeInterval DstanceBetweenDatesInMins = [[NSDate date] timeIntervalSinceDate:RowItem.MessageData.SendTime] / 60;
            
            
            if(DstanceBetweenDatesInMins <= 10 || ![RowItem.MessageData.Servered boolValue])
            {
                
                CanEdit = YES;
            }
        }
        
    }
    
    return CanEdit;
}

- (BOOL) SelectCell:(BOOL) Selected withMessagesCellModel:(UiChatViewMessagesCellModel *) RowItem
{
    BOOL Allowed = [self CanEditSelectCellWithModel:RowItem];
    
    if(Allowed)
    {
        if(Selected)
            [self AddToSelected:RowItem];
        else
            [self RemoveFromSelected:RowItem];
    }
    
    
    return Allowed;
}

- (void) AddToSelected:(UiChatViewMessagesCellModel *) RowModel
{
    BOOL HasChat = NO;
    
    for (ObjC_ChatMessageModel *Message in self.SelectedMessages) {
        
        if([Message.Id isEqualToString:RowModel.MessageData.Id])
        {
            HasChat = YES;
            
            break;
        }
        
    }
    
    if(!HasChat)
    {
        [self.SelectedMessages addObject:RowModel.MessageData];
    }
    
    [self SetSelected:RowModel];
    
    [self CalcSelectedNumber];
    
}

- (void) RemoveFromSelected:(UiChatViewMessagesCellModel *) RowModel
{
    for (ObjC_ChatMessageModel *Message in self.SelectedMessages) {
        
        if([Message.Id isEqualToString:RowModel.MessageData.Id])
        {
            [self.SelectedMessages removeObject:Message];
            
            break;
        }
        
    }
    
    [self SetSelected:RowModel];
    
    [self CalcSelectedNumber];
}

- (void) RevertSelected:(UiChatViewMessagesCellModel *) RowModel
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

- (void) CalcSelectedNumber
{
    
    [self setSelectedCellsNumber:[NSNumber numberWithInteger:[self.SelectedMessages count]]];
}

- (void) DeleteSelectedMessages
{
    if(self.SelectedMessages && [self.SelectedMessages count] > 0)
    {
        NSMutableArray <NSString *> *MessagesIds = [NSMutableArray new];
        
        for (ObjC_ChatMessageModel *Message in [self.SelectedMessages copy])
        {
            [MessagesIds addObject:[Message.Id copy]];
        }
        
        [[ChatsManager Chats] DeleteMessages:MessagesIds WithChatId:[self.ChatData.Id copy]];
    }
}


@end
