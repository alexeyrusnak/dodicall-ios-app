//
//  UiPreferenceVideoSetsTableViewModel.m
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

#import "UiPreferenceVideoSetsTableViewModel.h"

@implementation UiPreferenceVideoSetsTableViewModel

@synthesize UiVideoEnabled;
@synthesize UiVideoCellSize;
@synthesize UiVideoWiFiSize;

- (instancetype)init
{
    self = [super init];
    if (self) {
        
        //self.UiVideoEnabled = TRUE;
        //self.UiVideoWiFiSize = @"QVGA";
        //self.UiVideoCellSize = @"QVGA";
        
        
        [self BindAll];
    }
    return self;
}

- (void) BindAll
{
    
    RACChannelTo(self, UiVideoEnabled) = RACChannelTo([AppManager app].UserSettingsModel, VideoEnabled);
    
    RACChannelTo(self, self.UiVideoWiFiSize) = RACChannelTo([AppManager app].UserSettingsModel, VideoSizeWifi);
    
    RACChannelTo(self, self.UiVideoCellSize) = RACChannelTo([AppManager app].UserSettingsModel, VideoSizeCell);
}

- (void) DidCellSelected:(NSString *) CellIdentifier
{
    NSLog(@"DidCellSelected %@",CellIdentifier);
    
    if( [CellIdentifier isEqualToString:@"VideoWiFiSizeQVGA"] )
    {
        self.UiVideoWiFiSize = VideoSizeQvga;
    }
    
    if( [CellIdentifier isEqualToString:@"VideoWiFiSizeVGA"] )
    {
        self.UiVideoWiFiSize = VideoSizeVga;
    }
    
    if( [CellIdentifier isEqualToString:@"VideoWiFiSize720p"] )
    {
        self.UiVideoWiFiSize = VideoSize720p;
    }
    
    
    if( [CellIdentifier isEqualToString:@"VideoCellSizeQVGA"] )
    {
        self.UiVideoCellSize = VideoSizeQvga;
    }
    
    if( [CellIdentifier isEqualToString:@"VideoCellSizeVGA"] )
    {
        self.UiVideoCellSize = VideoSizeVga;
    }
    
    if( [CellIdentifier isEqualToString:@"VideoCellSize720p"] )
    {
        self.UiVideoCellSize = VideoSize720p;
    }
    
    
}

@end
