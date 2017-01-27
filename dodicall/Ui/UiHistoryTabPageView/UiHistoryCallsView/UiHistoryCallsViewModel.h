//
//  UiHistoryCallsViewModel.h
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
#import "ObjC_HistoryStatisticsModel.h"
#import <ReactiveCocoa/ReactiveCocoa.h>
#import "UiHistoryCallsContactCellModel.h"

@interface UiHistoryCallsViewModel : NSObject

@property (strong, nonatomic) ObjC_HistoryStatisticsModel *StatisticsModel;
@property (strong, nonatomic) NSMutableArray *ThreadSafeCallsRowsArray;
@property (strong, nonatomic) NSMutableArray *CallsDataUpdateStages;
@property (strong, nonatomic) NSNumber *CallsRowsUpdated;

@property  (strong, nonatomic) UiHistoryCallsContactCellModel *ContactCellModel;

@property (strong, nonatomic) RACCommand *ShowComingSoonCommand;
@property (strong, nonatomic) RACCommand *CallCommand;
@property (strong, nonatomic) RACCommand *MessageCommand;

- (void) SaveContactAndReturnInCallback: (void (^)(BOOL))Callback;

- (void) SetReaded;

@end
