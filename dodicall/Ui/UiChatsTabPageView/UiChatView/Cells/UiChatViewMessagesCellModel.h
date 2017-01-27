//
//  UiChatViewMessagesCellModel.h
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
#import <UIKit/UIKit.h>

#define UiChatMessageTypeText   @"UiChatMessageTypeText"
#define UiChatMessageTypeInfoText   @"UiChatMessageTypeInfoText"
typedef NSString*               UiChatMessageType;

#define UiChatMessageDirectionTypeIncoming   @"UiChatMessageDirectionTypeIncoming"
#define UiChatMessageDirectionTypeOutgoing   @"UiChatMessageDirectionTypeOutgoing"
typedef NSString*               UiChatMessageDirectionType;

#define BubbleContainerMarginTop 6
#define BubbleContainerMarginRight -52
#define BubbleContainerMarginBottom -6
#define BubbleContainerMarginLeft 52
#define BubbleContainerDeltaMarginForEditView 23

#define MessageTextViewMarginTop 11
#define MessageTextViewMarginRight -11
#define MessageTextViewMarginBottom -11
#define MessageTextViewMarginLeft 11

#define MessageViewContactStatusPanelMarginTop 6
#define MessageViewContactStatusPanelHeight 21

#define MessageViewDeliveryStatusPanelWidth 170
#define MessageViewTimeLabelWidth 60
#define MessageViewDeliveryStatusIndicatorWidth 7

#define MessageViewOutgoingTimeLabelMarginRight 22
#define MessageViewOutgoingTimeLabelMarginLeft 10

#define MessageTextViewLineFragmentPadding 0

#define MessageEditIconWidthWithMargin 23

#define MessageTextViewNuiClass @"UiChatViewMessagesBubbleContainerTextView"
#define MessageTextOutgoingViewNuiClass @"UiChatViewMessagesBubbleContainerOutgoingTextView"
#define MessageTextDeletedViewNuiClass @"UiChatViewMessagesBubbleContainerDeletedMessageTextView"

#define MessageInfoTextViewNuiClass @"UiChatViewMessagesInfoTextView"


@class ObjC_ChatMessageModel;

@interface UiChatViewMessagesCellModel : NSObject

@property ObjC_ChatMessageModel *MessageData;

@property NSString *SectionKey;

@property UiChatMessageType MessageType;

@property UiChatMessageDirectionType MessageDirection;

@property NSString *MessageText;

@property NSMutableAttributedString *MessageAttributedText;

@property NSString *MessageTime;

@property NSString *MessageSenderTitle;

@property BOOL IsMultyChatMessage;

@property BOOL IsReaded;

@property NSString *Status;

@property NSString *SenderXmppId;

@property NSNumber *DeliveryStatus;

@property NSArray *LinksRangesArray;

@property NSNumber *IsSelected;

@property NSNumber *WasEdited;

@property NSString *AvatarPath;

//@property UIImage *MessageSenderAvatar;

// Metrics
@property CGFloat CellHeight;

@property CGSize TextSize;

- (void) CalcMessageTextViewSize;

- (void) CalcCellHeight;

- (void) PrepareAttributedString;

@end
