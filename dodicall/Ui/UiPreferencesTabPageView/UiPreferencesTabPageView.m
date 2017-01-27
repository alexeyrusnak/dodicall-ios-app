//
//  UiPreferencesTabPageView.m
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

#import "UiPreferencesTabPageView.h"
#import "UiPreferencesTabPagePreferencesListView.h"
#import <ReactiveCocoa/ReactiveCocoa.h>

#import "UiAlertControllerView.h"

#import "UiContactsTabNavRouter.h"

//#define EnableHiddenLogout

@interface UiPreferencesTabPageView ()

@property (weak, nonatomic) IBOutlet UILabel *AppVersionLabel;

@property (weak, nonatomic) IBOutlet UIButton *SettingsNavButton;

@property (weak, nonatomic) IBOutlet UIButton *BackButton;

@property NSNumber *SettingsNavButtonTouchCount;

@end

@implementation UiPreferencesTabPageView
{
    BOOL _IsAllBinded;
}

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        
        self.ViewModel =  [[UiPreferencesTabPageViewModel alloc] init];
        
        self.SettingsNavButtonTouchCount = [NSNumber numberWithInt:0];
        
        
    }
    return self;
}


- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self BindAll];
    
}

- (void)didReceiveMemoryWarning {
    
    [super didReceiveMemoryWarning];
    
}


- (void) BindAll
{
    if(_IsAllBinded)
        return;
    
    @weakify(self);
    
    RAC(self.AppVersionLabel, text) = RACObserve(self.ViewModel, AppVersionText);
    
#ifdef EnableHiddenLogout
    [[self.SettingsNavButton rac_signalForControlEvents:UIControlEventTouchUpInside] subscribeNext:^(id x)
    {
        
        @strongify(self);
        
        self.SettingsNavButtonTouchCount = [NSNumber numberWithInt:([self.SettingsNavButtonTouchCount intValue] + 1)];
        
        if([self.SettingsNavButtonTouchCount intValue] >= 10)
            [self ShowLogoutAlert];
            
        
    }];
#endif
    
    [[[[RACObserve(self, SettingsNavButtonTouchCount) ignore:nil] filter:^BOOL(NSNumber *Value) {
        if([Value intValue] > 0)
            return YES;
        else
            return NO;
    }] throttle:5] subscribeNext:^(id x) {
        
        @strongify(self);
        
        self.SettingsNavButtonTouchCount = [NSNumber numberWithInt:0];
        
    }];
    
    
    
    _IsAllBinded = TRUE;
}

- (BOOL)shouldPerformSegueWithIdentifier:(NSString *)Identifier sender:(id)Sender
{
    
//    if([Identifier isEqualToString:@"UiPreferencesTabPageContainerViewSegue"])
//    {
//
//        double delayInSeconds = 0.0;
//        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
//        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
//
//            [self performSegueWithIdentifier:Identifier sender:Sender];
//            
//            
//        });
//        
//        
//        return NO;
//    
//    }
    
    return YES;
}

- (void) ShowLogoutAlert
{
    self.SettingsNavButtonTouchCount = [NSNumber numberWithInt:0];
    
    UiAlertControllerView* alert = [UiAlertControllerView alertControllerWithTitle:nil
                                                                           message:NSLocalizedString(@"Question_DoYouWantToLogout", nil)
                                                                    preferredStyle:UIAlertControllerStyleActionSheet];
    
    UIAlertAction* LogoutAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Title_Logout", nil) style:UIAlertActionStyleDefault
                                                      handler:^(UIAlertAction * action) {
                                                          
                                                          [self.ViewModel Logout];
                                                          
                                                          
                                                      }];
    
    [alert addAction:LogoutAction];
    
    
    UIAlertAction* cancelAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Title_Cancel", nil) style:UIAlertActionStyleCancel
                                                         handler:^(UIAlertAction * action) {
                                                             
                                                             
                                                         }];
    
    [alert addAction:cancelAction];
    
    
    UIPopoverPresentationController *popPresenter = [alert popoverPresentationController];
    popPresenter.sourceView = self.view;
    popPresenter.sourceRect = self.view.bounds;
    
    [self presentViewController:alert animated:YES completion:nil];
    
    
}

- (IBAction)BackButtonAction:(id)sender
{
    [UiContactsTabNavRouter ClosePreferencesViewWhenBackAction];
}


@end
