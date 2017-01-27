//
//  UiContactsRosterViewModel.m
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

#import "UiContactsRosterViewModel.h"

#import "ContactsManager.h"

#import "UiLogger.h"

@implementation UiContactsRosterViewModel

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        
        self.ThreadSafeSections = [NSMutableDictionary new];
        self.ThreadSafeSectionsKeys = [NSMutableArray new];
        self.DataUpdateStages = [NSMutableArray new];
        
        
        self.DataReloaded = @(NO);
        self.DataReloadedSignal = RACObserve(self, DataReloaded);
        
        
        @weakify(self);
        
        [[ContactsManager Contacts].ContactsSubscriptionsSignal subscribeNext:^(NSMutableDictionary *Data) {
            
            @strongify(self);
            [self ReloadData];
        }];
    }
    
    return self;
}

- (void) ReloadData
{
    NSMutableDictionary *InvitesAndRequests = [[ContactsManager Contacts] GetAllSubscriptionsInvitesAndRequests];
    
    [UiLogger WriteLogInfo:[NSString stringWithFormat:@"UiContactsRosterViewModel: Invites: %lu", (unsigned long)[(NSMutableArray *)[InvitesAndRequests objectForKey:@"Invites"] count]]];
    
    [UiLogger WriteLogInfo:[NSString stringWithFormat:@"UiContactsRosterViewModel: Requests: %lu", (unsigned long)[(NSMutableArray *)[InvitesAndRequests objectForKey:@"Requests"] count]]];
    
    NSMutableArray *Invites = [NSMutableArray new];
    NSMutableArray *Requests = [NSMutableArray new];
    
    NSMutableDictionary *Sections = [NSMutableDictionary new];
    NSMutableArray *SectionsKeys = [NSMutableArray new];
    
    
    for (ObjC_ContactModel *ContactModel in InvitesAndRequests[@"InvitesUnread"])
    {
        
        [Invites addObject:[self CreateAndFillRowModelWithContact:ContactModel AndType:UiContactsRosterRequestTypeInvite]];
        
    }
    
    for (ObjC_ContactModel *ContactModel in InvitesAndRequests[@"Invites"])
    {
        
        [Invites addObject:[self CreateAndFillRowModelWithContact:ContactModel AndType:UiContactsRosterRequestTypeInvite]];
        
    }
    
    for (ObjC_ContactModel *ContactModel in InvitesAndRequests[@"Requests"])
    {
        
        [Requests addObject:[self CreateAndFillRowModelWithContact:ContactModel AndType:UiContactsRosterRequestTypeRequest]];
        
    }
    
    
    if([Invites count] > 0)
    {
        NSString *SectionKey = NSLocalizedString(@"Title_Invites", nil);
        
        [SectionsKeys addObject:SectionKey];
        
        [Sections setObject:Invites forKey:SectionKey];
    }
    
    if([Requests count] > 0)
    {
        NSString *SectionKey = NSLocalizedString(@"Title_Requests", nil);
        
        [SectionsKeys addObject:SectionKey];
        
        [Sections setObject:Requests forKey:SectionKey];
    }
    
    NSDictionary *DataUpdateStage = @{@"Sections":Sections, @"SectionsKeys":SectionsKeys};
    
    [self.DataUpdateStages addObject:DataUpdateStage];
    
    self.DataReloaded = @(YES);
}

- (UiContactsRosterRowItemViewModel *) CreateAndFillRowModelWithContact:(ObjC_ContactModel *) Contact AndType:(UiContactsRosterRequestType) Type
{
    UiContactsRosterRowItemViewModel *RowModel = [[UiContactsRosterRowItemViewModel alloc] init];
    
    [RowModel setContactData:Contact];
    
    [RowModel setTitle:[ContactsManager GetContactTitle:Contact]];
    
    [RowModel setXmppId:[ContactsManager GetXmppIdOfContact:Contact]];
    
    [RowModel setRequestType:Type];
    
    @weakify(RowModel);
    RAC(RowModel, AvatarPath) = [[ContactsManager Manager] AvatarSignalForContactUpdate:[[RACSignal empty] startWith:Contact] WithDoNextBlock:^(NSString *Path) {
        @strongify(RowModel);
        RowModel.AvatarPath = Path;
    }];
    
    if([Type isEqualToString:UiContactsRosterRequestTypeRequest])
    {
        [RowModel setIsNew:NO];
    }
    else
    {
        [RowModel setIsNew:(Contact.subscription.SubscriptionStatus == ContactSubscriptionStatusNew) ? YES : NO];
    }
    
    
    return RowModel;
}

/*
- (void) Add:(UiContactsRosterRowItemViewModel *) Model
{
    
    NSString *SectionKey;
    
    if([Model.RequestType isEqualToString:UiContactsRosterRequestTypeInvite])
    {
        SectionKey = NSLocalizedString(@"Title_Invites", nil);
    }
    else
    {
        SectionKey = NSLocalizedString(@"Title_Requests", nil);
    }
    
    
    NSMutableArray *Rows = [self.Sections objectForKey:SectionKey];
    
    if(!Rows)
    {
        Rows = [[NSMutableArray alloc] init];
        [self.Sections setObject:Rows forKey:SectionKey];
        [self.SectionsKeys addObject:SectionKey];
    }
    
    [Rows addObject:Model];
}
 */

- (void) SetStatusToModel:(UiContactsRosterRowItemViewModel *) RowModel
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
            [RowModel setStatus:@"INVISIBLE"];
            [RowModel setDescription:[NSStringHelper CapitalaizeFirstLetter:NSLocalizedString(@"title_OFFLINE", nil)]];
            break;
    }
    
    [RowModel setDescription:[RowModel.Description stringByAppendingString:@". "]];
    
    if(Status.ExtStatus && Status.ExtStatus.length > 0)
        [RowModel setDescription:[RowModel.Description stringByAppendingString:Status.ExtStatus]];
}

- (void) ExecuteAcceptAction:(ObjC_ContactModel *)ContactData withAccept:(BOOL) Accept withCallback:(void (^)(BOOL))Callback
{
    
    [UiLogger WriteLogInfo:[NSString stringWithFormat:@"UiContactsRosterViewModel: Accept action executed with status %@",Accept ? @"Accepted" : @"Rejected"]];
    [UiLogger WriteLogDebug:[NSString stringWithFormat:@"ContactModel: %@", [CoreHelper ContactModelDescription:ContactData]]];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        ContactIdType ContactId = 0;
        
        BOOL Result;
        
        if(Accept)
        {
            ObjC_ContactModel *ResultContact = [[AppManager app].Core SaveContact:ContactData];
            
            if(ResultContact && ResultContact.Id)
                ContactId = ResultContact.Id;
        }
        else
        {
            Result = [[AppManager app].Core AnswerSubscriptionRequest:ContactData:Accept];
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            
            if((Accept && ContactId > 0) || (!Accept && Result))
            {
                
                [UiLogger WriteLogInfo:@"UiContactsRosterViewModel: Accept action finished with success"];
                Callback(YES);
            }
            else
            {
                [UiLogger WriteLogInfo:@"UiContactsRosterViewModel: Accept action failed"];
                Callback(NO);
            }
            
            
        });
    });
}

/*
- (void) MarkSubscriptionsAsOld: (NSMutableArray *) Rows
{
    if(Rows && [Rows count] > 0)
    {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            
            for (UiContactsRosterRowItemViewModel *RowModel in Rows)
            {
                if(RowModel.IsNew)
                {
                    [[AppManager app].Core MarkSubscriptionAsOld:RowModel.XmppId];
                }
            }
            
            
            dispatch_async(dispatch_get_main_queue(), ^{
                
            });
        });
    }
    
}
 */

@end
