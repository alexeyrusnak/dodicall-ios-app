//
//  UiPreferenceStatusSetViewModel.m
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

#import "UiPreferenceStatusSetViewModel.h"
#import "UiPreferenceStatusSetTableViewModel.h"

@implementation UiPreferenceStatusSetViewModel

- (void) ExecuteSaveAction {

    [AppManager app].UserSettingsModel.UserBaseStatus = self.SetStatusTableViewModel.UiUserStatus;
    [AppManager app].UserSettingsModel.UserExtendedStatus = self.SetStatusTableViewModel.UiUserTetxStatus;
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [[AppManager app].Core SaveUserSettings:[AppManager app].UserSettingsModel];
    });
}

- (void) ExecuteCancelAction
{
    [[AppManager app] UpdateUserSettingsModel];
}

@end
