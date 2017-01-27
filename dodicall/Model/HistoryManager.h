//
//  HistoryManager.h
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
#import "ObjC_HistoryStatisticsModel.h"
#import "ObjC_HistoryCallModel.h"

//#define HistoryManagerModeFake

typedef NS_ENUM(NSInteger, HistoryStatisticsListUpdatingState)
{
    HistoryStatisticsListUpdatingStateNone,
    HistoryStatisticsListUpdatingLoading,
    HistoryStatisticsListUpdatingReady,
    HistoryStatisticsListUpdatingFailed,
    HistoryStatisticsListUpdatingStateUpdated
};

typedef NS_ENUM(NSInteger, HistoryStatisticsUpdatingState)
{
    HistoryStatisticsUpdatingStateStateNone,
    HistoryStatisticsUpdatingStateStateAdded,
    HistoryStatisticsUpdatingStateStateUpdated,
    HistoryStatisticsUpdatingStateRemoved
};

@interface HistoryStatisticsUpdatingSignalObject : NSObject

@property HistoryStatisticsUpdatingState State;

@property NSString *Id;

- (instancetype)initWithId:(NSString *) HistoryStatisticsId AndState:(HistoryStatisticsUpdatingState) State;

@end



@interface HistoryManager : NSObject

+ (instancetype) Manager;

+ (void) Destroy;

- (void) SetActive:(BOOL) Active;

@property dispatch_group_t DispatchGroup;
@property dispatch_queue_t ViewModelQueue;
@property RACTargetQueueScheduler *ViewModelScheduler;
@property RACTargetQueueScheduler *ManagerScheduler;

@property NSNumber *MissedCalls;

#pragma mark HistoryStatisticsList

@property NSArray <ObjC_HistoryStatisticsModel *> *HistoryStatisticsList;
@property RACSignal *HistoryStatisticsListUpdatingStateSignal;
@property RACSignal *HistoryStatisticsUpdatingSignal;

- (void) LoadHistoryStatisticsList;

- (ObjC_HistoryStatisticsModel *) GetHistoryStatisticsById:(NSString *) HistoryStatisticsId;

- (void) SetAllHistoryReaded;

- (void) SetHistoryReadedForId:(NSString *) Id;

- (void) PerformHistoryChangedEvent:(NSMutableArray *) HistoryStatisticsIds;


#pragma mark HistoryCallModelList

- (NSMutableArray <ObjC_HistoryCallModel *> *) GetHistoryStatisticsCallsById:(NSString *) HistoryStatisticsId;


@end
