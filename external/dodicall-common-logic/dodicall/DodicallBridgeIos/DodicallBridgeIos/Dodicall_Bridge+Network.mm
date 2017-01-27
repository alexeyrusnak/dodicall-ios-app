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
//  Dodicall_Bridge+Network.m
//  DodicallBridgeIos
//


#import "Dodicall_Bridge+Network.h"
#import <CoreTelephony/CTTelephonyNetworkInfo.h>
#import "Dodicall_Bridge+Helpers.h"

//static CTTelephonyNetworkInfo *TelephonyInfo = nil;

@implementation Dodicall_Bridge (Network)

- (void) SetupNetworkTechnologyNotifications
{
    dispatch_async(dispatch_get_main_queue(), ^{
        
        Internet_Availabillity *Reachability = [Internet_Availabillity reachabilityForInternetConnection];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(ReachabilityChanged:) name:kReachabilityChangedNotification object:nil];
        
        [Reachability startNotifier];
        
        ///[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(ReachabilityChanged:) name:CTRadioAccessTechnologyDidChangeNotification object:nil];
        
    });
}

- (NetworkTechnology) GetNetworkTechnology:(void (^)(NetworkTechnology note)) CallBack
{
    Internet_Availabillity *reachability = [Internet_Availabillity reachabilityForInternetConnection];
    NetworkStatus networkStatus = [reachability currentReachabilityStatus];

    if(networkStatus == NotReachable)
    {
        
        if(CallBack)
            CallBack(NetworkTechnologyNone);
        
        return NetworkTechnologyNone;
    }
    else if (networkStatus == ReachableViaWiFi)
    {
        if(CallBack)
            CallBack(NetworkTechnologyWifi);
        
        return NetworkTechnologyWifi;
    }
    else if (networkStatus == ReachableViaWWAN)
    {

        CTTelephonyNetworkInfo *TelephonyInfo = [CTTelephonyNetworkInfo new];
        
        if(CallBack)
        {
        
            if(TelephonyInfo.currentRadioAccessTechnology)
            {
                CallBack([self GetNetworkTechnologyFromRadioAccessTechnology:TelephonyInfo.currentRadioAccessTechnology]);
            }
            else
            {
                [NSNotificationCenter.defaultCenter addObserverForName:CTRadioAccessTechnologyDidChangeNotification
                                                                object:nil
                                                                 queue:nil
                                                            usingBlock:^(NSNotification *note) {
                                                                
                                                                CallBack([self GetNetworkTechnologyFromRadioAccessTechnology:TelephonyInfo.currentRadioAccessTechnology]);
                                                                
                                                            }];
            }
        }
        
        
        return [self GetNetworkTechnologyFromRadioAccessTechnology:TelephonyInfo.currentRadioAccessTechnology];
    }
    
    return NetworkTechnologyNone;
}

- (NetworkTechnology) GetNetworkTechnologyFromRadioAccessTechnology: (NSString*) RadioAccessTechnology
{
    
    if ( [RadioAccessTechnology isEqualToString:CTRadioAccessTechnologyGPRS])
        return NetworkTechnologyEdge;
    else if ([RadioAccessTechnology  isEqualToString:CTRadioAccessTechnologyEdge])
        return NetworkTechnologyEdge;
    else if ([RadioAccessTechnology  isEqualToString:CTRadioAccessTechnologyWCDMA])
        return NetworkTechnology3g;
    else if ([RadioAccessTechnology  isEqualToString:CTRadioAccessTechnologyHSDPA])
        return NetworkTechnology3g;
    else if ([RadioAccessTechnology  isEqualToString:CTRadioAccessTechnologyHSUPA])
        return NetworkTechnology3g;
    else if ([RadioAccessTechnology  isEqualToString:CTRadioAccessTechnologyCDMA1x])
        return NetworkTechnology3g;
    else if ([RadioAccessTechnology  isEqualToString:CTRadioAccessTechnologyCDMAEVDORev0])
        return NetworkTechnology3g;
    else if ([RadioAccessTechnology  isEqualToString:CTRadioAccessTechnologyCDMAEVDORevA])
        return NetworkTechnology3g;
    else if ([RadioAccessTechnology  isEqualToString:CTRadioAccessTechnologyCDMAEVDORevB])
        return NetworkTechnology3g;
    else if ([RadioAccessTechnology  isEqualToString:CTRadioAccessTechnologyeHRPD])
        return NetworkTechnologyLte;
    else if ([RadioAccessTechnology  isEqualToString:CTRadioAccessTechnologyLTE])
        return NetworkTechnologyLte;
    
    return NetworkTechnologyNone;
}

- (void) ReachabilityChanged:(NSNotification *)Note
{
    [self SetNetworkTechnology];
}

- (ObjC_NetworkStateModel*) GetNetworkState
{
    ObjC_NetworkStateModel* objc_nw_state = [[ObjC_NetworkStateModel alloc] init];
    
    dodicall::NetworkStateModel c_nw_state = dodicall::Application::GetInstance().GetNetworkState();
    
    switch ( c_nw_state.Technology ) {
        case dodicall::dbmodel::NetworkTechnologyNone:
            objc_nw_state.Technology = NetworkTechnologyNone;
            break;
        case dodicall::dbmodel::NetworkTechnologyWifi:
            objc_nw_state.Technology = NetworkTechnologyWifi;
            break;
        case dodicall::dbmodel::NetworkTechnology2g:
            objc_nw_state.Technology = NetworkTechnologyEdge;
            break;
        case dodicall::dbmodel::NetworkTechnology3g:
            objc_nw_state.Technology = NetworkTechnology3g;
            break;
        case dodicall::dbmodel::NetworkTechnology4g:
            objc_nw_state.Technology = NetworkTechnologyLte;
            break;
    }
    objc_nw_state.VoipStatus = [NSNumber numberWithBool: c_nw_state.VoipStatus ? YES : NO];
    
    objc_nw_state.ChatStatus = [NSNumber numberWithBool: c_nw_state.ChatStatus ? YES : NO];
    
    return objc_nw_state;
}

- (void) SetNetworkTechnologyInternal
{

    [self GetNetworkTechnology:^(NetworkTechnology nw_technology){
    
        dodicall::dbmodel::NetworkTechnology  c_nw_technology;
        
        switch ( nw_technology ) {
            case NetworkTechnologyNone:
                c_nw_technology = dodicall::dbmodel::NetworkTechnologyNone;
                break;
            case NetworkTechnologyEdge:
                c_nw_technology = dodicall::dbmodel::NetworkTechnology2g;
                break;
            case NetworkTechnology3g:
                c_nw_technology = dodicall::dbmodel::NetworkTechnology3g;
                break;
            case NetworkTechnologyLte:
                c_nw_technology = dodicall::dbmodel::NetworkTechnology4g;
                break;
            case NetworkTechnologyWifi:
                c_nw_technology = dodicall::dbmodel::NetworkTechnologyWifi;
                break;
        }
        
        dodicall::Application::GetInstance().SetNetworkTechnology( c_nw_technology );
    
    }];
    
    
}

- (void) SetNetworkTechnology
{
    [self SetNetworkTechnology:NO];
}

- (void) SetNetworkTechnology:(BOOL) InitialSetup
{
    if(!InitialSetup)
    {
        //DMC-2011
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            
            [self SetNetworkTechnologyInternal];
            
            
        });
    }
    else
    {
        [self SetNetworkTechnologyInternal];
    }
}


@end
