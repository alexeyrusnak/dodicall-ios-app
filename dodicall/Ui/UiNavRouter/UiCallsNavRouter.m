//
//  UiCallNavRouter.m
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

#import "UiCallsNavRouter.h"


#import "UiLogger.h"
#import "UiNavRouter.h"
#import "UiAlertControllerView.h"

#import "UiCurrentCallView.h"
#import "UiIncomingCallView.h"
#import "UiOutgoingCallView.h"
#import "UiCallTransferTabPageView.h"

#import "CallsManager.h"

#import "AudioManager.h"

#import "UiCurrentConferenceView.h"
#import "UiInCallStatusBar.h"

@import MediaPlayer;

static UiCallsNavRouter* CallsNavRouterSingleton = nil;

@implementation UiCallsNavRouter

/*
- (instancetype)init {
    if(self = [super init])
        _NavRouter = self;
    
    return self;
}
 */

+ (instancetype) Router
{
    return [self NavRouter];
}

+ (instancetype) NavRouter
{
    
    static dispatch_once_t CallsNavRouterSingletonToken;
    
    dispatch_once(&CallsNavRouterSingletonToken, ^{
        
        CallsNavRouterSingleton = [[UiCallsNavRouter alloc] init];
        
    });
    
    return CallsNavRouterSingleton;
}

- (UiCallViewAnimator *)Animator
{
    if(!_Animator)
        _Animator = [UiCallViewAnimator new];
    
    return _Animator;
}

- (UiCallNavigationController *)NavigationView {
    if(!_NavigationView) {
        
        UiCallNavigationController *callsNav = [UiCallNavigationController new];
        [callsNav setNavigationBarHidden:YES];
        callsNav.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
        
        [callsNav setDelegate:[[UiCallsNavRouter NavRouter]Animator]];
        
        _NavigationView = callsNav;
        
        UiAlertControllerView *UpdateAlert = [UiNavRouter NavRouter].UpdateAlertView;
        
        if(UpdateAlert) {
            [[[UiNavRouter NavRouter] AppMainNavigationView] dismissViewControllerAnimated:YES completion:nil];
            [UiNavRouter NavRouter].UpdateAlertView = nil;
        }
        
        [[[UiNavRouter NavRouter] AppMainNavigationView] presentViewController:callsNav animated:YES completion:nil];
    
    }
    return _NavigationView;
}

+(void)CreateAndShowCurrentCallViewWithCall:(ObjC_CallModel *)callModel {
    
    [UiLogger WriteLogInfo: @"CallsNavRouter: Show Current Call"];
    
    [[AudioManager Manager] StopVibration];
    
    UIStoryboard *sb = [UIStoryboard storyboardWithName:@"UiCallView" bundle:nil];
    UiCurrentCallView *currentCallView = [sb instantiateViewControllerWithIdentifier:@"UiCurrentCallView"];
    currentCallView.ViewModel.CallModel = callModel;
    
    
    [UiCallsNavRouter NavRouter].CurrentCallView = (UIViewController *)currentCallView;
    [[[UiCallsNavRouter NavRouter] NavigationView] setViewControllers:@[currentCallView] animated:YES];
}

+(void)CreateAndShowIncomingCallViewWithCall:(ObjC_CallModel *)callModel {
    [UiLogger WriteLogInfo: @"CallsNavRouter: Show Incoming Call"];
    
    [[AudioManager Manager] StartVibration];
    
    UIStoryboard *sb = [UIStoryboard storyboardWithName:@"UiCallView" bundle:nil];
    UiIncomingCallView *incomingCallView = [sb instantiateViewControllerWithIdentifier:@"UiIncomingCallView"];
    incomingCallView.ViewModel.CallModel = callModel;
    
    [UiCallsNavRouter NavRouter].CurrentCallView = (UIViewController *)incomingCallView;
    [[[UiCallsNavRouter NavRouter] NavigationView] pushViewController:incomingCallView animated:NO];
    [UiCallsNavRouter NavRouter].IsCallViewVisible = @(YES);
}
+ (void) CreateAndShowCurrentConferenceCall:(ConferenceModel *)ConferenceModel {
    [UiLogger WriteLogInfo: @"CallsNavRouter: Show Active Conference Call"];
    
    UIStoryboard *Sb = [UIStoryboard storyboardWithName:@"UiCallView" bundle:nil];
    
    UiCurrentConferenceView *ActiveConferenceCall = [Sb instantiateViewControllerWithIdentifier:@"UiCurrentConferenceView"];
    ActiveConferenceCall.ViewModel.ConferenceModel = ConferenceModel;
    
    [UiCallsNavRouter NavRouter].CurrentCallView = (UIViewController *)ActiveConferenceCall;
    [[[UiCallsNavRouter NavRouter] NavigationView] pushViewController:ActiveConferenceCall animated:NO];
}


+(void)ShowComingSoon {
    [UiLogger WriteLogInfo: @"CallsNavRouter: Show coming soon"];
    
    UiAlertControllerView* Alert = [UiAlertControllerView alertControllerWithTitle:nil
                                                                           message:nil
                                                                    preferredStyle:UIAlertControllerStyleAlert];
    
    
    Alert.title = @"Coming soon...";
    
    UIAlertAction* OkAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault
                                                     handler:^(UIAlertAction * action) {
                                                         
                                                     }];
    
    [Alert addAction:OkAction];
    
    [[[UiCallsNavRouter NavRouter] NavigationView ] presentViewController:Alert animated:YES completion:nil];
}

+ (void) ShowMicrophoneDisabledInfo
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [UiLogger WriteLogInfo: @"NavRouter: Show microphone disabled info"];
    
        UiAlertControllerView* Alert = [UiAlertControllerView alertControllerWithTitle:nil
                                                                               message:NSLocalizedString(@"Message_MicrophoneAccessDeniedInSettings", nil)
                                                                        preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction* OkAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel
                                                         handler:^(UIAlertAction * action) {
                                                             
                                                         }];
        
        [Alert addAction:OkAction];
        
        UIAlertAction* GoToSettingsAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Title_Settings", nil) style:UIAlertActionStyleDefault
                                                                   handler:^(UIAlertAction * action) {
                                                                       
                                                                       [[CallsManager Manager] HangupCurrentActiveCall];
                                                                       
                                                                       
                                                                       double delayInSeconds = 1.0;
                                                                       dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
                                                                       dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
                                                                           
                                                                           [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]];
                                                                           
                                                                       });
                                                                       
                                                                   }];
        
        [Alert addAction:GoToSettingsAction];
        
        [[[UiCallsNavRouter NavRouter] NavigationView ] presentViewController:Alert animated:YES completion:nil];
    });
    
}

+(void)CloseCurrentCallView {
    
    [UiLogger WriteLogInfo: @"CallsNavRouter: Close Call View"];
    
    [[AudioManager Manager] StopVibration];
    
    if([[[UiCallsNavRouter NavRouter] IsCallViewVisible] boolValue])
    {
        [[[UiNavRouter NavRouter] AppMainNavigationView] dismissViewControllerAnimated:YES completion:nil];
       // [[[UiNavRouter NavRouter] AppMainNavigationView] setNeedsStatusBarAppearanceUpdate];
    }
    
    [[UiCallsNavRouter NavRouter] setNavigationView:nil];
    [[UiCallsNavRouter NavRouter] setAnimator:nil];
    [[UiCallsNavRouter NavRouter] setCurrentCallView:nil];
    [UiCallsNavRouter NavRouter].IsCallViewVisible = @(NO);
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
        [[AppManager Manager].UserSession CheckUpdate];
    });
}

+(void)CreateAndShowOutgoingCallViewWithCall:(ObjC_CallModel *)callModel {
    
    [UiLogger WriteLogInfo: @"CallsNavRouter: Show Outgoing Call"];
    
    UIStoryboard *sb = [UIStoryboard storyboardWithName:@"UiCallView" bundle:nil];
    UiOutgoingCallView *outgoingCallView = [sb instantiateViewControllerWithIdentifier:@"UiOutgoingCallView"];
    outgoingCallView.ViewModel.CallModel = callModel;
    
    [UiCallsNavRouter NavRouter].CurrentCallView = (UIViewController *)outgoingCallView;
    [[[UiCallsNavRouter NavRouter] NavigationView] pushViewController:outgoingCallView animated:NO];
    
    [UiCallsNavRouter NavRouter].IsCallViewVisible = @(YES);
    
}
+ (void) UpdateCurrentCallViewWithCall:(ObjC_CallModel *)callModel {
    UIViewController *currentView = [UiCallsNavRouter NavRouter].CurrentCallView;
    if([currentView isKindOfClass:[UiCurrentCallView class]]) {
        ((UiCurrentCallView *)currentView).ViewModel.CallModel = callModel;
    }
    else if([currentView isKindOfClass:[UiIncomingCallView class]]){
        ((UiIncomingCallView *)currentView).ViewModel.CallModel = callModel;
    }
    else if([currentView isKindOfClass:[UiOutgoingCallView class]]) {
        ((UiOutgoingCallView *)currentView).ViewModel.CallModel = callModel;
    }
}
+ (void) HideCallView {
    if(![[UiCallsNavRouter NavRouter].IsCallViewVisible boolValue])
        return;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [[[UiNavRouter NavRouter] AppMainNavigationView] dismissViewControllerAnimated:YES completion:nil];
        [UiCallsNavRouter NavRouter].IsCallViewVisible = @(NO);
    });
}

+ (void) ShowCallView {
    
    if([[UiCallsNavRouter NavRouter].IsCallViewVisible boolValue])
        return;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [[[UiNavRouter NavRouter] AppMainNavigationView] presentViewController:[[UiCallsNavRouter NavRouter] NavigationView] animated:YES completion:nil];
        [UiCallsNavRouter NavRouter].IsCallViewVisible = @(YES);
    });
    
}

// HACK! Do not remove!
+ (void) SetupMPVolumeView
{
    MPVolumeView *volumeView = [ [MPVolumeView alloc] initWithFrame:CGRectMake(100,100,100,100)] ;
}


#pragma mark CallTransfer

+ (void) CreateAndShowCallTransferTabPageView
{
    [UiLogger WriteLogInfo: @"CallsNavRouter: Show CallTransferTabPageView"];
    UIStoryboard *sb = [UIStoryboard storyboardWithName:@"UiCallView" bundle:nil];
    [UiCallsNavRouter NavRouter].CallTransferTabPageView = [sb instantiateViewControllerWithIdentifier:@"UiCallTransferTabPageView"];
    
    [[[UiCallsNavRouter NavRouter] NavigationView] presentViewController:[UiCallsNavRouter NavRouter].CallTransferTabPageView animated:YES completion:^{
        [[[CallsManager Manager] InCallStatusBar] ShowInView:[[UiCallsNavRouter NavRouter].CallTransferTabPageView view] WithTapCallback:^{
            [UiCallsNavRouter CloseCallTransferTabPageView];
        }];
        [[[CallsManager Manager] InCallStatusBar] SetShouldChangeStatusBarColorBack:NO];
    }];
}

+ (void) CloseCallTransferTabPageView
{
    [[[CallsManager Manager] InCallStatusBar] HideAnimated:YES WithCompletion:^{
        [[UiCallsNavRouter NavRouter].CallTransferTabPageView dismissViewControllerAnimated:YES completion:nil];
        [UiCallsNavRouter NavRouter].CallTransferTabPageView = nil;
    }];
}

+ (void) ShowCallStartError {
    [UiLogger WriteLogInfo: @"CallsNavRouter: Show call start error"];
    
    UiAlertControllerView* Alert = [UiAlertControllerView alertControllerWithTitle:nil
                                                                           message:nil
                                                                    preferredStyle:UIAlertControllerStyleAlert];
    
    
    Alert.title = @"В данный момент разговор по второй линии не поддерживается. Завершите текущий разговор и повторите попытку.";
    
    UIAlertAction* OkAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault
                                                     handler:^(UIAlertAction * action) {
                                                         
                                                     }];
    
    [Alert addAction:OkAction];
    
    [[[UiNavRouter NavRouter] AppMainNavigationView ] presentViewController:Alert animated:YES completion:nil];
    
}

/*
+ (void) ShowAudioSourceMenuForOptions:(NSArray *)Options AndCallback:(void (^)(NSUInteger))Callback {
    
    [UiLogger WriteLogInfo: @"CallsNavRouter: Show audio source"];
//    
//    UiAlertControllerView *audioMenu = [UiAlertControllerView alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
//    
//    for (NSString *audioName in Options) {
//        UIAlertAction* option = [UIAlertAction actionWithTitle:audioName style:UIAlertActionStyleDefault
//                                                         handler:^(UIAlertAction * action) {
//                                                             Callback([Options indexOfObject:audioName]);
//                                                         }];
//        [audioMenu addAction:option];
//    }
//    
//    [[[UiCallsNavRouter NavRouter] NavigationView ] presentViewController:audioMenu animated:YES completion:nil];
    
    
    
    
    //[volumeView setShowsVolumeSlider:NO];
    //[volumeView setShowsRouteButton:NO];
    
    
    //[volumeView sizeToFit];
    
    
    //[volumeView sh]
    
    //[view addSubview:volumeView];
    
    
//    [[UiCallsNavRouter NavRouter] NavigationView].view.backgroundColor = [UIColor clearColor];
    //MPVolumeView *myVolumeView = [ [MPVolumeView alloc] init];
    //[[MPVolumeView alloc] initWithFrame: [[UiCallsNavRouter NavRouter] NavigationView].view.bounds];
    //[[[UiCallsNavRouter NavRouter] NavigationView].visibleViewController.view addSubview: volumeView];
//
    
    
    //MPVolumeSettingsAlertShow();
   
}
 */
@end
