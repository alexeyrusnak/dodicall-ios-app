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
//  ObjC_CallsModel.h
//  DodicallBridgeIos
//

#pragma once

#import <Foundation/Foundation.h>
#import "ObjC_ContactModel.h"

@interface ObjC_SoundDeviceModel: NSObject {
};
    @property NSString *DevId;
    @property NSNumber *CanCapture;
    @property NSNumber *CanPlay;
    @property NSNumber *CurrentRinger;
    @property NSNumber *CurrentPlayback;
    @property NSNumber *CurrentCapture;
@end


@interface ObjC_StateSettingsModel: NSObject {
};
    @property NSNumber *active;
    @property NSString *destination; //<"voicemail"/abcnumber/sip/ext:string>,
@end

@interface ObjC_StateSettingsExtendedModel: NSObject {
};
    @property NSNumber *active;
    @property NSString *destination; //<"voicemail"/abcnumber/sip/ext:string>,
    @property int duration; //<time(sec):int>
@end

@interface ObjC_CallForwardingSettingsModel: NSObject {
};
    @property ObjC_StateSettingsModel *stateSettingsAlways;
    @property ObjC_StateSettingsModel *stateSettingsBusy;
    @property ObjC_StateSettingsExtendedModel *stateSettingsNoAnswer;
    @property ObjC_StateSettingsModel *stateSettingsNotReachable;
@end

typedef enum  {
    CallDirectionOutgoing = 0,
    CallDirectionIncoming
} CallDirection;

typedef enum  {
    CallEncryptionNone = 0,
    CallEncryptionSRTP
} CallEncription;

typedef enum {
    CallStateInitialized = 0,
    CallStateDialing,
    CallStateRinging,
    CallStateConversation,
    CallStateEarlyMedia,
    CallStatePaused,
    CallStateEnded
} CallState;

typedef enum {
    CallAddressPhone,
    CallAddressDodicall
} CallAddressType;

@interface ObjC_CallModel: NSObject {
};
    
    @property NSString *Id;
    @property CallDirection Direction;
    @property CallEncription Encription;
    @property CallState State;
    @property CallAddressType AddressType;
    @property NSString *Identity;
    @property ObjC_ContactModel *Contact;
    @property NSTimeInterval Duration;

@end


@interface ObjC_ConferenceModel: NSObject {
};

    @property NSMutableArray *Calls;

@end

@interface ObjC_CallsModel: NSObject {
};

    @property ObjC_ConferenceModel *Conference;

    @property NSMutableArray *SingleCalls;

@end

/* ObjC_ChatModel_h */
