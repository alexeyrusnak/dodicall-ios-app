/*
Copyright (C) 2016, Telco Cloud Trading & Logistic Ltd
*/
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
//
//  ObjC_HistoryStatisticsModel.h
//  DodicallBridgeIos
//


#import <Foundation/Foundation.h>
#import "ObjC_ContactModel.h"

@class ObjC_HistoryCallModel;

@interface ObjC_HistoryStatisticsModel : NSObject

@property NSString *Id;

//@property NSString *MasterId;

@property NSString *Identity;

@property NSMutableArray <ObjC_ContactModel *> *Contacts;

@property NSMutableArray <ObjC_HistoryCallModel *> *HistoryCallsList;

@property NSNumber *HasIncomingEncryptedCall;
@property NSNumber *NumberOfIncomingSuccessfulCalls;
@property NSNumber *NumberOfIncomingUnsuccessfulCalls;
@property NSNumber *NumberOfMissedCalls;

@property NSNumber *HasOutgoingEncryptedCall;
@property NSNumber *NumberOfOutgoingSuccessfulCalls;
@property NSNumber *NumberOfOutgoingUnsuccessfulCalls;

@property NSNumber *WasConference;

@property NSDate *LastCallDate;

//@property NSNumber *Readed;

@end

@interface ObjC_HistoryStatisticsFilterModel : NSObject

@property NSMutableArray <NSString *> *HistoryStatisticsIds;

@property NSDate *DateFrom;

@property NSDate *DateTo;

@end
