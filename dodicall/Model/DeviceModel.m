//
//  DeviceModel.m
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

#import "DeviceModel.h"
#include <sys/types.h>
#include <sys/sysctl.h>

@implementation UIDevice (DeviceModel)

- (NSString*)ModelVersion
{
    size_t size;
    
    sysctlbyname("hw.machine", NULL, &size, NULL, 0);
    char* machine = malloc(size);
    sysctlbyname("hw.machine", machine, &size, NULL, 0);
    NSString* platform = [NSString stringWithUTF8String:machine];
    free(machine);
    
    return platform;
}

- (NSString*)UniqueAppInstanceIdentifier
{
    NSUserDefaults* UserDefaults = [NSUserDefaults standardUserDefaults];
    static NSString* UUID_KEY = @"UUID";
    
    NSString* AppUuid = [UserDefaults stringForKey:UUID_KEY];
    
    if (AppUuid == nil) {
        CFUUIDRef UuidRef = CFUUIDCreate(kCFAllocatorDefault);
        CFStringRef UuidString = CFUUIDCreateString(kCFAllocatorDefault, UuidRef);
        
        AppUuid = [NSString stringWithString:(__bridge NSString*)UuidString];
        [UserDefaults setObject:AppUuid forKey:UUID_KEY];
        [UserDefaults synchronize];
        
        CFRelease(UuidString);
        CFRelease(UuidRef);
    }
    
    return AppUuid;
}

@end

@implementation DeviceModel

- (NSDictionary *) GetDeviceInfo
{
    UIDevice* Device = [UIDevice currentDevice];
    NSMutableDictionary* DevProps = [NSMutableDictionary dictionaryWithCapacity:4];
    
    [DevProps setObject:@"Mobile" forKey:@"Type"];
    [DevProps setObject:[Device ModelVersion] forKey:@"Model"];
    [DevProps setObject:@"iOS" forKey:@"Platform"];
    [DevProps setObject:[Device systemVersion] forKey:@"Version"];
    [DevProps setObject:[Device UniqueAppInstanceIdentifier] forKey:@"Uuid"];
    
    NSDictionary* DevReturn = [NSDictionary dictionaryWithDictionary:DevProps];
    return DevReturn;
}

- (BOOL) IsSmallDevice
{
    NSDictionary *DeviceInfo = [self GetDeviceInfo];
    NSString *DeviceModel = [DeviceInfo objectForKey:@"Model"];
    
    BOOL SmallDevice = NO;
    
    if([DeviceModel isEqualToString:@"iPhone3,1"])
        SmallDevice = YES;
    else if([DeviceModel isEqualToString:@"iPhone3,3"])
        SmallDevice = YES;
    else if([DeviceModel isEqualToString:@"iPhone4,1"])
        SmallDevice = YES;
    
    return SmallDevice;
}

@end
