//
//  UiCheckListButtonView.m
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

#import "UiCheckListButtonView.h"

@implementation UiCheckListButtonView


- (void)drawRect:(CGRect)rect {
    // Drawing code
    [super drawRect:rect];
    
    //self.titleEdgeInsets = UIEdgeInsetsMake(0, -self.imageView.frame.size.width, 0, self.imageView.frame.size.width);
    //self.imageEdgeInsets = UIEdgeInsetsMake(0, self.bounds.size.width - 31, 0, 0);
    
    self.titleEdgeInsets = UIEdgeInsetsMake(0, -24, 0, 0);
    self.imageEdgeInsets = UIEdgeInsetsMake(5, self.frame.size.width - 39, 0, -self.frame.size.width);
    
    
}

@end
