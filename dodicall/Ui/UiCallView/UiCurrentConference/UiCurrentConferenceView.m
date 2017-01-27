//
//  UiCurrentConferenceView.m
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

#import "UiCurrentConferenceView.h"
#import "UiMPVolumeView.h"
#import <NUIRenderer.h>

#import "UiCurrentConferenceUserCell.h"

@interface UiCurrentConferenceView () <UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout>

@property (weak, nonatomic) IBOutlet UILabel *TitleLabel;
@property (weak, nonatomic) IBOutlet UILabel *StatusLabel;
@property (weak, nonatomic) IBOutlet UIButton *BackButton;
@property (weak, nonatomic) IBOutlet UIButton *ChatButton;

@property (weak, nonatomic) IBOutlet UILabel *DurationLabel;

@property (weak, nonatomic) IBOutlet UIButton *AddUserButton;
@property (weak, nonatomic) IBOutlet UIButton *MicButton;
@property (weak, nonatomic) IBOutlet UIButton *DropCallButton;
@property (weak, nonatomic) IBOutlet UIButton *HoldCallButton;

@property (weak, nonatomic) IBOutlet UiMPVolumeView *VolumeView;

@property (strong, nonatomic) IBOutletCollection(NSLayoutConstraint) NSArray *ButtonStacksOutterMargins;

@property (weak, nonatomic) IBOutlet UILabel *AudioSourceLabel;

@property (weak, nonatomic) IBOutlet UIButton *SpeakerButton;
@property (strong, nonatomic) NSNumber *AudioRoutesAvailable;
@property (weak, nonatomic) UIButton *RouteButton;

@property (weak, nonatomic) IBOutlet UICollectionView *UsersList;

@end

@implementation UiCurrentConferenceView

#pragma mark - View
-(instancetype)initWithCoder:(NSCoder *)aDecoder {
    if(self = [super initWithCoder:aDecoder]) {
        self.ViewModel = [UiCurrentConferenceViewModel new];
    }
    return self;
}
- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self SetupSizes];
    [self SetupRouteButtonVisibility];
    
    [self BindAll];
}

-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent];
}

-(void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault];
}

- (void) SetupSizes {
    @weakify(self);
    
    [[[[RACObserve(self, view.frame)
        merge:RACObserve(self, view.bounds)]
        map:^id(NSValue *Value) {
           return @(CGRectGetWidth([Value CGRectValue]));
        }]
        distinctUntilChanged]
        subscribeNext:^(NSNumber *Width) {
            CGFloat ViewWidth = [Width floatValue];
            CGFloat StackViewWidth = ViewWidth/1.2;
         
            if(StackViewWidth > 400)
                StackViewWidth = 400;
         
            CGFloat ButtonsOutter = (ViewWidth - StackViewWidth)/2;
         
            @strongify(self);
            for(NSLayoutConstraint *Constraint in self.ButtonStacksOutterMargins) {
                [Constraint setConstant:ButtonsOutter];
            }
         
        }];
}

- (void) SetupRouteButtonVisibility {
    @weakify(self);
    
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
    
    
    [RACObserve(self, RouteButton.alpha) subscribeNext:^(NSNumber *x) {
        @strongify(self);
        
        if([x floatValue] == 0)
            self.AudioRoutesAvailable = @(0);
        else
            self.AudioRoutesAvailable = @(1);
    }];
    
    
    [[[[RACObserve(self, AudioRoutesAvailable)
        distinctUntilChanged]
        throttle:0.2]
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
}

- (void) BindAll {
    
    self.AddUserButton.rac_command = self.ViewModel.ShowComingSoon;
    self.BackButton.rac_command = self.ViewModel.ShowComingSoon;
    self.ChatButton.rac_command = self.ViewModel.ShowComingSoon;
    self.HoldCallButton.rac_command = self.ViewModel.ShowComingSoon;
    
    self.DropCallButton.rac_command = self.ViewModel.DropCall;
    self.MicButton.rac_command = self.ViewModel.SwitchMic;
    
    
    RAC(self.TitleLabel, text) = [RACObserve(self.ViewModel, ConferenceTitle) deliverOnMainThread];
    
    @weakify(self);
    
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
    
    [[RACObserve(self.ViewModel, ConferenceDuration)
        deliverOnMainThread]
        subscribeNext:^(NSNumber *x) {
            @strongify(self);
            NSInteger ti = [x integerValue];
            NSInteger seconds = ti % 60;
            NSInteger minutes = (ti / 60) % 60;
            NSString *time = [NSString stringWithFormat:@"%02ld:%02ld", (long)minutes, (long)seconds];
            [self.DurationLabel setText:time];
        }];
    
    
    [[RACObserve(self.ViewModel, UsersArray) deliverOnMainThread] subscribeNext:^(id x) {
        @strongify(self);
        [self.UsersList reloadData];
    }];
}


#pragma mark - Collection View

-(NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

-(NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return [self.ViewModel.UsersArray count];
}

-(UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    UICollectionViewCell *Cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"UiCurrentCollectionViewUserCell" forIndexPath:indexPath];
    
    return Cell;
}
-(void)collectionView:(UICollectionView *)collectionView willDisplayCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath {
    UiCurrentConferenceUserCell *Cell = (UiCurrentConferenceUserCell *)cell;
    UiCurrentConferenceUserCellModel *CellModel = [self.ViewModel.UsersArray objectAtIndex:indexPath.row];
    
    [Cell.Name setText:CellModel.Name];
    
    if([CellModel.IsEncrypted boolValue])
        [Cell.EncryptionImage setAlpha:1];
    else
        [Cell.EncryptionImage setAlpha:0];
    
    if([CellModel.IsDodicall boolValue])
        [Cell.DodicallImage setAlpha:1];
    else
        [Cell.DodicallImage setAlpha:0];
    
    if([CellModel.IsActive boolValue])
        [Cell.DialingImage setAlpha:0];
    else
        [Cell.DialingImage setAlpha:1];
    
    
    
}

-(UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout insetForSectionAtIndex:(NSInteger)section {
    
    return UIEdgeInsetsMake(0, -5, 0, -5);
}

@end
