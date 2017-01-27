//
//  UiCallView.m
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
#import "UiCurrentCallView.h"
#import "UiCallsNavRouter.h"
#import "NuiRenderer.h"
#import "NuiGraphics.h"
#import "UiMPVolumeView.h"

#import "UiCallDialerView.h"
#import "UiCallDialerViewModel.h"

#import "NUIRenderer.h"

#import "ContactsManager.h"
@import MediaPlayer;

@interface UiCurrentCallView () {
    bool _IsBinded;
}

@property (weak, nonatomic) IBOutlet UINavigationBar *NavigationBar;
@property (weak, nonatomic) IBOutlet UIButton *BackButton;
@property (weak, nonatomic) IBOutlet UIButton *MessageButton;

@property (weak, nonatomic) IBOutlet UILabel *TitleLabel;
@property (weak, nonatomic) IBOutlet UILabel *StatusLabel;

@property (weak, nonatomic) IBOutlet UIImageView *AvatarImageView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *AvatarHeight;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *AvatarBottom;

@property (weak, nonatomic) IBOutlet UIButton *LockButton;
@property (weak, nonatomic) IBOutlet UIImageView *DodicallImage;

@property (weak, nonatomic) IBOutlet UIButton *VideoButton;
@property (weak, nonatomic) IBOutlet UIButton *MicButton;
@property (weak, nonatomic) IBOutlet UIButton *SpeakerButton;
@property (weak, nonatomic) IBOutlet UIButton *AdduserButton;
@property (weak, nonatomic) IBOutlet UIButton *HoldcallButton;
@property (weak, nonatomic) IBOutlet UIButton *TransfercallButton;
@property (weak, nonatomic) IBOutlet UIButton *DialpadButton;
@property (weak, nonatomic) IBOutlet UIButton *DropcallButton;

@property (weak, nonatomic) IBOutlet UILabel *VideoLabel;
@property (weak, nonatomic) IBOutlet UILabel *AudioSourceLabel;

@property (weak, nonatomic) IBOutlet UiMPVolumeView *VolumeView;
@property (weak, nonatomic) UIButton *RouteButton;

@property (strong, nonatomic) IBOutletCollection(NSLayoutConstraint) NSArray *ButtonsStacksOutterMargins;

@property (weak, nonatomic) IBOutlet UIView *AvatarContainerView;
@property (weak, nonatomic) IBOutlet UIView *TopButtonsConainerView;
@property (weak, nonatomic) IBOutlet UIView *BottomButtonsContainerView;
@property (weak, nonatomic) IBOutlet UIView *DialpadContainerView;

@property (weak, nonatomic) IBOutlet UIStackView *TopButtonsStack;

@property (weak, nonatomic) UiCallDialerView *DialerView;

@property (strong, nonatomic) NSNumber *AudioRoutesAvailable;

@end


@implementation UiCurrentCallView

-(instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if(self) {
        self.ViewModel = [UiCurrentCallViewModel new];
        _IsBinded = NO;
    }
    return self;
}

-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent];
}

-(void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [UIDevice currentDevice].proximityMonitoringEnabled = YES;
    [self SetViewsSizes];
    [self BindAll];
}

- (void)BindAll {
    
    if (_IsBinded)
        return;
    
    self.VideoButton.rac_command = self.ViewModel.ShowComingSoon;
    self.AdduserButton.rac_command = self.ViewModel.ShowComingSoon;
    
    self.MessageButton.rac_command = self.ViewModel.ShowComingSoon;
    self.HoldcallButton.rac_command = self.ViewModel.ShowComingSoon;
    
    self.DropcallButton.rac_command = self.ViewModel.CloseCallView;
    self.MicButton.rac_command = self.ViewModel.SwitchMic;
    self.TransfercallButton.rac_command = self.ViewModel.TransferCall;
    self.BackButton.rac_command = self.ViewModel.HideView;
    
    RAC(self.TitleLabel, text) = [RACObserve(self.ViewModel, Name) deliverOnMainThread];
    RAC(self.DodicallImage, hidden) = [[[RACObserve(self.ViewModel, Dodicall) ignore:nil] not] deliverOnMainThread];
    RAC(self.LockButton, hidden) = [[[RACObserve(self.ViewModel, Encrypted) ignore:nil] not] deliverOnMainThread];
    
    @weakify(self);
    
    //Sizes
    [[[[[RACObserve(self, view.frame)
        merge:RACObserve(self, view.bounds)]
        map:^id(NSValue *Value) {
            return @(CGRectGetWidth([Value CGRectValue]));
        }]
        distinctUntilChanged]
        deliverOnMainThread]
        subscribeNext:^(NSNumber *Width) {
            
            CGFloat ViewWidth = [Width floatValue];
            CGFloat StackViewWidth = ViewWidth/1.2;
            
            if(StackViewWidth > 400)
                StackViewWidth = 400;
    
            CGFloat ButtonsOutter = (ViewWidth - StackViewWidth)/2;
            
            @strongify(self);
            for(NSLayoutConstraint *Constraint in self.ButtonsStacksOutterMargins) {
                [Constraint setConstant:ButtonsOutter];
            }
            
        }];
    
    //Buttons visibility, styles
    [[[[RACObserve(self.ViewModel, MobileCall)
        ignore:nil]
        not]
        deliverOnMainThread]
        subscribeNext:^(NSNumber *enabled) {
            @strongify(self);
            
            [self.VideoButton setUserInteractionEnabled:[enabled boolValue]];

            CGFloat alpha;
            if([enabled boolValue])
                alpha = 1;
            else
                alpha = 0.5;

            [self.VideoButton setAlpha:alpha];
            [self.VideoLabel setAlpha:alpha];
        }];
    
    
    [[[RACObserve(self.ViewModel, IsMicEnabled)
        ignore:nil]
        deliverOnMainThread]
        subscribeNext:^(NSNumber *MicEnabled) {
            @strongify(self);
            
            if([MicEnabled boolValue])
                [self.MicButton setValue:@"UiCallMicButton" forKey:@"nuiClass"];
            else
                [self.MicButton setValue:@"UiCallMicButtonDisabled" forKey:@"nuiClass"];

            [NUIRenderer renderButton:self.MicButton withClass:self.MicButton.nuiClass];
        }];
    
    
    [[RACObserve(self.ViewModel, ChatAllowed)
        deliverOnMainThread]
        subscribeNext:^(id chatAllowed) {
            @strongify(self);
            [self.MessageButton setEnabled:[chatAllowed boolValue]];

            if([chatAllowed boolValue])
                [self.MessageButton setAlpha:1.0];
            else
                [self.MessageButton setAlpha:0];
        }];
    
    
    [[RACObserve(self.ViewModel, CallDuration)
        deliverOnMainThread]
        subscribeNext:^(NSNumber *x) {
            @strongify(self);
            NSInteger ti = [x integerValue];
            NSInteger seconds = ti % 60;
            NSInteger minutes = (ti / 60) % 60;
            NSString *time = [NSString stringWithFormat:@"%02ld:%02ld", (long)minutes, (long)seconds];
            [self.StatusLabel setText:time];
        }];
    
    
    
    //Audio route button/ MPVolumeView
    [RACObserve(self.VolumeView, subviews) subscribeNext:^(NSArray *Subviews) {
        @strongify(self);
        
        for( UIView *subview in Subviews ) {
            if([subview isKindOfClass:[UIButton class]]) {
                
                UIButton *routeButton = (UIButton *)subview;
                self.RouteButton = routeButton;
                break;
            }
        }
    }];
    
    
    [[RACObserve(self, RouteButton.alpha) deliverOnMainThread] subscribeNext:^(NSNumber *x) {
        @strongify(self);
        
        if([x floatValue] == 0)
            self.AudioRoutesAvailable = @(0);
        else
            self.AudioRoutesAvailable = @(1);
    }];
    
    
    [[[RACObserve(self, AudioRoutesAvailable)
        distinctUntilChanged]
        throttle:0.2]
        subscribeNext:^(NSNumber *RoutesAvailable) {
            @strongify(self);
            if([RoutesAvailable boolValue]) {
                [self.SpeakerButton setAlpha:1];
                [self.AudioSourceLabel setAlpha:1];
                [self.SpeakerButton.imageView setAlpha:0];
            }
            else {
                [self.SpeakerButton setAlpha:0.5];
                [self.AudioSourceLabel setAlpha:0.5];
                [self.SpeakerButton.imageView setAlpha:1];
            }
        }];

    
    
    //Dialer
    [[self.DialpadButton rac_signalForControlEvents:UIControlEventTouchUpInside] subscribeNext:^(id x) {
        @strongify(self);
        [self SetMainViewOpened:NO WithDuration:0.2 Completion:^{
            [self SetDialpadOpened:YES WithDuration:0.2];
        }];
    }];
    

    [[[RACObserve(self.DialerView.view, hidden)
        distinctUntilChanged]
        filter:^BOOL(NSNumber *IsHidden) {
            return [IsHidden boolValue];
        }]
        subscribeNext:^(id x) {
            @strongify(self);
            [self SetDialpadOpened:NO WithDuration:0];
            [self SetMainViewOpened:YES WithDuration:0.2 Completion:nil];
        }];
    
    
    RAC(self.AvatarImageView, image) = [[ContactsManager AvatarImageSignalForPathSignal:RACObserve(self.ViewModel, AvatarPath) WithTakeUntil:[RACSignal never]] deliverOnMainThread];
    
    _IsBinded = YES;
}



#pragma mark - Views Visibility

- (void) SetViewsSizes {
    if([self.ViewModel.IsSmallDevice boolValue]) {
        self.AvatarBottom.constant = 10;
        self.AvatarHeight.constant = 80;
        
        self.TopButtonsStack.spacing = 10;
        
        self.AvatarImageView.nuiClass = [self.AvatarImageView.nuiClass stringByAppendingString:@"Compact"];
    }
}

- (void) SetMainViewOpened:(BOOL)Opened WithDuration:(NSTimeInterval) Duration Completion:(nullable void(^)())Completion {
    
    
    CGFloat Alpha = 0;
    UIViewAnimationOptions Options;
    
    if(Opened) {
        Alpha = 1;
        Options = UIViewAnimationOptionCurveEaseIn;
    }
    else {
        Alpha = 0;
        Options = UIViewAnimationOptionCurveEaseOut;
    }
    
    [UIView animateWithDuration:Duration delay:0 options:Options animations:^{
        self.TopButtonsConainerView.alpha = Alpha;
        self.AvatarContainerView.alpha = Alpha;
        self.BottomButtonsContainerView.alpha = Alpha;
    }
    completion:^(BOOL finished) {
        if(Completion)
            Completion();
    }];
}

- (void) SetDialpadOpened:(BOOL)Opened WithDuration:(NSTimeInterval) Duration {
   
    if(Opened) {
        self.DialpadContainerView.alpha = 1;
        self.DialerView.view.alpha = 0;
        self.DialpadContainerView.hidden = NO;
        self.DialerView.view.hidden = NO;
    }
    else {
        self.DialpadContainerView.alpha = 1;
        self.DialerView.view.alpha = 0;
        self.DialpadContainerView.hidden = YES;
        self.DialerView.view.hidden = YES;
    }
    
    [UIView animateWithDuration:Duration delay:0 options:UIViewAnimationOptionCurveEaseIn animations:^{
        if(Opened)
            self.DialerView.view.alpha = 1;
        else
            self.DialerView.view.alpha = 0;
        
    } completion:^(BOOL finished) {
        
    }];
}

#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if([segue.identifier isEqualToString:@"UiCallViewShowDialer"]) {
        
        self.DialerView = segue.destinationViewController;
        self.DialerView.ViewModel.HangupCallCommand = self.ViewModel.CloseCallView;
    }
}
@end
