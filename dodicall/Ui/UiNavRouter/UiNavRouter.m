//
//  UINavRouter.m
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

#import "UiNavRouter.h"
#import "UiLogger.h"
#import "MBProgressHUD.h"

#import "AppManager.h"

#import "ContactsManager.h"

static UiNavRouter* NavRouterSingleton = nil;

@interface UiNavRouter()

@property UIViewController *CurrentView;
@property UIImageView *LoadingView;

@end

@implementation UiNavRouter

//@synthesize MainView;
/*
@synthesize AppLoginPageNavigationView;
@synthesize AppLoginPageView;
@synthesize AppTabs;
@synthesize AppMainNavigationView;
@synthesize AppMainSlideNavigationView;
@synthesize ContactsTabPageView;
@synthesize ContactsTabPageContactsListView;
@synthesize CallHistoryTabPageView;
@synthesize DialerTabPageView;
@synthesize ChatHistoryTabPageView;
@synthesize PreferencesTabPageView;
@synthesize PreferencesLanguageSelectView;
@synthesize PreferencesStatusSetView;
@synthesize MyProfileView;
@synthesize PreferenceSipAccountsView;
@synthesize PreferenceVideoSetsView;
@synthesize PreferenceServerAreaSelectView;
@synthesize PreferenceVoipEncryptionSelectView;
@synthesize PreferenceEchoCancellationSelectView;
@synthesize PreferenceUiStyleSelectView;
@synthesize PreferenceWebView;
@synthesize PreferenceCodecsView;
@synthesize PreferenceIssueTicketView;
 */

+ (instancetype) Router
{
    return [self NavRouter];
}

+ (instancetype) NavRouter {
    
    static dispatch_once_t NavRouterSingletonToken;
    
    dispatch_once(&NavRouterSingletonToken, ^{
        
        NavRouterSingleton = [[UiNavRouter alloc] init];
        
    });
    
    return NavRouterSingleton;
    
}

- (instancetype) init
{
    self = [super init];
    
    if (self) {
        
        [UiLogger WriteLogInfo:@"Navigation router init"];
        
        //Setup loading view
        self.LoadingView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"loading_01"]];
        self.LoadingView.animationImages =  @[[UIImage imageNamed:@"loading_01"], [UIImage imageNamed:@"loading_02"],[UIImage imageNamed:@"loading_03"], [UIImage imageNamed:@"loading_04"],[UIImage imageNamed:@"loading_05"]];
        self.LoadingView.animationDuration = 0.5;
        
        
        
    }
    
    return self;
}

- (void) Reset
{
    self.AppLoginPageNavigationView = nil;
    self.AppLoginPageView = nil;
    self.AppMainNavigationView = nil;
    //self.AppMainSlideNavigationView.delegate = nil; //TODO:LEFT_MENU
    //self.AppMainSlideNavigationView.leftMenu = nil; //TODO:LEFT_MENU
    //self.AppMainSlideNavigationView = nil;
    self.AppTabs = nil;
    self.ContactsTabPageView = nil;
    self.ContactsTabPageContactsListView = nil;
    self.CallHistoryTabPageView = nil;
    self.DialerTabPageView = nil;
    self.ChatHistoryTabPageView = nil;
    self.PreferencesTabPageView = nil;
    self.PreferencesLanguageSelectView = nil;
    self.PreferencesStatusSetView = nil;
    self.PreferenceSipAccountsView = nil;
    self.PreferenceVideoSetsView = nil;
    self.PreferenceServerAreaSelectView = nil;
    self.PreferenceVoipEncryptionSelectView = nil;
    self.PreferenceEchoCancellationSelectView = nil;
    self.PreferenceUiStyleSelectView = nil;
    self.PreferenceWebView = nil;
    self.PreferenceCodecsView = nil;
    self.PreferenceIssueTicketView = nil;
    self.MyProfileView = nil;
    self.RosterView = nil;
    
    self.CurrentView = nil;
    [[[UIApplication sharedApplication] delegate] window].rootViewController = nil;
    
    [UiChatsTabNavRouter Reset];
    [UiContactsTabNavRouter Reset];
    [UiPreferencesTabNavRouter Reset];
    [UiHistoryTabNavRouter Reset];
}

- (void) ShowPageProcess
{
    
    [UiLogger WriteLogInfo:@"NavRouter: Show page process"];
    
    MBProgressHUD *hud;
    
    if(self.CurrentView && self.CurrentView.presentedViewController)
    {
        hud = [MBProgressHUD showHUDAddedTo:self.CurrentView.presentedViewController.view  animated:YES];
    }
    else
    {
        hud = [MBProgressHUD showHUDAddedTo:self.CurrentView.view  animated:YES];
    }
    
    [hud setMode:MBProgressHUDModeCustomView];
    [hud setCustomView:self.LoadingView];
    [hud setMargin:10];
    [hud setColor:[UIColor colorWithRed:0.36 green:0.36 blue:0.36 alpha:0.8]];
    [self.LoadingView startAnimating];
    
}


- (void) HidePageProcess
{
    
    [UiLogger WriteLogInfo:@"NavRouter: Hide page process"];
    
    if(self.CurrentView && self.CurrentView.presentedViewController)
    {
        [MBProgressHUD hideHUDForView:self.CurrentView.presentedViewController.view animated:YES];
    }
    else
    {
        [MBProgressHUD hideHUDForView:self.CurrentView.view animated:YES];
    }
    
    [self.LoadingView stopAnimating];
    
}

- (void) ShowPageProcessWithView:(UIView *) View
{
    if(View) {
        MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:View  animated:YES];
        
        [hud setMode:MBProgressHUDModeCustomView];
        [hud setCustomView:self.LoadingView];
        [hud setMargin:10];
        [hud setColor:[UIColor colorWithRed:0.36 green:0.36 blue:0.36 alpha:0.8]];
        [self.LoadingView startAnimating];
    }
    
}

- (void) HidePageProcessWithView:(UIView *) View
{
    if(View) {
        [MBProgressHUD hideHUDForView:View animated:YES];
        [self.LoadingView stopAnimating];
    }
    
}


- (void) ShowLoginPage
{
    
    [UiLogger WriteLogInfo:@"NavRouter: Show login page"];
    
    if(self.AppLoginPageNavigationView)
    {
        self.AppLoginPageNavigationView = nil;
        self.AppLoginPageView = nil;
    }
    
    
    if(!self.AppLoginPageView)
    {
        UIStoryboard *sb = [UIStoryboard storyboardWithName:@"UiLoginPageView" bundle:nil];
        self.AppLoginPageNavigationView = (UINavigationController *)[sb instantiateViewControllerWithIdentifier:@"UiLoginPageNavigationView"];
        
        self.AppLoginPageView = (UiLoginPageView *)[self.AppLoginPageNavigationView topViewController];
    }
    
    [[[UIApplication sharedApplication] delegate] window].rootViewController = self.AppLoginPageNavigationView;
    
    self.CurrentView = self.AppLoginPageView;
    
}

- (void) ShowContactsTabPage
{
    
    [UiLogger WriteLogInfo:@"NavRouter: Show contacts tab page"];
    
    if(self.CurrentView.presentedViewController)
        [self.CurrentView dismissViewControllerAnimated:TRUE completion:nil];
    
    if(!self.AppMainNavigationView)
    {
        UIStoryboard *sb = [UIStoryboard storyboardWithName:@"UiAppTabsView" bundle:nil];
        self.AppMainNavigationView = (UINavigationController *)[sb instantiateViewControllerWithIdentifier:@"AppMainNavigationView"];
        //self.AppMainSlideNavigationView = (SlideNavigationController *)[self.AppMainNavigationView topViewController];
        
        
        self.AppTabs = (UiAppTabsView *)[self.AppMainNavigationView topViewController];
        
        //self.AppMainSlideNavigationView.leftMenu = (UIViewController *) [sb instantiateViewControllerWithIdentifier:@"UiAppLeftSlideMenuNavigationContainer"];

    }
    
    if([[[UIApplication sharedApplication] delegate] window].rootViewController)
        
        if(self.CurrentView == self.AppMainNavigationView)
        {
            [self.AppTabs setSelectedIndex:0];
        }
        else
        {
            [UIView transitionWithView:[[[UIApplication sharedApplication] delegate] window]
                              duration:0.5
                               options:UIViewAnimationOptionTransitionCrossDissolve
                            animations:^{ [[[UIApplication sharedApplication] delegate] window].rootViewController = self.AppMainNavigationView; }
                            completion:nil];
            
        }
    else
        [[[UIApplication sharedApplication] delegate] window].rootViewController = self.AppMainNavigationView;
    
    
    [self.AppTabs setSelectedIndex:0];
    
    self.CurrentView = self.AppMainNavigationView;
    
    self.AppLoginPageNavigationView = nil;
    self.AppLoginPageView = nil;
    
}

- (void) ShowPreferenceTabPage
{
    
    [UiLogger WriteLogInfo:@"NavRouter: Show preferences tab page"];
    
    if(self.CurrentView.presentedViewController)
        [self.CurrentView dismissViewControllerAnimated:TRUE completion:nil];
    
    if(!self.AppMainNavigationView)
    {
        UIStoryboard *sb = [UIStoryboard storyboardWithName:@"UiAppTabsView" bundle:nil];
        self.AppMainNavigationView = (UINavigationController *)[sb instantiateViewControllerWithIdentifier:@"AppMainNavigationView"];
        //self.AppMainSlideNavigationView = (SlideNavigationController *)[self.AppMainNavigationView topViewController];
        
        
        self.AppTabs = (UiAppTabsView *)[self.AppMainNavigationView topViewController];
        
        //self.AppMainSlideNavigationView.leftMenu = (UIViewController *) [sb instantiateViewControllerWithIdentifier:@"UiAppLeftSlideMenuNavigationContainer"];
    }
    
    if([[[UIApplication sharedApplication] delegate] window].rootViewController)
        
        if(self.CurrentView == self.AppMainNavigationView)
        {
            [self.AppTabs setSelectedIndex:4];
        }
        else
        {
            
            [UIView transitionWithView:[[[UIApplication sharedApplication] delegate] window]
                              duration:0.5
                               options:UIViewAnimationOptionTransitionFlipFromLeft
                            animations:^{ [[[UIApplication sharedApplication] delegate] window].rootViewController = self.AppMainNavigationView; }
                            completion:nil];
            
        }
        else
            [[[UIApplication sharedApplication] delegate] window].rootViewController = self.AppMainNavigationView;

    
    [self.AppTabs setSelectedIndex:4];
    
    self.CurrentView = self.AppMainNavigationView;
    
    self.AppLoginPageNavigationView = nil;
    self.AppLoginPageView = nil;
    
}

- (void) ShowChatsTabPage
{
    
    [UiLogger WriteLogInfo:@"NavRouter: Show chats tab page"];
    
    if(self.CurrentView.presentedViewController)
        [self.CurrentView dismissViewControllerAnimated:TRUE completion:nil];
    
    if(!self.AppMainNavigationView)
    {
        UIStoryboard *sb = [UIStoryboard storyboardWithName:@"UiAppTabsView" bundle:nil];
        self.AppMainNavigationView = (UINavigationController *)[sb instantiateViewControllerWithIdentifier:@"AppMainNavigationView"];
        //self.AppMainSlideNavigationView = (SlideNavigationController *)[self.AppMainNavigationView topViewController];
        
        
        self.AppTabs = (UiAppTabsView *)[self.AppMainNavigationView topViewController];
        
        //self.AppMainSlideNavigationView.leftMenu = (UIViewController *) [sb instantiateViewControllerWithIdentifier:@"UiAppLeftSlideMenuNavigationContainer"];
    }
    
    if([[[UIApplication sharedApplication] delegate] window].rootViewController)
        
        if(self.CurrentView == self.AppMainNavigationView)
        {
            [self.AppTabs setSelectedIndex:3];
        }
        else
        {
            
            [UIView transitionWithView:[[[UIApplication sharedApplication] delegate] window]
                              duration:0.5
                               options:UIViewAnimationOptionTransitionFlipFromLeft
                            animations:^{ [[[UIApplication sharedApplication] delegate] window].rootViewController = self.AppMainNavigationView; }
                            completion:nil];
            
        }
        else
            [[[UIApplication sharedApplication] delegate] window].rootViewController = self.AppMainNavigationView;
    
    
    [self.AppTabs setSelectedIndex:3];
    
    self.CurrentView = self.AppMainNavigationView;
    
    self.AppLoginPageNavigationView = nil;
    self.AppLoginPageView = nil;
    
}

- (void) ShowHistoryTabPage
{
    
    [UiLogger WriteLogInfo:@"NavRouter: Show history tab page"];
    
    if(self.CurrentView.presentedViewController)
        [self.CurrentView dismissViewControllerAnimated:TRUE completion:nil];
    
    if(!self.AppMainNavigationView)
    {
        UIStoryboard *sb = [UIStoryboard storyboardWithName:@"UiAppTabsView" bundle:nil];
        self.AppMainNavigationView = (UINavigationController *)[sb instantiateViewControllerWithIdentifier:@"AppMainNavigationView"];
        //self.AppMainSlideNavigationView = (SlideNavigationController *)[self.AppMainNavigationView topViewController];
        
        
        self.AppTabs = (UiAppTabsView *)[self.AppMainNavigationView topViewController];
        
        //self.AppMainSlideNavigationView.leftMenu = (UIViewController *) [sb instantiateViewControllerWithIdentifier:@"UiAppLeftSlideMenuNavigationContainer"];
    }
    
    if([[[UIApplication sharedApplication] delegate] window].rootViewController)
        
        if(self.CurrentView == self.AppMainNavigationView)
        {
            [self.AppTabs setSelectedIndex:1];
        }
        else
        {
            
            [UIView transitionWithView:[[[UIApplication sharedApplication] delegate] window]
                              duration:0.5
                               options:UIViewAnimationOptionTransitionFlipFromLeft
                            animations:^{ [[[UIApplication sharedApplication] delegate] window].rootViewController = self.AppMainNavigationView; }
                            completion:nil];
            
        }
        else
            [[[UIApplication sharedApplication] delegate] window].rootViewController = self.AppMainNavigationView;
    
    
    [self.AppTabs setSelectedIndex:1];
    
    self.CurrentView = self.AppMainNavigationView;
    
    self.AppLoginPageNavigationView = nil;
    self.AppLoginPageView = nil;
    
}


- (void) ShowPreferenceLanguageSelectView
{
    
    [UiLogger WriteLogInfo:@"NavRouter: Show preference language select view"];
    
    if(self.AppLoginPageView)
        self.AppLoginPageView = nil;
    
    if(!self.PreferencesLanguageSelectView)
    {
        UIStoryboard *sb = [UIStoryboard storyboardWithName:@"UiPreferencesTabPageView" bundle:nil];
        self.PreferencesLanguageSelectView = (UiPreferenceLanguageSelectView *)[sb instantiateViewControllerWithIdentifier:@"UiPreferenceLanguageSelectView"];
    }
    
    
    
    [self.CurrentView presentViewController:self.PreferencesLanguageSelectView animated:YES completion:^{}];
    
}

- (void) HidePreferenceLanguageSelectView
{
    [UiLogger WriteLogInfo:@"NavRouter: Hide preference language select view"];
    
    if(self.CurrentView && self.CurrentView.presentedViewController)
        [self.CurrentView dismissViewControllerAnimated:TRUE completion:nil];
    
}


- (void) ShowPreferenceStatusSetView
{
    
    [UiLogger WriteLogInfo:@"NavRouter: Show preference status set view"];
    
    if(!self.PreferencesStatusSetView)
    {
        UIStoryboard *sb = [UIStoryboard storyboardWithName:@"UiPreferencesTabPageView" bundle:nil];
        self.PreferencesStatusSetView = (UiPreferenceStatusSetView *)[sb instantiateViewControllerWithIdentifier:@"UiPreferenceStatusSetView"];
    }
    
    [self.PreferencesStatusSetView setCallbackOnBackAction:^{
        
        [CATransaction begin];
        [CATransaction setCompletionBlock:^{
            
            dispatch_async(dispatch_get_main_queue(), ^{
                
                //[[UiNavRouter NavRouter] OpenAppLeftMenu];
                
                [UiNavRouter NavRouter].PreferencesStatusSetView = nil;
                
            });
            
        }];
        
        [[UiNavRouter NavRouter].AppMainNavigationView popToRootViewControllerAnimated:YES];
        
        [[UiNavRouter NavRouter].AppMainNavigationView setNavigationBarHidden:YES animated:YES];
        
        
        [CATransaction commit];
        
    }];
    
    
    
    [self.AppMainNavigationView pushViewController:self.PreferencesStatusSetView animated:YES];
    
    [[UiNavRouter NavRouter].AppMainNavigationView setNavigationBarHidden:NO animated:YES];
    
}

- (void) HidePreferenceStatusSetView
{
    [UiLogger WriteLogInfo:@"NavRouter: Hide preference status set view"];
    
    if(self.CurrentView && self.CurrentView.presentedViewController)
        [self.CurrentView dismissViewControllerAnimated:TRUE completion:nil];
    
}

- (void) ShowMyProfileView
{
    [UiLogger WriteLogInfo:@"NavRouter: Show preference my profile"];
    
    @weakify(self);
    
    void (^Callback)(ObjC_ContactModel *) = ^(ObjC_ContactModel * MyProfile)
    {
        @strongify(self);
        
        [self HidePageProcess];
        
        if(MyProfile)
        {
            if(!self.MyProfileView)
            {
                UIStoryboard *sb = [UIStoryboard storyboardWithName:@"UiContactsTabPage" bundle:nil];
                self.MyProfileView = (UiContactProfileView *)[sb instantiateViewControllerWithIdentifier:@"UiContactProfileView"];
            }
            
            [UiLogger WriteLogDebug:[NSString stringWithFormat:@"NavRouter: %@", [CoreHelper ContactModelDescription:(ObjC_ContactModel *) MyProfile]]];
            
            [self.MyProfileView.ViewModel setContactData:(ObjC_ContactModel *) MyProfile];
            
            [self.MyProfileView setCallbackOnBackAction:^{
                
                [CATransaction begin];
                [CATransaction setCompletionBlock:^{
    
                    dispatch_async(dispatch_get_main_queue(), ^{
                        
                        //[[UiNavRouter NavRouter] OpenAppLeftMenu];
                        
                        [UiNavRouter NavRouter].MyProfileView = nil;
                        
                    });
                    
                }];
                
                [[UiNavRouter NavRouter].AppMainNavigationView popToRootViewControllerAnimated:YES];
                
                [[UiNavRouter NavRouter].AppMainNavigationView setNavigationBarHidden:YES animated:YES];
                
                
                [CATransaction commit];
                
            }];
            
            
            [self.AppMainNavigationView pushViewController:self.MyProfileView animated:YES];
            
            [[UiNavRouter NavRouter].AppMainNavigationView setNavigationBarHidden:NO animated:YES];
        } 
    };
    
    [self ShowPageProcess];
    
    [[AppManager app].UserSession GetMyProfile:Callback];
    
    
    
}

- (void) ShowPreferenceSipAccountsView
{
    [UiLogger WriteLogInfo:@"NavRouter: Show preference sip accounts view"];
    
    if(!self.PreferenceSipAccountsView)
    {
        UIStoryboard *sb = [UIStoryboard storyboardWithName:@"UiPreferencesTabPageView" bundle:nil];
        self.PreferenceSipAccountsView = (UiPreferenceSipAccountsView *)[sb instantiateViewControllerWithIdentifier:@"UiPreferenceSipAccountsView"];
    }
    
    
    
    [self.CurrentView presentViewController:self.PreferenceSipAccountsView animated:YES completion:^{}];
    
}

- (void) HidePreferenceSipAccountsView
{
    [UiLogger WriteLogInfo:@"NavRouter: Hide preference sip accounts view"];
    
    if(self.CurrentView && self.CurrentView.presentedViewController)
        [self.CurrentView dismissViewControllerAnimated:TRUE completion:nil];
    
}

- (void) ShowPreferenceVideoSetsView
{
    
    [UiLogger WriteLogInfo:@"NavRouter: Show preference video sets view"];
    
    if(!self.PreferenceVideoSetsView)
    {
        UIStoryboard *sb = [UIStoryboard storyboardWithName:@"UiPreferencesTabPageView" bundle:nil];
        self.PreferenceVideoSetsView = (UiPreferenceVideoSetsView *)[sb instantiateViewControllerWithIdentifier:@"UiPreferenceVideoSetsView"];
    }
    
    
    
    [self.CurrentView presentViewController:self.PreferenceVideoSetsView animated:YES completion:^{}];
    
}

- (void) HidePreferenceVideoSetsView
{
    [UiLogger WriteLogInfo:@"NavRouter: Hide preference video sets view"];
    
    if(self.CurrentView && self.CurrentView.presentedViewController)
        [self.CurrentView dismissViewControllerAnimated:TRUE completion:nil];
    
}

- (void) ShowPreferenceServerAreaSelectView
{
    
    [UiLogger WriteLogInfo:@"NavRouter: Show preference server area select view"];
    
    if(!self.PreferenceServerAreaSelectView)
    {
        UIStoryboard *sb = [UIStoryboard storyboardWithName:@"UiPreferencesTabPageView" bundle:nil];
        self.PreferenceServerAreaSelectView = (UiPreferenceServerAreaSelectView *)[sb instantiateViewControllerWithIdentifier:@"UiPreferenceServerAreaSelectView"];
    }
    
    
    
    [self.CurrentView presentViewController:self.PreferenceServerAreaSelectView animated:YES completion:^{}];
    
}

- (void) HidePreferenceServerAreaSelectView
{
    [UiLogger WriteLogInfo:@"NavRouter: Hide preference server area select view"];
    
    if(self.CurrentView && self.CurrentView.presentedViewController)
        [self.CurrentView dismissViewControllerAnimated:TRUE completion:nil];
    
}

- (void) ShowPreferenceVoipEncryptionSelectView
{
    
    [UiLogger WriteLogInfo:@"NavRouter: Show preference voip encryption select view"];
    
    if(!self.PreferenceVoipEncryptionSelectView)
    {
        UIStoryboard *sb = [UIStoryboard storyboardWithName:@"UiPreferencesTabPageView" bundle:nil];
        self.PreferenceVoipEncryptionSelectView = (UiPreferenceVoipEncryptionSelectView *)[sb instantiateViewControllerWithIdentifier:@"UiPreferenceVoipEncryptionSelectView"];
    }
    
    
    
    [self.CurrentView presentViewController:self.PreferenceVoipEncryptionSelectView animated:YES completion:^{}];
    
}

- (void) HidePreferenceVoipEncryptionSelectView
{
    
    [UiLogger WriteLogInfo:@"NavRouter: Hide preference voip encryption select view"];
    
    if(self.CurrentView && self.CurrentView.presentedViewController)
        [self.CurrentView dismissViewControllerAnimated:TRUE completion:nil];
    
}

- (void) ShowPreferenceEchoCancellationSelectView
{
    
    [UiLogger WriteLogInfo:@"NavRouter: Show preference echo cancellation select view"];
    
    if(!self.PreferenceEchoCancellationSelectView)
    {
        UIStoryboard *sb = [UIStoryboard storyboardWithName:@"UiPreferencesTabPageView" bundle:nil];
        self.PreferenceEchoCancellationSelectView = (UiPreferenceEchoCancellationSelectView *)[sb instantiateViewControllerWithIdentifier:@"UiPreferenceEchoCancellationSelectView"];
    }
    
    
    
    [self.CurrentView presentViewController:self.PreferenceEchoCancellationSelectView animated:YES completion:^{}];
    
}

- (void) HidePreferenceEchoCancellationSelectView
{
    
    [UiLogger WriteLogInfo:@"NavRouter: Hide preference echo cancellation select view"];
    
    if(self.CurrentView && self.CurrentView.presentedViewController)
        [self.CurrentView dismissViewControllerAnimated:TRUE completion:nil];
    
}

- (void) ShowPreferenceUiStyleSelectView
{
    
    [UiLogger WriteLogInfo:@"NavRouter: Show preference Ui style select view"];
    
    if(!self.PreferenceUiStyleSelectView)
    {
        UIStoryboard *sb = [UIStoryboard storyboardWithName:@"UiPreferencesTabPageView" bundle:nil];
        self.PreferenceUiStyleSelectView = (UiPreferenceUiStyleSelectView *)[sb instantiateViewControllerWithIdentifier:@"UiPreferenceUiStyleSelectView"];
    }

    [self.CurrentView presentViewController:self.PreferenceUiStyleSelectView animated:YES completion:^{}];
    
}

- (void) HidePreferenceUiStyleSelectView
{
    [UiLogger WriteLogInfo:@"NavRouter: Hide preference Ui style select view"];
    
    if(self.CurrentView && self.CurrentView.presentedViewController)
        [self.CurrentView dismissViewControllerAnimated:TRUE completion:nil];
    
}

- (void) ShowPreferenceWebView:(NSString *) Url withTitle:(NSString *) Title
{
    
    [UiLogger WriteLogInfo:@"NavRouter: Show preference web view with url"];
    
    if(!self.PreferenceWebView)
    {
        UIStoryboard *sb = [UIStoryboard storyboardWithName:@"UiPreferencesTabPageView" bundle:nil];
        self.PreferenceWebView = (UiPreferenceWebView *)[sb instantiateViewControllerWithIdentifier:@"UiPreferenceWebView"];
    }
    
    [self.PreferenceWebView.ViewModel setTitleText:Title];
    
    
    [self.CurrentView presentViewController:self.PreferenceWebView animated:YES completion:^{
        [self.PreferenceWebView.ViewModel setUrl:Url];
    }];
    
}

- (void) ShowPreferenceWebViewWithHtmlData:(NSString *) DataHtml withTitle:(NSString *) Title
{
    
    [UiLogger WriteLogInfo:@"NavRouter: Show preference web view with html data"];
    
    if(!self.PreferenceWebView)
    {
        UIStoryboard *sb = [UIStoryboard storyboardWithName:@"UiPreferencesTabPageView" bundle:nil];
        self.PreferenceWebView = (UiPreferenceWebView *)[sb instantiateViewControllerWithIdentifier:@"UiPreferenceWebView"];
    }
    
    [self.PreferenceWebView.ViewModel setTitleText:Title];
    
    [self.CurrentView presentViewController:self.PreferenceWebView animated:YES completion:^{
        [self.PreferenceWebView.ViewModel setDataHtml:DataHtml];
    }];
}

- (void) HidePreferenceWebView
{
    
    [UiLogger WriteLogInfo:@"NavRouter: Hide preference web view"];
    
    if(self.CurrentView && self.CurrentView.presentedViewController)
        [self.CurrentView dismissViewControllerAnimated:TRUE completion:nil];
        
    if(self.PreferenceWebView)
    {
        [self.PreferenceWebView.ViewModel setTitleText:@""];
        [self.PreferenceWebView.ViewModel setUrl:@""];
    }
    
}

- (void) ShowPreferenceCodecsView
{
    
    [UiLogger WriteLogInfo:@"NavRouter: Show preference codecs view"];
    
    if(!self.PreferenceCodecsView)
    {
        UIStoryboard *sb = [UIStoryboard storyboardWithName:@"UiPreferencesTabPageView" bundle:nil];
        self.PreferenceCodecsView = (UiPreferenceCodecsView *)[sb instantiateViewControllerWithIdentifier:@"UiPreferenceCodecsView"];
    }

    [self.CurrentView presentViewController:self.PreferenceCodecsView animated:YES completion:^{}];
    
}

- (void) HidePreferenceCodecsView
{
    [UiLogger WriteLogInfo:@"NavRouter: Hide preference codecs view"];
    
    if(self.CurrentView && self.CurrentView.presentedViewController)
        [self.CurrentView dismissViewControllerAnimated:TRUE completion:nil];
    
}

- (void) ShowPreferenceIssueTicketView
{
    
    [UiLogger WriteLogInfo:@"NavRouter: Show preference issue ticket view"];
    
    if(!self.PreferenceIssueTicketView)
    {
        UIStoryboard *sb = [UIStoryboard storyboardWithName:@"UiPreferencesTabPageView" bundle:nil];
        self.PreferenceIssueTicketView = (UiPreferenceIssueTicketView *)[sb instantiateViewControllerWithIdentifier:@"UiPreferenceIssueTicketView"];
    }

    [self.CurrentView presentViewController:self.PreferenceIssueTicketView animated:YES completion:^{}];
    
}

- (void) HidePreferenceIssueTicketView
{
    [UiLogger WriteLogInfo:@"NavRouter: Hide preference issue ticket view"];
    
    if(self.CurrentView && self.CurrentView.presentedViewController)
        [self.CurrentView dismissViewControllerAnimated:TRUE completion:nil];
    
}

- (void) OpenUrlInExternalBrowser:(NSString *) Url
{
    
    [UiLogger WriteLogInfo:[ NSString stringWithFormat:@"NavRouter: Show external url %@", Url]];
    
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:Url]];
    
}

//- (void) OpenAppLeftMenu
//{
//    
//    [self.AppMainSlideNavigationView openMenu:MenuLeft withCompletion:nil];
//    
//}
//
//- (void) OpenAppLeftMenuWithCompletion:(void (^)())Callback
//{
//    
//    [self.AppMainSlideNavigationView openMenu:MenuLeft withCompletion:Callback];
//    
//}
//
//- (void) HideAppLeftMenu
//{
//    
//    [self.AppMainSlideNavigationView closeMenuWithCompletion:nil];
//    
//}
//
//- (void) HideAppLeftMenuWithCompletion:(void (^)())Callback
//{
//    
//    [self.AppMainSlideNavigationView closeMenuWithCompletion:Callback];
//    
//}

+ (void) ShowComingSoon
{
    
    [UiLogger WriteLogInfo: @"NavRouter: Show coming soon"];
    
    UiAlertControllerView* Alert = [UiAlertControllerView alertControllerWithTitle:nil
                                                                           message:nil
                                                                    preferredStyle:UIAlertControllerStyleAlert];

    
    Alert.title = @"Coming soon...";
    
    UIAlertAction* OkAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault
                                                     handler:^(UIAlertAction * action) {
                                                         
                                                     }];
    
    [Alert addAction:OkAction];
    
    [[UiNavRouter NavRouter].AppMainNavigationView presentViewController:Alert animated:YES completion:nil];
}

+ (void) ShowUnknownError
{
    
    [UiLogger WriteLogInfo: @"NavRouter: Show unknown error"];
    
    UiAlertControllerView* Alert = [UiAlertControllerView alertControllerWithTitle:nil
                                                                           message:nil
                                                                    preferredStyle:UIAlertControllerStyleAlert];
    
    
    Alert.title = NSLocalizedString(@"Title_UnknownError", nil);
    
    UIAlertAction* OkAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault
                                                     handler:^(UIAlertAction * action) {
                                                         
                                                     }];
    
    [Alert addAction:OkAction];
    
    [[UiNavRouter NavRouter].AppMainNavigationView presentViewController:Alert animated:YES completion:nil];
}

- (void) ShowVersionAlertWithAction:(void (^)())Action {
    [UiLogger WriteLogInfo:@"NavRouter: Show version alert"];
    
    UiAlertControllerView* Alert = [UiAlertControllerView alertControllerWithTitle:nil
                                                                           message:NSLocalizedString(@"Update_alert", nil)
                                                                    preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction* OkAction = [UIAlertAction actionWithTitle:@"Ok" style:UIAlertActionStyleDefault
                                                     handler:^(UIAlertAction * _Nonnull action) {
                                                         self.UpdateAlertView = nil;
                                                         Action();
                                                     }];
    
    [Alert addAction:OkAction];
    
    
    if([UiNavRouter NavRouter].AppMainNavigationView) {
        [[UiNavRouter NavRouter].AppMainNavigationView presentViewController:Alert animated:YES completion:nil];
        self.UpdateAlertView = Alert;
    }
    else if([UiNavRouter NavRouter].AppLoginPageView){
        [[UiNavRouter NavRouter].AppLoginPageView presentViewController:Alert animated:YES completion:nil];
        self.UpdateAlertView = Alert;
    }
    
    
}

- (void) ShowRosterView
{
    [UiLogger WriteLogInfo:@"NavRouter: Show roster view"];
    
    [self ShowContactsTabPage];
    
    @weakify(self);
    
    [[[RACObserve(self, ContactsTabPageContactsListView) ignore:nil] take:1] subscribeNext:^(id x) {
        
        @strongify(self);
        
        [self.ContactsTabPageContactsListView performSegueWithIdentifier:UiContactsTabNavRouterSegueShowContactsRoster sender:nil];
        
    }];
    
    /*
    if(!self.RosterView)
    {
        UIStoryboard *sb = [UIStoryboard storyboardWithName:@"UiContactsTabPage" bundle:nil];
        self.RosterView = (UiContactsRosterView *)[sb instantiateViewControllerWithIdentifier:@"UiContactsRosterView"];
    }
    
    [self.RosterView setCallbackOnBackAction:^{
        
        [CATransaction begin];
        [CATransaction setCompletionBlock:^{
            
            dispatch_async(dispatch_get_main_queue(), ^{
                
                [UiNavRouter NavRouter].RosterView = nil;
                
            });
            
        }];
        
        [[UiNavRouter NavRouter].AppMainNavigationView popToRootViewControllerAnimated:YES];
        
        [[UiNavRouter NavRouter].AppMainNavigationView setNavigationBarHidden:YES animated:YES];
        
        
        [CATransaction commit];
        
    }];
    
    
    [self.AppMainNavigationView pushViewController:self.RosterView animated:YES];
    
    [[UiNavRouter NavRouter].AppMainNavigationView setNavigationBarHidden:NO animated:YES];
     */
     
}

- (void) ShowProfileView:(ObjC_ContactModel *) Profile
{
    if(!self.ProfileView)
    {
        UIStoryboard *sb = [UIStoryboard storyboardWithName:@"UiContactsTabPage" bundle:nil];
        self.ProfileView = (UiContactProfileView *)[sb instantiateViewControllerWithIdentifier:@"UiContactProfileView"];
    }
    
    [UiLogger WriteLogInfo:@"NavRouter: Show profile view"];
    
    [UiLogger WriteLogDebug:[NSString stringWithFormat:@"NavRouter: %@", [CoreHelper ContactModelDescription:(ObjC_ContactModel *) Profile]]];
    
    [self.ProfileView.ViewModel setContactData:(ObjC_ContactModel *) Profile];
    
    [self.ProfileView setCallbackOnBackAction:^{
        
        [CATransaction begin];
        [CATransaction setCompletionBlock:^{
            
            dispatch_async(dispatch_get_main_queue(), ^{
                
                [UiNavRouter NavRouter].ProfileView = nil;
                
            });
            
        }];
        
        [[UiNavRouter NavRouter].AppMainNavigationView popToRootViewControllerAnimated:YES];
        
        [[UiNavRouter NavRouter].AppMainNavigationView setNavigationBarHidden:YES animated:YES];
        
        
        [CATransaction commit];
        
    }];
    
    
    [self.AppMainNavigationView pushViewController:self.ProfileView animated:YES];
    
    [[UiNavRouter NavRouter].AppMainNavigationView setNavigationBarHidden:NO animated:YES];
    
}

- (void) ShowOrWaitInviteWithXmppId:(NSString *) XmppId WithAutoAccept:(BOOL) AutoAccept
{
    if(XmppId && XmppId.length)
    {
        @weakify(self);
        
        void (^Callback)(BOOL,  ObjC_ContactModel *) = ^(BOOL Accept, ObjC_ContactModel *Invite){
            
            @strongify(self);
            
            if(Accept)
            {
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
                    
                    ObjC_ContactModel *ResultContact = [[AppManager app].Core SaveContact:Invite];
                    
                    dispatch_async(dispatch_get_main_queue(), ^{
                        
                        if(ResultContact)
                            [self ShowProfileView:ResultContact];
                        else
                            [self ShowProfileView:Invite];
                        
                        
                    });
                    
                });
            }
            else
            {
                [self ShowProfileView:Invite];
            }
            
        };
        
        
        if([[ContactsManager Manager].ContactInvites objectForKey:XmppId])
        {
            ObjC_ContactModel *Invite = [[ContactsManager Manager].ContactInvites objectForKey:XmppId];
            
            Callback(AutoAccept, Invite);
        }
        
        else
        {
            [[[[[[RACObserve([ContactsManager Manager], InviteUpdate) timeout:15 onScheduler:[RACScheduler schedulerWithPriority:RACSchedulerPriorityHigh]] ignore:nil] filter:^BOOL(InviteUpdateSignalObject *Signal) {
            
                if(Signal.State == ContactUpdatingStateUpdated)
                {
                    if([[ContactsManager GetXmppIdOfContact:Signal.Contact] isEqualToString:XmppId])
                    {
                        return YES;
                    }
                }
                
                return NO;
            
            }] take:1] deliverOnMainThread] subscribeNext:^(InviteUpdateSignalObject *Signal) {
                
                Callback(AutoAccept, Signal.Contact);
                
            }];
        }
        
    }
}


- (void) ShowOrWaitInviteWithXmppId:(NSString *) XmppId
{
    [self ShowOrWaitInviteWithXmppId:XmppId WithAutoAccept:NO];
}

- (BOOL) IsCurrentViewLogin
{
    return (self.CurrentView && (self.CurrentView == self.AppLoginPageView));
}

- (void) PreloadAllTabs
{
    [[self.AppTabs.viewControllers objectAtIndex:3] view];
    [[self.AppTabs.viewControllers objectAtIndex:1] view];
    [[self.AppTabs.viewControllers objectAtIndex:2] view];
    [[self.AppTabs.viewControllers objectAtIndex:4] view];
}

@end
