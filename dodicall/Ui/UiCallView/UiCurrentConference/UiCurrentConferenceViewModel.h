//
//  UiCurrentConferenceViewModel.h
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

#import "ConferenceModel.h"
#import "ObjC_CallsModel.h"
#import "UiCurrentConferenceUserCellModel.h"

@interface UiCurrentConferenceViewModel : NSObject



@property (strong, nonatomic) ConferenceModel *ConferenceModel;

@property (strong, nonatomic) NSMutableArray <UiCurrentConferenceUserCellModel *> *UsersArray;
@property (strong, nonatomic) NSString *ConferenceTitle;
@property (strong, nonatomic) NSString *ChatId;
@property (assign) NSTimeInterval ConferenceDuration;
@property (strong, nonatomic) NSNumber *IsMicEnabled;

@property (strong, nonatomic) RACCommand *ShowComingSoon;
@property (strong, nonatomic) RACCommand *DropCall;
@property (strong, nonatomic) RACCommand *SwitchMic;

@end
