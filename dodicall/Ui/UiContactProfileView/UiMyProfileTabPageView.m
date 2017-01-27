//
//  UiMyProfileView.m
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

#import "UiMyProfileTabPageView.h"
#import "UiContactProfileView.h"
#import "UiLogger.h"
#import "AppManager.h"

@interface UiMyProfileTabPageView ()

@end

@implementation UiMyProfileTabPageView

- (BOOL)shouldPerformSegueWithIdentifier:(NSString *)Identifier sender:(id)Sender
{
    
    return YES;
}

- (void)performSegueWithIdentifier:(NSString *)identifier sender:(nullable id)sender
{
    
}
- (void)prepareForSegue:(UIStoryboardSegue *)Segue sender:(nullable id)Sender
{
    if ([[Segue identifier] isEqualToString:@"UiMyProfileEmbedSegue"])
    {
        
        [UiLogger WriteLogInfo:@"UiMyProfileTabPageView: Show my profile"];
        
        
        
        UiContactProfileView *ContactProfileView = (UiContactProfileView *)[[Segue destinationViewController] topViewController];
        
        [ContactProfileView.ViewModel setIsInTabView:YES];
        
        
        void (^Callback)(ObjC_ContactModel *) = ^(ObjC_ContactModel * MyProfile)
        {
            [UiLogger WriteLogDebug:[NSString stringWithFormat:@"UiMyProfileTabPageView: %@", [CoreHelper ContactModelDescription:MyProfile]]];
            
            if(MyProfile)
                [ContactProfileView.ViewModel setContactData:MyProfile];
        };
        
        [[AppManager app].UserSession GetMyProfile:Callback];
    }
}


@end
