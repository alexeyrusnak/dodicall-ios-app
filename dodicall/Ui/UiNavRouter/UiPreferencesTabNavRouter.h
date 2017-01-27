//
//  UiPreferencesTabNavRouter.h
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


#define UiPreferencesTabNavRouterSeguesShowPreferenceLanguageSelectView     @"UiPreferencesTabNavRouterSeguesShowPreferenceLanguageSelectView"

#define UiPreferencesTabNavRouterSeguesShowPreferenceServerAreaSelectView   @"UiPreferencesTabNavRouterSeguesShowPreferenceServerAreaSelectView"

#define UiPreferencesTabNavRouterSeguesShowPreferenceStatusSetView          @"UiPreferencesTabNavRouterSeguesShowPreferenceStatusSetView"

#define UiPreferencesTabNavRouterSeguesShowSipAccountsView                  @"UiPreferencesTabNavRouterSeguesShowSipAccountsView"

#define UiPreferencesTabNavRouterSeguesShowVideoSetsView                    @"UiPreferencesTabNavRouterSeguesShowVideoSetsView"

#define UiPreferencesTabNavRouterSeguesShowVoipEncryptionSelectView         @"UiPreferencesTabNavRouterSeguesShowVoipEncryptionSelectView"

#define UiPreferencesTabNavRouterSeguesShowEchoCancellationSelectView       @"UiPreferencesTabNavRouterSeguesShowEchoCancellationSelectView"

#define UiPreferencesTabNavRouterSeguesShowStyleSelectView                  @"UiPreferencesTabNavRouterSeguesShowStyleSelectView"

#define UiPreferencesTabNavRouterCodecsView                                 @"UiPreferencesTabNavRouterCodecsView"

#define UiPreferencesTabNavRouterTicketView                                 @"UiPreferencesTabNavRouterTicketView"

#define UiPreferencesTabNavRouterWebView                                    @"UiPreferencesTabNavRouterWebView"

#define UiPreferencesTabNavRouterMyProfile                                  @"UiPreferencesTabNavRouterMyProfile"

typedef NSString*                                                           UiPreferencesTabNavRouterSegue;





@interface UiPreferencesTabNavRouter : NSObject

+ (void) Reset;

+ (void) PrepareForSegue:(UIStoryboardSegue *)Segue sender:(id)Sender;

+ (void) ClosePreferenceLanguageSelectView;

+ (void) ClosePreferenceServerAreaSelectView;

+ (void) ClosePreferenceStatusSetView;

+ (void) ClosePreferenceSipAccountsView;

+ (void) ClosePreferenceVideoSetsView;

+ (void) ClosePreferenceVoipEncryptionSelectView;

+ (void) ClosePreferenceEchoCancellationSelectView;

+ (void) ClosePreferenceStyleView;

+ (void) ClosePreferenceCodecsView;

+ (void) ClosePreferenceTicketView;

+ (void) ClosePreferenceWebView;

+ (void) CloseProfileViewWhenBackAction;

@end


