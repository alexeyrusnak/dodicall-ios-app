//
//  UiPreferencesTabNavRouter.m
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

#import "UiPreferencesTabNavRouter.h"
#import "UiLogger.h"
#import "UiPreferenceWebView.h"

#import "UiContactProfileView.h"
#import <ObjC_ContactModel.h>

static UINavigationController *SourceNavController;

static BOOL WasNavbarHiddenInSourceNavController;

@implementation UiPreferencesTabNavRouter

+ (void) Reset
{
    SourceNavController = nil;
}

+ (void)PrepareForSegue:(UIStoryboardSegue *)Segue sender:(id)Sender
{
    
    if ([[Segue identifier] isEqualToString:UiPreferencesTabNavRouterSeguesShowPreferenceLanguageSelectView])
    {
        [UiLogger WriteLogInfo:@"UiPreferencesTabNavRouter: Show preference language select view"];
        
        SourceNavController = [Segue sourceViewController].navigationController;
        
        WasNavbarHiddenInSourceNavController = SourceNavController.isNavigationBarHidden;
        
        [SourceNavController setNavigationBarHidden:NO animated:NO];
        
    }
    
    if ([[Segue identifier] isEqualToString:UiPreferencesTabNavRouterSeguesShowPreferenceServerAreaSelectView])
    {
        [UiLogger WriteLogInfo:@"UiPreferencesTabNavRouter: Show preference server area select view"];
        
        SourceNavController = [Segue sourceViewController].navigationController;
        
        WasNavbarHiddenInSourceNavController = SourceNavController.isNavigationBarHidden;
        
        [SourceNavController setNavigationBarHidden:NO animated:NO];
        
    }
    
    if ([[Segue identifier] isEqualToString:UiPreferencesTabNavRouterSeguesShowPreferenceStatusSetView])
    {
        [UiLogger WriteLogInfo:@"UiPreferencesTabNavRouter: Show preference status set view"];
        
        SourceNavController = [Segue sourceViewController].navigationController;
        
        WasNavbarHiddenInSourceNavController = SourceNavController.isNavigationBarHidden;
        
        [SourceNavController setNavigationBarHidden:NO animated:NO];
        
    }
    
    if ([[Segue identifier] isEqualToString:UiPreferencesTabNavRouterSeguesShowSipAccountsView])
    {
        [UiLogger WriteLogInfo:@"UiPreferencesTabNavRouter: Show preference sip accounts view"];
        
        SourceNavController = [Segue sourceViewController].navigationController;
        
    }
    
    if ([[Segue identifier] isEqualToString:UiPreferencesTabNavRouterSeguesShowVideoSetsView])
    {
        [UiLogger WriteLogInfo:@"UiPreferencesTabNavRouter: Show preference video sets view"];
        
        SourceNavController = [Segue sourceViewController].navigationController;
        
    } 
    
    if ([[Segue identifier] isEqualToString:UiPreferencesTabNavRouterSeguesShowVoipEncryptionSelectView])
    {
        [UiLogger WriteLogInfo:@"UiPreferencesTabNavRouter: Show preference voip encryption select view"];
        
        SourceNavController = [Segue sourceViewController].navigationController;
        
    }     
    
    if ([[Segue identifier] isEqualToString:UiPreferencesTabNavRouterSeguesShowEchoCancellationSelectView])
    {
        [UiLogger WriteLogInfo:@"UiPreferencesTabNavRouter: Show preference echo cancelation select view"];
        
        SourceNavController = [Segue sourceViewController].navigationController;
        
    } 
    
    if ([[Segue identifier] isEqualToString:UiPreferencesTabNavRouterSeguesShowStyleSelectView])
    {
        [UiLogger WriteLogInfo:@"UiPreferencesTabNavRouter: Show preference style select view"];
        
        SourceNavController = [Segue sourceViewController].navigationController;
        
    } 
    
    if ([[Segue identifier] isEqualToString:UiPreferencesTabNavRouterCodecsView])
    {
        [UiLogger WriteLogInfo:@"UiPreferencesTabNavRouter: Show preference codecs view"];
        
        SourceNavController = [Segue sourceViewController].navigationController;
        
    }
    
    if ([[Segue identifier] isEqualToString:UiPreferencesTabNavRouterTicketView])
    {
        [UiLogger WriteLogInfo:@"UiPreferencesTabNavRouter: Show preference ticket view"];
        
        SourceNavController = [Segue sourceViewController].navigationController;
        
    }
    
    if ([[Segue identifier] isEqualToString:UiPreferencesTabNavRouterWebView])
    {
        
        if([(NSDictionary *) Sender objectForKey:@"Url"])
        {
            [self PrepareForWebViewSegue:Segue sender:Sender withUrl:[(NSDictionary *) Sender objectForKey:@"Url"] withTitle:[(NSDictionary *) Sender objectForKey:@"Title"]];
        }
        
        if([(NSDictionary *) Sender objectForKey:@"DataHtml"])
        {
            [self PrepareForWebViewSegue:Segue sender:Sender withDataHtml:[(NSDictionary *) Sender objectForKey:@"DataHtml"] withTitle:[(NSDictionary *) Sender objectForKey:@"Title"]];
        }
    }
    
    if ([[Segue identifier] isEqualToString:UiPreferencesTabNavRouterMyProfile])
    {
        
        [UiLogger WriteLogInfo:@"UiPreferencesTabNavRouter: Show preference my profile"];
        
        SourceNavController = [Segue sourceViewController].navigationController;
        
        UiContactProfileView *ContactProfileView = (UiContactProfileView *)[[Segue destinationViewController] topViewController];
        
        [ContactProfileView setCallbackOnBackAction:^{
            
            [self CloseProfileViewWhenBackAction];
            
        }];
        
        if((ObjC_ContactModel *) Sender)
        {
            [UiLogger WriteLogDebug:[NSString stringWithFormat:@"UiPreferencesTabNavRouter: %@", [CoreHelper ContactModelDescription:(ObjC_ContactModel *) Sender]]];
            
            [ContactProfileView.ViewModel setContactData:(ObjC_ContactModel *) Sender];
        }
        
        
    }
    
    
}

+ (void)PrepareForWebViewSegue:(UIStoryboardSegue *)Segue sender:(id)Sender withUrl:(NSString *) Url withTitle:(NSString *) Title
{
    [UiLogger WriteLogInfo:@"UiPreferencesTabNavRouter: Show preference web view with url"];
    
    SourceNavController = [Segue sourceViewController].navigationController;
    
    UiPreferenceWebView *PreferenceWebView = (UiPreferenceWebView *)[(UINavigationController *)[Segue destinationViewController] topViewController];
    
    [PreferenceWebView.ViewModel setTitleText:Title];
    
    [PreferenceWebView.ViewModel setUrl:Url];
}

+ (void)PrepareForWebViewSegue:(UIStoryboardSegue *)Segue sender:(id)Sender withDataHtml:(NSString *) DataHtml withTitle:(NSString *) Title
{
    [UiLogger WriteLogInfo:@"UiPreferencesTabNavRouter: Show preference web view with html data"];
    
    SourceNavController = [Segue sourceViewController].navigationController;
    
    UiPreferenceWebView *PreferenceWebView = (UiPreferenceWebView *)[(UINavigationController *)[Segue destinationViewController] topViewController];
    
    [PreferenceWebView.ViewModel setTitleText:Title];
    
    [PreferenceWebView.ViewModel setDataHtml:DataHtml];
}


+ (void) ClosePreferenceLanguageSelectView
{
    [UiLogger WriteLogInfo:@"UiPreferencesTabNavRouter: Close preference language select view"];
    
    [SourceNavController popToRootViewControllerAnimated:YES];
    [SourceNavController setNavigationBarHidden:WasNavbarHiddenInSourceNavController animated:NO];
    
    SourceNavController = nil;
}

+ (void) ClosePreferenceServerAreaSelectView
{
    [UiLogger WriteLogInfo:@"UiPreferencesTabNavRouter: Close preference server area select view"];
    
    [SourceNavController popToRootViewControllerAnimated:YES];
    [SourceNavController setNavigationBarHidden:WasNavbarHiddenInSourceNavController animated:NO];
    
    SourceNavController = nil;
}

+ (void) ClosePreferenceStatusSetView
{
    [UiLogger WriteLogInfo:@"UiPreferencesTabNavRouter: Close preference status set view"];
    
    [SourceNavController popToRootViewControllerAnimated:YES];
    [SourceNavController setNavigationBarHidden:WasNavbarHiddenInSourceNavController animated:NO];
    
    SourceNavController = nil;
}

+ (void) ClosePreferenceSipAccountsView
{
    [UiLogger WriteLogInfo:@"UiPreferencesTabNavRouter: Close preference sip accounts view"];
    
    [SourceNavController popToRootViewControllerAnimated:YES];
    
    SourceNavController = nil;
}

+ (void) ClosePreferenceVideoSetsView
{
    [UiLogger WriteLogInfo:@"UiPreferencesTabNavRouter: Close preference video sets view"];
    
    [SourceNavController popToRootViewControllerAnimated:YES];
    
    SourceNavController = nil;
}

+ (void) ClosePreferenceVoipEncryptionSelectView
{
    [UiLogger WriteLogInfo:@"UiPreferencesTabNavRouter: Close preference voip encryption select view"];
    
    [SourceNavController popToRootViewControllerAnimated:YES];
    
    SourceNavController = nil;
}

+ (void) ClosePreferenceEchoCancellationSelectView
{
    [UiLogger WriteLogInfo:@"UiPreferencesTabNavRouter: Close preference echo cancelation select view"];
    
    [SourceNavController popToRootViewControllerAnimated:YES];
    
    SourceNavController = nil;
}


+ (void) ClosePreferenceStyleView
{
    [UiLogger WriteLogInfo:@"UiPreferencesTabNavRouter: Close preference style select view"];
    
    [SourceNavController popToRootViewControllerAnimated:YES];
    
    SourceNavController = nil;
}

+ (void) ClosePreferenceCodecsView
{
    [UiLogger WriteLogInfo:@"UiPreferencesTabNavRouter: Close preference codecs view"];
    
    [SourceNavController popToRootViewControllerAnimated:YES];
    
    SourceNavController = nil;
}

+ (void) ClosePreferenceTicketView
{
    [UiLogger WriteLogInfo:@"UiPreferencesTabNavRouter: Close preference ticket view"];
    
    [SourceNavController popToRootViewControllerAnimated:YES];
    
    SourceNavController = nil;
}

+ (void) ClosePreferenceWebView
{
    [UiLogger WriteLogInfo:@"UiPreferencesTabNavRouter: Close preference web view"];
    
    [SourceNavController popToRootViewControllerAnimated:YES];
    
    SourceNavController = nil;
}

+ (void) CloseProfileViewWhenBackAction
{
    
    [UiLogger WriteLogInfo:@"UiPreferencesTabNavRouter: Contact profile view back action -> preferences"];
    
    [SourceNavController popToRootViewControllerAnimated:YES];
    
}

    


@end
