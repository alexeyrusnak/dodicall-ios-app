//
//  UiPreferencesTabPageViewPreferencesList.h
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

#import <UIKit/UIKit.h>
#import "UiAccordionTableView.h"
#import "UiAccordionTableSectionHeaderView.h"
#import "UiAccordionTableViewModel.h"
#import "UiAccordionTableSectionHeaderViewModel.h"
#import "UiPreferencesTabPagePreferencesListViewModel.h"

@interface UiPreferencesTabPagePreferencesListView : UiAccordionTableView

@property (nonatomic) UiPreferencesTabPagePreferencesListViewModel* PreferencesViewModel;


//Profile group

//BalanceCell
//@property (weak, nonatomic) IBOutlet UILabel *BalanceCellTitleLabel;
//@property (weak, nonatomic) IBOutlet UILabel *BalanceCellValueLabel;

//MyProfileCell
//@property (weak, nonatomic) IBOutlet UILabel *MyProfileCell;


//Common group

//StatusCell
//@property (weak, nonatomic) IBOutlet UILabel *StatusCellTitleLabel;
//@property (weak, nonatomic) IBOutlet UILabel *StatusCellValueLabel;

//AutoLoginCell
@property (weak, nonatomic) IBOutlet UILabel *AutoLoginCellTitleLabel;
@property (weak, nonatomic) IBOutlet UISwitch *AutoLoginCellEnableSwitch;

//WhiteListCell
@property (weak, nonatomic) IBOutlet UILabel *WhiteListCellTitleLabel;
@property (weak, nonatomic) IBOutlet UISwitch *WhiteListCellEnableSwitch;


//Telephony group

//SipAccountsCell
@property (weak, nonatomic) IBOutlet UILabel *SipAccountsCellTitleLabel;

//VoiceMailCell
@property (weak, nonatomic) IBOutlet UILabel *VoiceMailCellTitleLabel;
@property (weak, nonatomic) IBOutlet UILabel *VoiceMailCellValueLabel;

//EncryptionCell
@property (weak, nonatomic) IBOutlet UILabel *EncryptionCellTitleLabel;
@property (weak, nonatomic) IBOutlet UILabel *EncryptionCellValueLabel;

//VideoCell
@property (weak, nonatomic) IBOutlet UILabel *VideoCellTitleview;
@property (weak, nonatomic) IBOutlet UILabel *VideoCellCellValueLabel;

//EchoNoiseReducerCell
@property (weak, nonatomic) IBOutlet UILabel *EchoNoiseReducerCellTitleLabel;
@property (weak, nonatomic) IBOutlet UILabel *EchoNoiseReducerCellValueLabel;

//Chat group

//ChatFontSizeCell
@property (weak, nonatomic) IBOutlet UILabel *ChatFontSizeCellTitleLabel;
@property (weak, nonatomic) IBOutlet UILabel *ChatFontSizeCellValueLabel;
@property (weak, nonatomic) IBOutlet UISlider *ChatFontSizeCellValueSlider;

//ClearChatsCell
@property (weak, nonatomic) IBOutlet UILabel *ClearChatsCellTitleLabel;




//UI group

//UiStyleCell
@property (weak, nonatomic) IBOutlet UILabel *UiStyleCellTitleLabel;
@property (weak, nonatomic) IBOutlet UILabel *UiStyleCellValueLabel;

//UiLanguageCell
@property (weak, nonatomic) IBOutlet UILabel *UiLanguageCellTitleLabel;
@property (weak, nonatomic) IBOutlet UILabel *UiLanguageCellValueLabel;

//UiAnimationCell
@property (weak, nonatomic) IBOutlet UILabel *UiAnimationCellTitleValue;
@property (weak, nonatomic) IBOutlet UISwitch *UiAnimationEnableSwitch;

//Debug group

//DebugModeCell
@property (weak, nonatomic) IBOutlet UILabel *DebugModeCellTitleLabel;
@property (weak, nonatomic) IBOutlet UISwitch *DebugModeCellEnableSwitch;

//CodecsCell
@property (weak, nonatomic) IBOutlet UILabel *CodecsCell;

//CallLogCell
@property (weak, nonatomic) IBOutlet UILabel *CallLogCellTitleLabel;

//HistoryLogCell
@property (weak, nonatomic) IBOutlet UILabel *HistoryLogCellTitleLabel;

//QualityLogCell
@property (weak, nonatomic) IBOutlet UILabel *QualityLogCellTitleLabel;

//ChatLogCell
@property (weak, nonatomic) IBOutlet UILabel *ChatLogCellTitleLabel;

//DbLogCell
@property (weak, nonatomic) IBOutlet UILabel *DbLogCellTitleLabel;

//ServerLogCell
@property (weak, nonatomic) IBOutlet UILabel *ServerLogCellTitleLabel;

//TraceLogCell
@property (weak, nonatomic) IBOutlet UILabel *TraceLogCellTitleLabel;

//SendIssueCell
@property (weak, nonatomic) IBOutlet UILabel *SendIssueCellTitleLabel;


























@end
