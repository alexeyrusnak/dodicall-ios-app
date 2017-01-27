//
//  UiLoginView.m
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

#import "UiLoginPageView.h"
#import <ReactiveCocoa/ReactiveCocoa.h>
#import "UiLogger.h"
#import "UiPreferencesTabNavRouter.h"
//#import <Crashlytics/Crashlytics.h>
#import "AppManager.h"

#define UiLoginPageAreaSwitch

@interface UiLoginPageView ()

@property (weak, nonatomic) IBOutlet UITextField* LoginTextField;
@property (weak, nonatomic) IBOutlet UITextField* PasswordTextField;
@property (weak, nonatomic) IBOutlet UIButton* LoginButton;
@property (weak, nonatomic) IBOutlet UIButton* RegistrationButton;
@property (weak, nonatomic) IBOutlet UIButton* ForgotPasswordButton;
@property (weak, nonatomic) IBOutlet UILabel* AppVersionLabel;
@property (weak, nonatomic) IBOutlet UILabel* ErrorLabel;
@property (weak, nonatomic) IBOutlet UILabel *UiLanguageLabel;
@property (weak, nonatomic) IBOutlet UIImageView *UiLanguageImage;
@property (weak, nonatomic) IBOutlet UIView *UiLanguage;
@property (weak, nonatomic) IBOutlet UIImageView *LogoImage;

@property (weak, nonatomic) IBOutlet UIView *FooterView;


@property (weak, nonatomic) IBOutlet UITapGestureRecognizer *UiLanguageTapGesture;

@property (weak, nonatomic) IBOutlet UITapGestureRecognizer *LogoTapGesture;

@property (weak, nonatomic) IBOutlet UITapGestureRecognizer *ViewTapGesture;

@property (nonatomic, assign) id currentResponder;
@property CGPoint OriginalViewCenter;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *CenterFormYConstraint;


@property (weak, nonatomic) IBOutlet NSLayoutConstraint *CenterFormHeightConstraint;

@property CGFloat CenterFormHeightConstraintInitialConstant;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *TopViewTopConstraint;


@end

@implementation UiLoginPageView
{
    BOOL _IsAllBinded;
}

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        
        self.ViewModel =  [[UiLoginPageViewModel alloc] init];
        
        
    }
    return self;
}


- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Orgiginal center of the view
    self.OriginalViewCenter = self.view.center;
    
    self.CenterFormHeightConstraintInitialConstant = self.CenterFormHeightConstraint.constant;
    
    // Bind signals and events
    [self BindAll];
    
    /*
    UITapGestureRecognizer *singleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(resignOnTap:)];
    [singleTap setNumberOfTapsRequired:1];
    [singleTap setNumberOfTouchesRequired:1];
    [self.view addGestureRecognizer:singleTap];
     */
    
    
    // Try autologin
    //[[[AppManager Manager] UserSession] ExecuteAutologinProcess];
    
    
    // Keyboard notifications
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(KeyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(KeyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
    
    /*
    UIButton* button = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    button.frame = CGRectMake(20, 50, 100, 30);
    [button setTitle:@"Crash" forState:UIControlStateNormal];
    [button addTarget:self action:@selector(crashButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:button];
     */

    
}

/*
- (IBAction)crashButtonTapped:(id)sender {
    [[Crashlytics sharedInstance] crash];
}
 */


- (void)didReceiveMemoryWarning {
    
    [super didReceiveMemoryWarning];
    
}


- (void) BindAll
{
    if(_IsAllBinded)
        return;
    
    
    @weakify(self);
    
    // Bind login text field
    
    RAC(self.LoginTextField, text) = [RACObserve(self.ViewModel, LoginText) deliverOnMainThread];
    
    RAC(self.ViewModel, LoginText) = self.LoginTextField.rac_textSignal;
    
    
    // Bind password text field
    
    RAC(self.PasswordTextField, text) = [RACObserve(self.ViewModel, PasswordText) deliverOnMainThread];
    
    RAC(self.ViewModel, PasswordText) = self.PasswordTextField.rac_textSignal;
    
    // Bind form valid signal
    
    
    RACSignal *IsFormValidSignal = RACObserve(self.ViewModel, IsFormValid);
    
    RACSignal *IsLoginProcessActiveSignal = RACObserve(self.ViewModel, IsLoginProcessActive);
    
    RACSignal *IsLastResultSuccess = RACObserve(self.ViewModel, LastResultSuccess);
    
    
    
    RAC(self.LoginButton, enabled) = [[RACSignal combineLatest:@[IsFormValidSignal, IsLoginProcessActiveSignal] reduce:^(NSNumber *IsFormValid, NSNumber *IsLoginProcessActive ) {
        
        return ([IsFormValid integerValue] > 0 && [IsLoginProcessActive integerValue] == 0)?[NSNumber numberWithInt:1]:[NSNumber numberWithInt:0];
        
    }] deliverOnMainThread];
    
    RAC(self.RegistrationButton, enabled) = [[IsLoginProcessActiveSignal not] deliverOnMainThread];
    RAC(self.ForgotPasswordButton, enabled) = [[IsLoginProcessActiveSignal not] deliverOnMainThread];
    
    RAC(self.ErrorLabel, alpha) =
    [[IsLastResultSuccess
        map:^id(NSNumber *Result) {
        return (Result != nil && [Result intValue] == 0) ? @1.0 : @0.0;
        }]
        deliverOnMainThread];
    
    RAC(self.ErrorLabel, text) = [RACObserve(self.ViewModel, LastResultErrorText) deliverOnMainThread];
    
    
    // Bind login process
    [[self.LoginButton rac_signalForControlEvents: UIControlEventTouchUpInside] subscribeNext: ^(id value) {
        
        @strongify(self);
        
        [UiLogger WriteLogInfo:@"LoginPageView: Login button taped"];
        
        [self resignOnTap:nil];
        
        [self.ViewModel ExecuteLoginProcess];
        
    }];
    
    // Bind error label
    
    
    // Bind UiLanguage
    RACSignal *UiLanguageLabelSignal = [RACObserve(self.ViewModel, UiLanguageTextValue) deliverOnMainThread];
    
    RAC(self.UiLanguageLabel, text) = UiLanguageLabelSignal;
    
    RAC(self.UiLanguageImage, image) = [UiLanguageLabelSignal map:^id(NSString *UiLanguageString) {
        
        return [UIImage imageNamed: [NSString stringWithFormat:@"%@_flag_icon", UiLanguageString]];
        
    }];
    
    /*
    [[self.UiLanguageTapGesture rac_gestureSignal] subscribeNext: ^(id value) {
        
        [UiLogger WriteLogInfo:@"LoginPageView: Language tap gesture"];
        
        [self.ViewModel ExecuteUiLanguageTapProcess];
        
        [self resignOnTap:nil];
        
    }];
     */
    
    [[self.LogoTapGesture rac_gestureSignal] subscribeNext: ^(id value) {
        
        @strongify(self);

        [self resignOnTap:nil];
    }];
    
    [[self.ViewTapGesture rac_gestureSignal] subscribeNext: ^(id value) {
        
        @strongify(self);
        
        [self resignOnTap:nil];
        
    }];
    
    [[self.RegistrationButton rac_signalForControlEvents: UIControlEventTouchUpInside] subscribeNext: ^(id value) {
        
        @strongify(self);
        
        [UiLogger WriteLogInfo:@"LoginPageView: Registration button tapped"];
        
        [self.ViewModel ExecuteRegistrationTapProcess];
        
    }];
    
    [[self.ForgotPasswordButton rac_signalForControlEvents: UIControlEventTouchUpInside] subscribeNext: ^(id value) {
        
        @strongify(self);
        
        [UiLogger WriteLogInfo:@"LoginPageView: Forgot password button tapped"];
        
        [self.ViewModel ExecuteForgotPasswordProcess];
        
    }];
    
    RAC(self.AppVersionLabel, text) = [RACObserve(self.ViewModel, AppVersionText) deliverOnMainThread];


    
    _IsAllBinded = YES;
}

#pragma mark UITextField delegates

- (void)textFieldDidBeginEditing:(UITextField *)textField {
    
    self.currentResponder = textField;
    
}

- (void)textFieldDidEndEditing:(UITextField *)textField
{
    
}

- (void)resignOnTap:(id)iSender {
    [self.currentResponder resignFirstResponder];
}

-(BOOL)textFieldShouldReturn:(UITextField *)TextField
{
    if (TextField == self.LoginTextField) {
        [self.PasswordTextField performSelector:@selector(becomeFirstResponder) withObject:nil afterDelay:0];
    }
    else if (TextField == self.PasswordTextField) {
        [self.ViewModel ExecuteLoginProcess];
    }
    return YES;
}


#pragma mark Keyboard delegates

- (void)KeyboardWillShow:(NSNotification*)Notification {
    
    [self AdjustingHeightWhenKeyboard:TRUE withNotification:Notification];
}

- (void)KeyboardWillHide:(NSNotification*)Notification {
    
    [self AdjustingHeightWhenKeyboard:FALSE withNotification:Notification];
}

- (void)AdjustingHeightWhenKeyboard:(BOOL) Show withNotification:(NSNotification*)Notification  {
    
    
    NSDictionary *userInfo = Notification.userInfo;
    NSTimeInterval duration = [userInfo[UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    UIViewAnimationCurve curve = [userInfo[UIKeyboardAnimationCurveUserInfoKey] integerValue];
    
    CGRect keyboardFrameEnd = [userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue];
    keyboardFrameEnd = [self.view convertRect:keyboardFrameEnd fromView:nil];
    
    @weakify(self);
    
    [UIView animateWithDuration:duration delay:0 options:UIViewAnimationOptionBeginFromCurrentState | curve animations:^{
        
        @strongify(self);
        
        self.ErrorLabel.alpha = 0;
        
        self.view.frame = CGRectMake(0, 0, keyboardFrameEnd.size.width, keyboardFrameEnd.origin.y);
        
        //self.LogoImage.alpha = Show ? 0.7 : 1;
        
        self.LogoImage.alpha = Show ? 0 : 1;
        
        self.UiLanguage.alpha = Show ? 0 : 1;
        
        //self.FooterView.alpha = Show ? 0.7 : 1;
        
        self.FooterView.alpha = Show ? 0 : 1;
        
        self.AppVersionLabel.alpha = Show ? 0 : 1;
        
        self.TopViewTopConstraint.constant = Show ? self.view.frame.size.height/2 - 260 : 0;
        
        self.CenterFormYConstraint.constant = Show ? 0 : 50;
        
        self.CenterFormHeightConstraint.constant = Show ? self.CenterFormHeightConstraintInitialConstant - 30 : self.CenterFormHeightConstraintInitialConstant;
        
        [self.RegistrationButton setEnabled:Show ? NO : YES];
        
        [self.ForgotPasswordButton setEnabled:Show ? NO : YES];
        
        
    } completion:nil];
    
}


#pragma mark - Segues

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    
    [UiPreferencesTabNavRouter PrepareForSegue:segue sender:sender];
    
}

- (BOOL)shouldPerformSegueWithIdentifier:(NSString *)identifier sender:(id)sender {
    
#ifndef UiLoginPageAreaSwitch
    if([identifier isEqualToString:@"UiPreferencesTabNavRouterSeguesShowPreferenceServerAreaSelectView"])
        return NO;
#endif
    
    return YES;
}



@end
