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
//  Dodicall_Bridge+Settings.m
//  DodicallBridgeIos
//


#import "Dodicall_Bridge+Settings.h"
#import "Dodicall_Bridge+Helpers.h"


@implementation Dodicall_Bridge (Settings)


- (ObjC_UserSettingsModel*) GetUserSettings
{
    return [self GetUserSettings:YES];
}

- (ObjC_UserSettingsModel*) GetUserSettings:(BOOL) ShoudGetRealSettings
{
    dodicall::UserSettingsModel user_app_settings;
    
    if(ShoudGetRealSettings)
    {
        user_app_settings = dodicall::Application::GetInstance().GetUserSettings();
    }
    
    
    ObjC_UserSettingsModel *obj_c_user_app_settings = [[ObjC_UserSettingsModel alloc] init];
    
    switch ( user_app_settings.UserBaseStatus ) {
        case dodicall::dbmodel::BaseUserStatus::BaseUserStatusOffline:
            obj_c_user_app_settings.UserBaseStatus = BaseUserStatusOffline;
            break;
        case dodicall::dbmodel::BaseUserStatus::BaseUserStatusOnline:
            obj_c_user_app_settings.UserBaseStatus = BaseUserStatusOnline;
            break;
        case dodicall::dbmodel::BaseUserStatus::BaseUserStatusAway:
            obj_c_user_app_settings.UserBaseStatus = BaseUserStatusAway;
            break;
        case dodicall::dbmodel::BaseUserStatus::BaseUserStatusHidden:
            obj_c_user_app_settings.UserBaseStatus = BaseUserStatusHidden;
            break;
        case dodicall::dbmodel::BaseUserStatus::BaseUserStatusDnd:
            obj_c_user_app_settings.UserBaseStatus = BaseUserStatusDnd;
            break;
    }
            
            
    obj_c_user_app_settings.Autologin = [NSNumber numberWithBool: user_app_settings.Autologin? YES : NO];
    
    obj_c_user_app_settings.UserExtendedStatus = [self convert_to_obj_c_str:user_app_settings.UserExtendedStatus];
    
    obj_c_user_app_settings.DoNotDesturbMode = [NSNumber numberWithBool:user_app_settings.DoNotDesturbMode ? YES : NO];
    
    obj_c_user_app_settings.DefaultVoipServer = [self convert_to_obj_c_str:user_app_settings.DefaultVoipServer];
    
    obj_c_user_app_settings.VoipEncryption = user_app_settings.VoipEncryption == dodicall::dbmodel::VoipEncryptionType::VoipEncryptionNone ? VoipEncryptionNone : VoipEncryptionSrtp;
    
    if ( user_app_settings.EchoCancellationMode == dodicall::dbmodel::EchoCancellationMode::EchoCancellationModeOff )
        obj_c_user_app_settings.EchoCancellationMode = EchoCancellationModeOff;
    else if ( user_app_settings.EchoCancellationMode == dodicall::dbmodel::EchoCancellationMode::EchoCancellationModeSoft )
        obj_c_user_app_settings.EchoCancellationMode = EchoCancellationModeSoft;
    else if ( user_app_settings.EchoCancellationMode == dodicall::dbmodel::EchoCancellationMode::EchoCancellationModeHard )
        obj_c_user_app_settings.EchoCancellationMode = EchoCancellationModeHard;
    
    obj_c_user_app_settings.VideoEnabled = [NSNumber numberWithBool: user_app_settings.VideoEnabled ? YES : NO];
    
    
    if ( user_app_settings.VideoSizeWifi == dodicall::dbmodel::VideoSize::VideoSizeQvga )
        obj_c_user_app_settings.VideoSizeWifi = VideoSizeQvga;
    else if ( user_app_settings.VideoSizeWifi == dodicall::dbmodel::VideoSize::VideoSizeVga )
        obj_c_user_app_settings.VideoSizeWifi = VideoSizeVga;
    else if ( user_app_settings.VideoSizeWifi == dodicall::dbmodel::VideoSize::VideoSize720p )
        obj_c_user_app_settings.VideoSizeWifi = VideoSize720p;
    
    if ( user_app_settings.VideoSizeCell == dodicall::dbmodel::VideoSize::VideoSizeQvga )
        obj_c_user_app_settings.VideoSizeCell = VideoSizeQvga;
    else if ( user_app_settings.VideoSizeCell == dodicall::dbmodel::VideoSize::VideoSizeVga )
        obj_c_user_app_settings.VideoSizeCell = VideoSizeVga;
    else if ( user_app_settings.VideoSizeCell == dodicall::dbmodel::VideoSize::VideoSize720p )
        obj_c_user_app_settings.VideoSizeCell = VideoSize720p;
    
    obj_c_user_app_settings.GuiThemeName = [self convert_to_obj_c_str:user_app_settings.GuiThemeName];
    
    obj_c_user_app_settings.GuiAnimation = [NSNumber numberWithBool: user_app_settings.GuiAnimation ? YES : NO];
    
    obj_c_user_app_settings.GuiLanguage = [self convert_to_obj_c_str:user_app_settings.GuiLanguage];
    
    obj_c_user_app_settings.GuiFontSize = user_app_settings.GuiFontSize;
    
    obj_c_user_app_settings.TraceMode = [NSNumber numberWithBool: user_app_settings.TraceMode ? YES : NO];
    
    return obj_c_user_app_settings;
}

- (BOOL) SaveUserSettings: (ObjC_UserSettingsModel*) settings {
    dodicall::UserSettingsModel user_settings;
    
    switch ( settings.UserBaseStatus ) {
        case BaseUserStatusOffline:
            user_settings.UserBaseStatus = dodicall::dbmodel::BaseUserStatus::BaseUserStatusOffline;
            break;
        case BaseUserStatusOnline:
            user_settings.UserBaseStatus = dodicall::dbmodel::BaseUserStatus::BaseUserStatusOnline;
            break;
        case BaseUserStatusAway:
            user_settings.UserBaseStatus = dodicall::dbmodel::BaseUserStatus::BaseUserStatusAway;
            break;
        case BaseUserStatusHidden:
            user_settings.UserBaseStatus = dodicall::dbmodel::BaseUserStatus::BaseUserStatusHidden;
            break;
        case BaseUserStatusDnd:
            user_settings.UserBaseStatus = dodicall::dbmodel::BaseUserStatus::BaseUserStatusDnd;
            break;
    }
    
    user_settings.Autologin = [settings.Autologin boolValue] == YES ? true : false;
    
    user_settings.UserExtendedStatus = [self convert_to_std_string: settings.UserExtendedStatus] ;
    
    user_settings.DoNotDesturbMode = [settings.DoNotDesturbMode boolValue] == YES ? true : false;
    
    user_settings.DefaultVoipServer = [self convert_to_std_string: settings.DefaultVoipServer] ;
    
    user_settings.VoipEncryption = settings.VoipEncryption == VoipEncryptionNone ? dodicall::dbmodel::VoipEncryptionType::VoipEncryptionNone : dodicall::dbmodel::VoipEncryptionType::VoipEncryptionSrtp;
    
    if ( settings.EchoCancellationMode == EchoCancellationModeOff )
        user_settings.EchoCancellationMode = dodicall::dbmodel::EchoCancellationMode::EchoCancellationModeOff;
    else if ( settings.EchoCancellationMode == EchoCancellationModeSoft )
        user_settings.EchoCancellationMode = dodicall::dbmodel::EchoCancellationMode::EchoCancellationModeSoft;
    else if ( settings.EchoCancellationMode == EchoCancellationModeHard )
        user_settings.EchoCancellationMode = dodicall::dbmodel::EchoCancellationMode::EchoCancellationModeHard;
    
    user_settings.VideoEnabled = [settings.VideoEnabled boolValue] == YES ? true : false;
    
    if ( settings.VideoSizeWifi == VideoSizeQvga )
        user_settings.VideoSizeWifi = dodicall::dbmodel::VideoSize::VideoSizeQvga;
    else if ( settings.VideoSizeWifi == VideoSizeVga )
        user_settings.VideoSizeWifi = dodicall::dbmodel::VideoSize::VideoSizeVga;
    else if ( settings.VideoSizeWifi == VideoSize720p )
        user_settings.VideoSizeWifi = dodicall::dbmodel::VideoSize::VideoSize720p;
    
    if ( settings.VideoSizeCell == VideoSizeQvga )
        user_settings.VideoSizeCell = dodicall::dbmodel::VideoSize::VideoSizeQvga;
    else if ( settings.VideoSizeCell == VideoSizeVga )
        user_settings.VideoSizeCell = dodicall::dbmodel::VideoSize::VideoSizeVga;
    else if ( settings.VideoSizeCell == VideoSize720p )
        user_settings.VideoSizeCell = dodicall::dbmodel::VideoSize::VideoSize720p;
    
    user_settings.GuiThemeName = [self convert_to_std_string: settings.GuiThemeName] ;
    
    user_settings.GuiAnimation = [settings.GuiAnimation boolValue] == YES ? true : false;
    
    user_settings.GuiLanguage = [self convert_to_std_string: settings.GuiLanguage] ;
    
    user_settings.GuiFontSize = settings.GuiFontSize;
    
    user_settings.TraceMode = [settings.TraceMode boolValue] == YES ? true : false;
    
    return dodicall::Application::GetInstance().SaveUserSettings(user_settings) ? YES : NO;
}

- (BOOL) SaveDefaultGuiLanguage: (NSString*) lang {
    std::string lang_str = [self convert_to_std_string:lang];
    
    return dodicall::Application::GetInstance().SaveDefaultGuiLanguage(lang_str.c_str()) ? YES : NO;
}

- (BOOL) SaveDefaultGuiTheme: (NSString*) theme {
    std::string theme_str = [self convert_to_std_string:theme];
    
    return dodicall::Application::GetInstance().SaveDefaultGuiTheme(theme_str.c_str()) ? YES : NO;
}

- (NSString*) FormatPhone: (NSString*) phone {
    std::string phone_str = [self convert_to_std_string: phone];
    
    std::string format_phone_str =  dodicall::Application::GetInstance().FormatPhone(phone_str);
    
    return [self convert_to_obj_c_str : format_phone_str];
}



@end
