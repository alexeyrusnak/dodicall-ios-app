//
//  UINavRouter.h
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

#import "UiLoginPageView.h"
#import "UiAppTabsView.h"
#import "UiContactsTabPageView.h"
#import "UiContactsTabPageContactsListView.h"
#import "UiPreferenceLanguageSelectView.h"
#import "UiPreferenceStatusSetView.h"
#import "UiPreferenceSipAccountsView.h"
#import "UiPreferenceVideoSetsView.h"
#import "UiPreferenceServerAreaSelectView.h"
#import "UiPreferenceVoipEncryptionSelectView.h"
#import "UiPreferenceEchoCancellationSelectView.h"
#import "UiPreferenceUiStyleSelectView.h"
#import "UiPreferenceWebView.h"
#import "UiPreferenceCodecsView.h"
#import "UiPreferenceIssueTicketView.h"
#import "SlideNavigationController.h"
#import "UiContactProfileView.h"
#import "UiContactsRosterView.h"


#import "UiContactsTabNavRouter.h"
#import "UiChatsTabNavRouter.h"
#import "UiPreferencesTabNavRouter.h"
#import "UiHistoryTabNavRouter.h"

#import "UiAlertControllerView.h"



@interface UiNavRouter : NSObject

//@property UINavigationController *MainView;

@property UINavigationController *AppLoginPageNavigationView;

@property UiLoginPageView *AppLoginPageView;

//@property UINavigationController *AppMainNavigationView; //TODO:LEFT_MENU

@property UINavigationController *AppMainNavigationView; //TODO:LEFT_MENU

//@property SlideNavigationController *AppMainSlideNavigationView; //TODO:LEFT_MENU

@property (nonatomic, weak) UiAppTabsView *AppTabs;

@property UiContactsTabPageView *ContactsTabPageView;

@property UiContactsTabPageContactsListView *ContactsTabPageContactsListView;

@property NSNumber *Test;

@property UINavigationController *CallHistoryTabPageView;

@property UINavigationController *DialerTabPageView;

@property UINavigationController *ChatHistoryTabPageView;

@property UINavigationController *PreferencesTabPageView;

@property UiPreferenceLanguageSelectView *PreferencesLanguageSelectView;

@property UiPreferenceStatusSetView *PreferencesStatusSetView;

@property UiContactProfileView *MyProfileView;

@property UiContactProfileView *ProfileView;

@property UiContactsRosterView *RosterView;

@property UiPreferenceSipAccountsView *PreferenceSipAccountsView;

@property UiPreferenceVideoSetsView *PreferenceVideoSetsView;

@property UiPreferenceServerAreaSelectView *PreferenceServerAreaSelectView;

@property UiPreferenceVoipEncryptionSelectView *PreferenceVoipEncryptionSelectView;

@property UiPreferenceEchoCancellationSelectView *PreferenceEchoCancellationSelectView;

@property UiPreferenceUiStyleSelectView *PreferenceUiStyleSelectView;

@property UiPreferenceWebView *PreferenceWebView;

@property UiPreferenceCodecsView *PreferenceCodecsView;

@property UiPreferenceIssueTicketView *PreferenceIssueTicketView;

@property UiAlertControllerView *UpdateAlertView;

+ (instancetype) Router;

+ (instancetype) NavRouter;

- (void) Reset;

- (void) ShowPageProcess;
- (void) HidePageProcess;
- (void) ShowPageProcessWithView:(UIView *) View;
- (void) HidePageProcessWithView:(UIView *) View;


- (void) ShowLoginPage;
- (void) ShowContactsTabPage;
- (void) ShowPreferenceTabPage;
- (void) ShowChatsTabPage;
- (void) ShowHistoryTabPage;

- (void) ShowPreferenceLanguageSelectView;
- (void) HidePreferenceLanguageSelectView;

- (void) ShowPreferenceStatusSetView;
- (void) HidePreferenceStatusSetView;

- (void) ShowMyProfileView;

- (void) ShowPreferenceSipAccountsView;
- (void) HidePreferenceSipAccountsView;

- (void) ShowPreferenceVideoSetsView;
- (void) HidePreferenceVideoSetsView;

- (void) ShowPreferenceServerAreaSelectView;
- (void) HidePreferenceServerAreaSelectView;

- (void) ShowPreferenceVoipEncryptionSelectView;
- (void) HidePreferenceVoipEncryptionSelectView;

- (void) ShowPreferenceEchoCancellationSelectView;
- (void) HidePreferenceEchoCancellationSelectView;

- (void) ShowPreferenceUiStyleSelectView;
- (void) HidePreferenceUiStyleSelectView;

- (void) ShowPreferenceWebView:(NSString *) Url withTitle:(NSString *) Title;
- (void) ShowPreferenceWebViewWithHtmlData:(NSString *) DataHtml withTitle:(NSString *) Title;
- (void) HidePreferenceWebView;

- (void) ShowPreferenceCodecsView;
- (void) HidePreferenceCodecsView;

- (void) ShowPreferenceIssueTicketView;
- (void) HidePreferenceIssueTicketView;

- (void) OpenUrlInExternalBrowser:(NSString *) Url;

//- (void) OpenAppLeftMenu;
//- (void) OpenAppLeftMenuWithCompletion:(void (^)())Callback;
//- (void) HideAppLeftMenu;
//- (void) HideAppLeftMenuWithCompletion:(void (^)())Callback;

+ (void) ShowComingSoon;
+ (void) ShowUnknownError;
- (void) ShowVersionAlertWithAction:(void (^)())Action;

- (void) ShowRosterView;

- (void) ShowProfileView:(ObjC_ContactModel *) Profile;

- (void) ShowOrWaitInviteWithXmppId:(NSString *) XmppId WithAutoAccept:(BOOL) AutoAccept;
- (void) ShowOrWaitInviteWithXmppId:(NSString *) XmppId;

- (BOOL) IsCurrentViewLogin;

- (void) PreloadAllTabs;

@end
