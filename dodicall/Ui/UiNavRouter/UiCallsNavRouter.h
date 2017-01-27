//
//  UiCallNavRouter.h
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
#import <UIKit/UIKit.h>
#import "UiCallViewAnimator.h"
#import "UiCallNavigationController.h"

@class ObjC_CallModel;
@class ConferenceModel;
@class UiCallTransferTabPageView;

@interface UiCallsNavRouter : NSObject

@property (strong, nonatomic) UiCallNavigationController *NavigationView;
@property (strong, nonatomic) UiCallViewAnimator *Animator;
@property (strong, nonatomic) UIViewController *CurrentCallView;
@property (strong, nonatomic) UiCallTransferTabPageView *CallTransferTabPageView;
@property (strong, nonatomic) NSNumber *IsCallViewVisible;

+ (instancetype) Router;

+ (instancetype) NavRouter;

+ (void) CreateAndShowCurrentCallViewWithCall:(ObjC_CallModel *) callModel;
+ (void) CreateAndShowIncomingCallViewWithCall:(ObjC_CallModel *) callModel;
+ (void) CreateAndShowOutgoingCallViewWithCall:(ObjC_CallModel *) callModel;
+ (void) UpdateCurrentCallViewWithCall:(ObjC_CallModel *)callModel;
+ (void) CreateAndShowCurrentConferenceCall:(ConferenceModel *)ConferenceModel;

+ (void) CloseCurrentCallView;
+ (void) HideCallView;
+ (void) ShowCallView;
+ (void) ShowComingSoon;
+ (void) ShowMicrophoneDisabledInfo;
+ (void) ShowCallStartError;

#pragma mark CallTransfer
+ (void) CreateAndShowCallTransferTabPageView;
+ (void) CloseCallTransferTabPageView;

//+ (void) ShowAudioSourceMenuForOptions:(NSArray *)Options AndCallback:(void (^)(NSUInteger))Callback;

@end
