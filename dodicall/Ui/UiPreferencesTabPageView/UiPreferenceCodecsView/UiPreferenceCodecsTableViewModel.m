//
//  UiPreferenceCodecsTableViewModel.m
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

#import "UiPreferenceCodecsTableViewModel.h"
#import "AppManager.h"

@implementation UiPreferenceCodecsTableViewModel

- (instancetype)init
{
    self = [super init];
    if (self) {
        
        self.Data = [[NSMutableArray alloc] init];
        
        
        NSMutableArray *AudioWiFiCodecs = [[NSMutableArray alloc] init];
        NSMutableArray *AudioCellCodecs = [[NSMutableArray alloc] init];
        NSMutableArray *VideoCodecs = [[NSMutableArray alloc] init];
        
        int Index = 0;
        for (CodecSettingModel *SettingsObj in /*[AppManager app].TempCodecs*/ [AppManager app].DeviceSettingsModel.CodecSettings) {
            
            UiPreferenceCodecsTableCellViewModel *CellModel = [[UiPreferenceCodecsTableCellViewModel alloc] init];
            
            [CellModel setModelIndex:Index];
            [CellModel setEnabled:[SettingsObj.Enabled boolValue]];
            [CellModel setCodecName:SettingsObj.Name];
            
            if(SettingsObj.Type == CodecTypeAudio && SettingsObj.ConnectionType == ConnectionTypeWifi)
            {
                [AudioWiFiCodecs addObject:CellModel];
            }
            
            if(SettingsObj.Type == CodecTypeAudio && SettingsObj.ConnectionType == ConnectionTypeCell)
            {
                [AudioCellCodecs addObject:CellModel];
            }
            
            if(SettingsObj.Type == CodecTypeVideo)
            {
                [VideoCodecs addObject:CellModel];
            }
            
            RACChannelTo(SettingsObj,Enabled) = RACChannelTo(CellModel, Enabled);
            
             
            Index++;
            
            NSLog([NSString stringWithFormat:@"codec - %i",SettingsObj.Type]);
            
        }
        
        [self.Data addObject:AudioWiFiCodecs];
        [self.Data addObject:AudioCellCodecs];
        [self.Data addObject:VideoCodecs];
        
        self.SectionItemModels = [[NSMutableArray alloc] init];
        [self.SectionItemModels addObject:NSLocalizedString(@"Title_CodecsAudioWiFi", nil)];
        [self.SectionItemModels addObject:NSLocalizedString(@"Title_CodecsAudioCell", nil)];
        [self.SectionItemModels addObject:NSLocalizedString(@"Title_CodecsVideo", nil)];
        
        
    }
    return self;
}

- (void) DidCellSelected:(NSString *) CellIdentifier
{

}

@end
