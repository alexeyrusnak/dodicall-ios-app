//
//  UiHistoryStatisticsViewModel.h
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

@interface UiHistoryStatisticsViewModel : NSObject

@property (strong, nonatomic) NSMutableArray *ThreadSafeRows;
@property (strong, nonatomic) NSMutableArray *DataUpdateStages;
@property (strong, nonatomic) NSNumber *DataReloaded;

@property (strong, nonatomic) RACCommand *ShowComingSoonCommand;
@property (strong, nonatomic) RACCommand *CallCommand;
@property (strong, nonatomic) RACCommand *ChatCommand;

- (void) SaveContactForIndexPath:(NSIndexPath *)IndexPath AndReturnInCallback: (void (^)(BOOL))Callback;

@end
