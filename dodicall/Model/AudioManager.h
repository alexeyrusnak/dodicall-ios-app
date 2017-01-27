//
//  AudioManager.h
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

#import <CoreTelephony/CTCallCenter.h>

#import <AudioToolbox/AudioToolbox.h>

#import <AVFoundation/AVAudioSession.h>
#import <AVFoundation/AVAudioPlayer.h>

#include <signal.h>


@interface AudioDeviceModel : NSObject

@property NSString *DevId;

@property NSString *Title;

@property BOOL IsAvailable;

@property BOOL IsActive;

@end

@interface AudioManager : NSObject

@property NSNumber *MicrophoneEnabled;
@property NSNumber *MicrophonePermited;
@property NSNumber *SpeakerEnabled;
@property NSNumber *BluetoothEnabled;
@property NSNumber *BluetoothAvailable;

@property NSNumber *SystemRingtoneVolumeLabel;

@property NSMutableArray <AudioDeviceModel *> * AvailableAudioDevices;

+ (instancetype) Manager;

+ (void) Destroy;

- (void) SetActive:(BOOL) Active;

- (void) SetupAudio;

- (void) CheckMicrophone;

- (void) CheckMicrophonePermissions:(BOOL) AlertUser;

- (void) EnableMicrophone:(BOOL) Enabled;

- (void) SwitchMicrophone;

- (void) EnableSpeaker:(BOOL) Enabled;

- (void) SwitchSpeaker;

- (void) StartVibration;

- (void) StopVibration;

/*
- (void) GetAudioDevicesAndReturnItInCallback:(void (^)(NSMutableArray <AudioDeviceModel *> *)) Callback;

- (void) SetActiveAudioDeviceWithId:(NSString *) DeviceId;

*/

@end
