//
//  UiPreferenceIssueTicketTableViewModel.m
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

#import "UiPreferenceIssueTicketTableViewModel.h"
#import "UiAlertControllerView.h"
#import "UiPreferencesTabNavRouter.h"

@implementation UiPreferenceIssueTicketTableViewModel

- (instancetype)init
{
    self = [super init];
    if (self) {
        
        self.MessageTitleText = @"";
        
        self.MessageText = @"";
        
        self.CallsLogEnabled = [NSNumber numberWithBool:YES];
        
        self.CallsHistoryLogEnabled = [NSNumber numberWithBool:YES];
        
        self.CallsQualityLogEnabled = [NSNumber numberWithBool:YES];
        
        self.ChatLogEnabled = [NSNumber numberWithBool:YES];
        
        self.DbLogEnabled = [NSNumber numberWithBool:YES];
        
        self.ServerLogEnabled = [NSNumber numberWithBool:YES];
        
        self.TraceLogEnabled = [NSNumber numberWithBool:YES];
        
        self.UiLogEnabled = [NSNumber numberWithBool:YES];
        
        self.IsSendingProcessActive = [NSNumber numberWithInt:0];
        
        @weakify(self);
        
        RAC(self, IsFormValid) = [RACSignal combineLatest:@[RACObserve(self, MessageTitleText),
                                                            RACObserve(self, MessageText),
                                                            
                                                            RACObserve(self, CallsLogEnabled),
                                                            RACObserve(self, CallsHistoryLogEnabled),
                                                            RACObserve(self, CallsQualityLogEnabled),
                                                            RACObserve(self, ChatLogEnabled),
                                                            RACObserve(self, DbLogEnabled),
                                                            RACObserve(self, ServerLogEnabled),
                                                            RACObserve(self, TraceLogEnabled),
                                                            RACObserve(self, UiLogEnabled),
                                                            
                                                            
                                                            ] reduce:^()
        {
            
            @strongify(self);
            
            return [NSNumber numberWithBool: [self AreTextsValid] || [self AreSwitchesValid]];
            
        }];
        
        
    }
    return self;
}

- (BOOL) AreSwitchesValid
{
    return [self.CallsLogEnabled boolValue]
    || [self.CallsHistoryLogEnabled boolValue]
    || [self.CallsQualityLogEnabled boolValue]
    || [self.ChatLogEnabled boolValue]
    || [self.DbLogEnabled boolValue]
    || [self.ServerLogEnabled boolValue]
    || [self.TraceLogEnabled boolValue]
    || [self.UiLogEnabled boolValue];
}

- (BOOL) AreTextsValid
{
    return self.MessageTitleText.length > 0 || self.MessageText.length > 0;
}

- (void) DidCellSelected:(NSString *) CellIdentifier
{
    
}

- (void) ExecuteSendAction
{
   
    self.IsSendingProcessActive = [NSNumber numberWithInt:1];
    
    [[[AppManager app] NavRouter] ShowPageProcess];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        ObjC_LogScope * LogScope = [[ObjC_LogScope alloc] init];
        
        [LogScope setDatabaseLog:self.DbLogEnabled];
        
        [LogScope setRequestsLog:self.ServerLogEnabled];
        
        [LogScope setVoipLog:self.CallsLogEnabled];
        
        [LogScope setCallHistoryLog:self.CallsHistoryLogEnabled];
        
        [LogScope setCallQualityLog:self.CallsQualityLogEnabled];
        
        [LogScope setChatLog:self.ChatLogEnabled];
        
        [LogScope setGuiLog:self.UiLogEnabled];
        
        [LogScope setTraceLog:self.TraceLogEnabled];
        
        
        ObjC_CreateTroubleTicketResult *Result = [[AppManager app].Core SendTroubleTicket:self.MessageTitleText:self.MessageText:LogScope];
        
        
        
        dispatch_async(dispatch_get_main_queue(), ^{
            
            self.IsSendingProcessActive = [NSNumber numberWithInt:0];
            
            [[[AppManager app] NavRouter] HidePageProcess];
            
            //UIAlertView *alert;
            UiAlertControllerView* Alert = [UiAlertControllerView alertControllerWithTitle:nil
                                                                                   message:nil
                                                                            preferredStyle:UIAlertControllerStyleAlert];
            
            if([Result.Success boolValue])
            {
                
                //Clear fields
                [self setMessageTitleText:@""];
                [self setMessageText:@""];
                
                
                NSString *TitleFormat = NSLocalizedString(@"Alert_TicketCreated", nil);
                
                Alert.title = [NSString stringWithFormat:TitleFormat, Result.IssueId];
                
                UIAlertAction* OkAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault
                                                                     handler:^(UIAlertAction * action) {
                                                                         
                                                                         //[[[AppManager app] NavRouter] HidePreferenceIssueTicketView];
                                                                         
                                                                         [UiPreferencesTabNavRouter ClosePreferenceTicketView];
                                                                         
                                                                     }];
                
                [Alert addAction:OkAction];
                
                /*
                alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Alert_TicketCreated", nil)
                                                                message:nil
                                                               delegate:self
                                                      cancelButtonTitle:@"OK"
                                                      otherButtonTitles:nil];
                 */
                
                
                
            }
            else
            {
                
                Alert.title = NSLocalizedString(@"Alert_TicketNotCreated", nil);
                
                UIAlertAction* OkAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault
                                                                 handler:^(UIAlertAction * action) {}];
                
                [Alert addAction:OkAction];
                
                
                /*
                alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Alert_TicketNotCreated", nil)
                                                                message:nil
                                                               delegate:self
                                                      cancelButtonTitle:@"OK"
                                                      otherButtonTitles:nil];
                 */
            }
            
            //[alert show];
            [self.View presentViewController:Alert animated:YES completion:nil];
            
            
        });
    });
}

@end
