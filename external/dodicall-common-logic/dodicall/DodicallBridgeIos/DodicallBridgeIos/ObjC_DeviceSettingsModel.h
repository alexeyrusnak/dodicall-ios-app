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
//  ObjC_DeviceSettingsModel.h
//  
//

#import <Foundation/Foundation.h>
#import "ObjC_UserSettingsModel.h"



@interface VoipEncryptionSerttingsModel: NSObject {


};

    @property VoipEncryptionType Type;
    @property NSNumber* Mandatory;
    @property NSNumber* Ignore;


@end

typedef enum {
    CodecTypeAudio,
    CodecTypeVideo
} CodecType;

typedef enum {
    ConnectionTypeCell,
    ConnectionTypeWifi
} CodecConnectionType;

@interface CodecSettingModel: NSObject {


};


    @property CodecType Type;
    @property CodecConnectionType ConnectionType;
    @property NSString *Name;
    @property NSString *Mime;
    @property unsigned int Rate;
    @property unsigned int Priority;
    @property NSNumber* Enabled;

@end

typedef enum {
    ServerTypeSip,
    ServerTypeXmpp
} ServerSettingType;

typedef enum {
    ServerProtocolTypeTls,
    ServerProtocolTypeTcp,
    ServerProtocolTypeUdp
} ServerProtocolType;



@interface ServerSettingModel: NSObject {

   
};

    @property ServerSettingType ServerType;
    @property ServerProtocolType ProtocolType;
    @property NSString *Server;
    @property unsigned int Port;
    @property NSString *Domain;
    @property NSString *Username;
    @property NSString *Password;
    @property NSString *AuthUserName;
    @property NSString *Extension;
    @property NSNumber* Default;

@end


@interface ObjC_DeviceSettingsModel : NSObject {
    
    

    
};


    @property NSString *VoiceMailGate;
    @property VoipEncryptionSerttingsModel *EncryptionSettings;
    @property NSMutableArray *CodecSettings;
    @property NSMutableArray *ServerSettings;





@end
