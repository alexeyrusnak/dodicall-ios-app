//
//  UiIncomingCallView.m
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

#import "UiIncomingCallView.h"
#import "NUIRenderer.h"
#import "ContactsManager.h"

@interface UiIncomingCallView () {
    BOOL _IsBinded;
}

@property (weak, nonatomic) IBOutlet UIImageView *AvatarImageView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *AvatarHeight;
@property (weak, nonatomic) IBOutlet UIImageView *DodicallImage;

@property (weak, nonatomic) IBOutlet UILabel *NameLabel;

@property (weak, nonatomic) IBOutlet UIButton *HoldcallButton;
@property (weak, nonatomic) IBOutlet UIButton *DropcallButton;
@property (weak, nonatomic) IBOutlet UIButton *AnswercallButton;
@property (weak, nonatomic) IBOutlet UIButton *MessageButton;

@end

@implementation UiIncomingCallView


-(instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if(self) {
        self.ViewModel = [UiIncomingCallViewModel new];
        _IsBinded = NO;
    }
    return self;
}
- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
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
    [self BindAll];
    [self SetViewsSizes];
}

- (void)BindAll {
    
    if (_IsBinded)
        return;
    
    self.MessageButton.rac_command = self.ViewModel.ShowComingSoon;
    self.HoldcallButton.rac_command = self.ViewModel.ShowComingSoon;
    
    self.DropcallButton.rac_command = self.ViewModel.DropCall;
    self.AnswercallButton.rac_command = self.ViewModel.AnswerCall;
    
    RAC(self.NameLabel, text) = [RACObserve(self.ViewModel, Name) deliverOnMainThread];
    RAC(self.DodicallImage, hidden) = [[[RACObserve(self.ViewModel, Dodicall) ignore:nil] not] deliverOnMainThread];
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
