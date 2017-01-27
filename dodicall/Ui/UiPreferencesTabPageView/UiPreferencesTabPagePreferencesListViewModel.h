//
//  UiPreferencesTabPagePreferencesListViewModel.h
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
#import <Foundation/Foundation.h>

@interface UiPreferencesTabPagePreferencesListViewModel : NSObject

@property NSString *BalanceTextValue;

@property NSString *StatusTextValue;

@property NSString *VoiceMailTextValue;

@property NSString *EchoNoiseReducerTextValue;

@property NSString *ChatFontSizeTextValue;

@property NSNumber *ChatFontSizeIntegerValue;

@property NSString *UiStyleTextValue;

@property NSString *UiLanguageTextValue;

@property NSString *EncryptionType;

@property NSString *WhiteListTextValue;

@property(nonatomic) BOOL AutoLoginEnabled;

@property(nonatomic) BOOL WhiteListEnabled;

@property(nonatomic) BOOL UiAnimationEnabled;

@property(nonatomic) BOOL DebugModeEnabled;

@property(nonatomic) BOOL VideoEnabled;

@property(nonatomic) NSNumber *UiLanguageSettingsEditable;

@property NSTimer *SaveUserSettingTimer;


- (void) DidCellSelected:(NSString *) Identifier;

- (void) UpdateBalance;

@end
