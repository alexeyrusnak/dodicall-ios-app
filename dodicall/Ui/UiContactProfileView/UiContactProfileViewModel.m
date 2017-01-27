//
//  UiContactProfileViewModel.m
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

#import "UiContactProfileViewModel.h"
#import "UiContactProfileAddContactsTableCellViewModel.h"
#import "ContactsManager.h"
#import "AppManager.h"
#import "UiLogger.h"

@interface UiContactProfileViewModel()
{
    BOOL IsBinded;
}
@end

@implementation UiContactProfileViewModel

- (instancetype)init
{
    self = [super init];
    if (self) {
        
        self.ContactData = [[ObjC_ContactModel alloc] init];
        
        self.IsRequestInputPanelOpened = NO;
        
        [self BindAll];
    }
    return self;
}

- (void) BindAll
{
    if(IsBinded)
        return;
    
    @weakify(self);
    
    self.SaveCommand = [[RACCommand alloc] initWithSignalBlock:^RACSignal *(id input) {
        @strongify(self);
        return [self ExecuteSaveActionN];
    }];
    
    
    //Check
    /*
    RACSignal *UpdatedContact = [[[[[[[ContactsManager Contacts].ContactsListStateSignal
        filter:^BOOL(NSNumber *State) {
            return ([State integerValue]==ContactsListLoadingStateFinishedSuccess || [State integerValue] == ContactsListLoadingStateUpdated);
        }]
        map:^id(NSNumber *State) {
            @strongify(self);
            return @([[ContactsManager Contacts] FindContactIndex:self.ContactData]);
        }]
        filter:^BOOL(NSNumber *Index) {
            return ([Index integerValue] != NSNotFound);
        }]
        map:^id(NSNumber *Index) {
            return [[ContactsManager Contacts].ContactsList objectAtIndex:[Index integerValue]];
        }]
        filter:^BOOL(ObjC_ContactModel *NewContact) {
            @strongify(self);
            return (![ContactsManager IsContact:NewContact IsEqualTo:self.ContactData]);
        }]
        doNext:^(ObjC_ContactModel *NewContact) {
            @strongify(self);
            self.ContactData = NewContact;
        }];
     */
    
    RACSignal *UpdatedContact = [[[ContactsManager Contacts].ContactUpdateSignal
         filter:^BOOL(ContactUpdateSignalObject *Signal) {
     
            BOOL Passed = NO;
            
            if(Signal.State == ContactUpdatingStateUpdated || Signal.State == ContactUpdatingStateAdded)
            {
                @strongify(self);
                
                if ([ContactsManager AreContactsEqualsByIds:Signal.Contact :self.ContactData])
                {
                    Passed = YES;
                }
            }
            
            return Passed;
            
        }] map:^ObjC_ContactModel *(ContactUpdateSignalObject *Signal) {
            
            return Signal.Contact;
            
        }];
    
    RAC(self, ContactData) = UpdatedContact;
    
    
    [[RACSignal combineLatest:@[RACObserve(self, ContactData), [ContactsManager Contacts].ContactsSubscriptionsSignal] reduce:^ObjC_ContactModel *(ObjC_ContactModel *Data, NSMutableDictionary *Subscriptions){
        
        return Data;
        
    }] subscribeNext:^(ObjC_ContactModel *Data) {
        
        @strongify(self);
        
        [self UpdateData:Data];
        
    }];
    
    /*
    [RACObserve(self, ContactData) subscribeNext:^(ObjC_ContactModel *Data) {
        
        @strongify(self);
        
        [self UpdateData:Data];
        
    }];
     */
    
    // Observe status changed event
     RACSignal *StatusChange = [[[[ContactsManager Contacts].XmppStatusesSignal
        map:^id(NSArray *Statuses) {
            @strongify(self);
            return @([Statuses containsObject:self.XmppId]);
        }]
        filter:^BOOL(NSNumber *Updated) {
            return [Updated boolValue];
        }]
        deliverOn:[ContactsManager Manager].ViewModelScheduler];
    
    [self rac_liftSelector:@selector(SetStatus:) withSignals:StatusChange, nil];

    
    //Subscription
    RACSignal *InviteSignal = [[ContactsManager Contacts].ContactsSubscriptionsSignal
      map:^id(NSMutableDictionary *Subscriptions) {
          @strongify(self);
          return @([ContactsManager CheckContactIsInvite:self.ContactData]);
      }];
    
    RAC(self, IsInvite) = [InviteSignal deliverOn:[ContactsManager Manager].ViewModelScheduler];
    
    RACSignal *DeclinedRequestSignal = [[[ContactsManager Contacts].ContactsSubscriptionsSignal
                                        map:^id(NSMutableDictionary *Subscriptions) {
                                            @strongify(self);
                                            return @([ContactsManager CheckContactIsDeclinedRequest:self.ContactData]);
                                        }]
                                        subscribeOn:[ContactsManager Manager].ViewModelScheduler];
    
    RAC(self, IsDeclinedRequest) = DeclinedRequestSignal;
    
    RACSignal *RequestSignal = [[[ContactsManager Contacts].ContactsSubscriptionsSignal
       map:^id(NSMutableDictionary *Subscriptions) {
           @strongify(self);
           return @([ContactsManager CheckContactIsRequest:self.ContactData]);
       }]
       subscribeOn:[ContactsManager Manager].ViewModelScheduler];

    RAC(self, IsRequest) = RequestSignal;
    
    
    [[[[[[[RACObserve(self, IsIam) distinctUntilChanged]
        filter:^BOOL(NSNumber *Iam) {
            return [Iam boolValue];
        }]
        doNext:^(id x) {
            [[AppManager app].UserSession UpdateBalance];
        }]
        merge:RACObserve([AppManager app].UserSettingsModel, UserBaseStatus)]
        merge:RACObserve([AppManager app].UserSettingsModel, UserExtendedStatus)]
        deliverOn:[ContactsManager Manager].ViewModelScheduler]
        subscribeNext:^(id x) {
            @strongify(self);
            [self SetMyProfileStatus];
        }];
    
    // Balance
    RAC(self, BalanceTextValue) = [RACObserve([AppManager app].UserSession, BalanceString) deliverOn:[ContactsManager Manager].ViewModelScheduler];

    
    RAC(self, AvatarPath) = [[ContactsManager Manager] AvatarSignalForContactUpdate:RACObserve(self, ContactData) WithDoNextBlock:^(NSString *Path) {
        @strongify(self);
        self.AvatarPath = Path;
    }];
    
    IsBinded = YES;
}

- (void) UpdateData: (ObjC_ContactModel *) Data
{
    ContactProfileType Type = [ContactsManager GetContactProfileType:Data];
    
    [self setIsIam:[Data.Iam boolValue]];
    
    if(Type == ContactProfileTypeDirectoryLocal)
    {
        [self setIsDirectoryLocalType:YES];
        [self setIsDirectoryRemoteType:NO];
        [self setIsLocalType:NO];
        [self setIsPhonebookType:NO];
    }
    
    if(Type == ContactProfileTypeDirectoryRemote)
    {
        [self setIsDirectoryLocalType:NO];
        [self setIsDirectoryRemoteType:YES];
        [self setIsLocalType:NO];
        [self setIsPhonebookType:NO];
        
        // Check if contact is in local directory
        NSInteger ContactIndex = [[ContactsManager Contacts] FindContactIndex:Data];
        if(ContactIndex != NSNotFound)
            [self setIsInLocalDirectory:YES];
        
    }
    
    if(Type == ContactProfileTypeLocal)
    {
        [self setIsDirectoryLocalType:NO];
        [self setIsDirectoryRemoteType:NO];
        [self setIsLocalType:YES];
        [self setIsPhonebookType:NO];
        
        
    }
    
    if(Type == ContactProfileTypePhonebook)
    {
        [self setIsDirectoryLocalType:NO];
        [self setIsDirectoryRemoteType:NO];
        [self setIsLocalType:NO];
        [self setIsPhonebookType:YES];
    }
    
    [self setIsInvite:@([ContactsManager CheckContactIsInvite:Data])];
    
    if([self.IsInvite boolValue])
    {
        if(Data.subscription.SubscriptionStatus == ContactSubscriptionStatusNew)
        {
            [[ContactsManager Contacts] MarkInviteAsRead:Data];
        }
    }
    
    [self setIsRequest:@([ContactsManager CheckContactIsRequest:Data])];
    
    [self setIsDeclinedRequest:@([ContactsManager CheckContactIsDeclinedRequest:Data])];
    
    [self setFirstNameLabelText:Data.FirstName];
    
    [self setLastNameLabelText:Data.LastName];
    
    [self setStatusLabelText:[NSStringHelper CapitalaizeFirstLetter:NSLocalizedString(@"title_OFFLINE", nil)]];
    
    [self setIsCallAvailable:FALSE];
    
    [self setIsVideoCallAvailable:FALSE];
    
    [self setIsChatCallAvailable:FALSE];
    
    [self setIsBlocked:[Data.Blocked boolValue]];
    
    // Sort contacts
    if(Data.Contacts)
        [ContactsManager SortContactContacts:Data.Contacts];
    
    // Populate contacts table
    
    NSMutableArray *__ContactsTable = [[NSMutableArray alloc] init];
    
    if(self.IsDirectoryLocalType || self.IsDirectoryRemoteType)
    {
        for (ObjC_ContactsContactModel *Contact in Data.Contacts) {
            
            UiContactProfileContactsTableCellViewModel * CellModel = [[UiContactProfileContactsTableCellViewModel alloc] init];
            
            if(![Contact.Manual boolValue] && (Contact.Type == ContactsContactSip /*|| Contact.Type == ContactsContactPhone*/))
            {
                if(Contact.Type == ContactsContactSip)
                    [CellModel setTypeLabelText:[NSLocalizedString(@"Title_ContactsContactSip", nil) lowercaseString]];
                
                else if(Contact.Type == ContactsContactPhone)
                    [CellModel setTypeLabelText:[NSLocalizedString(@"Title_ContactsContactPhone", nil) lowercaseString]];
                
                else
                    [CellModel setTypeLabelText:@""];
                
                [CellModel setPhoneLabelText:[Contact.Identity componentsSeparatedByString:@"@"][0]];
                
                [CellModel setIsFavourite:[Contact.Favourite boolValue]];
                
                [CellModel setContact:Contact];
                
                [__ContactsTable addObject:CellModel];
                
            }
            
        }
    }
    
    [self setContactsTable:__ContactsTable];
    
    // Populate add contacts table
    
    NSMutableArray *__AddContactsTable = [[NSMutableArray alloc] init];
    
    for (ObjC_ContactsContactModel *Contact in Data.Contacts) {
        
        if(((self.IsDirectoryLocalType || self.IsIam /*|| self.IsDirectoryRemoteType*/) && ([Contact.Manual boolValue] || Contact.Type == ContactsContactPhone)) || (!self.IsDirectoryLocalType && !self.IsDirectoryRemoteType))
        {
            UiContactProfileAddContactsTableCellViewModel * CellModel = [[UiContactProfileAddContactsTableCellViewModel alloc] init];
            
            if(Contact.Type == ContactsContactSip || Contact.Type == ContactsContactPhone)
            {
                if(Contact.Type == ContactsContactSip)
                    [CellModel setTypeLabelText:[NSLocalizedString(@"Title_ContactsContactSip", nil) lowercaseString]];
                
                else if(Contact.Type == ContactsContactPhone)
                    [CellModel setTypeLabelText:[NSLocalizedString(@"Title_ContactsContactPhone", nil) lowercaseString]];
                
                else
                    [CellModel setTypeLabelText:@""];
                
                [CellModel setPhoneLabelText:[Contact.Identity componentsSeparatedByString:@"@"][0]];
                
                [CellModel setContact:Contact];
                
                [__AddContactsTable addObject:CellModel];
                
            }
        }
    }
    
    [self setAddContactsTable:__AddContactsTable];
    
    // Set status
    if(self.IsDirectoryLocalType)
    {
        
        [self setXmppId:[ContactsManager GetXmppIdOfContact:Data]];
        
        if(self.XmppId)
        {
            [self SetStatus:@(YES)];
            if(self.IsIam)
                [self SetMyProfileStatus];
            
        }
    }
}

- (void) SetStatus:(NSNumber *)Updated
{
    
    if(!self.XmppId)
        return;
    
    //Status
    ObjC_ContactPresenceStatusModel *__Status = [ContactsManager GetXmppStatusByXmppId:self.XmppId];
    
    switch (__Status.BaseStatus) {
            
        case BaseUserStatusOnline:
            [self setStatus:@"ONLINE"];
            [self setStatusLabelText:[NSStringHelper CapitalaizeFirstLetter:NSLocalizedString(@"title_ONLINE", nil)]];
            break;
            
        case BaseUserStatusDnd:
            [self setStatus:@"DND"];
            [self setStatusLabelText:[NSStringHelper CapitalaizeFirstLetter:NSLocalizedString(@"title_DND", nil)]];
            break;
            
        case BaseUserStatusAway:
            [self setStatus:@"AWAY"];
            [self setStatusLabelText:[NSStringHelper CapitalaizeFirstLetter:NSLocalizedString(@"title_AWAY", nil)]];
            break;
            
        case BaseUserStatusHidden:
            [self setStatus:@"INVISIBLE"];
            [self setStatusLabelText:[NSStringHelper CapitalaizeFirstLetter:NSLocalizedString(@"title_INVISIBLE", nil)]];
            break;
            
        default:
            [self setStatus:@"OFFLINE"];
            [self setStatusLabelText:[NSStringHelper CapitalaizeFirstLetter:NSLocalizedString(@"title_OFFLINE", nil)]];
            break;
    }
    
    if(__Status.ExtStatus && __Status.ExtStatus.length > 0)
        [self setStatusLabelText:[[self.StatusLabelText stringByAppendingString:@". "] stringByAppendingString:__Status.ExtStatus]];
}

- (void) SetMyProfileStatus
{
    
    
    //Status
    BaseUserStatus __Status = [AppManager app].UserSettingsModel.UserBaseStatus;
    
    switch (__Status) {
            
        case BaseUserStatusOnline:
            [self setMyProfileStatus:@"ONLINE"];
            [self setMyProfileStatusLabelText:[NSStringHelper CapitalaizeFirstLetter:NSLocalizedString(@"title_ONLINE", nil)]];
            break;
            
        case BaseUserStatusDnd:
            [self setMyProfileStatus:@"DND"];
            [self setMyProfileStatusLabelText:[NSStringHelper CapitalaizeFirstLetter:NSLocalizedString(@"title_DND", nil)]];
            break;
            
        case BaseUserStatusAway:
            [self setMyProfileStatus:@"AWAY"];
            [self setMyProfileStatusLabelText:[NSStringHelper CapitalaizeFirstLetter:NSLocalizedString(@"title_AWAY", nil)]];
            break;
            
        case BaseUserStatusHidden:
            [self setMyProfileStatus:@"INVISIBLE"];
            [self setMyProfileStatusLabelText:[NSStringHelper CapitalaizeFirstLetter:NSLocalizedString(@"title_INVISIBLE", nil)]];
            break;
            
        default:
            [self setMyProfileStatus:@"INVISIBLE"];
            [self setMyProfileStatusLabelText:[NSStringHelper CapitalaizeFirstLetter:NSLocalizedString(@"title_OFFLINE", nil)]];
            break;
    }
    
    NSString *StatusString = [AppManager app].UserSettingsModel.UserExtendedStatus;
    
    if(StatusString && StatusString.length > 0)
        [self setMyProfileStatusLabelText:[[self.MyProfileStatusLabelText stringByAppendingString:@". "] stringByAppendingString:StatusString]];
}





- (void) SetFavourite:(UiContactProfileContactsTableCellViewModel *) RowItem
{
    [self setNeedToBeSaved:YES];
    
    if(!RowItem.IsFavourite)
    {

        [RowItem setIsFavourite:YES];
        [RowItem.Contact setFavourite:[NSNumber numberWithBool:YES]];
        
    }
    else
    {
        [RowItem setIsFavourite:NO];
        [RowItem.Contact setFavourite:[NSNumber numberWithBool:NO]];
    }
    
    for(UiContactProfileContactsTableCellViewModel *Item in self.ContactsTable)
    {
        if(Item != RowItem)
        {
            [Item setIsFavourite:NO];
            [Item.Contact setFavourite:[NSNumber numberWithBool:NO]];
        }
    }
}

- (void) ExecuteAcceptAction:(BOOL) Accept withCallback:(void (^)(BOOL))Callback
{
    [UiLogger WriteLogInfo:[NSString stringWithFormat:@"UiContactProfileViewModel: Accept-Reject action executed with status %@",Accept ? @"Accepted" : @"Rejected"]];
    [UiLogger WriteLogDebug:[NSString stringWithFormat:@"ContactModel: %@", [CoreHelper ContactModelDescription:self.ContactData]]];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        
        ContactIdType ContactId = 0;
        
        BOOL Result;
        
        if(Accept)
        {
            ObjC_ContactModel *ResultContact = [[AppManager app].Core SaveContact:self.ContactData];
            
            if(ResultContact && ResultContact.Id)
            {
                ContactId = ResultContact.Id;
                self.ContactData.Id = ContactId;
            }
            
        }
        else
        {
            Result = [[ContactsManager Contacts] RejectInviteByUser:self.ContactData]; //[[AppManager app].Core AnswerSubscriptionRequest:ContactData:Accept];
        }
        
        
        dispatch_async(dispatch_get_main_queue(), ^{
            
            if((Accept && ContactId > 0) || (!Accept && Result))
            {
                
                [UiLogger WriteLogInfo:@"UiContactProfileViewModel: Accept-Reject action finished with success"];
                Callback(YES);
            }
            else
            {
                [UiLogger WriteLogInfo:@"UiContactProfileViewModel: Accept-Reject action failed"];
                Callback(NO);
            }
            
            
        });
    });
}

- (void) ExecuteUnblockAction:(void (^)(BOOL))Callback
{
    [UiLogger WriteLogInfo:@"UiContactProfileViewModel: Unblock action executed with status"];
    
    self.ContactData.Blocked = [NSNumber numberWithBool:NO];
    
    [UiLogger WriteLogDebug:[NSString stringWithFormat:@"ContactModel: %@", [CoreHelper ContactModelDescription:self.ContactData]]];
    
    
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        ContactIdType ContactId = 0;
        
        ObjC_ContactModel *ResultContact = [[AppManager app].Core SaveContact:self.ContactData];
        
        if(ResultContact && ResultContact.Id)
            ContactId = ResultContact.Id;
        
        
        dispatch_async(dispatch_get_main_queue(), ^{
            
            if(ContactId > 0)
            {
                
                self.ContactData.Id = ContactId;
                
                [self setIsBlocked:NO];
                
                Callback(YES);
            }
            else
            {
                [self setIsBlocked:YES];
                
                Callback(NO);
            }
            
            
        });
        
    });
}
- (RACSignal *)ExecuteSaveActionN {
    @weakify(self);
    return [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        @strongify(self);
        
        self.SavingProcessState = [NSNumber numberWithInt:UiContactProfileSavingStateStart];
        
        
        ContactIdType ContactId = 0;
        
        ObjC_ContactModel *ResultContact = [[AppManager app].Core SaveContact:self.ContactData];
        
        if(ResultContact && ResultContact.Id)
            ContactId = ResultContact.Id;
        
        
        if(ContactId > 0) {
            self.ContactData.Id = ContactId;
            self.SavingProcessState = [NSNumber numberWithInt:UiContactProfileSavingStateCompleteWithSuccess];
        }
        else {
            self.SavingProcessState = [NSNumber numberWithInt:UiContactProfileSavingStateCompleteWithError];
        }
        
        [subscriber sendCompleted];
                
        
        return [RACDisposable new];
    }];
}
- (RACSignal *)ExecuteUnbind {
    return [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        
        IsBinded = NO;
        [subscriber sendCompleted];
        return [RACDisposable new];
    }];
}

- (void) Logout
{
    
    [[AppManager app].UserSession ExecuteLogoutProcess];
}

@end
