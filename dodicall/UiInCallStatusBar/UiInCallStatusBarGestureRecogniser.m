//
//  UiInCallStatusBarGestureRecogniser.m
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

#import "UiInCallStatusBarGestureRecogniser.h"

@implementation UiInCallStatusBarGestureRecogniser
#pragma mark - Status bar touch tracking
- (void) touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    [super touchesBegan:touches withEvent:event];
    
    CGRect TrackFrameWithMargin = self.FrameToTrack;
    TrackFrameWithMargin.size.height+=2;
    
    CGPoint location = [[[event allTouches] anyObject] locationInView:[[UIApplication sharedApplication] keyWindow]];
    
    if (!CGRectEqualToRect(self.FrameToTrack, CGRectZero) && CGRectContainsPoint(TrackFrameWithMargin, location)) {
        self.cancelsTouchesInView = YES;
        self.state = UIGestureRecognizerStateRecognized;
    }
    else {
        self.cancelsTouchesInView = NO;
        self.state = UIGestureRecognizerStateFailed;
    }
    
}

@end
