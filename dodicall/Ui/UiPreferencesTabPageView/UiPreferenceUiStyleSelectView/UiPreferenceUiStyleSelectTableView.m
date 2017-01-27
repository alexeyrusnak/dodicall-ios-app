//
//  UiPreferenceUiStyleSelectTableView.m
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

#import "UiPreferenceUiStyleSelectTableView.h"
#import <ReactiveCocoa/ReactiveCocoa.h>

@interface UiPreferenceUiStyleSelectTableView ()

@property (weak, nonatomic) IBOutlet UIImageView *UiStyleDefaultCheckIcon;

@property (weak, nonatomic) IBOutlet UIImageView *UiStyleLightCheckIcon;

@property (weak, nonatomic) IBOutlet UIImageView *UiStyleDarkCheckIcon;

@end

@implementation UiPreferenceUiStyleSelectTableView
{
    BOOL _IsAllBinded;
}

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        
        self.ViewModel =  [[UiPreferenceUiStyleSelectTableViewModel alloc] init];
        
        
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
    
    RACSignal *UiUiStyleChangeSignal = RACObserve(self.ViewModel, Style);
    
    RAC(self.UiStyleDefaultCheckIcon, alpha) = [UiUiStyleChangeSignal map:^id(NSString *Style) {
        return [Style isEqualToString:UiStyleDefault] ? @1.0 : @0.0;
    }];
    
    RAC(self.UiStyleLightCheckIcon, alpha) = [UiUiStyleChangeSignal map:^id(NSString *Style) {
        return [Style isEqualToString:UiStyleLight] ? @1.0 : @0.0;
    }];
    
    RAC(self.UiStyleDarkCheckIcon, alpha) = [UiUiStyleChangeSignal map:^id(NSString *Style) {
        return [Style isEqualToString:UiStyleDark] ? @1.0 : @0.0;
    }];

    
    
    _IsAllBinded = TRUE;
    
    
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    
    [self.ViewModel DidCellSelected:cell.reuseIdentifier];
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

@end
