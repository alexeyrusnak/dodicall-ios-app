//
//  UiContactsTabNavRouter.h
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


#define UiContactsTabNavRouterSegueShowContactsList                     @"UiContactsTabNavRouterSegueShowContactsList"
#define UiContactsTabNavRouterSegueShowContactProfile                   @"UiContactsTabNavRouterSegueShowContactProfile"
#define UiContactsTabNavRouterSegueShowContactProfileEdit               @"UiContactsTabNavRouterSegueShowContactProfileEdit"
#define UiContactsTabNavRouterSegueShowContactProfileEditNew            @"UiContactsTabNavRouterSegueShowContactProfileEditNew"
#define UiContactsTabNavRouterSegueShowDirectorySearch                  @"UiContactsTabNavRouterSegueShowDirectorySearch"
#define UiContactsTabNavRouterSegueShowDirectorySearchContactProfile    @"UiContactsTabNavRouterSegueShowDirectorySearchContactProfile"
#define UiContactsTabNavRouterSegueShowContactsRoster                   @"UiContactsTabNavRouterSegueShowContactsRoster"
#define UiContactsTabNavRouterSegueShowRosterContactProfile             @"UiContactsTabNavRouterSegueShowRosterContactProfile"
#define UiContactsTabNavRouterSegueShowProfileStatusPreference          @"UiContactsTabNavRouterSegueShowProfileStatusPreference"
#define UiContactsTabNavRouterSegueShowPreferencesView                  @"UiContactsTabNavRouterSegueShowPreferencesView"

typedef NSString*                                           UiContactsTabNavRouterSegue;

@class ObjC_ContactModel;

@interface UiContactsTabNavRouter : NSObject

+ (void) Reset;

+ (void)PrepareForSegue:(UIStoryboardSegue *)Segue sender:(id)Sender contactModel:(ObjC_ContactModel *) ContactModel;

+ (void) CloseProfileViewWhenBackAction;

+ (void) CloseProfileViewWhenSaveAction;

+ (void) CloseProfileEditViewWhenBackAction;

+ (void) CloseProfileEditViewWhenSaveAction;

+ (void) CloseProfileEditViewWhenDeleteAction;

+ (void) CloseDirectorySearchViewWhenBackAction;

+ (void) CloseRosterViewWhenBackAction;

+ (void) ClosePreferencesViewWhenBackAction;

@end
