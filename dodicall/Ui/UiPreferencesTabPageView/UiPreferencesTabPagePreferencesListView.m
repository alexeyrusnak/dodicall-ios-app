//
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

#import "UiPreferencesTabPagePreferencesListView.h"
#import <ReactiveCocoa/ReactiveCocoa.h>
#import "UiPreferencesTabNavRouter.h"
#import "AppManager.h"

@interface UiPreferencesTabPagePreferencesListView ()

@end

@implementation UiPreferencesTabPagePreferencesListView

{
    BOOL _IsAllBinded;
}

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        
        self.PreferencesViewModel =  [[UiPreferencesTabPagePreferencesListViewModel alloc] init];
        
        
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self BindAll];
}

- (void) BindAll
{
    
    if(_IsAllBinded)
        return;
    
    //@weakify(self);
    
    //RAC(self.BalanceCellValueLabel, text) = RACObserve(self.PreferencesViewModel, BalanceTextValue);
    
    //RACSignal *StatusCellValueLabelSignal = RACObserve(self.PreferencesViewModel, StatusTextValue);
    /*
    RAC(self.StatusCellValueLabel, text) = [StatusCellValueLabelSignal map:^id(NSString *StatusString) {
        return NSLocalizedString(([NSString stringWithFormat:@"title_%@", StatusString]),nil);
    }];
     */
    
    /*
    [RACObserve(self.PreferencesViewModel, StatusTextValue) subscribeNext:^(NSString *StatusString) {
        
        dispatch_async(dispatch_get_main_queue(), ^{
            
            @strongify(self);
            
            [self.StatusCellValueLabel setText:NSLocalizedString(([NSString stringWithFormat:@"title_%@", StatusString]),nil)];
            
        });
        
    }];
     */
    
    RACSignal *VoipEncryptionSignal = RACObserve(self.PreferencesViewModel, EncryptionType);
    RAC(self.EncryptionCellValueLabel, text) = [[VoipEncryptionSignal deliverOnMainThread] map:^id(NSString *EncryptionTypeString) {
        return NSLocalizedString(([NSString stringWithFormat:@"%@", EncryptionTypeString]),nil);
    }];
    
    
    RACSignal *VideoCellCellValueLabelSignal = RACObserve(self.PreferencesViewModel, VideoEnabled);
    RAC(self.VideoCellCellValueLabel, text) = [[VideoCellCellValueLabelSignal deliverOnMainThread] map:^id(NSNumber *VideoEnabled) {
        return NSLocalizedString(([NSString stringWithFormat:@"title_%@", [VideoEnabled boolValue] == TRUE ? @"On" : @"Off"]),nil);
    }];
    
    
    RAC(self.VoiceMailCellValueLabel, text) = [RACObserve(self.PreferencesViewModel, VoiceMailTextValue) deliverOnMainThread];
    
    RAC(self.EchoNoiseReducerCellValueLabel, text) = [[RACObserve(self.PreferencesViewModel, EchoNoiseReducerTextValue) deliverOnMainThread] map:^id(NSString *ModeString) {
        return NSLocalizedString(([NSString stringWithFormat:@"title_%@", ModeString]),nil);
    }];
    
    // Font size
    RAC(self.ChatFontSizeCellValueLabel, text) = [RACObserve(self.PreferencesViewModel, ChatFontSizeTextValue) deliverOnMainThread];
    
    
    
    RAC(self.ChatFontSizeCellValueSlider, value) = [RACObserve(self.PreferencesViewModel, ChatFontSizeIntegerValue) deliverOnMainThread];
    RAC(self.PreferencesViewModel, ChatFontSizeIntegerValue) = [self.ChatFontSizeCellValueSlider rac_newValueChannelWithNilValue:@11];
    
    
    
    RAC(self.UiStyleCellValueLabel, text) = [[RACObserve(self.PreferencesViewModel, UiStyleTextValue) deliverOnMainThread] map:^id(NSString *Style) {
        return NSLocalizedString(Style,nil);
    }];
    
    RACSignal *UiLanguageCellValueLabeSignal = RACObserve(self.PreferencesViewModel, UiLanguageTextValue);
    RAC(self.UiLanguageCellValueLabel, text) = [[UiLanguageCellValueLabeSignal deliverOnMainThread] map:^id(NSString *UiLanguageString) {
        return NSLocalizedString(([NSString stringWithFormat:@"title_%@_lang", UiLanguageString]),nil);
    }];
    
    RAC(self.AutoLoginCellEnableSwitch, on) = [RACObserve(self.PreferencesViewModel, AutoLoginEnabled) deliverOnMainThread];
    RAC(self.PreferencesViewModel, AutoLoginEnabled) = self.AutoLoginCellEnableSwitch.rac_newOnChannel;
    
    RAC(self.WhiteListCellEnableSwitch, on) = [RACObserve(self.PreferencesViewModel, WhiteListEnabled) deliverOnMainThread];
    RAC(self.PreferencesViewModel, WhiteListEnabled) = self.WhiteListCellEnableSwitch.rac_newOnChannel;
    
    RAC(self.WhiteListCellTitleLabel, text) = [RACObserve(self.PreferencesViewModel, WhiteListTextValue) deliverOnMainThread];

    RAC(self.UiAnimationEnableSwitch, on) = [RACObserve(self.PreferencesViewModel, UiAnimationEnabled) deliverOnMainThread];
    RAC(self.PreferencesViewModel, UiAnimationEnabled) = self.UiAnimationEnableSwitch.rac_newOnChannel;
    
    RAC(self.DebugModeCellEnableSwitch, on) = [RACObserve(self.PreferencesViewModel, DebugModeEnabled) deliverOnMainThread];
    RAC(self.PreferencesViewModel, DebugModeEnabled) = self.DebugModeCellEnableSwitch.rac_newOnChannel;
    @weakify(self);
    [[[[RACObserve(self.PreferencesViewModel, DebugModeEnabled) skip:1] distinctUntilChanged] deliverOnMainThread] subscribeNext:^(NSNumber *Enabled) {
        
        @strongify(self);
        
        if([Enabled boolValue])
            [self ShowDebugModeAlert];
        
    }];
    
    _IsAllBinded = TRUE;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    
    if( [cell.reuseIdentifier isEqualToString:@"ProfileCell"] )
    {
        
        [self ShowMyProfile];
    }
    
    else if( [cell.reuseIdentifier isEqualToString:@"BalanceCell"] )
    {
        
        [[[AppManager app] NavRouter] OpenUrlInExternalBrowser:[[AppManager app].UserSession GetBalanceInfoUrl]];
    }
    
    else if( [cell.reuseIdentifier isEqualToString:@"AboutCell"] )
    {
        
        NSMutableDictionary *Params = [[NSMutableDictionary alloc] init];
        
        [Params setObject:NSLocalizedString(@"Url_UiInfoAbout", nil) forKey:@"Url"];
        
        [Params setObject:NSLocalizedString(@"Title_UiInfoAbout", nil) forKey:@"Title"];
        
        [self performSegueWithIdentifier:UiPreferencesTabNavRouterWebView sender:Params];
    }
    
    else if( [cell.reuseIdentifier isEqualToString:@"WhatsNewCell"] )
    {
        NSMutableDictionary *Params = [[NSMutableDictionary alloc] init];
        
        [Params setObject:NSLocalizedString(@"Url_UiInfoWhatsNew", nil) forKey:@"Url"];
        
        [Params setObject:NSLocalizedString(@"Title_UiInfoWhatsNew", nil) forKey:@"Title"];
        
        [self performSegueWithIdentifier:UiPreferencesTabNavRouterWebView sender:Params];
    }
    
    else if( [cell.reuseIdentifier isEqualToString:@"KnownProblemsCell"] )
    {
        NSMutableDictionary *Params = [[NSMutableDictionary alloc] init];
        
        [Params setObject:NSLocalizedString(@"Url_UiInfoKnownBugs", nil) forKey:@"Url"];
        
        [Params setObject:NSLocalizedString(@"Title_UiInfoKnownBugs", nil) forKey:@"Title"];
        
        [self performSegueWithIdentifier:UiPreferencesTabNavRouterWebView sender:Params];
    }
    
    else if( [cell.reuseIdentifier isEqualToString:@"HelpCell"] )
    {
        [UiNavRouter ShowComingSoon];
        
        /*
        NSMutableDictionary *Params = [[NSMutableDictionary alloc] init];
        
        [Params setObject:NSLocalizedString(@"Url_UiInfoHelp", nil) forKey:@"Url"];
        
        [Params setObject:NSLocalizedString(@"Title_UiInfoHelp", nil) forKey:@"Title"];
        
        [self performSegueWithIdentifier:UiPreferencesTabNavRouterWebView sender:Params];
         */
    }
    
    else if( [cell.reuseIdentifier isEqualToString:@"CallsHistoryLogCell"] )
    {
        [self ShowLog:@"CallsHistoryLog"];
    }
    
    else if( [cell.reuseIdentifier isEqualToString:@"CallsQualityLogCell"] )
    {
        [self ShowLog:@"CallsQualityLog"];
    }
    
    else if( [cell.reuseIdentifier isEqualToString:@"CallsLogCell"] )
    {
        [self ShowLog:@"CallsLog"];
    }
    
    else if( [cell.reuseIdentifier isEqualToString:@"ChatLogCell"] )
    {
        [self ShowLog:@"ChatLog"];
    }
    
    else if( [cell.reuseIdentifier isEqualToString:@"DbLogCell"] )
    {
        [self ShowLog:@"DbLog"];
    }
    
    else if( [cell.reuseIdentifier isEqualToString:@"UiLogCell"] )
    {
        [self ShowLog:@"UiLog"];
    }
    
    else if( [cell.reuseIdentifier isEqualToString:@"ServerLogCell"] )
    {
        [self ShowLog:@"ServerLog"];
    }
    
    else if( [cell.reuseIdentifier isEqualToString:@"TraceLogCell"] )
    {
        [self ShowLog:@"TraceLog"];
    }
    
    else
    {
        [self.PreferencesViewModel DidCellSelected:cell.reuseIdentifier];
    }
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark - Segues

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    
    [UiPreferencesTabNavRouter PrepareForSegue:segue sender:sender];
    
}

- (BOOL)shouldPerformSegueWithIdentifier:(NSString *)identifier sender:(id)sender
{
    
    if( [identifier isEqualToString:UiPreferencesTabNavRouterWebView] )
    {
        return NO;
    }
    
    else if( [identifier isEqualToString:UiPreferencesTabNavRouterMyProfile] )
    {
        return NO;
    }
    
    else if( [identifier isEqualToString:UiPreferencesTabNavRouterSeguesShowPreferenceLanguageSelectView] && ![self.PreferencesViewModel.UiLanguageSettingsEditable boolValue])
    {
        return NO;
    }
    
    else if( [identifier isEqualToString:UiPreferencesTabNavRouterSeguesShowStyleSelectView] && ![self.PreferencesViewModel.UiLanguageSettingsEditable boolValue])
    {
        return NO;
    }
    
    
    return YES;
}

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
        
        if([LogName isEqualToString:@"TraceLog"])
            LogFetchResult = [[AppManager app].Core GetTraceLog:LogArray];
        
        if([LogName isEqualToString:@"CallsQualityLog"])
            LogFetchResult = [[AppManager app].Core GetCallQualityLog:LogArray];
        
        if([LogName isEqualToString:@"CallsHistoryLog"])
            LogFetchResult = [[AppManager app].Core GetCallHistoryLog:LogArray];
        
        /*
        if([LogName isEqualToString:@"QualityLog"])
            LogFetchResult = [[AppManager app].Core GetTraceLog:LogArray];
         */
        
        dispatch_async(dispatch_get_main_queue(), ^{
            
            [[[AppManager app] NavRouter] HidePageProcess];
            
            NSString * DataHtml = @"<div style=\"width:100%; padding:15px; box-sizing:border-box; font-size:12px; overflow-x: hidden; white-space: normal;\"><div style=\"overflow-x: hidden;\">";
            
            if(LogFetchResult && [LogArray count] > 0)
            {
                
                for (NSString *LogString in LogArray) {
                    
                    NSString *_LogString = [LogString stringByReplacingOccurrencesOfString:@"<" withString:@"&lt;"];
                    
                    _LogString = [_LogString stringByReplacingOccurrencesOfString:@">" withString:@"&gt;"];
                    
                    DataHtml = [DataHtml stringByAppendingString:[NSString stringWithFormat:@"<p>%@</p>",_LogString]];
                    
                }
            }
            
            DataHtml = [DataHtml stringByAppendingString:@"</div></div>"];
            
            NSString *LogTitle = [NSString stringWithFormat:@"Title_%@",LogName];
            
            //[[[AppManager app] NavRouter] ShowPreferenceWebViewWithHtmlData:DataHtml withTitle:NSLocalizedString(LogTitle, nil)];
            
            NSMutableDictionary *Params = [[NSMutableDictionary alloc] init];
            
            [Params setObject:DataHtml forKey:@"DataHtml"];
            
            [Params setObject:NSLocalizedString(LogTitle, nil) forKey:@"Title"];
            
            [self performSegueWithIdentifier:UiPreferencesTabNavRouterWebView sender:Params];
            
        });
    });
    
}

- (void) ShowMyProfile
{
    
    /*
    [[[AppManager app] NavRouter] ShowPageProcess];
    
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        
        ObjC_ContactModel * MyProfile = [[AppManager app].Core GetAccountData];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            
            [[[AppManager app] NavRouter] HidePageProcess];
            
            [self performSegueWithIdentifier:UiPreferencesTabNavRouterMyProfile sender:MyProfile];
            
        });
    });
     */
    
    @weakify(self);
    
    void (^Callback)(ObjC_ContactModel *) = ^(ObjC_ContactModel * MyProfile)
    {
        @strongify(self);
        
        [[[AppManager app] NavRouter] HidePageProcess];
        
        [self performSegueWithIdentifier:UiPreferencesTabNavRouterMyProfile sender:MyProfile];
    };
    
    [[[AppManager app] NavRouter] ShowPageProcess];
    
    [[AppManager app].UserSession GetMyProfile:Callback];
    
}

- (void) viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [self.PreferencesViewModel UpdateBalance];
}

- (void) ShowDebugModeAlert
{
    UiAlertControllerView* alert = [UiAlertControllerView alertControllerWithTitle:nil
                                                                           message:NSLocalizedString(@"WarningAlert_DebugModeEnabled", nil)
                                                                    preferredStyle:UIAlertControllerStyleActionSheet];
    
    UIAlertAction* AddAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Title_Enable", nil) style:UIAlertActionStyleDefault
                                                      handler:^(UIAlertAction * action) {
                                                          
                                                          [self.PreferencesViewModel setDebugModeEnabled:YES];
                                                          
                                                          
                                                      }];
    
    [alert addAction:AddAction];
    
    
    UIAlertAction* cancelAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Title_Disable", nil) style:UIAlertActionStyleCancel
                                                         handler:^(UIAlertAction * action) {
                                                             
                                                             [self.PreferencesViewModel setDebugModeEnabled:NO];
                                                             
                                                         }];
    
    [alert addAction:cancelAction];
    
    [self presentViewController:alert animated:YES completion:nil];
}

@end
