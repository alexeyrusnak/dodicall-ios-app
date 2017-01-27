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
//  ObjC_UserSettingsModel.h
//
//

#import <Foundation/Foundation.h>

@interface ObjC_AreaInfo : NSObject {
};
    @property NSString *Url;
    @property NSString *AccUrl;
    @property NSString *NameEn;
    @property NSString *NameRu;
    @property NSString *Reg;
    @property NSString *ForgotPwd;
@end

typedef enum {
    BaseUserStatusOffline = 0,
    BaseUserStatusOnline,
    BaseUserStatusHidden,
    BaseUserStatusAway,
    BaseUserStatusDnd
} BaseUserStatus;

typedef enum {
    VideoSizeQvga = 1,
    VideoSizeVga,
    VideoSize720p
} VideoSize;

typedef enum {
    EchoCancellationModeOff = 0,
    EchoCancellationModeSoft,
    EchoCancellationModeHard
} EchoCancellationMode;

typedef enum {
    VoipEncryptionNone,
    VoipEncryptionSrtp
} VoipEncryptionType;

@interface ObjC_UserSettingsModel : NSObject {
};

    @property NSNumber* Autologin;
    @property BaseUserStatus UserBaseStatus;
    @property NSString *UserExtendedStatus;
    @property NSNumber* DoNotDesturbMode;

    @property NSString *DefaultVoipServer;
    @property VoipEncryptionType VoipEncryption;
    @property EchoCancellationMode EchoCancellationMode;

    @property NSNumber* VideoEnabled;
    @property VideoSize VideoSizeWifi;
    @property VideoSize VideoSizeCell;

    @property NSString *GuiThemeName;
    @property NSNumber* GuiAnimation;
    @property NSString *GuiLanguage;
    @property int GuiFontSize;

    @property NSNumber* TraceMode;

@end
