//
//  HistoryManager.m
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

#import "HistoryManager.h"
#import "UiNotificationsManager.h"
#import "AppManager.h"
#import "UiLogger.h"
#import "ContactsManager.h"

static HistoryManager* HistoryManagerSingleton = nil;
static dispatch_once_t HistoryManagerSingletonOnceToken;

@interface HistoryManager ()

@property HistoryStatisticsUpdatingSignalObject *HistoryStatisticsUpdating;
@property HistoryStatisticsListUpdatingState HistoryStatisticsListState;
@property NSMutableArray <ObjC_HistoryStatisticsModel *> *HistoryStatisticsListMutable;
@property dispatch_queue_t HistorySerialQueue;

@property NSNumber *Active;

@end

@implementation HistoryStatisticsUpdatingSignalObject

- (instancetype)initWithId:(NSString *) HistoryStatisticsId AndState:(HistoryStatisticsUpdatingState) State
{
    if (self = [super init]) {
        
        self.Id = HistoryStatisticsId;
        
        self.State = State;
    }
    return self;
}

@end

@implementation HistoryManager
//{
//    BOOL AllInited;
//}

+ (instancetype) Manager
{
    dispatch_once(&HistoryManagerSingletonOnceToken, ^{
        HistoryManagerSingleton = [[HistoryManager alloc] init];
    });
    
   // [HistoryManagerSingleton InitAll];
    
    return HistoryManagerSingleton;
}

+ (void) Destroy
{
    if(HistoryManagerSingleton)
    {
        HistoryManagerSingleton.HistorySerialQueue = nil;
        HistoryManagerSingleton = nil;
        HistoryManagerSingletonOnceToken = 0;
    }
}

- (void) SetActive:(BOOL) Active
{
    self.Active = [NSNumber numberWithBool:Active];
}

- (instancetype)init {
    
    if(self = [super init])
    {    
        self.MissedCalls = [NSNumber numberWithInt:0];
        self.HistoryStatisticsList = [NSArray new];
        self.HistoryStatisticsListMutable = [NSMutableArray new];
        self.HistoryStatisticsListState = HistoryStatisticsListUpdatingStateNone;
        self.HistoryStatisticsListUpdatingStateSignal = RACObserve(self, HistoryStatisticsListState);
        self.HistoryStatisticsUpdatingSignal = RACObserve(self, HistoryStatisticsUpdating);
        self.HistorySerialQueue = dispatch_queue_create("HistorySerialQueue", DISPATCH_QUEUE_SERIAL);
        self.DispatchGroup = dispatch_group_create();
        self.ViewModelQueue = dispatch_queue_create("HistoryViewModelQueue", DISPATCH_QUEUE_SERIAL);
        self.ViewModelScheduler = [[RACTargetQueueScheduler alloc] initWithName:@"HistoryViewModelScheduler" queue:self.ViewModelQueue];
        self.ManagerScheduler = [[RACTargetQueueScheduler alloc] initWithName:@"HistoryManagerScheduler" queue:self.HistorySerialQueue];
        
        @weakify(self);
        
        [[self.HistoryStatisticsListUpdatingStateSignal deliverOn:self.ViewModelScheduler ] subscribeNext:^(NSNumber *Signal) {
            
            @strongify(self);
            
            if([Signal integerValue] == HistoryStatisticsListUpdatingReady || [Signal integerValue] == HistoryStatisticsListUpdatingStateUpdated)
                [self CalcMissedCallCount];
        }];
        
        //[self LoadHistoryStatisticsList];
        
        
        RACSignal *ContactsListStateChangedSignal = [[ContactsManager Contacts].ContactsListStateSignal
                                                        filter:^BOOL(NSNumber *State) {
                                                            return (State.integerValue == ContactsListLoadingStateFinishedSuccess || State.integerValue == ContactsListLoadingStateUpdated);
                                                        }];
        
        [[[ContactsListStateChangedSignal
            throttle:1.0 afterAllowing:0 withStrike:5.0] deliverOn:self.ManagerScheduler ]
            subscribeNext:^(id x) {
                @strongify(self);
                [self RefreshHistory];
            }];
        
        [[[[RACObserve(self, Active) ignore:nil] filter:^BOOL(NSNumber *Active) {
            return ![Active boolValue];
        }] deliverOn:self.ViewModelScheduler] subscribeNext:^(id x) {
            
            @strongify(self);
            
            self.MissedCalls = [NSNumber numberWithInt:0];
            self.HistoryStatisticsList = [NSArray new];
            self.HistoryStatisticsListMutable = [NSMutableArray new];
            self.HistoryStatisticsListState = HistoryStatisticsListUpdatingStateNone;
            
        }];
        
    }
    
    return self;
}

//- (void) InitAll
//{
//   
//    if (!AllInited)
//    {
//        AllInited = YES;
//        
//        self.MissedCalls = [NSNumber numberWithInt:0];
//        self.HistoryStatisticsList = [NSArray new];
//        self.HistoryStatisticsListMutable = [NSMutableArray new];
//        self.HistoryStatisticsListState = HistoryStatisticsListUpdatingStateNone;
//        self.HistoryStatisticsListUpdatingStateSignal = RACObserve(self, HistoryStatisticsListState);
//        self.HistoryStatisticsUpdatingSignal = RACObserve(self, HistoryStatisticsUpdating);
//        self.HistorySerialQueue = dispatch_queue_create("HistorySerialQueue", DISPATCH_QUEUE_SERIAL);
//        
//        @weakify(self);
//        
//        [self.HistoryStatisticsListUpdatingStateSignal subscribeNext:^(NSNumber *Signal) {
//            
//            @strongify(self);
//            
//            if([Signal integerValue] == HistoryStatisticsListUpdatingReady || [Signal integerValue] == HistoryStatisticsListUpdatingStateUpdated)
//                [self CalcMissedCallCount];
//        }];
//        
//
////#ifdef HistoryManagerModeFake
////        
////        [[ContactsManager Contacts].ContactsListStateSignal subscribeNext:^(NSNumber *State) {
////            
////            @strongify(self);
////            
////            if([State integerValue] == ContactsListLoadingStateFinishedSuccess || [State integerValue] == ContactsListLoadingStateUpdated)
////                [self LoadHistoryStatisticsList];
////            
////        }];
////#else
//
//        [self LoadHistoryStatisticsList];
//        
//        [[ContactsManager Contacts].ContactsListStateSignal subscribeNext:^(NSNumber *State) {
//            
//            @strongify(self);
//            
//            if([State integerValue] == ContactsListLoadingStateFinishedSuccess || [State integerValue] == ContactsListLoadingStateUpdated)
//                [self PerformHistoryChangedEventWhenContactsChanged];
//            
//        }];
////#endif
//    }
//}

- (void) CalcMissedCallCount
{
    int Count = 0;
    
    for (ObjC_HistoryStatisticsModel * HS in [self.HistoryStatisticsList mutableCopy])
    {
        //if(![HS.Readed boolValue])
        Count += [HS.NumberOfMissedCalls intValue];
    }
    
    if([self.MissedCalls intValue] != Count)
    {
        self.MissedCalls = [NSNumber numberWithInt:Count];
        
        [[UiNotificationsManager NotificationsManager] PerformMissedCallsCounterChangeEvent:self.MissedCalls];
    }
}

#pragma mark HistoryStatisticsList

- (void) LoadHistoryStatisticsList
{
    [UiLogger WriteLogInfo:@"HistoryManager:LoadHistoryStatisticsList: Started"];
    
    self.HistoryStatisticsListState = HistoryStatisticsListUpdatingLoading;
    
    NSMutableArray *AllHistoryStatisticsList = [NSMutableArray new];
    
    
    dispatch_group_async(self.DispatchGroup, self.HistorySerialQueue, ^{
        
        BOOL Success;
        
//#ifdef HistoryManagerModeFake
//        
//        Success = [[AppManager app].Core GetAllHistoryStatisticsFake:AllHistoryStatisticsList];
//        
//        if(Success)
//            [self AddFakeContacts:AllHistoryStatisticsList];
//#else
 
        Success = [[AppManager app].Core GetAllHistoryStatistics:AllHistoryStatisticsList];
//#endif
        
        
        if(Success)
        {
            self.HistoryStatisticsListMutable = AllHistoryStatisticsList;
            
            [UiLogger WriteLogInfo:[NSString stringWithFormat:@"HistoryManager: History statistics fetched: %lu", (unsigned long)[self.HistoryStatisticsListMutable count]]];
            
            [self SortAllHistoryStatisticsByDate];
            
            NSArray *HistoryStatisticsListMutableCopy = [self.HistoryStatisticsListMutable copy];
            
            dispatch_async(self.ViewModelQueue, ^{
                
                if([self.Active boolValue])
                {
                    [self setHistoryStatisticsList:HistoryStatisticsListMutableCopy];
                    [self setHistoryStatisticsListState: HistoryStatisticsListUpdatingReady];
                }
                else
                {
                    [self setHistoryStatisticsList:[NSArray new]];
                    [self setHistoryStatisticsListState: HistoryStatisticsListUpdatingFailed];
                }
                
            });
        }
        else
        {
            dispatch_async(self.ViewModelQueue, ^{
                [UiLogger WriteLogInfo:@"HistoryManager:LoadHistoryStatisticsList: Failed"];
                [self setHistoryStatisticsListState: HistoryStatisticsListUpdatingFailed];
            });
        }
        
    });
}

// Temp
//- (void) AddFakeContacts:(NSMutableArray *)AllHistoryStatisticsList
//{
//    if([[ContactsManager Contacts].ContactsList count] > 0)
//    {
//    
//        
//        NSMutableArray *Contacts = [[ContactsManager Contacts].ContactsList mutableCopy];
//        
//        NSPredicate *SearchTextPredicate = [NSPredicate predicateWithFormat:@"(SELF.DodicallId.length > 0) AND (SELF.Blocked == %@)", [NSNumber numberWithBool:NO]];
//        [Contacts filterUsingPredicate:SearchTextPredicate];
//        
//        NSMutableArray *PhoneContacts = [[ContactsManager Contacts].ContactsList mutableCopy];
//        
//        NSPredicate *SearchTextPredicate1 = [NSPredicate predicateWithFormat:@"(SELF.PhonebookId.length > 0) AND (SELF.Blocked == %@)", [NSNumber numberWithBool:NO]];
//        [PhoneContacts filterUsingPredicate:SearchTextPredicate1];
//        
//        int count = (int)[Contacts count] - 1;
//        
//        if(count > 0)
//        {
//            for (ObjC_HistoryStatisticsModel *Entry in AllHistoryStatisticsList) {
//            
//                if(Entry.Contacts && [Entry.Contacts count] > 0)
//                {
//                    ObjC_ContactModel * Contact = Entry.Contacts[0];
//                    
//                    @try {
//                        if(Contact.Id > 0 && Contact.DodicallId && Contact.DodicallId.length > 0)
//                        {
//                            ObjC_ContactModel *ContactReal = Contacts[(arc4random() % count)];
//                            
//                            NSMutableArray *ContactsReal = [[NSMutableArray alloc] init];
//                            
//                            [ContactsReal addObject:ContactReal];
//                            
//                            Entry.Contacts = ContactsReal;
//                        }
//                    }
//                    @catch (NSException *exception) {
//                        
//                    }
//                    @finally {
//                        
//                    }
//                    
//                    @try {
//                        if(Contact.PhonebookId && Contact.PhonebookId.length > 0)
//                        {
//                            ObjC_ContactModel *ContactReal = PhoneContacts[(arc4random() % count)];
//                            
//                            NSMutableArray *ContactsReal = [[NSMutableArray alloc] init];
//                            
//                            [ContactsReal addObject:ContactReal];
//                            
//                            Entry.Contacts = ContactsReal;
//                        }
//                    }
//                    @catch (NSException *exception) {
//                        
//                    }
//                    @finally {
//                        
//                    }
//                    
//                }
//            
//            }
//        }
//        
//        
//    }
//}



- (void) PerformHistoryChangedEvent:(NSMutableArray *) HistoryStatisticsIds
{
    
//    #ifdef HistoryManagerModeFake
//    return;
//    #endif
    
    NSMutableArray *AllHistoryStatisticsList = [NSMutableArray new];
    
    
    dispatch_group_async(self.DispatchGroup, self.HistorySerialQueue, ^{
        
        self.HistoryStatisticsListState = HistoryStatisticsListUpdatingLoading;
        
        BOOL Success = [[AppManager app].Core GetHistoryStatisticsByIds:HistoryStatisticsIds : AllHistoryStatisticsList];
        
        if(Success)
        {
            [self PerformHistoryChangedEvent:HistoryStatisticsIds:AllHistoryStatisticsList];
        }
        else
        {
            dispatch_async(self.ViewModelQueue, ^{
                self.HistoryStatisticsListState = HistoryStatisticsListUpdatingFailed;
            });
        }
            
    });
}

//TODO:Check
- (void) RefreshHistory
{
    if([self.Active boolValue])
    {
        [UiLogger WriteLogInfo:@"HistoryManager:RefreshHistory"];
    
        [self LoadHistoryStatisticsList];
    }
    
}

- (void) PerformHistoryChangedEvent:(NSMutableArray *) HistoryStatisticsIds :
                                    (NSMutableArray <ObjC_HistoryStatisticsModel *> *) HistoryStatisticsList
{
    [UiLogger WriteLogInfo:[NSString stringWithFormat:@"HistoryManager:PerformHistoryChangedEvent: ChangedIds: %lu; ChangedStatistics:%lu", (unsigned long)[HistoryStatisticsIds count], (unsigned long)[HistoryStatisticsList count]]];
    
    NSMutableArray *HistoryUpdates = [NSMutableArray new];
    
    for (ObjC_HistoryStatisticsModel *HistoryStatistics in HistoryStatisticsList)
    {
        HistoryStatisticsUpdatingSignalObject *HistoryUpdate = [self AddOrReplaceHistoryStatistics: HistoryStatistics];
        
        if(HistoryUpdate)
            [HistoryUpdates addObject:HistoryUpdate];
    }
    
    [self SortAllHistoryStatisticsByDate];
    
    NSArray *HistoryStatisticsListCopy = [self.HistoryStatisticsListMutable copy];
    
    dispatch_async(self.ViewModelQueue, ^{
        
        if([self.Active boolValue])
        {
            self.HistoryStatisticsList = HistoryStatisticsListCopy;
            
            if([HistoryUpdates count])
            {
                for(HistoryStatisticsUpdatingSignalObject *Update in HistoryUpdates)
                {
                    [self setHistoryStatisticsUpdating:Update];
                }
                
                self.HistoryStatisticsListState = HistoryStatisticsListUpdatingStateUpdated;
            }
        }
        else
        {
            [self setHistoryStatisticsList:[NSArray new]];
            [self setHistoryStatisticsListState: HistoryStatisticsListUpdatingFailed];
        }
        
        
    });
    
    
    
}


- (HistoryStatisticsUpdatingSignalObject *) AddOrReplaceHistoryStatistics:(ObjC_HistoryStatisticsModel *) HistoryStatistics
{
    
    [UiLogger WriteLogInfo:@"AddOrHistoryStatistics"];
    
    //TODO: CoreHelper HistoryStatisticsDescription
    //[UiLogger WriteLogDebug:[CoreHelper HistoryStatisticsDescription:HistoryStatistics]];
    
    NSInteger Index = [self FindHistoryStatisticsIndex:HistoryStatistics];
    
    if(Index != NSNotFound)
    {
        [self.HistoryStatisticsListMutable replaceObjectAtIndex:Index withObject:HistoryStatistics];
        
        [UiLogger WriteLogInfo:[NSString stringWithFormat:@"AddOrReplaceHistoryStatistics:HistoryStatisticsUpdatingStateStateUpdated: %@",HistoryStatistics.Id]];
        
        return [[HistoryStatisticsUpdatingSignalObject alloc] initWithId:HistoryStatistics.Id AndState:HistoryStatisticsUpdatingStateStateUpdated];
    }
    else
    {
        [self.HistoryStatisticsListMutable addObject:HistoryStatistics];
        
        [UiLogger WriteLogInfo:[NSString stringWithFormat:@"AddOrReplaceHistoryStatistics:HistoryStatisticsUpdatingStateUpdated: %@",HistoryStatistics.Id]];
        
        return [[HistoryStatisticsUpdatingSignalObject alloc] initWithId:HistoryStatistics.Id AndState:HistoryStatisticsUpdatingStateStateAdded];
    }
    
}

- (void) SortAllHistoryStatisticsByDate
{
    
    NSSortDescriptor *SortDescriptorDate = [[NSSortDescriptor alloc] initWithKey:@"LastCallDate" ascending:NO];
    
    [self.HistoryStatisticsListMutable sortUsingDescriptors:@[SortDescriptorDate]];
    
    /*
     [self.HistoryStatisticsListMutable sortUsingComparator:^NSComparisonResult(ObjC_HistoryStatisticsModel *obj1, ObjC_HistoryStatisticsModel *obj2) {
     
     NSDate *Obj1MaxDate;
     for(ObjC_HistoryCallModel *HistoryModel in obj1.HistoryCallsList) {
     if(!Obj1MaxDate || HistoryModel.Date > Obj1MaxDate) Obj1MaxDate = HistoryModel.Date;
     }
     
     NSDate *Obj2MaxDate;
     for(ObjC_HistoryCallModel *HistoryModel in obj1.HistoryCallsList) {
     if(!Obj2MaxDate || HistoryModel.Date > Obj2MaxDate) Obj2MaxDate = HistoryModel.Date;
     }
     
     if(Obj1MaxDate > Obj2MaxDate)
     return NSOrderedAscending;
     else if(Obj1MaxDate < Obj2MaxDate)
     return NSOrderedDescending;
     else
     return NSOrderedSame;
     
     }];
     */
}

- (NSInteger) FindHistoryStatisticsIndexById:(NSString *) HistoryStatisticsId InList:(NSArray *)List
{
    
    NSInteger Index = NSNotFound;
    

    if(List && [List count] && HistoryStatisticsId && HistoryStatisticsId.length)
    {
        for (ObjC_HistoryStatisticsModel *HistoryStatistics in List) {
            
            
            //#ifdef HistoryManagerModeFake
            //
            //            if(HistoryStatistics && HistoryStatistics.Id && HistoryStatistics.Id.length > 0 && [HistoryStatistics.Id isEqualToString:HistoryStatisticsId])
            //#else
            if(HistoryStatistics && HistoryStatistics.Id && HistoryStatistics.Id.length && [[AppManager app].Core CompareHistoryStatisticsIds:HistoryStatistics.Id:HistoryStatisticsId])
                //#endif
                
                
            {
                Index = [List indexOfObject:HistoryStatistics];
                
                break;
            }
            
            
        }
    }
    

    return Index;
    
}

- (NSInteger) FindHistoryStatisticsIndex:(ObjC_HistoryStatisticsModel *) HistoryStatistics
{
    
    if(HistoryStatistics && HistoryStatistics.Id && HistoryStatistics.Id.length)
    {
        return [self FindHistoryStatisticsIndexById:HistoryStatistics.Id InList:self.HistoryStatisticsListMutable];
    }
    
    else
    {
        return NSNotFound;
    }
    
}

- (ObjC_HistoryStatisticsModel *) GetHistoryStatisticsById:(NSString *) HistoryStatisticsId
{
    NSInteger Index = [self FindHistoryStatisticsIndexById:HistoryStatisticsId InList:self.HistoryStatisticsList];
    
    if(Index != NSNotFound)
    {
        return [self.HistoryStatisticsList objectAtIndex:Index];
    }
    else
    {
        return nil;
    }
}

- (ObjC_HistoryStatisticsModel *) GetMutableHistoryStatisticsById:(NSString *) HistoryStatisticsId
{
    NSInteger Index = [self FindHistoryStatisticsIndexById:HistoryStatisticsId InList:self.HistoryStatisticsListMutable];
    
    if(Index != NSNotFound)
    {
        return [self.HistoryStatisticsListMutable objectAtIndex:Index];
    }
    else
    {
        return nil;
    }
}

- (void) SetAllHistoryReaded
{
    self.HistoryStatisticsListState = HistoryStatisticsListUpdatingLoading;
    
    
    dispatch_group_async(self.DispatchGroup, self.HistorySerialQueue, ^{
        
        //NSMutableArray <NSString *> *Ids = [NSMutableArray new];
        
        for(ObjC_HistoryStatisticsModel *HistoryStatistics in self.HistoryStatisticsListMutable)
        {
            if([HistoryStatistics.NumberOfMissedCalls intValue] > 0)
            {
                /*
                for (ObjC_HistoryCallModel *HistoryCall in HistoryStatistics.HistoryCallsList) {
                    
                    [Ids addObject:[HistoryCall.Id copy]];
                    
                }
                 */
                
                HistoryStatistics.NumberOfMissedCalls = [NSNumber numberWithInt:0];
            }

        }
    
//#ifndef HistoryManagerModeFake
        
            
        [[AppManager app].Core SetAllCallHistoryReaded];
            
        
//#endif
        
        NSArray *HistoryListCopy = [self.HistoryStatisticsListMutable copy];
        
        dispatch_async(self.ViewModelQueue, ^{
            self.HistoryStatisticsList = HistoryListCopy;
            self.HistoryStatisticsListState = HistoryStatisticsListUpdatingStateUpdated;
        });
        
    });
}

- (void) SetHistoryReadedForId:(NSString *) Id
{
    self.HistoryStatisticsListState = HistoryStatisticsListUpdatingLoading;
    
    dispatch_group_async(self.DispatchGroup, self.HistorySerialQueue, ^{
        
        //NSMutableArray <NSString *> *Ids = [NSMutableArray new];
        
        ObjC_HistoryStatisticsModel *HistoryStatistics = [self GetMutableHistoryStatisticsById:Id];
        
        if(HistoryStatistics && [HistoryStatistics.NumberOfMissedCalls intValue] > 0)
        {
            /*
            for (ObjC_HistoryCallModel *HistoryCall in HistoryStatistics.HistoryCallsList) {
                
                [Ids addObject:[HistoryCall.Id copy]];
                
            }
             */
            
            HistoryStatistics.NumberOfMissedCalls = [NSNumber numberWithInt:0];
        }

    
//#ifndef HistoryManagerModeFake
    
        
        [[AppManager app].Core SetCallHistoryReaded: Id];
        
    
//#endif
        
        NSArray *HistoryListCopy = [self.HistoryStatisticsListMutable copy];
        
        dispatch_async(self.ViewModelQueue, ^{
            self.HistoryStatisticsList = HistoryListCopy;
            self.HistoryStatisticsListState = HistoryStatisticsListUpdatingStateUpdated;
        });
    });
}

#pragma mark HistoryCallModelList

/*
- (void) PopulateAllHistory: (NSMutableArray <ObjC_HistoryCallModel *> *) AllHistoryCallList
{
    [self SortCallHitoryListByDate:AllHistoryCallList];
    
    NSMutableDictionary *HistoryStatisticsCalls = [[NSMutableDictionary alloc] init];
    
    for (ObjC_HistoryCallModel *HistoryCall in AllHistoryCallList)
    {
        NSString *Id = HistoryCall.HistoryStatisticsId;
        
        if(![HistoryStatisticsCalls objectForKey:Id])
        {
            [HistoryStatisticsCalls setObject:[[NSMutableArray alloc] init] forKey:Id];
        }
        
        NSMutableArray <ObjC_HistoryCallModel *> * HistoryCallListForKey = [HistoryStatisticsCalls objectForKey:Id];
        
        [HistoryCallListForKey addObject:HistoryCall];
        
    }
    
    self.HistoryStatisticsCalls = HistoryStatisticsCalls;
}
 */

- (void) SortCallHitoryListByDate:(NSMutableArray <ObjC_HistoryCallModel *> *) HistoryCallList
{
    NSSortDescriptor *SortDescriptorDate = [[NSSortDescriptor alloc] initWithKey:@"Date" ascending:NO];
    
    [HistoryCallList sortUsingDescriptors:@[SortDescriptorDate]];
}

/*
- (void) PopulateHistoryForHistoryStatisticsId:(NSString *) HistoryStatisticsId: (NSMutableArray <ObjC_HistoryCallModel *> *) AllHistoryCallList
{
    
    NSMutableArray *HistoryCallList = [AllHistoryCallList mutableCopy];
    
    NSPredicate *Predicate = [NSPredicate predicateWithFormat:@"SELF.HistoryStatisticsId == [cd] %@",HistoryStatisticsId];
    
    [HistoryCallList filterUsingPredicate:Predicate];
    
    [self SortCallHitoryListByDate:HistoryCallList];
    
    [self.HistoryStatisticsCalls setObject:HistoryCallList forKey:HistoryStatisticsId];
}
 */

- (NSMutableArray <ObjC_HistoryCallModel *> *) GetHistoryStatisticsCallsById:(NSString *) HistoryStatisticsId
{
    
    ObjC_HistoryStatisticsModel *HistoryStatistics = [self GetHistoryStatisticsById:HistoryStatisticsId];
    
    NSMutableArray *HistoryCalls = [NSMutableArray new];
    
    if(HistoryStatistics && HistoryStatistics.Id.length > 0)
    {
        HistoryCalls = HistoryStatistics.HistoryCallsList;
    }
    
    return HistoryCalls;
}

@end
