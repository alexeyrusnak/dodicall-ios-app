/*
Copyright (C) 2016, Telco Cloud Trading & Logistic Ltd
*/
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
//
//  Dodicall_Bridge+Settings.h
//  DodicallBridgeIos
//


#import "Dodicall_Bridge.h"


@interface Dodicall_Bridge (Settings)


- (ObjC_UserSettingsModel*) GetUserSettings;

- (ObjC_UserSettingsModel*) GetUserSettings:(BOOL) ShoudGetRealSettings;

- (BOOL) SaveUserSettings: (ObjC_UserSettingsModel*) settings;

- (BOOL) SaveDefaultGuiLanguage: (NSString*) lang;

- (NSString*) FormatPhone: (NSString*) phone;

@end
