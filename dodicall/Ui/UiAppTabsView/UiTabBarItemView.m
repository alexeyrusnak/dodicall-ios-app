//
//  UiTabBarItemView.m
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

#import "UiTabBarItemView.h"

#define CUSTOM_BADGE_TAG 99
#define OFFSET 0.6f

@implementation UiTabBarItemView

@synthesize bage;
@synthesize badgeValue;
//@synthesize _badgeValue;

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        
    }
    return self;
}


-(void)setBadgeValue:(NSString*)value
{
    //bage.text = value;
    
    [self setCustomBadgeValue: value withFont:[UIFont systemFontOfSize:8.0] andFontColor: [UIColor greenColor] andBackgroundColor: [UIColor greenColor]];
}

-(void) setCustomBadgeValue: (NSString *) value withFont: (UIFont *) font andFontColor: (UIColor *) color andBackgroundColor: (UIColor *) backColor
{
    UIView *v = [self valueForKey:@"view"];
    
    //[super setBadgeValue:value];
    
    

    for(UIView *sv in v.subviews)
    {
        
        NSString *str = NSStringFromClass([sv class]);
        
        if([str isEqualToString:@"_UIBadgeView"])
        {
            for(UIView *ssv in sv.subviews)
            {
                // REMOVE PREVIOUS IF EXIST
                if(ssv.tag == CUSTOM_BADGE_TAG) { [ssv removeFromSuperview]; }
            }
            
            UILabel *l = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, sv.frame.size.width, sv.frame.size.height)];
            
            
            [l setFont:font];
            [l setText:value];
            [l setBackgroundColor:backColor];
            [l setTextColor:color];
            [l setTextAlignment:NSTextAlignmentCenter];
            
            l.layer.cornerRadius = l.frame.size.height/2;
            l.layer.masksToBounds = YES;
            
            // Fix for border
            sv.layer.borderWidth = 1;
            sv.layer.borderColor = [backColor CGColor];
            sv.layer.cornerRadius = sv.frame.size.height/2;
            sv.layer.masksToBounds = YES;
            
            
            [v.superview addSubview:l];
            
            l.tag = CUSTOM_BADGE_TAG;
        }
    }
}

@end
