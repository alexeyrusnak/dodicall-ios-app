//
//  NSStringHelper.h
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
//  along with dodicall.If not, see <http://www.gnu.org/licenses/>.  Copyright © 2015 dodidone. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

typedef enum  {
    ManEndingSingle = 0,
    ManEndingPlural
} ManEnding;
//Человек, человека

typedef enum  {
    ParticipantTypeEndingOne = 0,
    ParticipantTypeEndingTwo,
    ParticipantTypeEndingThree,
    ParticipantTypeEndingSingle
} ParticipantTypeEnding;
//Участник, участника, участников, участник

@interface NSStringHelper : NSObject

+ (NSString *) CapitalaizeFirstLetter: (NSString *) String;

+ (NSMutableAttributedString *) PrepareHtmlFormatedString:(NSString *) String WithNuiClass:(NSString *) NuiClass AndBaseFont:(UIFont *)BaseFont;

+ (NSMutableAttributedString *) PrepareHtmlFormatedString:(NSString *) String WithNuiClass:(NSString *) NuiClass;

+ (NSMutableAttributedString *) FormatHyperlinksInAttributedString:(NSAttributedString *)String WithRanges:(NSArray *)Ranges;

+ (ManEnding) GetManEnding:(NSUInteger)count;

+ (ParticipantTypeEnding)GetParticipantEnding:(NSInteger)count;

@end
