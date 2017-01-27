//
//  UiPreferencesTabPagePreferencesListViewModel.m
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

#import "UiPreferencesTabPagePreferencesListViewModel.h"
#import "AppManager.h"
#import "ContactsManager.h"
#import "CallsManager.h"

#import "UiLogger.h"

@implementation UiPreferencesTabPagePreferencesListViewModel
{
    BOOL _IsAllBinded;
}

//@synthesize BalanceTextValue;
//@synthesize StatusTextValue;
//@synthesize VoiceMailTextValue;
//@synthesize EchoNoiseReducerTextValue;
//@synthesize ChatFontSizeTextValue;
//@synthesize UiStyleTextValue;
//@synthesize UiLanguageTextValue;
//@synthesize AutoLoginEnabled;
//@synthesize WhiteListEnabled;
//@synthesize EncryptionEnabled;
//@synthesize UiAnimationEnabled;
//@synthesize DebugModeEnabled;


- (instancetype)init
{
    self = [super init];
    if (self) {
        
        
        
        self.BalanceTextValue = @"0 р.";
        self.StatusTextValue = @"в сети";
        self.VoiceMailTextValue = @"0 / 0";
        self.EchoNoiseReducerTextValue = @"выкл";
        //self.ChatFontSizeTextValue = @"15";
        self.UiStyleTextValue = @"по умолчанию";
        self.UiLanguageTextValue = @"русский";
        
        
        //self.AutoLoginEnabled = FALSE;
        //self.WhiteListEnabled = FALSE;
        //self.EncryptionEnabled = TRUE;
        //self.UiAnimationEnabled = TRUE;
        //self.DebugModeEnabled = TRUE;
        
        
        
        
        //self.EncryptionEnabled = TRUE;
        //self.UiAnimationEnabled = TRUE;
        //self.DebugModeEnabled = TRUE;
        
        [self BindAll];
        
        
    }
    return self;
}

- (void) BindAll
{
    
    if(_IsAllBinded)
        return;
    
    // Bind autologin
    RACSignal *AutologinSignal = [RACObserve([AppManager app].UserSettingsModel, Autologin) distinctUntilChanged];
    
    @weakify(self);
    
    [AutologinSignal subscribeNext:^(id Value) {
        
        @strongify(self);
        
        //NSLog(@"AutologinSignal subscribeNext");
        self.AutoLoginEnabled = [Value boolValue];
        
    }];
    
    RACSignal *AutoLoginEnabledSignal = [RACObserve(self, AutoLoginEnabled) distinctUntilChanged];
    
    [AutoLoginEnabledSignal subscribeNext:^(id Value) {
        
        @strongify(self);
        
        //NSLog(@"AutoLoginEnabledSignal subscribeNext");
        
        [AppManager app].UserSettingsModel.Autologin = [Value boolValue] ? @YES :@NO;
        [self SaveUserSettingsModelWithDelay];
    }];
    
    /*
    RACChannelTerminal *AutoLoginTerminal = RACChannelTo([AppManager app].UserSettingsModel, Autologin);
    RACChannelTerminal *AutoLoginEnabledTerminal = RACChannelTo(self, AutoLoginEnabled);
    
    [AutoLoginTerminal subscribe:AutoLoginEnabledTerminal];
    [AutoLoginEnabledTerminal subscribe:AutoLoginTerminal];
    [AutoLoginEnabledTerminal subscribeNext:^(id Value) {
        
        NSLog(@"Save UserSettingsModel here");
        [[AppManager app] SaveUserSettingsModel];
        
    }];
     */
    
    
    //Bind ui language
    RAC(self, UiLanguageTextValue) = RACObserve([AppManager app].UserSettingsModel, GuiLanguage);
    RAC(self, UiLanguageSettingsEditable) = [RACObserve([CallsManager Manager], CurrentCall) map:^id(id value) {
        return value ? @NO :@YES;
    }];
    
    
    // Bind status text value
    RAC(self, StatusTextValue) = [RACObserve([AppManager app].UserSettingsModel, UserBaseStatus) map:^id(NSNumber *Status) {
        
        if([Status intValue] == BaseUserStatusOnline)
            return @"ONLINE";
        
        if([Status intValue] == BaseUserStatusOffline)
            return @"OFFLINE";
        
        if([Status intValue] == BaseUserStatusAway)
            return @"AWAY";
        
        if([Status intValue] == BaseUserStatusDnd)
            return @"DND";
        
        if([Status intValue] == BaseUserStatusHidden)
            return @"INVISIBLE";
        
        return @"";
        
    }];
    
    
    // Bind Encryption text value
    RAC(self, EncryptionType) = [RACObserve([AppManager app].UserSettingsModel, VoipEncryption) map:^id(NSNumber *Status) {
        
        if([Status intValue] == VoipEncryptionNone)
            return @"title_VoipEncryptionNone";
        
        if([Status intValue] == VoipEncryptionSrtp)
            return @"title_VoipEncryptionSrtp";
        
        return @"";
        
    }];
    
    // Bind white list
    RACSignal *DoNotDesturbModeSignal = [RACObserve([AppManager app].UserSettingsModel, DoNotDesturbMode) distinctUntilChanged];
    
    [DoNotDesturbModeSignal subscribeNext:^(id Value) {
        
        @strongify(self);
        
        self.WhiteListEnabled = [Value boolValue];
        
    }];
    
    
    RACSignal *WhiteListEnabledSignal = [RACObserve(self, WhiteListEnabled) distinctUntilChanged];
    
    [WhiteListEnabledSignal subscribeNext:^(id Value) {
        
        @strongify(self);
        
        [AppManager app].UserSettingsModel.DoNotDesturbMode = [Value boolValue] ? @YES :@NO;
        [self SaveUserSettingsModelWithDelay];
    }];
    
    
    /*
    RACChannelTerminal *DoNotDesturbModeTerminal = RACChannelTo([AppManager app].UserSettingsModel, DoNotDesturbMode);
    RACChannelTerminal *WhiteListEnabledTerminal = RACChannelTo(self, WhiteListEnabled);
    
    [DoNotDesturbModeTerminal subscribe:WhiteListEnabledTerminal];
    [WhiteListEnabledTerminal subscribe:DoNotDesturbModeTerminal];
    [WhiteListEnabledTerminal subscribeNext:^(id value) {
        
        NSLog(@"Save UserSettingsModel here");
        [[AppManager app] SaveUserSettingsModel];
        
    }];
    */
    
    // Bind EchoNoiseReducerTextValue
    RAC(self, EchoNoiseReducerTextValue) = [RACObserve([AppManager app].UserSettingsModel, EchoCancellationMode) map:^id(NSNumber *Status) {
        
        if([Status intValue] == EchoCancellationModeOff)
            return @"EchoCancellationModeOff";
        
        if([Status intValue] == EchoCancellationModeSoft)
            return @"EchoCancellationModeSoft";
        
        if([Status intValue] == EchoCancellationModeHard)
            return @"EchoCancellationModeHard";
        
        return @"";
        
    }];
    
    
    // Bind video enabled
    //RAC(self, VideoEnabled) = RACObserve([AppManager app].UserSettingsModel, VideoEnabled);
    RACSignal *VideoEnablednSignal = [RACObserve([AppManager app].UserSettingsModel, VideoEnabled) distinctUntilChanged];
    
    [VideoEnablednSignal subscribeNext:^(id Value) {
        
        @strongify(self);
        
        //NSLog(@"VideoEnablednSignal subscribeNext");
        self.VideoEnabled = [Value boolValue];
        
    }];
    
    // Animation enabled
    RACSignal *GuiAnimationSignal = [RACObserve([AppManager app].UserSettingsModel, GuiAnimation) distinctUntilChanged];
    
    [GuiAnimationSignal subscribeNext:^(id Value) {
        
        @strongify(self);
        
        //NSLog(@"GuiAnimationSignal subscribeNext");
        self.UiAnimationEnabled = [Value boolValue];
        
    }];
    
    RACSignal *UiAnimationEnabledSignal = [RACObserve(self, UiAnimationEnabled) distinctUntilChanged];
    
    [UiAnimationEnabledSignal subscribeNext:^(id Value) {
        
        @strongify(self);
        
        //NSLog(@"UiAnimationEnabledSignal subscribeNext");
        
        [AppManager app].UserSettingsModel.GuiAnimation = [Value boolValue] ? @YES :@NO;
        [self SaveUserSettingsModelWithDelay];
    }];
    /*
    RACChannelTerminal *GuiAnimationTerminal = RACChannelTo([AppManager app].UserSettingsModel, GuiAnimation);
    RACChannelTerminal *UiAnimationEnabledTerminal = RACChannelTo(self, UiAnimationEnabled);
    
    [GuiAnimationTerminal subscribe:UiAnimationEnabledTerminal];
    [UiAnimationEnabledTerminal subscribe:GuiAnimationTerminal];
    [UiAnimationEnabledTerminal subscribeNext:^(id value) {
        
        NSLog(@"Save UserSettingsModel here");
        [[AppManager app] SaveUserSettingsModel];
        
    }];
    */
    
    // Bind UiStyleTextValue
    RAC(self, UiStyleTextValue) = [RACObserve([AppManager app].UserSettingsModel, GuiThemeName) map:^id(NSString *Style) {
        
        if([Style isEqualToString:UiStyleDefault])
            return @"title_UiStyleDefault";
        
        if([Style isEqualToString:UiStyleBright])
            return @"title_UiStyleBright";
        
        return @"";
        
    }];
    
    
    // Debug mode enabled
    RACSignal *TraceModeSignal = [RACObserve([AppManager app].UserSettingsModel, TraceMode) distinctUntilChanged];
    
    [TraceModeSignal subscribeNext:^(id Value) {
        
        @strongify(self);
        
        //NSLog(@"TraceModeSignal subscribeNext");
        self.DebugModeEnabled = [Value boolValue];
        
    }];
    
    RACSignal *DebugModeEnabledSignal = [RACObserve(self, DebugModeEnabled) distinctUntilChanged];
    
    [DebugModeEnabledSignal subscribeNext:^(id Value) {
        
        @strongify(self);
        
        //NSLog(@"DebugModeEnabledSignal subscribeNext");
        
        [AppManager app].UserSettingsModel.TraceMode = [Value boolValue] ? @YES :@NO;
        [self SaveUserSettingsModelWithDelay];
    }];
    /*
    RACChannelTerminal *TraceModeTerminal = RACChannelTo([AppManager app].UserSettingsModel, TraceMode);
    RACChannelTerminal *DebugModeEnabledTerminal = RACChannelTo(self, DebugModeEnabled);
    
    [TraceModeTerminal subscribe:DebugModeEnabledTerminal];
    [DebugModeEnabledTerminal subscribe:TraceModeTerminal];
    [DebugModeEnabledTerminal subscribeNext:^(id value) {
        
        NSLog(@"Save UserSettingsModel here");
        [[AppManager app] SaveUserSettingsModel];
        
    }];
    */
    
    
    // Chat font size
    RAC(self, ChatFontSizeTextValue) = [RACObserve([AppManager app].UserSettingsModel, GuiFontSize) map:^id(NSNumber *Value) {
        
        return [NSString stringWithFormat:@"%@", Value];
        
    }];
    
    RACChannelTerminal *GuiFontSizeTerminal = RACChannelTo([AppManager app].UserSettingsModel, GuiFontSize);
    RACChannelTerminal *ChatFontSizeTerminal = RACChannelTo(self, ChatFontSizeIntegerValue);
    
    
    [GuiFontSizeTerminal subscribe:ChatFontSizeTerminal];
    [ChatFontSizeTerminal subscribeNext:^(NSNumber *Value) {
        
        @strongify(self);
        
        if(Value)
        {
            [AppManager app].UserSettingsModel.GuiFontSize = [Value intValue];
            
            [self SaveUserSettingsModelWithDelay];

        }
        
        
    }];
    
    [RACObserve([AppManager app].UserSession, BalanceString) subscribeNext:^(NSString *BalanceString) {
        
        @strongify(self);
        
        [self setBalanceTextValue:BalanceString];
        
    }];
    
    [RACObserve([ContactsManager Contacts], WhiteContactsCounter) subscribeNext:^(NSNumber *Count) {
        
        @strongify(self);
        
        NSString *CountString = [NSString stringWithFormat:NSLocalizedString(@"Title_%@OfContacts", nil),Count];
        
        if([Count intValue] == 1)
            CountString = [NSString stringWithFormat:NSLocalizedString(@"Title_%@_one_OfContacts", nil),Count];
        
        if([Count intValue] > 1 && [Count intValue] < 5)
            CountString = [NSString stringWithFormat:NSLocalizedString(@"Title_%@_less_then_5_OfContacts", nil),Count];
            
        
        [self setWhiteListTextValue:[NSString stringWithFormat:NSLocalizedString(@"Title_WhiteList(%@)", nil),CountString]];
        
    }];
    
    _IsAllBinded = TRUE;
    
}

- (void) DidCellSelected:(NSString *) CellIdentifier
{
    
    [UiLogger WriteLogInfo:[NSString stringWithFormat:@"UiPreferencesTabPagePreferencesListViewModel:DidCellSelected:%@",CellIdentifier]];
    
    
    if( [CellIdentifier isEqualToString:@"BalanceCell"] )
    {
        
    }
    
    else if( [CellIdentifier isEqualToString:@"ProfileCell"] )
    {

    }
    
    else if( [CellIdentifier isEqualToString:@"UiLanguageCell"] )
    {
        //[[[AppManager app] NavRouter] ShowPreferenceLanguageSelectView];
    }
    
    else if( [CellIdentifier isEqualToString:@"StatusCell"] )
    {
        //[[[AppManager app] NavRouter] ShowPreferenceStatusSetView];
    }

    else if( [CellIdentifier isEqualToString:@"SipAccountsCell"] )
    {
        //[[[AppManager app] NavRouter] ShowPreferenceSipAccountsView];
    }
    
    else if( [CellIdentifier isEqualToString:@"VideoCell"] )
    {
        //[[[AppManager app] NavRouter] ShowPreferenceVideoSetsView];
    }
    
    else if( [CellIdentifier isEqualToString:@"EncryptionCell"] )
    {
        //[[[AppManager app] NavRouter] ShowPreferenceVoipEncryptionSelectView];
    }
    
    else if( [CellIdentifier isEqualToString:@"AutoLoginCell"] )
    {
        // Nothing to do
    }
    
    else if( [CellIdentifier isEqualToString:@"WhiteListCel"] )
    {
        // Nothing to do
    }
    
    else if( [CellIdentifier isEqualToString:@"UiAnimationCell"] )
    {
        // Nothing to do
    }
    
    else if( [CellIdentifier isEqualToString:@"DebugModeCell"] )
    {
        // Nothing to do
    }
    
    else if( [CellIdentifier isEqualToString:@"EchoNoiseReducerCell"] )
    {
        //[[[AppManager app] NavRouter] ShowPreferenceEchoCancellationSelectView];
    }
    
    else if( [CellIdentifier isEqualToString:@"UiStyleCell"] )
    {
        //[[[AppManager app] NavRouter] ShowPreferenceUiStyleSelectView];
    }
    
    else if( [CellIdentifier isEqualToString:@"ChatFontSizeCell"] )
    {
        // Nothing to do
    }
    
    else if( [CellIdentifier isEqualToString:@"AboutCell"] )
    {
        //[[[AppManager app] NavRouter] ShowPreferenceWebView:NSLocalizedString(@"Url_UiInfoAbout", nil) withTitle:NSLocalizedString(@"Title_UiInfoAbout", nil)];
    }
    
    else if( [CellIdentifier isEqualToString:@"WhatsNewCell"] )
    {
        //[[[AppManager app] NavRouter] ShowPreferenceWebView:NSLocalizedString(@"Url_UiInfoWhatsNew", nil) withTitle:NSLocalizedString(@"Title_UiInfoWhatsNew", nil)];
    }
    
    else if( [CellIdentifier isEqualToString:@"KnownProblemsCell"] )
    {
        //[[[AppManager app] NavRouter] ShowPreferenceWebView:NSLocalizedString(@"Url_UiInfoKnownBugs", nil) withTitle:NSLocalizedString(@"Title_UiInfoKnownBugs", nil)];
    }
    
    else if( [CellIdentifier isEqualToString:@"HelpCell"] )
    {
        //[[[AppManager app] NavRouter] ShowPreferenceWebView:NSLocalizedString(@"Url_UiInfoHelp", nil) withTitle:NSLocalizedString(@"Title_UiInfoHelp", nil)];
    }
    
    else if( [CellIdentifier isEqualToString:@"CodecsCell"] )
    {
        //[[[AppManager app] NavRouter] ShowPreferenceCodecsView];
    }
    
    else if( [CellIdentifier isEqualToString:@"CallsLogCell"] )
    {
        //[self ShowLog:@"CallsLog"];
    }
    
    /*
    else if( [CellIdentifier isEqualToString:@"CallsHistoryLogCell"] )
    {
        NSString * DataHtml = @"<h3 style=\"text-align:center;\">Лог истории звонков</h3><p style=\"text-align:center;\">Coming soon...</p>";
        
        [[[AppManager app] NavRouter] ShowPreferenceWebViewWithHtmlData:DataHtml withTitle:NSLocalizedString(@"Title_CallsHistoryLog", nil)];
    }
    
    else if( [CellIdentifier isEqualToString:@"CallsQualityLogCell"] )
    {
        NSString * DataHtml = @"<h3 style=\"text-align:center;\">Лог качества звонков</h3><p style=\"text-align:center;\">Coming soon...</p>";
        
        [[[AppManager app] NavRouter] ShowPreferenceWebViewWithHtmlData:DataHtml withTitle:NSLocalizedString(@"Title_CallsQualityLog", nil)];
        
    }
    */
    
    else if( [CellIdentifier isEqualToString:@"ChatLogCell"] )
    {
        
        //[self ShowLog:@"ChatLog"];
    }
    
    else if( [CellIdentifier isEqualToString:@"DbLogCell"] )
    {
        
        //[self ShowLog:@"DbLog"];
        
    }
    
    else if( [CellIdentifier isEqualToString:@"UiLogCell"] )
    {
        
        //[self ShowLog:@"UiLog"];
        
    }
    
    else if( [CellIdentifier isEqualToString:@"ServerLogCell"] )
    {
        //[self ShowLog:@"ServerLog"];
    }
    
    else if( [CellIdentifier isEqualToString:@"SendIssueCell"] )
    {
        //[[[AppManager app] NavRouter] ShowPreferenceIssueTicketView];
    }
    
    else if( [CellIdentifier isEqualToString:@"ClearLogsCell"] )
    {
        [self ClearAllLogs];
    }
    
    else
    {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Coming soon..."
                                                        message:nil
                                                       delegate:self
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
        [alert show];
    }
    
}

- (void) SaveUserSettingsModelWithDelay
{
    if(self.SaveUserSettingTimer)
        [self.SaveUserSettingTimer invalidate];
    
    self.SaveUserSettingTimer = [NSTimer scheduledTimerWithTimeInterval:0.3
                                                                 target:[AppManager app]
                                                               selector:@selector(SaveUserSettingsModel)
                                                               userInfo:nil
                                                                repeats:NO];
}

/*
- (void) ShowLog:(NSString *) LogName
{
    
    
    [[[AppManager app] NavRouter] ShowPageProcess];
    
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        
        NSMutableArray *LogArray = [[NSMutableArray alloc] init];
        
        BOOL LogFetchResult = NO;
        
        
        if([LogName isEqualToString:@"DbLog"])
            LogFetchResult = [[AppManager app].Core GetDatabaseLog:LogArray];
        
        if([LogName isEqualToString:@"ServerLog"])
            LogFetchResult = [[AppManager app].Core GetRequestsLog:LogArray];
        
        if([LogName isEqualToString:@"ChatLog"])
            LogFetchResult = [[AppManager app].Core GetChatLog:LogArray];
        
        if([LogName isEqualToString:@"CallsLog"])
            LogFetchResult = [[AppManager app].Core GetVoipLog:LogArray];
        
        if([LogName isEqualToString:@"UiLog"])
            LogFetchResult = [[AppManager app].Core GetGuiLog:LogArray];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            
            [[[AppManager app] NavRouter] HidePageProcess];
            
            NSString * DataHtml = @"<div style=\"width:100%; padding:15px; box-sizing:border-box; font-size:12px; overflow-x: hidden; white-space: normal;\"><div style=\"overflow-x: hidden;\">";
            
            if(LogFetchResult && [LogArray count] > 0)
            {
                
                for (NSString *LogString in LogArray) {
                    
                    NSString *_LogString = [LogString stringByReplacingOccurrencesOfString:@"<" withString:@"&lt;"];
                    
                    _LogString = [_LogString stringByReplacingOccurrencesOfString:@">" withString:@"&gt;"];
                    
                    DataHtml = [DataHtml stringByAppendingString:[NSString stringWithFormat:@"<p>%@</p>",_LogString]];
                     //NSLog(LogString);
                    
                }
            }
            
            DataHtml = [DataHtml stringByAppendingString:@"</div></div>"];
            
            NSString *LogTitle = [NSString stringWithFormat:@"Title_%@",LogName];
            
            [[[AppManager app] NavRouter] ShowPreferenceWebViewWithHtmlData:DataHtml withTitle:NSLocalizedString(LogTitle, nil)];
            
        });
    });
    
}
*/

- (void) ClearAllLogs
{
    
    
    [[[AppManager app] NavRouter] ShowPageProcess];
    
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        
        [[AppManager app].Core ClearLogs];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            
            [[[AppManager app] NavRouter] HidePageProcess];
            
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Alert_AllLogsCleared", nil)
                                                            message:nil
                                                           delegate:self
                                                  cancelButtonTitle:@"OK"
                                                  otherButtonTitles:nil];
            [alert show];
            
        });
    });
    
}


- (void) UpdateBalance
{
    [[AppManager app].UserSession UpdateBalance];
}

@end
