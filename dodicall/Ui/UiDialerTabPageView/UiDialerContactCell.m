//
//  UiDialerContactCell.m
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

#import "UiDialerContactCell.h"
#import <ReactiveCocoa/ReactiveCocoa.h>

@interface UiDialerContactCell ()

@property (weak, nonatomic) IBOutlet UILabel *TypeLabel;
@property (weak, nonatomic) IBOutlet UIImageView *FavouritesImageView;
@property (weak, nonatomic) IBOutlet UIImageView *CheckmarkImageView;

@end

@implementation UiDialerContactCell

- (void)BindViewModel:(UiDialerContactCellModel *)ViewModel {
    RAC(self.TypeLabel, text) = [RACObserve(ViewModel, Type) deliverOnMainThread];
    RAC(self.NumberLabel, text) = [RACObserve(ViewModel, Number) deliverOnMainThread];
    RAC(self.FavouritesImageView, alpha) = [RACObserve(ViewModel, IsFavourite) deliverOnMainThread];
    RAC(self.CheckmarkImageView, alpha) = [RACObserve(ViewModel, IsSelected) deliverOnMainThread];
}

@end
