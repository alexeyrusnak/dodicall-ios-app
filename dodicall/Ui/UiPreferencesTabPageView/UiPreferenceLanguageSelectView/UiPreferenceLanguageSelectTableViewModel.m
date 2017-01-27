//
//  UiPreferenceLanguageSelectTableViewModel.m
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

#import "UiPreferenceLanguageSelectTableViewModel.h"
#import "AppManager.h"

@implementation UiPreferenceLanguageSelectTableViewModel

@synthesize UiLanguage;

- (instancetype)init
{
    self = [super init];
    if (self) {
        
        //RACChannelTo(self, UiLanguage) = RACChannelTo([AppManager app].UserSettingsModel, GuiLanguage);
        
        RAC(self, UiLanguage) = [RACObserve([AppManager app].UserSettingsModel, GuiLanguage) distinctUntilChanged];
        
        //RAC([AppManager app].UserSettingsModel, GuiLanguage) = RACObserve(self, UiLanguage);
        
        [RACObserve(self, UiLanguage) subscribeNext:^(NSString *Language) {
            
            [AppManager app].UserSettingsModel.GuiLanguage = Language;
        }];
        
        
    }
    return self;
}

- (void) DidCellSelected:(NSString *) CellIdentifier
{
    NSLog(@"DidCellSelected %@",CellIdentifier);
    
    if( [CellIdentifier isEqualToString:@"UiLanguageCellRu"] )
    {
        self.UiLanguage = @"RU";
    }
    if( [CellIdentifier isEqualToString:@"UiLanguageCellEn"] )
    {
        self.UiLanguage = @"EN";
    }
    if( [CellIdentifier isEqualToString:@"UiLanguageCellTr"] )
    {
        self.UiLanguage = @"TR";
    }
    
    self.WasLanguageChanged = TRUE;
}

- (void) ExecuteBackAction
{
    if(self.WasLanguageChanged)
    {
        self.WasLanguageChanged = FALSE;
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            
            if([AppManager app].UserSession.IsUserAuthorized)
                [[AppManager app].Core SaveUserSettings:[AppManager app].UserSettingsModel];
            
            [[AppManager app].Core SaveDefaultGuiLanguage:[AppManager app].UserSettingsModel.GuiLanguage];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                
                [[AppManager app] SetUiLanguage];
                
                if(![AppManager app].UserSession.IsUserAuthorized)
                    [[[AppManager app] NavRouter] ShowLoginPage];
                else
                    [[[AppManager app] NavRouter] ShowPreferenceTabPage];
            });
            
        });
    }
}

@end
