//
//  UiPreferenceVoipEncryptionSelectTableViewModel.m
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

#import "UiPreferenceVoipEncryptionSelectTableViewModel.h"

@implementation UiPreferenceVoipEncryptionSelectTableViewModel

@synthesize Encryption;

- (instancetype)init
{
    self = [super init];
    if (self) {
        
        RACChannelTo(self, Encryption) = RACChannelTo([AppManager app].UserSettingsModel, VoipEncryption);
        
    }
    return self;
}

- (void) DidCellSelected:(NSString *) CellIdentifier
{
    NSLog(@"DidCellSelected %@",CellIdentifier);
    
    if( [CellIdentifier isEqualToString:@"VoipEncryptionNone"] )
    {
        self.Encryption = VoipEncryptionNone;
    }
    
    if( [CellIdentifier isEqualToString:@"VoipEncryptionSrtp"] )
    {
        self.Encryption = VoipEncryptionSrtp;
    }
}

@end
