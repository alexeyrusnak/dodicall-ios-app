//
//  ContactsManager.h
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
#import "ObjC_ContactSubscription.h"
#import "UiNotificationsManager.h"

typedef NS_ENUM(NSInteger, ContactsListLoadingState)
{
    ContactsListLoadingStateNone,
    ContactsListLoadingStateInProgress,
    ContactsListLoadingStateFinishedSuccess,
    ContactsListLoadingStateFinishedFail,
    ContactsListLoadingStateUpdated
};

typedef NS_ENUM(NSInteger, ContactProfileType)
{
    ContactProfileTypeDirectoryLocal,
    ContactProfileTypeDirectoryRemote,
    ContactProfileTypeLocal,
    ContactProfileTypePhonebook
};

typedef NS_ENUM(NSInteger, ContactUpdatingState)
{
    ContactUpdatingStateNone,
    ContactUpdatingStateAdded,
    ContactUpdatingStateUpdated,
    ContactUpdatingStateRemoved
};

typedef NS_ENUM(NSInteger, ContactSubscriptionUpdatingState)
{
    ContactSubscriptionUpdatingStateNone,
    ContactSubscriptionUpdatingStateAdded,
    ContactSubscriptionUpdatingStateUpdated,
    ContactSubscriptionUpdatingStateRemoved
};

@interface ContactUpdateSignalObject : NSObject

    @property ContactUpdatingState State;

    @property ObjC_ContactModel *Contact;

    - (instancetype)initWithContact:(ObjC_ContactModel *) Contact AndState:(ContactUpdatingState) State;

@end

@interface InviteUpdateSignalObject : NSObject

@property ContactUpdatingState State;

@property ObjC_ContactModel *Contact;

- (instancetype)initWithContact:(ObjC_ContactModel *) Contact AndState:(ContactUpdatingState) State;

@end


@interface ContactSubscriptionUpdateSignalObject : NSObject

    @property ContactSubscriptionUpdatingState State;

    @property NSString *XmppId;

    @property ObjC_ContactSubscription *Subscription;

- (instancetype)initWithContactSubscription:(ObjC_ContactSubscription *) Subscription WithXmppId:(NSString*) XmppId AndState:(ContactSubscriptionUpdatingState) State;

@end

@interface ContactAvatarUpdateSignalObject : NSObject

@property ContactDodicallIdType ContactId;
@property NSString *AvatarPath;
- (instancetype) initWithContactId:(ContactDodicallIdType)ContactId AndAvatarPath:(NSString *)Path;

@end


@interface ContactDescriptionStatusModel : NSObject

    @property NSString *Status;

    @property NSString *Description;

@end


@interface ContactsManager : NSObject

    @property NSArray *ContactsList;

    @property NSMutableDictionary *ContactInvites;

    @property ContactsListLoadingState ContactsListState;

    @property RACSignal *ContactsListStateSignal;

    @property ContactUpdateSignalObject *ContactUpdate;

    @property RACSignal *ContactUpdateSignal;

    @property InviteUpdateSignalObject *InviteUpdate;

    @property RACSignal *InviteUpdateSignal;

    @property ContactSubscriptionUpdateSignalObject *ContactSubscriptionUpdate;

    @property RACSignal *ContactSubscriptionUpdateSignal;

    @property NSMutableArray *XmppStatuses;

    @property RACSignal *XmppStatusesSignal;

    @property NSMutableDictionary *ContactsSubscriptions;

    @property RACSignal *ContactsSubscriptionsSignal;

    @property NSNumber *SubscriptionInvitesCounter;

    @property RACSignal *SubscriptionInvitesCounterSignal;

    @property NSNumber *WhiteContactsCounter;

    @property RACSignal *WhiteContactsCounterSignal;

    @property ContactAvatarUpdateSignalObject *AvatarUpdate;

    @property dispatch_group_t DispatchGroup;

    @property dispatch_queue_t ViewModelQueue;

    @property RACTargetQueueScheduler *ViewModelScheduler;

    @property RACTargetQueueScheduler *ManagerScheduler;


    + (instancetype) Manager;

    + (instancetype) ManagerForCallBack;

    + (instancetype) Contacts;

    + (void) Destroy;

    - (void) SetActive:(BOOL) Active;

    - (void) GetAllContacts;

    - (void) StartCachingPhoneBookContacts;

    - (void) PerformContactsChangedEvent;

    - (void) PerformContactsChangedEvent: (NSMutableArray *) ChangedContacts : (NSMutableArray *) RemovedContacts;

    - (NSInteger) FindContactIndex:(ObjC_ContactModel *) Contact;

    - (void) PerformXmppStatusesChangedEvent:(NSMutableArray *) StatusesArr;

    - (void) PerformXmppPresenceOfflineEvent;

    - (void) PerformSubscriptionsChangedEvent:(NSMutableArray *) SubscriptionsArr;

    - (NSMutableDictionary *) GetAllSubscriptionsInvitesAndRequests;

    - (BOOL) RejectInviteByUser:(ObjC_ContactModel *) Contact;

    - (void) MarkInviteAsRead: (ObjC_ContactModel *) Invite;

    - (NSArray<ObjC_ContactModel *> *) FindContactsWithTextFilter: (NSString *) Search;

    - (void) DownloadAvatarForContactWithDodicallId:(ContactDodicallIdType)ContactId;

    - (NSString *)AvatarPathForContact:(ObjC_ContactModel *)Contact;

    #pragma mark Helper methotds

    + (NSString *) GetContactTitle: (ObjC_ContactModel *) Contact;

    + (ContactProfileType) GetContactProfileType: (ObjC_ContactModel *) Contact;

    + (ObjC_ContactModel *) CopyContact: (ObjC_ContactModel *) Contact;

    + (ObjC_ContactModel *) CopyContactAndMakeManualAllContacts: (ObjC_ContactModel *) Contact;

    + (ObjC_ContactModel *) CopyContactAndPrepareForSaveLocal: (ObjC_ContactModel *) Contact;

    + (void) SortContactContacts: (ContactsContactList) Contacts;

    + (NSString *) GetXmppIdOfContact: (ObjC_ContactModel *) Contact;

    + (ObjC_ContactPresenceStatusModel *) GetXmppStatusByXmppId: (NSString *) XmppId;

    + (ObjC_ContactPresenceStatusModel *) GetXmppStatusOfContact: (ObjC_ContactModel *) Contact;

    + (ObjC_ContactSubscription *) GetContactSubscriptionByXmppId:(NSString *) XmppId;

    + (ObjC_ContactSubscription *) GetContactSubscription:(ObjC_ContactModel *) Contact;

    + (BOOL) CheckContactIsInvite:(ObjC_ContactModel *) Contact;

    + (BOOL) CheckContactIsRequest:(ObjC_ContactModel *) Contact;

    + (BOOL) CheckContactIsDeclinedRequest:(ObjC_ContactModel *) Contact;

    + (ContactDescriptionStatusModel *) GetContactDescriptionStatusModel:(ObjC_ContactModel *) Contact;

    + (void) RetriveContactByNumber: (NSString*) Number AndReturnItInCallback:(void (^)(ObjC_ContactModel *Contact, NSString *Number)) Callback;

    + (BOOL) IsContact:(ObjC_ContactModel *)First IsEqualTo:(ObjC_ContactModel *)Second;

    + (BOOL) AreContactsEqualsByIds:(ObjC_ContactModel *)First :(ObjC_ContactModel *)Second;

    + (BOOL) AreSubscriptionsEquals:(ObjC_ContactSubscription *)First And:(ObjC_ContactSubscription *)Second;

    + (NSData *) AvatarDataForPath:(NSString *)Path;

    - (RACSignal *) AvatarSignalForContactUpdate:(RACSignal *)ContactUpdate WithDoNextBlock:(void (^)(NSString *))NextBlock;

    + (RACSignal *) AvatarImageSignalForPathSignal:(RACSignal *)PathSignal WithTakeUntil:(RACSignal *)TakeUntilSignal;

@end
