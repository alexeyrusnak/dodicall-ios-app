//
//  AppDelegate.m
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

#import "AppDelegate.h"
#import "Model/AppManager.h"
#import <Crashlytics/Crashlytics.h>
#import "StackHandler.h"
#import "UsageHandler.h"
#import "UiLogger.h"

AppManager* app;

@interface AppDelegate ()

@property (strong, nonatomic) UsageHandler *UsageMonitor;

@end


@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    
    //Start usage logging
    self.UsageMonitor = [UsageHandler new];
    [self.UsageMonitor StartScheduledLogging];
    
    [Crashlytics startWithAPIKey:@"YOUR_CRASHLITICS_API_KEY"];
    
    //Register crash handler
    [StackHandler performSelector:@selector(RegisterCrashHandler) withObject:nil afterDelay:0];
    

    self.window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
    
    app = [AppManager Manager];
    
    [self.window makeKeyAndVisible];
    
    if(launchOptions)
    {
        //Handle remote notification
        NSDictionary *remoteNotif = [launchOptions objectForKey:UIApplicationLaunchOptionsRemoteNotificationKey];
        if(remoteNotif)
        {
            [UiLogger WriteLogInfo:@"Recieve notification on start #1"];
            [[AppManager app] PerformDidReceiveSystemRemoteNotfification:remoteNotif];
        }
        
        //Handle loacal notification
        UILocalNotification *localNotif = [launchOptions objectForKey:UIApplicationLaunchOptionsLocalNotificationKey];
        if(localNotif != nil)
        {
            [UiLogger WriteLogInfo:@"Recieve notification on start #2"];
            NSDictionary *localNotifUserInfo = localNotif.userInfo;
            if(localNotifUserInfo)
                [[AppManager app] PerformDidReceiveSystemLocalNotfification:localNotif];
        }
    }

    return YES;
}

- (void)application:(UIApplication *)app didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)devToken
{
    [[AppManager app] PerformDidRegisterForRemoteNotificationsWithDeviceToken:devToken];
    /*
    NSString *devTokenString = [[devToken description] stringByReplacingOccurrencesOfString:@"<" withString:@""];
    devTokenString = [devTokenString stringByReplacingOccurrencesOfString:@">" withString:@""];
    devTokenString = [devTokenString stringByReplacingOccurrencesOfString: @" " withString: @""];
    NSString *userUuid = [[AppManager app].Core GetAccountData].DodicallId;
    
    NSLog(@"didRegisterForRemoteNotificationsWithDeviceToken: %@", devToken);
    
    dispatch_async(dispatch_get_main_queue(), ^{
        
        [[AppManager app].Core didRegisterForRemoteNotificationsWithDeviceToken: devTokenString : userUuid];
        
    });
     */
}

- (void)application:(UIApplication *)app didFailToRegisterForRemoteNotificationsWithError:(NSError *)err
{

    [[AppManager app] PerformDidFailToRegisterForRemoteNotificationsWithError:err];
    
/*
#ifdef TARGET_IPHONE_SIMULATOR
    
    NSString *userUuid = [[AppManager app].Core GetAccountData].DodicallId;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        
        [[AppManager app].Core didRegisterForRemoteNotificationsWithDeviceToken: @"SIMULATOR" : userUuid];
        
    });
#endif
    
    NSLog(@"didFailToRegisterForRemoteNotificationsWithError: %@", err);
 */
}

- (void)application:(UIApplication *)application didReceiveLocalNotification:(UILocalNotification *)notification
{
    [UiLogger WriteLogInfo:@"Recieve notification on start #3"];
    [[AppManager app] PerformDidReceiveSystemLocalNotfification:notification];
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo
{
    
    [UiLogger WriteLogInfo:@"Recieve notification on start #4"];
    UIApplicationState state = [[UIApplication sharedApplication] applicationState];
    
    if(state != UIApplicationStateActive)
        [[AppManager app] PerformDidReceiveSystemRemoteNotfification:userInfo];
}

- (void)application:(UIApplication *)application handleActionWithIdentifier:(nullable NSString *)Identifier forRemoteNotification:(NSDictionary *)RemoteNotfification withResponseInfo:(NSDictionary *)ResponseInfo completionHandler:(void(^)())CompletionHandler
{
    
    [UiLogger WriteLogInfo:@"Recieve notification on start #5"];
    [[AppManager app] PerformHandleActionOfSystemRemoteNotfificationWithIdentifier:Identifier AndAction: RemoteNotfification withResponseInfo:ResponseInfo completionHandler:CompletionHandler];
    
    //CompletionHandler();
    
}

- (void)application:(UIApplication *)application handleActionWithIdentifier:(nullable NSString *)Identifier forLocalNotification:(UILocalNotification *)LocalNotification withResponseInfo:(NSDictionary *)ResponseInfo completionHandler:(void(^)())CompletionHandler
{
    [UiLogger WriteLogInfo:@"Recieve notification on start #6"];
    [[AppManager app] PerformHandleActionOfSystemLocalNotfificationWithIdentifier:Identifier AndAction: LocalNotification withResponseInfo:ResponseInfo completionHandler:CompletionHandler];
    
    //CompletionHandler();
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    [[AppManager app] ApplicaionPause];
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    [[AppManager app] ApplicaionResume];
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    [UiLogger WriteLogDebug:@"Application will terminate"];
}

-(void)applicationDidReceiveMemoryWarning:(UIApplication *)application {
    [UiLogger WriteLogDebug:@"Application did receive memory warning"];
}
#pragma mark - Status bar touch tracking
- (void) touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    [super touchesBegan:touches withEvent:event];
    
    CGPoint location = [[[event allTouches] anyObject] locationInView:[self window]];
    CGRect statusBarFrame = [UIApplication sharedApplication].statusBarFrame;
    if (CGRectContainsPoint(statusBarFrame, location)) {
        [self statusBarTouchedAction];
    }
}

- (void)statusBarTouchedAction {
    [[NSNotificationCenter defaultCenter] postNotificationName:@"StatusBarTouched" object:nil];
}


@end
