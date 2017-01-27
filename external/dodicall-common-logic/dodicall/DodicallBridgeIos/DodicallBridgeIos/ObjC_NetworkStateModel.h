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
//  ObjC_NetworkStateModel.h
//  DodicallBridgeIos
//


#ifndef ObjC_NetworkStateModel_h
#define ObjC_NetworkStateModel_h

#import <Foundation/Foundation.h>

typedef enum {
    NetworkTechnologyNone = 0,
    NetworkTechnologyWifi,
    NetworkTechnologyEdge,
    NetworkTechnology3g,
    NetworkTechnologyLte
} NetworkTechnology;

@interface ObjC_NetworkStateModel: NSObject {
};

    @property NetworkTechnology Technology;
    @property NSNumber* VoipStatus;
    @property NSNumber* ChatStatus;



@end




#endif /* ObjC_NetworkStateModel_h */
