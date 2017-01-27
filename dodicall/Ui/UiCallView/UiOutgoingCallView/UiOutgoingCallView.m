//
//  UiOutgoingCallView.m
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

#import "UiOutgoingCallView.h"
#import "UiMPVolumeView.h"
#import "NUIRenderer.h"
#import "ContactsManager.h"

@import MediaPlayer;

@interface UiOutgoingCallView () {
    BOOL _IsBinded;
}

@property (weak, nonatomic) IBOutlet UINavigationBar *NavigationBar;
@property (weak, nonatomic) IBOutlet UIButton *BackButton;
@property (weak, nonatomic) IBOutlet UIButton *MessageButton;

@property (weak, nonatomic) IBOutlet UIImageView *AvatarImageView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *AvatarHeight;
@property (weak, nonatomic) IBOutlet UIImageView *DodicallImage;

@property (weak, nonatomic) IBOutlet UILabel *TitleLabel;

@property (weak, nonatomic) IBOutlet UIButton *VideoButton;
@property (weak, nonatomic) IBOutlet UIButton *SpeakerButton;
@property (weak, nonatomic) IBOutlet UIButton *HoldButton;
@property (weak, nonatomic) IBOutlet UIButton *DropcallButton;

@property (weak, nonatomic) IBOutlet UILabel *VideoLabel;
@property (weak, nonatomic) IBOutlet UILabel *AudioSourceLabel;

@property (weak, nonatomic) IBOutlet UiMPVolumeView *VolumeView;
@property (weak, nonatomic) UIButton *RouteButton;

@property (strong, nonatomic) NSNumber *AudioRoutesAvailable;

@end


@implementation UiOutgoingCallView

-(instancetype)initWithCoder:(NSCoder *)aDecoder {
    
    if(self = [super initWithCoder:aDecoder]) {
        self.ViewModel = [UiOutgoingCallViewModel new];
        _IsBinded = NO;
    }
    return self;
}

//- (UIStatusBarStyle)preferredStatusBarStyle {
//    return UIStatusBarStyleLightContent;
//}

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
  //  [self setNeedsStatusBarAppearanceUpdate];
    
    [self SetViewsSizes];
    
    [self BindAll];
}

-(void) BindAll {
    if(_IsBinded)
        return;
    
    self.MessageButton.rac_command = self.ViewModel.ShowComingSoon;
    self.VideoButton.rac_command = self.ViewModel.ShowComingSoon;
    self.HoldButton.rac_command = self.ViewModel.ShowComingSoon;
    
    self.BackButton.rac_command = self.ViewModel.HideView;
    self.DropcallButton.rac_command = self.ViewModel.DropCall;
    
    RAC(self.TitleLabel, text) = [RACObserve(self.ViewModel, Name) deliverOnMainThread];
    RAC(self.DodicallImage, hidden) = [[[RACObserve(self.ViewModel, Dodicall) ignore:nil] not] deliverOnMainThread];
    
    @weakify(self);
    
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
    
    [[[RACObserve(self.ViewModel, ChatAllowed)
        ignore:nil]
        deliverOnMainThread]
        subscribeNext:^(id chatAllowed) {
            @strongify(self);
            [self.MessageButton setEnabled:[chatAllowed boolValue]];
            
            if([chatAllowed boolValue])
                [self.MessageButton setAlpha:1.0];
            else
                [self.MessageButton setAlpha:0];
        }];
    
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
    
    [[[[RACObserve(self, AudioRoutesAvailable)
        distinctUntilChanged]
        throttle:0.2 afterAllowing:1]
        deliverOnMainThread]
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
    
    RAC(self.AvatarImageView, image) = [[ContactsManager AvatarImageSignalForPathSignal:RACObserve(self.ViewModel, AvatarPath) WithTakeUntil:[RACSignal never]] deliverOnMainThread];
    
    _IsBinded = YES;
}

- (void) SetViewsSizes {
    if([self.ViewModel.IsSmallDevice boolValue]) {
        
        self.AvatarHeight.constant = 80;
        self.AvatarImageView.nuiClass = [self.AvatarImageView.nuiClass stringByAppendingString:@"Compact"];
    }
}
@end
