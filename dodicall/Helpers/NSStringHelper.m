//
//  NSStringHelper.m
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

#import "NSStringHelper.h"
#import "NUIRenderer.h"

@implementation NSStringHelper

+ (NSString *) CapitalaizeFirstLetter: (NSString *) String
{
    
    NSString *FirstletterCap = [[String substringToIndex:1] capitalizedString];
    
    return [String stringByReplacingCharactersInRange:NSMakeRange(0,1) withString:FirstletterCap];
    
}

+ (NSMutableAttributedString *) PrepareHtmlFormatedString:(NSString *) String WithNuiClass:(NSString *) NuiClass AndBaseFont:(UIFont *)BaseFont
{
    UIFont *Font = BaseFont;
    
    if ([NUISettings hasFontPropertiesWithClass:NuiClass]) {
        
        Font = [NUISettings getFontWithClass:NuiClass baseFont:Font];
        
    }
    
    NSString *TextAlign = @"left";
    
    if ([NUISettings hasProperty:@"text-align" withClass:NuiClass]) {
        
        TextAlign = [NUISettings get:@"text-align" withClass:NuiClass];
        
    }
    
    NSString *FontStyle = @"normal";
    
    if ([NUISettings hasProperty:@"font-style" withClass:NuiClass]) {
        
        FontStyle = [NUISettings get:@"font-style" withClass:NuiClass];
        
    }
    
    NSString *HtmlStyle = [NSString stringWithFormat: @"<meta charset=\"UTF-8\"><style> body { font-family: '%@'; font-size: %dpx; color:%@; text-align:%@; font-style:%@; }</style>",Font.fontName, (int)roundf(Font.pointSize), [NUISettings get:@"font-color" withClass:NuiClass], TextAlign, FontStyle];
    
    return [[NSMutableAttributedString alloc] initWithData:[[NSString stringWithFormat:@"<html><head>%@</head><body>%@</body></html>", HtmlStyle, [String stringByReplacingOccurrencesOfString:@"\n" withString:@"<br/>"]] dataUsingEncoding:NSUTF8StringEncoding]
                                                                         options:@{NSDocumentTypeDocumentAttribute: NSHTMLTextDocumentType,
                                                                                   NSCharacterEncodingDocumentAttribute: @(NSUTF8StringEncoding), NSFontAttributeName : Font}
                                                              documentAttributes:nil error:nil];
}

+ (NSMutableAttributedString *) FormatHyperlinksInAttributedString:(NSAttributedString *)String WithRanges:(NSArray *)Ranges {

    NSMutableAttributedString *resultString = [String mutableCopy];
    
    if(Ranges && Ranges.count) {
        for(NSValue *RangeValue in Ranges) {
            
            NSRange Range = [RangeValue rangeValue];
            
            if(NSEqualRanges(Range, NSMakeRange(NSNotFound, 0)))
                continue;
            
            NSString *LinkStr = [[String string] substringWithRange:Range];
            
            LinkStr = [LinkStr stringByAddingPercentEncodingWithAllowedCharacters:NSCharacterSet.URLQueryAllowedCharacterSet];
            
            NSURL *UrlCandidate = [NSURL URLWithString:LinkStr];
            
            if(!UrlCandidate)
                continue;
            
            if(!UrlCandidate.scheme)
                LinkStr = [@"http://" stringByAppendingString:LinkStr];
            

            
            [resultString addAttribute:NSLinkAttributeName value:LinkStr range:Range];
        }
    }

    return resultString;
}

+ (NSMutableAttributedString *) PrepareHtmlFormatedString:(NSString *) String WithNuiClass:(NSString *) NuiClass
{
    UIFont *BaseFont = [UIFont fontWithName:@"HelveticaNeue" size:17];
    
    return [self PrepareHtmlFormatedString:String WithNuiClass:NuiClass AndBaseFont:BaseFont];
}

+ (ManEnding) GetManEnding:(NSUInteger)count {
    
    ManEnding ending = ManEndingSingle;
    
    int tenRemainder = count%10;
    int hundredRemainder = count%100;
    
    if(tenRemainder == 2) {
        ending = ManEndingPlural;
        if(hundredRemainder == 12)
            ending=ManEndingSingle;
    }
    if(tenRemainder == 3) {
        ending = ManEndingPlural;
        if(hundredRemainder == 13)
            ending=ManEndingSingle;
    }
    if(tenRemainder == 4) {
        ending = ManEndingPlural;
        if(hundredRemainder == 14)
            ending=ManEndingSingle;
    }
    
    return ending;
}

+ (ParticipantTypeEnding)GetParticipantEnding:(NSInteger)count {
    
    if(!count)
        return ParticipantTypeEndingThree;
    if (count == 1)
        return ParticipantTypeEndingSingle;
    
    int tenRemainder = count%10;
    int hundredRemainder = count%100;
    
    ParticipantTypeEnding ending = ParticipantTypeEndingThree;
    
    if(tenRemainder == 1) {
        ending = ParticipantTypeEndingOne;
        if(hundredRemainder == 11)
            ending = ParticipantTypeEndingThree;
    }
    if(tenRemainder == 2 || tenRemainder == 3 || tenRemainder == 4) {
        ending = ParticipantTypeEndingTwo;
        if(hundredRemainder == 12 || hundredRemainder == 13 || hundredRemainder == 14)
            ending = ParticipantTypeEndingThree;
    }
    
    return ending;
}

@end
