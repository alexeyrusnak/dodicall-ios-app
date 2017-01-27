//
//  UiHistoryStatisticsCellModel.h
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

@interface UiHistoryStatisticsCellModel : NSObject

@property (strong, nonatomic) NSNumber *IsDodicall;
@property (strong, nonatomic) NSString *CellId;
@property (strong, nonatomic) NSString *Title;
@property (strong, nonatomic) NSString *TitleIndicator;
@property (strong, nonatomic) NSString *CallInfo;
@property (strong, nonatomic) NSNumber *HasIncomingEncryptedCall;
@property (strong, nonatomic) NSNumber *HasOutgoingEncryptedCall;
@property (strong, nonatomic) NSNumber *NumberOfIncomingSuccessfulCalls;
@property (strong, nonatomic) NSNumber *NumberOfIncomingUnsuccessfulCalls;
@property (strong, nonatomic) NSNumber *NumberOfOutgoingSuccessfulCalls;
@property (strong, nonatomic) NSNumber *NumberOfOutgoingUnsuccessfulCalls;
@property (strong, nonatomic) NSString *Status;
@property (strong, nonatomic) NSString *XmppId;
@property (strong, nonatomic) NSString *TitleIndicatorColor;
@property (strong, nonatomic) NSString *AvatarPath;
@property (strong, nonatomic) ObjC_HistoryStatisticsModel *HistoryModel;

@end
