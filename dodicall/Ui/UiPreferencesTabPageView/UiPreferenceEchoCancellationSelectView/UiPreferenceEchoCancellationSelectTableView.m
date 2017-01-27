//
//  UiPreferenceEchoCancellationSelectTableView.m
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

#import "UiPreferenceEchoCancellationSelectTableView.h"
#import <ReactiveCocoa/ReactiveCocoa.h>

@interface UiPreferenceEchoCancellationSelectTableView ()

@property (weak, nonatomic) IBOutlet UIImageView *EchoCancellationModeOffCheckIcon;

@property (weak, nonatomic) IBOutlet UIImageView *EchoCancellationModeSoftCheckIcon;

@property (weak, nonatomic) IBOutlet UIImageView *EchoCancellationModeHardCheckIcon;

@end;


@implementation UiPreferenceEchoCancellationSelectTableView
{
    BOOL _IsAllBinded;
}

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        
        self.ViewModel =  [[UiPreferenceEchoCancellationSelectTableViewModel alloc] init];
        
        
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
    
    RACSignal *UiEchoCancellationChangeSignal = RACObserve(self.ViewModel, Mode);
    
    RAC(self.EchoCancellationModeOffCheckIcon, alpha) = [UiEchoCancellationChangeSignal map:^id(NSNumber *Mode) {
        return ([Mode intValue]  == EchoCancellationModeOff) ? @1.0 : @0.0;
    }];
    
    RAC(self.EchoCancellationModeSoftCheckIcon, alpha) = [UiEchoCancellationChangeSignal map:^id(NSNumber *Mode) {
        return ([Mode intValue]  == EchoCancellationModeSoft) ? @1.0 : @0.0;
    }];
    
    RAC(self.EchoCancellationModeHardCheckIcon, alpha) = [UiEchoCancellationChangeSignal map:^id(NSNumber *Mode) {
        return ([Mode intValue]  == EchoCancellationModeHard) ? @1.0 : @0.0;
    }];

    _IsAllBinded = TRUE;
    
    
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    
    [self.ViewModel DidCellSelected:cell.reuseIdentifier];
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

@end
