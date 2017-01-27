//
//  UiCallViewModel.h
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

@class ObjC_CallsModel;
@class ObjC_ContactModel;

@interface UiCurrentCallViewModel : NSObject

@property (nonatomic) ObjC_CallModel *CallModel;

@property (strong, nonatomic) NSString *Name;
@property (assign, nonatomic) NSTimeInterval CallDuration;
@property (strong, nonatomic) NSTimer *callTimer;

@property (strong, nonatomic) RACCommand *ShowComingSoon;
@property (strong, nonatomic) RACCommand *CloseCallView;
@property (strong, nonatomic) RACCommand *SwitchMic;
@property (strong, nonatomic) RACCommand *TransferCall;
@property (strong, nonatomic) RACCommand *HideView;

@property (assign, nonatomic) NSNumber *Encrypted;
@property (assign, nonatomic) NSNumber *Dodicall;
@property (assign, nonatomic) NSNumber *MobileCall;
@property (assign, nonatomic) NSNumber *ChatAllowed;
@property (assign, nonatomic) NSNumber *IsSmallDevice;
@property (assign, nonatomic) NSNumber *IsMicEnabled;

@property (strong, nonatomic) NSString *AvatarPath;

@end
