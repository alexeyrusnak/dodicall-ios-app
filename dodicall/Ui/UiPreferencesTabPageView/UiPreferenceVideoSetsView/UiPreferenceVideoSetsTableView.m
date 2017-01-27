//
//  UiPreferenceVideoSetsTableView.m
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

#import "UiPreferenceVideoSetsTableView.h"
#import <ReactiveCocoa/ReactiveCocoa.h>

@interface UiPreferenceVideoSetsTableView ()

@property (weak, nonatomic) IBOutlet UISwitch *VideoEnabledSwitch;

@property (weak, nonatomic) IBOutlet UIImageView *VideoWiFiSizeQVGACheckIcon;

@property (weak, nonatomic) IBOutlet UIImageView *VideoWiFiSizeVGACheckIcon;

@property (weak, nonatomic) IBOutlet UIImageView *VideoWiFiSize720pCheckIcon;

@property (weak, nonatomic) IBOutlet UIImageView *VideoCellSizeQVGACheckIcon;

@property (weak, nonatomic) IBOutlet UIImageView *VideoCellSizeVGACheckIcon;

@property (weak, nonatomic) IBOutlet UIImageView *VideoCellSize720pCheckIcon;


@end

@implementation UiPreferenceVideoSetsTableView
{
    BOOL _IsAllBinded;
}

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        
        self.ViewModel =  [[UiPreferenceVideoSetsTableViewModel alloc] init];
        
        
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self BindAll];
}

- (void) BindAll
{
    if(_IsAllBinded)
        return;
    
    RAC(self.VideoEnabledSwitch, on) = RACObserve(self.ViewModel, UiVideoEnabled);
    RAC(self.ViewModel, UiVideoEnabled) = self.VideoEnabledSwitch.rac_newOnChannel;
        
        
    RACSignal *UiVideoWiFiSizeChangeSignal = RACObserve(self.ViewModel, UiVideoWiFiSize);
    
    RAC(self.VideoWiFiSizeQVGACheckIcon, alpha) = [UiVideoWiFiSizeChangeSignal map:^id(NSNumber *UiVideoWiFiSizeString) {
        return [UiVideoWiFiSizeString intValue] == VideoSizeQvga ? @1.0 : @0.0;
    }];
    
    RAC(self.VideoWiFiSizeVGACheckIcon, alpha) = [UiVideoWiFiSizeChangeSignal map:^id(NSNumber *UiVideoWiFiSizeString) {
        return [UiVideoWiFiSizeString intValue] == VideoSizeVga ? @1.0 : @0.0;
    }];
    
    RAC(self.VideoWiFiSize720pCheckIcon, alpha) = [UiVideoWiFiSizeChangeSignal map:^id(NSNumber *UiVideoWiFiSizeString) {
        return [UiVideoWiFiSizeString intValue] == VideoSize720p ? @1.0 : @0.0;
    }]; 
    
    
    RACSignal *UiVideoCellSizeChangeSignal = RACObserve(self.ViewModel, UiVideoCellSize);
    
    RAC(self.VideoCellSizeQVGACheckIcon, alpha) = [UiVideoCellSizeChangeSignal map:^id(NSNumber *UiVideoCellSizeString) {
        return [UiVideoCellSizeString intValue] == VideoSizeQvga ? @1.0 : @0.0;
    }];
    
    RAC(self.VideoCellSizeVGACheckIcon, alpha) = [UiVideoCellSizeChangeSignal map:^id(NSNumber *UiVideoCellSizeString) {
        return [UiVideoCellSizeString intValue] == VideoSizeVga ? @1.0 : @0.0;
    }];
    
    RAC(self.VideoCellSize720pCheckIcon, alpha) = [UiVideoCellSizeChangeSignal map:^id(NSNumber *UiVideoCellSizeString) {
        return [UiVideoCellSizeString intValue] == VideoSize720p ? @1.0 : @0.0;
    }];     

    _IsAllBinded = TRUE;  
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    
    [self.ViewModel DidCellSelected:cell.reuseIdentifier];
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}


@end
