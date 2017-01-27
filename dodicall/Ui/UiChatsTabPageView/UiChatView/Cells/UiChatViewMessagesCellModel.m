//
//  UiChatViewMessagesCellModel.m
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

#import "UiChatViewMessagesCellModel.h"
#import "NUISettings.h"
#import "ChatsManager.h"
#import "UIColorHelper.h"

@implementation UiChatViewMessagesCellModel

- (void) PrepareAttributedString
{
    UIFont *Font = [UIFont fontWithName:@"HelveticaNeue" size:[AppManager app].UserSettingsModel.GuiFontSize];
    
    NSString * NuiClass = MessageTextViewNuiClass;
    
    if([self.MessageDirection isEqualToString:UiChatMessageDirectionTypeOutgoing])
    {
        NuiClass = MessageTextOutgoingViewNuiClass;
    }
    
    if([self.MessageType isEqualToString:UiChatMessageTypeInfoText])
    {
        NuiClass = MessageInfoTextViewNuiClass;
    }
    
    if(self.MessageData.Type == ChatMessageTypeDeleter)
    {
        NuiClass = MessageTextDeletedViewNuiClass;
    }
    
    
    
    NSMutableAttributedString *AttributedMessageStr = [NSStringHelper PrepareHtmlFormatedString:self.MessageText WithNuiClass:NuiClass AndBaseFont:Font];
    
    [self DetectHyperlinks:AttributedMessageStr];
    
    if(self.LinksRangesArray && self.LinksRangesArray.count)
        AttributedMessageStr = [NSStringHelper FormatHyperlinksInAttributedString:AttributedMessageStr WithRanges:self.LinksRangesArray];
    
    self.MessageAttributedText = AttributedMessageStr;
}

- (void) DetectHyperlinks:(NSMutableAttributedString *) AttributedMessageStr
{
    self.LinksRangesArray = nil;
    
    if([self.MessageType isEqualToString:UiChatMessageTypeInfoText])
    {
        return;
    }
    
    NSMutableArray *RangesArray = [NSMutableArray new];
    
    if(AttributedMessageStr && AttributedMessageStr.length) {
        
        NSRegularExpression *Regex = [NSRegularExpression regularExpressionWithPattern:@"(?:([a-z]+:\\/\\/)|w{3}.|mailto:){1}(?:\\S+(?::\\S*)?@)?(?:(?!10(?:\\.\\d{1,3}){3})(?!127(?:\\.\\d{1,3}){3})(?!169\\.254(?:\\.\\d{1,3}){2})(?!192\\.168(?:\\.\\d{1,3}){2})(?!172\\.(?:1[6-9]|2\\d|3[0-1])(?:\\.\\d{1,3}){2})(?:[1-9]\\d?|1\\d\\d|2[01]\\d|22[0-3])(?:\\.(?:1?\\d{1,2}|2[0-4]\\d|25[0-5])){2}(?:\\.(?:[1-9]\\d?|1\\d\\d|2[0-4]\\d|25[0-4]))|(?:(?:[a-z\\x{00a1}\\-\\x{ffff}0-9]+-?)*[a-z\\x{00a1}\\-\\x{ffff}0-9]+)(?:\\.(?:[a-z\\x{00a1}\\-\\x{ffff}0-9]+-?)*[a-z\\x{00a1}\\-\\x{ffff}0-9]+)*(?:\\.(?:[a-z\\x{00a1}\\-\\x{ffff}]{2,})))(?::\\d{2,5})?(?:\\/[^\\s]*)?" options:NSRegularExpressionCaseInsensitive error:nil];
        
        [Regex enumerateMatchesInString:[AttributedMessageStr string] options:0 range:NSMakeRange(0, AttributedMessageStr.length) usingBlock:^(NSTextCheckingResult * _Nullable result, NSMatchingFlags flags, BOOL * _Nonnull stop) {
            [RangesArray addObject:[NSValue valueWithRange:result.range]];
        }];
        
    }
    
    if(RangesArray && RangesArray.count)
        self.LinksRangesArray = RangesArray;
}

- (void) CalcMessageTextViewSize
{
    CGFloat TextViewWidth = [UIScreen mainScreen].bounds.size.width-2*MessageTextViewMarginLeft-2*BubbleContainerMarginLeft;

    NSAttributedString *TextViewString;
    
    //Support delivery status panel
    if([self.MessageDirection isEqualToString:UiChatMessageDirectionTypeOutgoing])
    {
        if(self.DeliveryStatus)
        {
            if(TextViewWidth < MessageViewDeliveryStatusPanelWidth + MessageViewTimeLabelWidth - 2*MessageTextViewMarginLeft)
            {
                TextViewWidth = MessageViewDeliveryStatusPanelWidth + MessageViewTimeLabelWidth - 2*MessageTextViewMarginLeft;
            }
            
        }
    }
    
    if(TextViewWidth < MessageViewTimeLabelWidth + MessageViewOutgoingTimeLabelMarginLeft + MessageViewOutgoingTimeLabelMarginRight - 2*MessageTextViewMarginLeft)
    {
        TextViewWidth = MessageViewTimeLabelWidth + MessageViewOutgoingTimeLabelMarginLeft + MessageViewOutgoingTimeLabelMarginRight - 2*MessageTextViewMarginLeft;
    }
    
    if([self.MessageType isEqualToString:UiChatMessageTypeInfoText])
    {
        TextViewWidth = [UIScreen mainScreen].bounds.size.width-2*BubbleContainerMarginLeft;
    }
    
    
    
    
    
    if(self.MessageAttributedText && self.MessageAttributedText.length > 0)
    {
        TextViewString = self.MessageAttributedText;
    }
    else
    {
        UIFont *Font = [UIFont fontWithName:@"HelveticaNeue" size:15];
        
        if ([NUISettings hasFontPropertiesWithClass:MessageTextViewNuiClass]) {
            
            Font = [NUISettings getFontWithClass:MessageTextViewNuiClass baseFont:Font];
        }
        
        TextViewString = [[NSAttributedString alloc] initWithString:self.MessageText attributes:@{ NSFontAttributeName : Font }];
    }
    
    if([self.WasEdited boolValue])
    {
        TextViewWidth -= MessageEditIconWidthWithMargin;
    }
    
    CGRect CalculatedRect = [TextViewString boundingRectWithSize:CGSizeMake(TextViewWidth, CGFLOAT_MAX) options:NSStringDrawingUsesFontLeading | NSStringDrawingUsesLineFragmentOrigin context:nil];
    
    self.TextSize = CGRectIntegral(CalculatedRect).size;
}

- (void) CalcCellHeight
{
    self.CellHeight = self.TextSize.height + 4*BubbleContainerMarginTop + 2*MessageTextViewMarginTop;
    
    if(self.IsMultyChatMessage && [self.MessageDirection isEqualToString:UiChatMessageDirectionTypeIncoming] )
    {
        self.CellHeight += MessageViewContactStatusPanelHeight;
    }
    
    if([self.MessageType isEqualToString:UiChatMessageTypeInfoText])
    {
        self.CellHeight = self.TextSize.height + 4*BubbleContainerMarginTop;
    }
    
}

@end
