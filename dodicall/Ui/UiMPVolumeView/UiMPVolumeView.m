//
//  UiMPVolumeView.m
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

#import "UiMPVolumeView.h"
#import "UiAlertControllerView.h"
#import "NuiGraphics.h"
#import "NuiSettings.h"
#import "UIView+NUI.h"

@implementation UiMPVolumeView

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        
        [self setShowsVolumeSlider:NO];
        [self setShowsRouteButton:YES];
        
        NSString *nuiClass = @"UiCallAudioRouteButton";
        
        [self setRouteButtonImage:[NUIGraphics resizeImage:[UIImage imageNamed:@"speaker_call"]:[NUISettings getSize:@"image-size" withClass:nuiClass]]  forState:UIControlStateNormal];
        
        [self sizeToFit];
        
    }
    return self;
}

@end
