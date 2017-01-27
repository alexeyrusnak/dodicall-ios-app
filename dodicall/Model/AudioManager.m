//
//  AudioManager.m
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

#import "AudioManager.h"
#import "AppManager.h"
#import <UIKit/UIKit.h>
#import "UiLogger.h"
#import <AudioToolbox/AudioServices.h>

static AudioManager *AudioManagerSingleton = nil;
static dispatch_once_t AudioManagerSingletonOnceToken;

@interface AudioManager()

@property (strong, nonatomic) NSNumber *Vibrating;
@property (strong, nonatomic) RACSignal *VibrationSignal;

@property (strong, nonatomic) NSNumber *Active;

@end

@implementation AudioDeviceModel

- (NSString *) description
{
    return  [NSString stringWithFormat:@"DevId:%@\n",self.DevId];
}

@end

@implementation AudioManager
{
    BOOL AllInited;
}

+ (instancetype) Manager
{
    dispatch_once(&AudioManagerSingletonOnceToken, ^{
        
        AudioManagerSingleton = [[AudioManager alloc] init];
        
    });
    
    [AudioManagerSingleton InitAll];
    
    return AudioManagerSingleton;
}

+ (void) Destroy
{
    if(AudioManagerSingleton)
    {
        AudioManagerSingleton = nil;
        AudioManagerSingletonOnceToken = 0;
    }
}

- (void) SetActive:(BOOL) Active
{
    self.Active = [NSNumber numberWithBool:Active];
}

- (void) InitAll
{
    if(!AllInited)
    {
        AllInited = YES;
        
        [self SetupAudio];
        
        @weakify(self);
        
        [[[RACObserve([AppManager app].UserSession, IsUserAuthorizedAndGuiReady) filter:^BOOL(NSNumber *IsAuthorized)
        {
            return [IsAuthorized boolValue];
        }] take:1] subscribeNext:^(id x)
        {
            
            @strongify(self);
            
            [self CheckMicrophonePermissions:YES];
            
        }];
        
    }
}

- (void) SetupAudio
{
    self.VibrationSignal = [RACSignal interval:0.7 onScheduler:[RACScheduler mainThreadScheduler]];
    
    
    //HACK: DMC-2835
    {

        AVAudioSession *AudioSession = [ AVAudioSession sharedInstance ];
        
        [[NSNotificationCenter defaultCenter] addObserver: self
                                                 selector: @selector(AudioRouteChangeListenerCallback:)
                                                     name: AVAudioSessionRouteChangeNotification
                                                   object: AudioSession];

        [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategorySoloAmbient error:nil];
    }
    
    
    
}

- (void) EnableMicrophone:(BOOL) Enabled
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        
        [[AppManager app].Core EnableMicrophone:Enabled];
        
        BOOL IsEnabled = [[AppManager app].Core IsMicrophoneEnabled];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            
            [self setMicrophoneEnabled:[NSNumber numberWithBool:IsEnabled]];
            
        });
    });
    
}

- (void) CheckMicrophone {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        
        BOOL IsEnabled = [[AppManager app].Core IsMicrophoneEnabled];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            
            [self setMicrophoneEnabled:[NSNumber numberWithBool:IsEnabled]];
            
        });
    });
}

- (void) CheckMicrophonePermissions:(BOOL) AlertUser
{
    AVAudioSessionRecordPermission PermissionStatus = [[AVAudioSession sharedInstance] recordPermission];
    
    switch (PermissionStatus)
    {
        case AVAudioSessionRecordPermissionUndetermined:
        {
            [UiLogger WriteLogInfo:[NSString stringWithFormat:@"AudioManager:CheckMicrophonePermissions:%@",@"Undetermined"]];
            [self setMicrophonePermited:@NO];
            break;
        }
        case AVAudioSessionRecordPermissionDenied:
            [UiLogger WriteLogInfo:[NSString stringWithFormat:@"AudioManager:CheckMicrophonePermissions:%@",@"Denied"]];
            [self setMicrophonePermited:@NO];
            break;
            
        case AVAudioSessionRecordPermissionGranted:
            [UiLogger WriteLogInfo:[NSString stringWithFormat:@"AudioManager:CheckMicrophonePermissions:%@",@"Granted"]];
            [self setMicrophonePermited:@YES];
            break;
            
        default:
            [UiLogger WriteLogInfo:[NSString stringWithFormat:@"AudioManager:CheckMicrophonePermissions:%@",@"Exception"]];
            [self setMicrophonePermited:@NO];
            break;
    }
    
    if(AlertUser && (PermissionStatus == AVAudioSessionRecordPermissionUndetermined || PermissionStatus == AVAudioSessionRecordPermissionDenied))
    {
        [UiLogger WriteLogInfo:[NSString stringWithFormat:@"AudioManager:CheckMicrophonePermissions:%@",@"User asked"]];
        
        [[AVAudioSession sharedInstance] requestRecordPermission:^(BOOL granted)
         {
             if(granted)
             {
                 [UiLogger WriteLogInfo:[NSString stringWithFormat:@"AudioManager:CheckMicrophonePermissions:%@",@"User granted"]];
                 [self setMicrophonePermited:@YES];
             }
             else
             {
                 [UiLogger WriteLogInfo:[NSString stringWithFormat:@"AudioManager:CheckMicrophonePermissions:%@",@"User disabled"]];
                 [self setMicrophonePermited:@NO];
             }
         }];
    }
}

- (void) SwitchMicrophone
{
    [self EnableMicrophone:![self.MicrophoneEnabled boolValue]];
}

- (void) EnableSpeaker:(BOOL) Enabled
{
    AVAudioSession *AudioSession = [AVAudioSession sharedInstance];
    
    NSError *Error = nil;
    BOOL Success;
    
    if(Enabled)
    {
        Success = [AudioSession overrideOutputAudioPort:AVAudioSessionPortOverrideSpeaker error:&Error];
        
        if(Success)
        {
            [self setBluetoothEnabled:[NSNumber numberWithBool:NO]];
            
            [self setSpeakerEnabled:[NSNumber numberWithBool:YES]];
        }
            
    }
    else
    {
        Success = [AudioSession overrideOutputAudioPort:AVAudioSessionPortOverrideNone error:&Error];
        
        if(Success)
        {
            [self setSpeakerEnabled:[NSNumber numberWithBool:NO]];
        }
    }
}

- (void) SwitchSpeaker
{
    [self EnableSpeaker:![self.SpeakerEnabled boolValue]];
}


- (void) AudioRouteChangeListenerCallback:(NSNotification*)Notification
{

    [UiLogger WriteLogInfo:[NSString stringWithFormat:@"AudioManager:AudioRouteChangeListenerCallback:%@",Notification.userInfo]];
    
    
}

- (void) StartVibration {
    self.Vibrating = @(YES);
    
    [[self.VibrationSignal takeUntil: [RACObserve(self, Vibrating) filter:^BOOL(NSNumber *value) {
        return ![value boolValue];
    }]]subscribeNext:^(id x) {
        AudioServicesPlaySystemSoundWithCompletion(kSystemSoundID_Vibrate, nil);
    }];
    
    
}

- (void) StopVibration {
    self.Vibrating = @(NO);
}

/*
static void AudioRouteChangeListenerCallback (void *UserData, AudioSessionPropertyID PropertyID, UInt32 PropertyValueSize, const void *PropertyValue)
{
    
    if (PropertyID == kAudioSessionProperty_AudioRouteChange)
    {
        BOOL SpeakerEnabled = FALSE;
        
        CFStringRef NewRoute = CFSTR("Unknown");
    
        UInt32 NewRouteSize = sizeof(NewRoute);
        
        OSStatus Status = AudioSessionGetProperty(kAudioSessionProperty_AudioRoute, &NewRouteSize, &NewRoute);
        
        
        if (!Status && NewRouteSize > 0)
        {
            NSString *Route = (NSString *) CFBridgingRelease(NewRoute);
            
            [UiLogger WriteLogInfo:[NSString stringWithFormat:@"AudioManager:AudioRouteChangeListenerCallback:%@",Route]];
            
            SpeakerEnabled = [Route isEqualToString: @"Speaker"] || [Route isEqualToString: @"SpeakerAndMicrophone"];
            
            if (UI_USER_INTERFACE_IDIOM() != UIUserInterfaceIdiomPad && [Route isEqualToString:@"HeadsetBT"] && !SpeakerEnabled) {
                
                [[AudioManager Manager] setBluetoothEnabled:[NSNumber numberWithBool:YES]];
                [[AudioManager Manager] setBluetoothAvailable:[NSNumber numberWithBool:YES]];
                
            }
            else
            {
                [[AudioManager Manager] setBluetoothEnabled:[NSNumber numberWithBool:NO]];
            }
            
            CFRelease(NewRoute);
        }
        
        [[AudioManager Manager] setSpeakerEnabled:[NSNumber numberWithBool:SpeakerEnabled]];
        
    }
}
*/



@end
