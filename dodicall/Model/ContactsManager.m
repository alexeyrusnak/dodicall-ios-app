//
//  ContactsManager.m
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

#import "ContactsManager.h"

#import "UiLogger.h"

@implementation ContactDescriptionStatusModel

@end

@implementation ContactUpdateSignalObject

- (instancetype)initWithContact:(ObjC_ContactModel *) Contact AndState:(ContactUpdatingState) State
{
    self = [super init];
    if (self) {
        
        self.Contact = Contact;
        
        self.State = State;
        
    }
    return self;
}

@end

@implementation InviteUpdateSignalObject

- (instancetype)initWithContact:(ObjC_ContactModel *) Contact AndState:(ContactUpdatingState) State
{
    self = [super init];
    if (self) {
        
        self.Contact = Contact;
        
        self.State = State;
        
    }
    return self;
}

@end

@implementation ContactSubscriptionUpdateSignalObject

- (instancetype)initWithContactSubscription:(ObjC_ContactSubscription *) Subscription WithXmppId:(NSString*) XmppId AndState:(ContactSubscriptionUpdatingState) State
{
    self = [super init];
    if (self) {
        
        self.Subscription = Subscription;
        
        self.XmppId = XmppId;
        
        self.State = State;
        
    }
    return self;
}

@end

@implementation ContactAvatarUpdateSignalObject

-(instancetype)initWithContactId:(ContactDodicallIdType)ContactId AndAvatarPath:(NSString *)Path
{
    if(self = [super init]) {
        _ContactId = ContactId;
        _AvatarPath = Path;
    }
    return self;
}

@end


static ContactsManager* ContactsManagerSingleton = nil;
static dispatch_once_t ContactsManagerSingletonOnceToken;


@interface ContactsManager()

@property NSMutableArray *ContactsListMutable;
@property dispatch_queue_t ContactsSerialQueue;
@property (strong, nonatomic) NSMutableDictionary<ContactDodicallIdType, NSString *> *AvatarsDictionary;

@property NSNumber *AllContactsFetched;

@property NSNumber *Active;

@end;


@implementation ContactsManager
{
    BOOL AllInited;
}

+ (instancetype) Manager
{
    return [self Contacts];
}

+ (instancetype) ManagerForCallBack
{
    if(ContactsManagerSingleton && [ContactsManagerSingleton.AllContactsFetched boolValue])
    {
        return [self Contacts];
    }
    
    return nil;
}

+ (instancetype) Contacts
{
    dispatch_once(&ContactsManagerSingletonOnceToken, ^{
        
        ContactsManagerSingleton = [[ContactsManager alloc] init];
        
    });
    
    [ContactsManagerSingleton InitAll];
    
    return ContactsManagerSingleton;
}

+ (void) Destroy
{
    if(ContactsManagerSingleton)
    {
        ContactsManagerSingleton.ContactsSerialQueue = nil;
        ContactsManagerSingleton = nil;
        ContactsManagerSingletonOnceToken = 0;
    }
}

- (void) SetActive:(BOOL) Active
{
    self.Active = [NSNumber numberWithBool:Active];
}

- (void) InitAll
{
    
    if (!AllInited) {
        
        AllInited = YES;
        
        self.ContactsSerialQueue = dispatch_queue_create("ContactsSerialQueue", DISPATCH_QUEUE_SERIAL);
        self.ViewModelQueue = dispatch_queue_create("ContactsViewModelQueue", DISPATCH_QUEUE_SERIAL);
        self.DispatchGroup = dispatch_group_create();
        
        self.ViewModelScheduler = [[RACTargetQueueScheduler alloc] initWithName:@"ContactViewModelScheduler" queue:self.ViewModelQueue];
        
        self.ManagerScheduler = [[RACTargetQueueScheduler alloc] initWithName:@"ContactsManagerScheduler" queue:self.ContactsSerialQueue];

        
        self.ContactsList = [[NSMutableArray alloc] init];
        self.ContactsListMutable = [[NSMutableArray alloc] init];
        self.ContactsListState = ContactsListLoadingStateNone;
        self.ContactsListStateSignal = RACObserve(self, ContactsListState);
        self.ContactUpdateSignal = RACObserve(self, ContactUpdate);
        self.InviteUpdateSignal = RACObserve(self, InviteUpdate);
        self.ContactSubscriptionUpdateSignal = RACObserve(self, ContactSubscriptionUpdate);
        
        self.XmppStatuses = [[NSMutableArray alloc] init];
        self.XmppStatusesSignal = RACObserve(self, XmppStatuses);
        
        self.ContactsSubscriptions = [[NSMutableDictionary alloc] init];
        self.SubscriptionInvitesCounter = [NSNumber numberWithInt:0];
        
        self.ContactInvites = [[NSMutableDictionary alloc] init];
        
        self.AvatarsDictionary = [NSMutableDictionary new];
        
        @weakify(self);
        
        [[self.ContactsListStateSignal deliverOn:self.ManagerScheduler ] subscribeNext:^(NSNumber *State) {
            
            @strongify(self);
            
            if([State integerValue] == ContactsListLoadingStateFinishedSuccess || [State integerValue] == ContactsListLoadingStateUpdated)
            {
                [self CollectSubscriptionsStatuses: nil];
                
                [self CalcSubscruptionsInvites];
                
                [self CalcWhiteListContactsNumber];
            }
            
        }];
        
        self.SubscriptionInvitesCounterSignal = RACObserve(self, self.SubscriptionInvitesCounter);
        
        [[self.SubscriptionInvitesCounterSignal deliverOn:self.ManagerScheduler] subscribeNext:^(NSNumber *State) {
            
            [[UiNotificationsManager NotificationsManager] PerformContactsSubscriptionsInvitesCounterChangeEvent:State];
            
        }];
        
        self.ContactsSubscriptionsSignal = RACObserve(self, self.ContactsSubscriptions);
        
        
        self.WhiteContactsCounter = [NSNumber numberWithInt:0];
        
        self.WhiteContactsCounterSignal = RACObserve(self, self.WhiteContactsCounter);
        
        [[[[RACObserve(self, Active) ignore:nil] filter:^BOOL(NSNumber *Active) {
            return ![Active boolValue];
        }] deliverOn:self.ViewModelScheduler] subscribeNext:^(id x) {
            
            @strongify(self);
            
            self.ContactsList = [NSArray new];
            self.ContactsListMutable = [NSMutableArray new];
            self.ContactsListState = ContactsListLoadingStateFinishedFail;
            
            self.ContactUpdate = nil;
            self.InviteUpdate = nil;
            self.ContactSubscriptionUpdate = nil;
            
            self.XmppStatuses = [NSMutableArray new];
            
            self.ContactsSubscriptions = [NSMutableDictionary new];
            self.SubscriptionInvitesCounter = [NSNumber numberWithInt:0];
            
            self.ContactInvites = [NSMutableDictionary new];
            
            self.AvatarsDictionary = [NSMutableDictionary new];
 
            self.AllContactsFetched = @NO;
            
        }];
        
        [[self.InviteUpdateSignal deliverOn:self.ManagerScheduler] subscribeNext:^(id x) {
            
            @strongify(self);
            
            [self CalcSubscruptionsInvites];
            
        }];

        //[self GetAllContacts];
        
    }
}

- (void) GetAllContacts
{

    dispatch_queue_t GetAllContactsQueue = dispatch_get_global_queue(QOS_CLASS_USER_INTERACTIVE,0);
    
    if([[UIApplication sharedApplication] applicationState] == UIApplicationStateBackground)
        GetAllContactsQueue = self.ContactsSerialQueue;
    
    dispatch_group_async(self.DispatchGroup, GetAllContactsQueue, ^{
        
        self.ContactsListState = ContactsListLoadingStateInProgress;

        NSDate *MethodStart = [NSDate date];
        
        BOOL result = [[AppManager app].Core GetAllContacts:self.ContactsListMutable];
        
        NSDate *MethodFinish = [NSDate date];
        
        NSTimeInterval ExecutionTime = [MethodFinish timeIntervalSinceDate:MethodStart];
        
        [UiLogger WriteLogInfo:[NSString stringWithFormat:@"ContactsManager:Core GetAllContacts:ExecutionTime = %f", ExecutionTime]];
        
        dispatch_group_async(self.DispatchGroup, self.ContactsSerialQueue, ^{
            
            self.AllContactsFetched = @YES;
            
            if(result)
            {
                [UiLogger WriteLogInfo:[NSString stringWithFormat:@"ContactsManager:GetAllContacts: Contacts fetched: %lu", (unsigned long)[self.ContactsListMutable count]]];
                
                [self CheckContactsListForInvites];
                
                [self SortAllContactsByFirstAndLastName];
                
                NSArray *ContactsListCopy = [self.ContactsListMutable copy];
                
                dispatch_async(self.ViewModelQueue, ^{
                    
                    if([self.Active boolValue])
                    {
                        self.ContactsList = ContactsListCopy;
                        self.ContactsListState = ContactsListLoadingStateFinishedSuccess;
                    }
                    else
                    {
                        self.ContactsList = [NSArray new];
                        self.ContactsListMutable = [NSMutableArray new];
                        self.ContactsListState = ContactsListLoadingStateFinishedFail;
                    }
                    
                });
            }
            else
            {
                [UiLogger WriteLogInfo:@"ContactsManager:GetAllContacts: Failed"];
                
                dispatch_async(self.ViewModelQueue, ^{
                    self.ContactsListState = ContactsListLoadingStateFinishedFail;
                });
                
            }
            
        });
    });

}

- (void) StartCachingPhoneBookContacts
{
    dispatch_group_async(self.DispatchGroup, self.ContactsSerialQueue, ^{
        
        [UiLogger WriteLogInfo:@"ContactsManager:StartCachingPhoneBookContacts"];
        
        [[AppManager app].Core StartCachingPhoneBookContacts];
        
    });
}

- (void) SortAllContactsByFirstAndLastName
{
    NSSortDescriptor *SortDescriptorFirstName = [[NSSortDescriptor alloc] initWithKey:@"FirstName" ascending:YES];
    NSSortDescriptor *SortDescriptorLastName = [[NSSortDescriptor alloc] initWithKey:@"LastName" ascending:YES];
    
    NSArray *SortDescriptors = [NSArray arrayWithObjects:SortDescriptorFirstName, SortDescriptorLastName, nil];
    
    [self.ContactsListMutable sortUsingDescriptors:SortDescriptors];
}

- (NSInteger) FindContactIndex:(ObjC_ContactModel *) Contact InList:(NSArray *) List
{
    for(ObjC_ContactModel *LocalContact in List) {
        if(Contact.Id && Contact.Id > 0 && LocalContact.Id && LocalContact.Id > 0 && Contact.Id == LocalContact.Id)
        {
            return [List indexOfObject:LocalContact];
            break;
        }

        if(Contact.DodicallId && Contact.DodicallId.length > 0 && LocalContact.DodicallId && LocalContact.DodicallId.length > 0 && [Contact.DodicallId isEqualToString:LocalContact.DodicallId])
        {
            return [List indexOfObject:LocalContact];
            break;
        }

        if(Contact.PhonebookId && Contact.PhonebookId.length > 0 && LocalContact.PhonebookId && LocalContact.PhonebookId.length > 0 && [Contact.PhonebookId isEqualToString:LocalContact.PhonebookId])
        {
            return [List indexOfObject:LocalContact];
            break;
        }

        if(Contact.NativeId && Contact.NativeId.length > 0 && LocalContact.NativeId && LocalContact.NativeId.length> 0 && [Contact.NativeId isEqualToString:LocalContact.NativeId])
        {
            return [List indexOfObject:LocalContact];
            break;
        }
    }
    
    return NSNotFound;
}

- (NSInteger) FindContactIndex:(ObjC_ContactModel *) Contact
{
    return [self FindContactIndex:Contact InList:self.ContactsList];
}

- (NSInteger) FindContactIndexMutable:(ObjC_ContactModel *) Contact
{
    return [self FindContactIndex:Contact InList:self.ContactsListMutable];
}


- (NSArray<ObjC_ContactModel *> *) FindContactsWithTextFilter: (NSString *) Search
{
    NSString *TrimmedSearch = [Search stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    
    if(TrimmedSearch.length > 0)
    {
        NSPredicate *SearchTextPredicate = [NSPredicate predicateWithFormat:@"(SELF.FirstName contains[cd] %@) OR (SELF.LastName contains[cd] %@) OR (ANY SELF.Contacts.Identity contains[cd] %@)",TrimmedSearch,TrimmedSearch,TrimmedSearch];
        return [self.ContactsList filteredArrayUsingPredicate:SearchTextPredicate];
    }
    
    return nil;
    
}

- (ContactUpdateSignalObject *) AddOrReplaceContact:(ObjC_ContactModel *) Contact
{
    
    //[UiLogger WriteLogInfo:@"AddOrReplaceContact"];
    //[UiLogger WriteLogDebug:[CoreHelper ContactModelDescription:Contact]];
    
    ContactUpdateSignalObject *Signal;
    
    InviteUpdateSignalObject *InviteSignal = [self AddOrRemoveInvite:Contact];
    
    ContactAvatarUpdateSignalObject *AvatarSignal = [self AddOrReplaceAvatarForContact:Contact];
    
    if(!InviteSignal || InviteSignal.State != ContactUpdatingStateUpdated)
    {
        NSInteger ContactIndex = [self FindContactIndexMutable:Contact];
        
        if(ContactIndex != NSNotFound)
        {
            [self.ContactsListMutable replaceObjectAtIndex:ContactIndex withObject:Contact];
            Signal = [[ContactUpdateSignalObject alloc] initWithContact:Contact AndState:ContactUpdatingStateUpdated];
        }
        else
        {
            if((![Contact.Iam boolValue] && Contact.Id != 0) || (Contact.PhonebookId.length > 0))
            {
                [self.ContactsListMutable addObject:Contact];
                Signal = [[ContactUpdateSignalObject alloc] initWithContact:Contact AndState:ContactUpdatingStateAdded];
            }
        }
    }
    
    if(InviteSignal)
    {
        //dispatch_sync(dispatch_get_main_queue(), ^{
            self.InviteUpdate = InviteSignal;
        //});
    }
    
    if(AvatarSignal)
    {
        dispatch_async(self.ViewModelQueue, ^{
            self.AvatarUpdate = AvatarSignal;
        });
    }
    
    return Signal;
}

- (ContactAvatarUpdateSignalObject *) AddOrReplaceAvatarForContact:(ObjC_ContactModel *)Contact
{
    ContactAvatarUpdateSignalObject *Signal;
    
    //NSString *OldPath = [self.AvatarsDictionary objectForKey:Contact.DodicallId];
    NSString *NewPath = Contact.AvatarPath;
    
    if(!Contact.DodicallId || !Contact.DodicallId.length)
        return Signal;
    
    [self.AvatarsDictionary setObject:NewPath forKey:Contact.DodicallId];
    Signal = [[ContactAvatarUpdateSignalObject alloc] initWithContactId:Contact.DodicallId AndAvatarPath:NewPath];
    
    /*
    if(NewPath && [NewPath length])
    {
        if(!OldPath || ![NewPath isEqualToString:OldPath])
        {
            [self.AvatarsDictionary setObject:NewPath forKey:Contact.DodicallId];
            Signal = [[ContactAvatarUpdateSignalObject alloc] initWithContactId:Contact.DodicallId AndAvatarPath:NewPath];
        }
    }
    else if(OldPath && [OldPath length])
    {
        [self.AvatarsDictionary removeObjectForKey:Contact.DodicallId];
    }
     */
    
    return Signal;
}

- (ContactUpdateSignalObject *) RemoveContact:(ObjC_ContactModel *) Contact
{
    ContactUpdateSignalObject *Signal;
    
    NSInteger ContactIndex = [self FindContactIndexMutable:Contact];
    
    if(ContactIndex != NSNotFound)
    {
        //[UiLogger WriteLogInfo:@"RemoveContact"];
        //[UiLogger WriteLogDebug:[CoreHelper ContactModelDescription:Contact]];
        
        [self.ContactsListMutable removeObjectAtIndex:ContactIndex];
        //[self.AvatarsDictionary removeObjectForKey:Contact.DodicallId];
        
        Signal = [[ContactUpdateSignalObject alloc] initWithContact:Contact AndState:ContactUpdatingStateRemoved];
    }
    
    [self RemoveInvite:Contact];
    
    return Signal;
}

- (void) PerformContactsChangedEvent
{
    NSMutableArray <ObjC_ContactModel *> *ChangedContacts = [[NSMutableArray alloc] init];
    
    NSMutableArray <ObjC_ContactModel *> *RemovedContacts = [[NSMutableArray alloc] init];
    
    dispatch_group_async(self.DispatchGroup, self.ContactsSerialQueue, ^{
        
        [[AppManager app].Core RetrieveChangedContacts:ChangedContacts:RemovedContacts];
        
        [self PerformContactsChangedEvent:ChangedContacts:RemovedContacts];
        
    });
}

- (void) PerformContactsChangedEvent: (NSMutableArray <ObjC_ContactModel *> *) ChangedContacts : (NSMutableArray <ObjC_ContactModel *> *) RemovedContacts
{
    dispatch_group_async(self.DispatchGroup, self.ContactsSerialQueue, ^{
    
        [UiLogger WriteLogInfo:[NSString stringWithFormat:@"PerformContactsChangedEvent: ChangedContacts: %lu; RemovedContacts: %lu;", (unsigned long)[ChangedContacts count], (unsigned long)[RemovedContacts count]]];
        
        
        NSMutableArray <ContactUpdateSignalObject *> * UpdateSignals = [NSMutableArray new];
        
        for (ObjC_ContactModel * Contact in ChangedContacts)
        {
            ContactUpdateSignalObject * Signal = [self AddOrReplaceContact:Contact];
            
            if(Signal)
               [UpdateSignals addObject:Signal];
        }
        
        for (ObjC_ContactModel * Contact in RemovedContacts)
        {
            ContactUpdateSignalObject *Signal =  [self RemoveContact:Contact];
            
            if(Signal)
                [UpdateSignals addObject:Signal];
        }
        
        [self SortAllContactsByFirstAndLastName];
        
        NSArray *ContactsListCopy = [self.ContactsListMutable copy];
        
        dispatch_async(self.ViewModelQueue, ^{
            
            if([self.Active boolValue])
            {
                self.ContactsList = ContactsListCopy;
                
                if([UpdateSignals count])
                {
                    for(ContactUpdateSignalObject *Signal in UpdateSignals)
                    {
                        [self setContactUpdate:Signal];
                    }
                    
                    [self setContactsListState:ContactsListLoadingStateUpdated];
                }
            }
            else
            {
                self.ContactsList = [NSArray new];
                self.ContactsListMutable = [NSMutableArray new];
                [self setContactsListState:ContactsListLoadingStateFinishedFail];
            }
            
            
            
        });
        
    });
    
}

- (void) PerformXmppStatusesChangedEvent:(NSMutableArray *) StatusesArr
{
    dispatch_async(self.ViewModelQueue, ^{
        self.XmppStatuses = StatusesArr;
    });
    
}

- (void) PerformXmppPresenceOfflineEvent
{
    
    NSMutableArray *XmppIdArr = [[NSMutableArray alloc] init];
    
    for(ObjC_ContactModel *Contact in [self.ContactsList copy])
    {
        if([ContactsManager GetContactProfileType:Contact] == ContactProfileTypeDirectoryLocal)
        {
            NSString * XmppId = [ContactsManager GetXmppIdOfContact:Contact];
            if(XmppId)
                [XmppIdArr addObject:XmppId];
        }

    }
    
    /*
    for (int i; i < [self.ContactsList count]; i++)
    {
        ObjC_ContactModel *Contact = (ObjC_ContactModel *)[self.ContactsList objectAtIndex:i];
        
        if(Contact && [ContactsManager GetContactProfileType:Contact] == ContactProfileTypeDirectoryLocal)
        {
            NSString * XmppId = [ContactsManager GetXmppIdOfContact:Contact];
            if(XmppId)
                [XmppIdArr addObject:XmppId];
        }
    }
     */
    
    dispatch_async(self.ViewModelQueue, ^{
        self.XmppStatuses = XmppIdArr;
    });
}

- (void)DownloadAvatarForContactWithDodicallId:(ContactDodicallIdType)ContactId {
    if(!ContactId || !ContactId.length)
        return;
    
    if([self.AvatarsDictionary objectForKey:ContactId])
        return;
    
    [self.AvatarsDictionary setObject:@"" forKey:ContactId];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
       [[[AppManager app] Core] DownloadAvatarForContactsWithDodicallIds:[NSMutableArray arrayWithObject:ContactId]];
    });
}

- (NSString *)AvatarPathForContact:(ObjC_ContactModel *)Contact {
    if(!Contact || !Contact.DodicallId || !Contact.DodicallId.length)
        return @"";
    
    NSString *ManagerPath = [self.AvatarsDictionary objectForKey:Contact.DodicallId];
    NSString *ContactPath = Contact.AvatarPath;
    
    if((!ManagerPath || !ManagerPath.length) && ContactPath && ContactPath.length)
    {
        [self.AvatarsDictionary setObject:ContactPath forKey:Contact.DodicallId];
        self.AvatarUpdate = [[ContactAvatarUpdateSignalObject alloc] initWithContactId:Contact.DodicallId AndAvatarPath:ContactPath];
    }
    
    return [self.AvatarsDictionary objectForKey:Contact.DodicallId];
}
#pragma mark Subscriptions

- (void) PerformSubscriptionsChangedEvent:(NSMutableArray *) SubscriptionsArr
{
    dispatch_group_async(self.DispatchGroup, self.ContactsSerialQueue, ^{
        
        if([self CollectSubscriptionsStatuses:SubscriptionsArr] && [self.ContactsList count] > 0)
            [self setContactsListState:ContactsListLoadingStateUpdated];
        
    });
    
}

- (BOOL) CollectSubscriptionsStatuses:(NSMutableArray *) SubscriptionsArr
{
    BOOL WasChanges = NO;
    
    NSPredicate *Predicate = [NSPredicate predicateWithFormat:@"DodicallId.length > 0"];
    
    NSArray *FilteredArray = [self.ContactsList filteredArrayUsingPredicate:Predicate];
    
    NSMutableArray *XmppIdsArr = [[NSMutableArray alloc] init];
    
    for(ObjC_ContactModel *Contact in FilteredArray)
    {
        NSString *XmppId = [ContactsManager GetXmppIdOfContact:Contact];
        
        if(XmppId && XmppId.length > 0)
        {
            [XmppIdsArr addObject:XmppId];
        }
    }
    
    if(SubscriptionsArr && [SubscriptionsArr count] > 0)
    {
        [XmppIdsArr addObjectsFromArray:[SubscriptionsArr copy]];
    }
    
    //Make unique
    NSMutableArray *XmppIdsArrUnique = [[NSMutableArray alloc] init];
    NSMutableSet * ProcessedXmppIdsArr = [NSMutableSet set];
    for (NSString * XmppId in XmppIdsArr) {
        if ([ProcessedXmppIdsArr containsObject:XmppId] == NO) {
            [XmppIdsArrUnique addObject:XmppId];
            [ProcessedXmppIdsArr addObject:XmppId];
        }
    }
    
    
    NSMutableDictionary *Subscriptions = [[NSMutableDictionary alloc] init];
    
    [[AppManager app].Core GetSubscriptionStatusesByXmppIds:XmppIdsArrUnique:Subscriptions];
    
    NSMutableDictionary *OldSubscriptions = [self.ContactsSubscriptions mutableCopy];
    
    for(NSString *Key in [Subscriptions allKeys])
    {
        ObjC_ContactSubscription *OldSubscription;
        
        if([OldSubscriptions objectForKey:Key])
        {
            OldSubscription = [OldSubscriptions objectForKey:Key];
        }
        
        ObjC_ContactSubscription *Subscription = [Subscriptions objectForKey:Key];
        
        [OldSubscriptions setObject:Subscription forKey:Key];
        
        // Signal
        if(!OldSubscription)
        {
            [self setContactSubscriptionUpdate:[[ContactSubscriptionUpdateSignalObject alloc] initWithContactSubscription:Subscription WithXmppId:Key AndState:ContactSubscriptionUpdatingStateAdded]];
            
            WasChanges = YES;
        }
        else
        {
            if (![ContactsManager AreSubscriptionsEquals:OldSubscription And:Subscription])
            {
                [self setContactSubscriptionUpdate:[[ContactSubscriptionUpdateSignalObject alloc] initWithContactSubscription:Subscription WithXmppId:Key AndState:ContactSubscriptionUpdatingStateUpdated]];
                
                WasChanges = YES;
            }
            
        }
    }
    
    self.ContactsSubscriptions = OldSubscriptions;
    
    [UiLogger WriteLogInfo:[NSString stringWithFormat:@"ContactsManager:CollectSubscritionsStatuses Subscritions statuses collected %lu",(unsigned long)[self.ContactsSubscriptions count]]];
    
    [self CalcSubscruptionsInvites];
    
    return WasChanges;
    
}

- (NSMutableDictionary *) GetAllSubscriptionsInvitesAndRequests
{
    
    NSMutableDictionary *Data = [[NSMutableDictionary alloc] init];
    
    NSMutableArray *InvitesArray = [[NSMutableArray alloc] init];
    
    NSMutableArray *InvitesUnreadArray = [[NSMutableArray alloc] init];
    
    NSMutableArray *RequestsArray = [[NSMutableArray alloc] init];
    
    [Data setObject:InvitesArray forKey:@"Invites"];
    
    [Data setObject:InvitesUnreadArray forKey:@"InvitesUnread"];
    
    [Data setObject:RequestsArray forKey:@"Requests"];
    
    
    NSPredicate *Predicate = [NSPredicate predicateWithFormat:@"DodicallId.length > 0"];
    
    NSArray *FilteredArray = [self.ContactsList filteredArrayUsingPredicate:Predicate];
    
    for(ObjC_ContactModel *Contact in FilteredArray)
    {
        ObjC_ContactSubscription *Subscription = [ContactsManager GetContactSubscription:Contact];
        
        if(Subscription)
        {
            Contact.subscription = Subscription;
            
            if(Contact.subscription)
            {   /*
                if(Contact.subscription.SubscriptionState == ContactSubscriptionStateTo)
                {
                    [InvitesArray addObject:Contact];
                }
                else*/
              
                
                if(Contact.subscription.SubscriptionState == ContactSubscriptionStateFrom && [Subscription.AskForSubscription boolValue]) // Show not declined requests only
                {
                    [RequestsArray addObject:Contact];
                }
                
            }
        }
        
    }
    
    for(ObjC_ContactModel *Contact in [self.ContactInvites allValues])
    {
        if(Contact.subscription && Contact.subscription.SubscriptionStatus == ContactSubscriptionStatusNew)
        {
            [InvitesUnreadArray addObject:Contact];
        }
        else
        {
            [InvitesArray addObject:Contact];
        }
        
        
    }
    
    NSSortDescriptor *SortDescriptorFirstName = [[NSSortDescriptor alloc] initWithKey:@"FirstName" ascending:YES];
    NSSortDescriptor *SortDescriptorLastName = [[NSSortDescriptor alloc] initWithKey:@"LastName" ascending:YES];
    
    NSArray *SortDescriptors = [NSArray arrayWithObjects:SortDescriptorFirstName, SortDescriptorLastName, nil];
    
    [InvitesArray sortUsingDescriptors:SortDescriptors];
    
    [InvitesUnreadArray sortUsingDescriptors:SortDescriptors];
    
    [RequestsArray sortUsingDescriptors:SortDescriptors];
    
    
    return Data;
}

- (void) CalcSubscruptionsInvites
{
    
    int NewInvitesCount = 0;
    
    for(ObjC_ContactModel *Invite in [[self.ContactInvites allValues] copy])
    {
        if(Invite && Invite.subscription.SubscriptionStatus == ContactSubscriptionStatusNew)
        {
            NewInvitesCount++;
        }
    }
    
    if([self.SubscriptionInvitesCounter intValue] != NewInvitesCount)
        self.SubscriptionInvitesCounter = [NSNumber numberWithInt:NewInvitesCount];
}

- (InviteUpdateSignalObject *) AddOrRemoveInvite:(ObjC_ContactModel *) Contact
{
    InviteUpdateSignalObject *Signal;
    
    if([ContactsManager CheckContactIsInvite:Contact])
    {
        [self.ContactInvites setObject:Contact forKey:[ContactsManager GetXmppIdOfContact:Contact]];
        
        [UiLogger WriteLogInfo:@"ContactsManager:AddOrRemoveInvite: Invite added or replaced"];
        
        [UiLogger WriteLogDebug:[CoreHelper ContactModelDescription:Contact]];
        
        Signal = [[InviteUpdateSignalObject alloc] initWithContact:Contact AndState:ContactUpdatingStateUpdated];
    }
    else
    {
        Signal = [self RemoveInvite:Contact];
    }
    
    return Signal;
}

- (InviteUpdateSignalObject *) RemoveInvite:(ObjC_ContactModel *) Contact
{
    InviteUpdateSignalObject *Signal;
    
    if(Contact.DodicallId.length > 0)
    {
        [UiLogger WriteLogInfo:@"ContactsManager:RemoveInvite: Invite removed"];
        
        NSString *XmppId = [ContactsManager GetXmppIdOfContact:Contact];
        
        if(XmppId && XmppId.length > 0)
        {//TODO: If no deletion is done, don't say its deleted :)
            [self.ContactInvites removeObjectForKey:XmppId];
            Signal = [[InviteUpdateSignalObject alloc] initWithContact:Contact AndState:ContactUpdatingStateRemoved];
        }
    }
    
    return Signal;
}

- (BOOL) RejectInviteByUser:(ObjC_ContactModel *) Contact
{
    if(Contact.DodicallId.length > 0)
    {
        [UiLogger WriteLogInfo:@"ContactsManager:RejectInviteByUser"];
        
        if([[AppManager app].Core AnswerSubscriptionRequest:Contact:NO])
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                
                NSString *XmppId = [ContactsManager GetXmppIdOfContact:Contact];
                
                if(XmppId && XmppId.length > 0)
                    [self.ContactInvites removeObjectForKey:XmppId];
                
                [self PerformSubscriptionsChangedEvent:nil];
                
                
            });

            return YES;
        }
        else
        {
            return NO;
        }
    }
    
    return NO;
}

- (void) CheckContactsListForInvites
{
    for(ObjC_ContactModel *Contact in [self.ContactsList copy])
    {
        if(Contact.DodicallId.length > 0 && Contact.Id == 0)
        {
            if([ContactsManager CheckContactIsInvite:Contact])
            {
                [self AddOrRemoveInvite:Contact];
                [self RemoveContact:Contact];
            }
        }
    }
}

- (void) CalcWhiteListContactsNumber
{
    int Count = 0;
    
    for(ObjC_ContactModel *Contact in [self.ContactsList copy])
    {
        if([Contact.White boolValue])
        {
            Count++;
        }
    }
    
    if([self.WhiteContactsCounter intValue] != Count)
        self.WhiteContactsCounter = [NSNumber numberWithInt:Count];
}

- (void) MarkInviteAsRead: (ObjC_ContactModel *) Invite
{
    
    if(Invite.subscription.SubscriptionStatus == ContactSubscriptionStatusNew)
    {
        Invite.subscription.SubscriptionStatus = ContactSubscriptionStatusReaded;
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            
            [[AppManager app].Core MarkSubscriptionAsOld:[ContactsManager GetXmppIdOfContact:Invite]];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                
                [self PerformSubscriptionsChangedEvent:nil];
                
            });
            
        });
    }
    
}

#pragma mark Helper methotds

+ (NSString *) GetContactTitle: (ObjC_ContactModel *) Contact
{
    if(Contact)
    {
        return [[NSString stringWithFormat:@"%@ %@", Contact.FirstName, Contact.LastName] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    }
    
    return @"";
}

+ (ContactProfileType) GetContactProfileType: (ObjC_ContactModel *) Contact
{
    
    if(Contact.DodicallId && Contact.DodicallId.length > 0 && Contact.Id > 0)
        return ContactProfileTypeDirectoryLocal;
    
    if(Contact.DodicallId && Contact.DodicallId.length > 0 && Contact.Id == 0)
        return ContactProfileTypeDirectoryRemote;
    
    else if(Contact.PhonebookId && Contact.PhonebookId.length > 0)
        return ContactProfileTypePhonebook;
    
    else if(Contact.NativeId && Contact.NativeId.length > 0)
        return ContactProfileTypeLocal;
    
    return ContactProfileTypeLocal;
}

+ (ObjC_ContactModel *) CopyContact: (ObjC_ContactModel *) Contact
{
    ObjC_ContactModel * NewContact = [[ObjC_ContactModel alloc] init];
    
    NewContact.Id = Contact.Id;
    NewContact.PhonebookId = [Contact.PhonebookId copy];
    NewContact.DodicallId = [Contact.DodicallId copy];
    NewContact.NativeId = [Contact.NativeId copy];
    NewContact.EnterpriseId = [Contact.EnterpriseId copy];
    
    NewContact.FirstName = [Contact.FirstName copy];
    NewContact.LastName = [Contact.LastName copy];
    NewContact.MiddleName = [Contact.MiddleName copy];
    
    NewContact.Blocked = [Contact.Blocked copy];
    NewContact.White = [Contact.White copy];
    NewContact.Iam = [Contact.Iam copy];
    NewContact.Deleted = [Contact.Deleted copy];
    NewContact.AvatarPath = [Contact.AvatarPath copy];
    
    ObjC_ContactSubscription *NewSubscription = [ObjC_ContactSubscription new];
    NewSubscription.SubscriptionState = Contact.subscription.SubscriptionState;
    NewSubscription.SubscriptionStatus = Contact.subscription.SubscriptionStatus;
    NewSubscription.AskForSubscription = [Contact.subscription.AskForSubscription copy];
    NewContact.subscription = NewSubscription;
    
    NewContact.Contacts = [[NSMutableArray alloc] init];
    
    for(ObjC_ContactsContactModel * ContactContact in Contact.Contacts)
    {
        ObjC_ContactsContactModel * NewContactContact = [[ObjC_ContactsContactModel alloc] init];
        
        NewContactContact.Type = ContactContact.Type;
        NewContactContact.Identity = [ContactContact.Identity copy];
        NewContactContact.Favourite = [ContactContact.Favourite copy];
        NewContactContact.Manual = [ContactContact.Manual copy];
        
        [NewContact.Contacts addObject:NewContactContact];
    }
    
    return NewContact;
}

+ (ObjC_ContactModel *) CopyContactAndMakeManualAllContacts: (ObjC_ContactModel *) Contact
{
    ObjC_ContactModel * NewContact = [self CopyContact:Contact];
    
    for(ObjC_ContactsContactModel * ContactContact in NewContact.Contacts)
    {
        
        ContactContact.Manual = [NSNumber numberWithBool:YES];
    }
    
    return NewContact;
}

+ (ObjC_ContactModel *) CopyContactAndPrepareForSaveLocal: (ObjC_ContactModel *) Contact
{
    ObjC_ContactModel * NewContact = [self CopyContactAndMakeManualAllContacts:Contact];
    
    //NewContact.FirstName = [NSString stringWithFormat:@"%@ copy", NewContact.FirstName];
    
    //NewContact.LastName = [NSString stringWithFormat:@"%@ copy", NewContact.LastName];
    
    return NewContact;
}

+ (void) SortContactContacts: (ContactsContactList) Contacts
{
    NSSortDescriptor *SortDescriptorIdentity = [[NSSortDescriptor alloc] initWithKey:@"Identity" ascending:YES];
    
    NSArray *SortDescriptors = [NSArray arrayWithObjects:SortDescriptorIdentity, nil];
    
    [Contacts sortUsingDescriptors:SortDescriptors];
}

+ (NSString *) GetXmppIdOfContact: (ObjC_ContactModel *) Contact
{
    if(Contact)
    {
        for(ObjC_ContactsContactModel * ContactContact in [Contact.Contacts copy])
        {
            
            if(ContactContact.Type == ContactsContactXmpp)
            {
                return ContactContact.Identity;
            }
        }
    }
    
    return nil;
}

+ (ObjC_ContactPresenceStatusModel *) GetXmppStatusByXmppId: (NSString *) XmppId
{
    if(XmppId)
    {
        NSMutableArray * PresenceStatuses = [[AppManager app].Core GetPresenceStatusesByXmppIds:[NSMutableArray arrayWithObjects:XmppId, nil]];
        
        if(PresenceStatuses && [PresenceStatuses count] == 1)
        {
            return [PresenceStatuses objectAtIndex:0];
        }
    }
    
    return nil;
}

+ (ObjC_ContactPresenceStatusModel *) GetXmppStatusOfContact: (ObjC_ContactModel *) Contact
{
    NSString * XmppId = [self GetXmppIdOfContact:Contact];
    
    return [self GetXmppStatusByXmppId:XmppId];
}

+ (ObjC_ContactSubscription *) GetContactSubscriptionByXmppId:(NSString *) XmppId
{
    
    return [[ContactsManager Contacts].ContactsSubscriptions objectForKey:XmppId];
}

+ (ObjC_ContactSubscription *) GetContactSubscription:(ObjC_ContactModel *) Contact
{
    ObjC_ContactSubscription * Subscription;
    
    if(Contact.DodicallId.length > 0)
    {
        NSString * XmppId = [self GetXmppIdOfContact:Contact];
        
        if (XmppId && XmppId.length > 0)
        {
            Subscription = [ContactsManager GetContactSubscriptionByXmppId:XmppId];
        }
    }
    
    if(!Subscription)
        Subscription = Contact.subscription;
    
    
    return Subscription;
}

+ (BOOL) CheckContactIsInvite:(ObjC_ContactModel *) Contact
{
    BOOL IsInvite = NO;
    
    if(Contact.DodicallId.length > 0 && Contact.Id == 0)
    {
        
        ObjC_ContactSubscription *Subscription = [ContactsManager GetContactSubscription:Contact];
        
        if(Subscription && (Subscription.SubscriptionState == ContactSubscriptionStateTo /*|| Subscription.SubscriptionState == ContactSubscriptionStateNone*/))
        {
            IsInvite = YES;
        }
        
    }

    return IsInvite;
}

+ (BOOL) CheckContactIsRequest:(ObjC_ContactModel *) Contact
{
    BOOL IsRequest = NO;
    
    if(Contact.DodicallId.length > 0)
    {
        
        ObjC_ContactSubscription *Subscription = [ContactsManager GetContactSubscription:Contact];
        
        if(Subscription && Subscription.SubscriptionState == ContactSubscriptionStateFrom)
        {
            IsRequest = YES;
        }
        
    }
    
    return IsRequest;
}

+ (BOOL) CheckContactIsDeclinedRequest:(ObjC_ContactModel *) Contact
{
    BOOL IsDeclinedRequest = NO;
    
    if(Contact.DodicallId.length > 0)
    {
        
        ObjC_ContactSubscription *Subscription = [ContactsManager GetContactSubscription:Contact];
        
        if(Subscription && Subscription.SubscriptionState == ContactSubscriptionStateFrom && ![Subscription.AskForSubscription boolValue])
        {
            IsDeclinedRequest = YES;
        }
        
    }
    
    return IsDeclinedRequest;
}

+ (ContactDescriptionStatusModel *) GetContactDescriptionStatusModel:(ObjC_ContactModel *) Contact
{
    ContactDescriptionStatusModel *Result = [[ContactDescriptionStatusModel alloc] init];
    
    ObjC_ContactPresenceStatusModel *Status = [ContactsManager GetXmppStatusOfContact:Contact];
    
    switch (Status.BaseStatus) {
            
        case BaseUserStatusOnline:
            [Result setStatus:@"ONLINE"];
            [Result setDescription:[NSStringHelper CapitalaizeFirstLetter:NSLocalizedString(@"title_ONLINE", nil)]];
            break;
            
        case BaseUserStatusDnd:
            [Result setStatus:@"DND"];
            [Result setDescription:[NSStringHelper CapitalaizeFirstLetter:NSLocalizedString(@"title_DND", nil)]];
            break;
            
        case BaseUserStatusAway:
            [Result setStatus:@"AWAY"];
            [Result setDescription:[NSStringHelper CapitalaizeFirstLetter:NSLocalizedString(@"title_AWAY", nil)]];
            break;
            
        case BaseUserStatusHidden:
            [Result setStatus:@"INVISIBLE"];
            [Result setDescription:[NSStringHelper CapitalaizeFirstLetter:NSLocalizedString(@"title_INVISIBLE", nil)]];
            break;
            
        default:
            [Result setStatus:@"OFFLINE"];
            [Result setDescription:[NSStringHelper CapitalaizeFirstLetter:NSLocalizedString(@"title_OFFLINE", nil)]];
            break;
    }
    
    if(Status.ExtStatus && Status.ExtStatus.length > 0)
    {
        [Result setDescription:[[Result.Description stringByAppendingString:@". "] stringByAppendingString:Status.ExtStatus]];
    }
    
    return Result;
}

+ (void) RetriveContactByNumber: (NSString*) Number AndReturnItInCallback:(void (^)(ObjC_ContactModel *Contact, NSString *Number)) Callback
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        ObjC_ContactModel *Contact = [[AppManager app].Core RetriveContactByNumber:Number];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if(Contact)
            {
                Callback(Contact, Number);
            }
            else
            {
                Callback(nil, Number);
            }
        });
    });

}
+ (BOOL) IsContact:(ObjC_ContactModel *)First IsEqualTo:(ObjC_ContactModel *)Second {
    
    BOOL IsEqual = YES;
    if(![First.FirstName isEqualToString:Second.FirstName])
        IsEqual = NO;
    if(![First.LastName isEqualToString:Second.LastName])
        IsEqual = NO;
    if(![First.MiddleName isEqualToString:Second.MiddleName])
        IsEqual = NO;
    
    if(![First.Blocked isEqual:Second.Blocked])
        IsEqual = NO;
    if(![First.White isEqual:Second.White])
        IsEqual = NO;
    if([First.Contacts count]!= [Second.Contacts count]) {
        IsEqual = NO;
    }
    else if(IsEqual){
        
        ContactsContactList FirstList = First.Contacts;
        ContactsContactList SecondList = Second.Contacts;
        [ContactsManager SortContactContacts:FirstList];
        [ContactsManager SortContactContacts:SecondList];
        
        for(int i=0;i<[FirstList count];i++) {
            ObjC_ContactsContactModel *FirstContact = [FirstList objectAtIndex:i];
            ObjC_ContactsContactModel *SecondContact = [SecondList objectAtIndex:i];
            
            if(FirstContact.Type != SecondContact.Type)
                IsEqual = NO;
            if(![FirstContact.Identity isEqualToString: SecondContact.Identity])
                IsEqual = NO;
            if(![FirstContact.Favourite isEqual: SecondContact.Favourite])
                IsEqual = NO;
            if(![FirstContact.Manual isEqual: SecondContact.Manual])
                IsEqual = NO;
            
            if(!IsEqual)
                break;
        }
    }
    
    return IsEqual;

}

+ (BOOL) AreContactsEqualsByIds:(ObjC_ContactModel *)First :(ObjC_ContactModel *)Second
{
    BOOL AreIdsEquals = YES;
    
    if(!First || !Second)
        return NO;
    
    if(First.Id != Second.Id)
        AreIdsEquals = NO;
    
    if(![First.DodicallId isEqualToString: Second.DodicallId])
        AreIdsEquals = NO;
    
    if(![First.PhonebookId isEqualToString: Second.PhonebookId])
        AreIdsEquals = NO;
    
    if(![First.NativeId isEqualToString: Second.NativeId])
        AreIdsEquals = NO;
    
    
    return AreIdsEquals;
    
}

+ (BOOL) AreSubscriptionsEquals:(ObjC_ContactSubscription *)First And:(ObjC_ContactSubscription *)Second
{
    BOOL AreEquals = YES;
    
    if(!First || !Second)
        return NO;
    
    if(First.SubscriptionState != Second.SubscriptionState)
        AreEquals = NO;
    
    if([First.AskForSubscription boolValue] != [Second.AskForSubscription boolValue])
        AreEquals = NO;
    
    if(First.SubscriptionStatus != Second.SubscriptionStatus)
        AreEquals = NO;
    
    return AreEquals;
}

+ (NSData *)AvatarDataForPath:(NSString *)Path {
    
    NSData *Data;
    
    if(Path && Path.length)
        Data = [[NSFileManager defaultManager] contentsAtPath:Path];
    
    if(Data && Data.length)
        return Data;
    else
        return nil;
}

- (RACSignal *) AvatarSignalForContactUpdate:(RACSignal *)ContactUpdate WithDoNextBlock:(nullable void (^)(NSString *))NextBlock {
    
    @weakify(self);
    return [[[[[[ContactUpdate ignore:nil]
                distinctUntilChanged]
                doNext:^(ObjC_ContactModel *Contact) {
                    @strongify(self);
                    if(NextBlock)
                        NextBlock([self AvatarPathForContact:Contact]);
                }]
                flattenMap:^RACStream *(ObjC_ContactModel *Contact) {
                    @strongify(self);
                    @weakify(Contact);
                    return [RACObserve(self, AvatarUpdate) filter:^BOOL(ContactAvatarUpdateSignalObject *Update) {
                        @strongify(Contact);
                        return [Update.ContactId isEqualToString:Contact.DodicallId];
                    }];
                }]
                map:^id(ContactAvatarUpdateSignalObject *Update) {
                    return [Update AvatarPath];
                }]
                deliverOn:self.ViewModelScheduler];
}

+ (RACSignal *) AvatarImageSignalForPathSignal:(RACSignal *)PathSignal WithTakeUntil:(RACSignal *)TakeUntilSignal {
    
    return [[[PathSignal takeUntil:TakeUntilSignal]
                distinctUntilChanged]
                map:^id(NSString *Path) {
                    NSData *ImageData = [ContactsManager AvatarDataForPath:Path];
                    if(ImageData)
                        return [UIImage imageWithData:ImageData];
                    else
                        return [UIImage imageNamed:@"no_photo_one"];
                }];
}

@end
