//
//  UiContactsListModel.m
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

#import "UiContactsListModel.h"
#import "UiContactsListRowItemModel.h"
#import "ContactsManager.h"
#import "CallsManager.h"

#import "UiLogger.h"

@implementation UiContactsListModel

@synthesize Data;

@synthesize Sections;

@synthesize SectionsKeys;

@synthesize DataReloaded;

@synthesize DataReloadedSignal;

@synthesize SearchText;

@synthesize Filter;

@synthesize TempContactData;

@synthesize DisposableRacArr;

//@synthesize XmppStatusesSignal;

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        //self.Data = [[NSMutableDictionary alloc] init];
        
        self.Filter = UiContactsFilterDirectoryLocal;
        
        self.Sections = [[NSMutableDictionary alloc] init];
        self.SectionsKeys = [[NSMutableArray alloc] init];
        
        self.ThreadSafeSections = [[NSMutableDictionary alloc] init];
        self.ThreadSafeSectionsKeys = [[NSMutableArray alloc] init];
        
        self.DataUpdateStages = [[NSMutableArray alloc] init];
        
        self.DisposableRacArr = [[NSMutableArray alloc] init];
        
        self.DataReloaded = [NSNumber numberWithBool:NO];
        self.DataReloadedSignal = RACObserve(self, DataReloaded);
        
        self.Mode = UiContactsListModeNormal;
        
        self.SelectedContacts = [[NSMutableArray alloc] init];
        
        self.DisabledContacts = [[NSMutableArray alloc] init];
        
        
        @weakify(self);
        
        //dispatch_async([ContactsManager Manager].ViewModelQueue, ^{
            
            [[[[ContactsManager Contacts].ContactsListStateSignal filter:^BOOL(NSNumber *State) {
                return [State integerValue] == ContactsListLoadingStateFinishedSuccess || [State integerValue] == ContactsListLoadingStateUpdated;
            }] deliverOn:[ContactsManager Manager].ViewModelScheduler] subscribeNext:^(NSNumber *State) {
                @strongify(self);
                    [self ReloadData];
            }];
            
            [[RACObserve(self, SelectedContacts) deliverOn:[ContactsManager Manager].ViewModelScheduler] subscribeNext:^(NSMutableArray *SelectedContacts) {
                @strongify(self);
                self.SelectedContactsCount = [NSNumber numberWithInteger:[SelectedContacts count]];
            }];
            
            
            [[[[RACObserve(self, Mode) ignore:nil]
                filter:^BOOL(UiContactsListMode Mode) {
                    if([Mode isEqualToString:UiContactsListModeCallTransfer])
                        return YES;
                    else
                        return NO;
                }] deliverOn:[ContactsManager Manager].ViewModelScheduler ]
                subscribeNext:^(UiContactsListMode Mode) {
                    ObjC_CallModel *Call = [[CallsManager Manager] GetCurrentActiveCall];
                 
                    if(Call && Call.Contact)
                    {
                        NSMutableArray *DisabledContacts = [NSMutableArray new];
                        [DisabledContacts addObject:[ContactsManager CopyContact:Call.Contact]];
                     
                        @strongify(self);
                        self.DisabledContacts = DisabledContacts;
                        [self ReloadData];
                    }
                }];
            
        //});

    }
    return self;
}

- (void) ReloadData
{
    //self.DataReloaded = [NSNumber numberWithBool:NO];
    
    for(RACDisposable *Disposable in self.DisposableRacArr)
    {
        [Disposable dispose];
    }
    
    [self.DisposableRacArr removeAllObjects];
    
    self.Sections = [[NSMutableDictionary alloc] init];
    
    //Sections keys
    NSString *_SectionsKeys = [NSString stringWithFormat:@"%@,%@",UiContactsListSectionsIndexDefault,UiContactsListSectionsIndexAll];
    
    if([[AppManager app].UserSettingsModel.GuiLanguage isEqualToString:UiLanguageRu])
    {
        _SectionsKeys = [NSString stringWithFormat:@"%@,%@,%@",UiContactsListSectionsIndexRU,UiContactsListSectionsIndexDefault,UiContactsListSectionsIndexAll];
    }
    
    self.SectionsKeys = [NSMutableArray arrayWithArray: [_SectionsKeys componentsSeparatedByString:@","]];
    
    
    NSMutableArray *ContactsArr = [NSMutableArray arrayWithArray:[ContactsManager Contacts].ContactsList];
    
    
    [self FilterContactsWithFilter:ContactsArr withFilter:self.Filter];
    
    if(self.SearchText.length > 0)
        [self FilterContactsWithSearchTextFilter:ContactsArr withFilter:self.SearchText];
    
    [UiLogger WriteLogInfo:[NSString stringWithFormat:@"UiContactsListModel:ReloadData: Contacts after filters apply: %lu", (unsigned long)[ContactsArr count]]];
    
    for (ObjC_ContactModel *ContactModel in ContactsArr) {
        
        UiContactsListRowItemModel *RowModel = [[UiContactsListRowItemModel alloc] init];
        
        [RowModel setContactData:ContactModel];
        
        //[RowModel setTitle:[[NSString stringWithFormat:@"%@ %@", ContactModel.FirstName, ContactModel.LastName] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]]];
        
        [RowModel setTitle:[ContactsManager GetContactTitle:ContactModel]]; 
        
        [RowModel setIsBlocked:[ContactModel.Blocked boolValue]];
        
        [RowModel setFilter:UiContactsFilterAll];
        
        if(ContactModel.PhonebookId && ContactModel.PhonebookId.length > 0)
            [RowModel setFilter:UiContactsFilterPhoneBook];
        
        if(ContactModel.DodicallId && ContactModel.DodicallId.length > 0)
        {
            [RowModel setFilter:UiContactsFilterDirectoryLocal];
            
            [RowModel setXmppId:[ContactsManager GetXmppIdOfContact:ContactModel]];
            
            if(RowModel.XmppId)
            {
                [self SetStatusToModel:RowModel];
                
                // Observe status changed event
                
                @weakify(self);
                
                RACDisposable *Disposable = [[RACObserve([ContactsManager Contacts], XmppStatuses) deliverOn:[ContactsManager Manager].ViewModelScheduler] subscribeNext:^(NSMutableArray *StatusesArr) {
                    
                    @strongify(self);
                    
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
        }
        
        if(ContactModel.DodicallId && ContactModel.DodicallId.length == 0 && ContactModel.PhonebookId && ContactModel.PhonebookId.length == 0)
            [RowModel setFilter:UiContactsFilterLocal];
        
        
        //ObjC_ContactSubscription *ContactSubscription = [ContactsManager GetContactSubscription:ContactModel];
        
        //[RowModel setIsSubscriptionFromOrNone:(ContactSubscription.SubscriptionState == ContactSubscriptionStateFrom || ContactSubscription.SubscriptionState == ContactSubscriptionStateNone)];
        
        [RowModel setIsRequest:[ContactsManager CheckContactIsRequest:ContactModel]];
        
        
        
        // DMC-2779
        if(!(RowModel.IsRequest && [self.Mode isEqualToString:UiContactsListModeMultySelectableForChat]))
        {
            [self SetSelected:RowModel];
        
            [self SetDisabled:RowModel];
        
            [self Add: RowModel];
        }
        
        @weakify(RowModel);
        RAC(RowModel, AvatarPath) = [[ContactsManager Manager] AvatarSignalForContactUpdate:[[RACSignal empty] startWith:ContactModel] WithDoNextBlock:^(NSString *Path) {
            @strongify(RowModel);
            RowModel.AvatarPath = Path;
        }];
        
        /*
        NSLog(@"=========");
        
        NSLog(RowModel.XmppId);
        NSLog(RowModel.Status);
        NSLog(RowModel.Description);
        
        NSLog(@"=========");
         */
        
    }
    
    NSDictionary *DataUpdatedStage = @{@"Sections":self.Sections, @"SectionsKeys":self.SectionsKeys};
    
    [self.DataUpdateStages addObject:DataUpdatedStage];
    
    self.DataReloaded = [NSNumber numberWithBool:YES];
    
}

- (void) SetStatusToModel:(UiContactsListRowItemModel *) RowModel
{
    
    //Status
    ObjC_ContactPresenceStatusModel *Status = [ContactsManager GetXmppStatusByXmppId:RowModel.XmppId];
    
    switch (Status.BaseStatus) {
            
        case BaseUserStatusOnline:
            [RowModel setStatus:@"ONLINE"];
            [RowModel setDescription:[NSStringHelper CapitalaizeFirstLetter:NSLocalizedString(@"title_ONLINE", nil)]];
            break;
            
        case BaseUserStatusDnd:
            [RowModel setStatus:@"DND"];
            [RowModel setDescription:[NSStringHelper CapitalaizeFirstLetter:NSLocalizedString(@"title_DND", nil)]];
            break;
            
        case BaseUserStatusAway:
            [RowModel setStatus:@"AWAY"];
            [RowModel setDescription:[NSStringHelper CapitalaizeFirstLetter:NSLocalizedString(@"title_AWAY", nil)]];
            break;
            
        case BaseUserStatusHidden:
            [RowModel setStatus:@"INVISIBLE"];
            [RowModel setDescription:[NSStringHelper CapitalaizeFirstLetter:NSLocalizedString(@"title_INVISIBLE", nil)]];
            break;
            
        default:
            [RowModel setStatus:@"OFFLINE"];
            [RowModel setDescription:[NSStringHelper CapitalaizeFirstLetter:NSLocalizedString(@"title_OFFLINE", nil)]];
            break;
    }
    
    if(Status.ExtStatus && Status.ExtStatus.length > 0)
    {
        [RowModel setDescription:[[RowModel.Description stringByAppendingString:@". "] stringByAppendingString:Status.ExtStatus]];
    }
}

- (void) Add:(UiContactsListRowItemModel *) Model
{
    NSString *SectionKey = UiContactsListSectionsIndexAll;
    
    if(Model.Title && Model.Title.length > 0)
        SectionKey = [[Model.Title substringToIndex:1] uppercaseString];
    
    NSMutableArray *Rows = [self.Sections objectForKey:SectionKey];
    
    if(!Rows)
    {
        Rows = [self.Sections objectForKey:[self TryTranslitSectionKey:SectionKey]];
        
        if(Rows)
        {
            SectionKey = [self TryTranslitSectionKey:SectionKey];
        }
    }
    
    if(!Rows)
    {
        if(![self.SectionsKeys containsObject:SectionKey])
        {
            if(![self.SectionsKeys containsObject:[self TryTranslitSectionKey:SectionKey]])
            {
                SectionKey = UiContactsListSectionsIndexAll;
            }
            else
            {
                SectionKey = [self TryTranslitSectionKey:SectionKey];
            }
            
            Rows = [self.Sections objectForKey:SectionKey];
            
            if(!Rows)
            {
                Rows = [[NSMutableArray alloc] init];
            }
        }
        else
        {
            Rows = [[NSMutableArray alloc] init];
        }

        [self.Sections setObject:Rows forKey:SectionKey];
        //[self.SectionsKeys addObject:SectionKey];
    }
    
    [Rows addObject:Model];
}

- (void) SetDisabled:(UiContactsListRowItemModel *) RowModel
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

- (void) SetSelected:(UiContactsListRowItemModel *) RowModel
{
    [RowModel setIsSelected:[NSNumber numberWithBool:NO]];
    
    if(self.SelectedContacts && [self.SelectedContacts count] > 0)
    {
        for (ObjC_ContactModel *Contact in self.SelectedContacts) {
            
            if([ContactsManager AreContactsEqualsByIds:Contact :RowModel.ContactData] /*Contact.Id == RowModel.ContactData.Id*/)
            {
                [RowModel setIsSelected:[NSNumber numberWithBool:YES]];
                
                break;
            }
            
        }
    }
}

- (void) AddToSelected:(UiContactsListRowItemModel *) RowModel
{
    BOOL HasContact = NO;
    
    for (ObjC_ContactModel *Contact in self.SelectedContacts) {
        
        if([ContactsManager AreContactsEqualsByIds:Contact :RowModel.ContactData]/*Contact.Id == RowModel.ContactData.Id*/)
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

- (void) RemoveFromSelected:(UiContactsListRowItemModel *) RowModel
{
    for (ObjC_ContactModel *Contact in self.SelectedContacts) {
        
        if([ContactsManager AreContactsEqualsByIds:Contact :RowModel.ContactData]/*Contact.Id == RowModel.ContactData.Id*/)
        {
            [self.SelectedContacts removeObject:Contact];
            
            break;
        }
        
    }
    
    [self SetSelected:RowModel];
    
    self.SelectedContactsCount = [NSNumber numberWithInteger:[self.SelectedContacts count]];
}

- (void) RevertSelected:(UiContactsListRowItemModel *) RowModel
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

#pragma mark Filters

- (void) SetSearchTextFilter:(NSString *)Search
{
    self.SearchText = Search;
    
    [UiLogger WriteLogInfo:[NSString stringWithFormat:@"UiContactsListModel: User set text filter: %@", self.SearchText]];
    
    dispatch_async([ContactsManager Manager].ViewModelQueue, ^{
        [self ReloadData];
    });
}

- (void) SetFilter:(UiContactsFilter)Filter
{
    self.Filter = Filter;
    
    [UiLogger WriteLogInfo:[NSString stringWithFormat:@"UiContactsListModel: User set contact filter: %@", self.Filter]];
    
    dispatch_async([ContactsManager Manager].ViewModelQueue, ^{
        [self ReloadData];
    });
}


- (void) SetMode:(UiContactsListMode) Mode
{
    self.Mode = Mode;
    
    [UiLogger WriteLogInfo:[NSString stringWithFormat:@"UiContactsListModel: User set contact mode: %@", self.Mode]];
}

- (void) FilterContactsWithSearchTextFilter: (NSMutableArray *) ContactsArr withFilter: (NSString *) Search
{
    NSString *TrimmedSearch = [Search stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    
    TrimmedSearch = [[TrimmedSearch componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] componentsJoinedByString:@""];
    
    TrimmedSearch = [[TrimmedSearch componentsSeparatedByString:@"+"] componentsJoinedByString:@""];
    
    if(TrimmedSearch.length > 0)
    {
        /*
        NSPredicate *SearchTextPredicate = [NSPredicate predicateWithFormat:@"(SELF.FirstName contains[cd] %@) OR (SELF.LastName contains[cd] %@) OR (ANY SELF.Contacts.Identity contains[cd] %@)",TrimmedSearch,TrimmedSearch,TrimmedSearch];
         */
        
        
        NSPredicate *SearchTextPredicate = [NSPredicate predicateWithBlock:^BOOL(ObjC_ContactModel *EvaluatedContact, NSDictionary *Bindings) {
            
            BOOL Contains = NO;
            
            if(EvaluatedContact) {
                
                if(EvaluatedContact.FirstName && [EvaluatedContact.FirstName rangeOfString:TrimmedSearch options:NSCaseInsensitiveSearch].location != NSNotFound)
                    Contains = YES;
                
                if(EvaluatedContact.LastName && [EvaluatedContact.LastName rangeOfString:TrimmedSearch options:NSCaseInsensitiveSearch].location != NSNotFound)
                    Contains = YES;
                
                if(EvaluatedContact.FirstName && EvaluatedContact.LastName && [[EvaluatedContact.FirstName stringByAppendingString:EvaluatedContact.LastName] rangeOfString:TrimmedSearch options:NSCaseInsensitiveSearch].location != NSNotFound)
                    Contains = YES;
                
                if(EvaluatedContact.FirstName && EvaluatedContact.LastName && [[EvaluatedContact.LastName stringByAppendingString:EvaluatedContact.FirstName] rangeOfString:TrimmedSearch options:NSCaseInsensitiveSearch].location != NSNotFound)
                    Contains = YES;
                
                if(!Contains && EvaluatedContact.Contacts && [EvaluatedContact.Contacts count] > 0) {
                    
                    for(ObjC_ContactsContactModel *ContactContact in EvaluatedContact.Contacts) {
                        
                        if(!ContactContact || ContactContact.Type == ContactsContactXmpp)
                            continue;
                        
                        NSString *TrimmedIdentity = [ContactContact.Identity stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
                        TrimmedIdentity = [[TrimmedIdentity componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] componentsJoinedByString:@""];
                        
                        if(ContactContact.Type == ContactsContactSip)
                            TrimmedIdentity = [TrimmedIdentity componentsSeparatedByString:@"@"][0];
                        
                        if([TrimmedIdentity rangeOfString:TrimmedSearch options:NSCaseInsensitiveSearch].location != NSNotFound) {
                            Contains = YES;
                            break;
                        }
                    }
                    
                }
            }
            
            return Contains;
        }];
        
        
        [ContactsArr filterUsingPredicate:SearchTextPredicate];
    }
    
    
}

- (void) FilterContactsWithFilter: (NSMutableArray *) ContactsArr withFilter: (UiContactsFilter) Filter
{
    
    if ([Filter isEqualToString:UiContactsFilterDirectoryLocal])
    {
        NSPredicate *SearchTextPredicate = [NSPredicate predicateWithFormat:@"(SELF.DodicallId.length > 0) AND (SELF.Blocked == %@)", [NSNumber numberWithBool:NO]];
        [ContactsArr filterUsingPredicate:SearchTextPredicate];
    }
    
    else if ([Filter isEqualToString:UiContactsFilterPhoneBook])
    {
        NSPredicate *SearchTextPredicate = [NSPredicate predicateWithFormat:@"(SELF.PhonebookId.length > 0) AND (SELF.Blocked == %@)", [NSNumber numberWithBool:NO]];
        [ContactsArr filterUsingPredicate:SearchTextPredicate];
    }
    
    else if ([Filter isEqualToString:UiContactsFilterLocal])
    {
        NSPredicate *SearchTextPredicate = [NSPredicate predicateWithFormat:@"(SELF.PhonebookId.length == 0) AND (SELF.DodicallId.length == 0) AND (SELF.Blocked == %@)", [NSNumber numberWithBool:NO]];
        [ContactsArr filterUsingPredicate:SearchTextPredicate];
    }
    
    else if ([Filter isEqualToString:UiContactsFilterBlocked])
    {
        NSPredicate *SearchTextPredicate = [NSPredicate predicateWithFormat:@"SELF.Blocked == %@", [NSNumber numberWithBool:YES]];
        [ContactsArr filterUsingPredicate:SearchTextPredicate];
    }
    
    else if ([Filter isEqualToString:UiContactsFilterWhite])
    {
        NSPredicate *SearchTextPredicate = [NSPredicate predicateWithFormat:@"(SELF.White == %@) AND (SELF.Blocked == %@)", [NSNumber numberWithBool:YES], [NSNumber numberWithBool:NO]];
        [ContactsArr filterUsingPredicate:SearchTextPredicate];
    }
    else
    {
        NSPredicate *SearchTextPredicate = [NSPredicate predicateWithFormat:@"(SELF.Blocked == %@)", [NSNumber numberWithBool:NO]];
        [ContactsArr filterUsingPredicate:SearchTextPredicate];
    }
}

- (void) ExecuteSaveAction:(ObjC_ContactModel *)ContactData withCallback:(void (^)(BOOL))Callback
{
    
    [UiLogger WriteLogInfo:@"UiContactsListModel: Save action executed"];
    [UiLogger WriteLogDebug:[NSString stringWithFormat:@"ContactModel: %@", [CoreHelper ContactModelDescription:ContactData]]];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        ObjC_ContactModel *NewContact = [ContactsManager CopyContactAndPrepareForSaveLocal:ContactData];
        
        NewContact.NativeId = nil;
        NewContact.PhonebookId = nil;
        NewContact.DodicallId = nil;
        NewContact.Id = 0;
        
        ContactIdType ContactId = 0;
        
        ObjC_ContactModel *ResultContact = [[AppManager app].Core SaveContact:NewContact];
        
        if(ResultContact && ResultContact.Id)
            ContactId = ResultContact.Id;
        
        
        dispatch_async(dispatch_get_main_queue(), ^{
            
            if(ContactId > 0)
            {
                
                [UiLogger WriteLogInfo:@"UiContactsListModel: Save action finished with success"];
                
                self.TempContactData = NewContact;
                
                self.TempContactData.Id = ContactId;
                
                Callback(YES);
            }
            else
            {
                [UiLogger WriteLogInfo:@"UiContactsListModel: Save action failed"];
                Callback(NO);
            }
            
            
        });
    });
}

- (void) ExecuteTransferCallAction:(NSString *) ContactIdentity withCallback:(void (^)(BOOL))Callback
{
    [UiLogger WriteLogInfo:@"UiContactsListModel: Call transfer action executed"];
    [UiLogger WriteLogDebug:[NSString stringWithFormat:@"Contact dentity: %@", ContactIdentity]];
    
    
    [[CallsManager Manager] TransferCurrentActiveCallToUrl:[ContactIdentity copy] WithCallback:Callback];

}

- (NSInteger) FindNearestNotEmptySectionIndex:(NSInteger) SectionIndex
{
    for(NSInteger i = SectionIndex ; i < [self.SectionsKeys count]; i++)
    {
        NSMutableArray *Rows = [self.Sections objectForKey:[self.SectionsKeys objectAtIndex:i]];
        
        if(Rows && [Rows count] > 0)
        {
            return i;
        }
    }
    
    return SectionIndex;
}

- (NSString *) TryTranslitSectionKey:(NSString *) SectionKey
{
    if([[AppManager app].UserSettingsModel.GuiLanguage isEqualToString:UiLanguageEn])
    {
        if([UiContactsListSectionsIndexTranslitRUEN objectForKey:SectionKey])
        {
            return [UiContactsListSectionsIndexTranslitRUEN objectForKey:SectionKey];
        }
    }
    
    return SectionKey;
}

@end
