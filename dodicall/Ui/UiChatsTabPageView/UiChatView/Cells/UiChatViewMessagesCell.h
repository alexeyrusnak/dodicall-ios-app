//
//  UiChatViewMessagesCell.h
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

#import <UIKit/UIKit.h>
#import "UiChatViewMessagesCellModel.h"
#import "UiChatView.h"

#define UiChatViewMessagesCellIdentifierOutgoingText    @"UiChatViewMessagesCellOutgoingText"
#define UiChatViewMessagesCellIdentifierIncomingText    @"UiChatViewMessagesCellIncomingText"
#define UiChatViewMessagesCellIdentifierInfoText        @"UiChatViewMessagesCellIdentifierInfoText"
typedef NSString*               UiChatViewMessagesCellIdentifier;


#define BubbleContainerTag 10

#define MessageTimeLabelTag 50

#define MessageContactStatusPanelTag 20

#define MessageContactStatusPanelStatusTag 21

#define MessageContactStatusPanelContactTitleTag 22

#define MessageDeliverStatusPanelTag 30

#define MessageDeliverStatusLabelTag 31

#define MessageDeliverStatusIndicator0Tag 32

#define MessageDeliverStatusIndicator1Tag 33

#define MessageDeliverStatusIndicator2Tag 34

#define MessageDeliverStatusIndicator3Tag 35

#define EditImageViewTag 45


@class UiChatView;

@interface UiChatViewMessagesCell : UITableViewCell

@property (weak, nonatomic) UiChatView *ChatView;

@property (weak, nonatomic) UiChatViewMessagesCellModel *ViewModel;

@property (weak, nonatomic) IBOutlet UIView *MessageContactStatusPanel;

@property (weak, nonatomic) IBOutlet UIView *MessageContactStatusPanelStatus;

@property (weak, nonatomic) IBOutlet UILabel *MessageContactStatusPanelContactTitle;

@property (weak, nonatomic) IBOutlet UIView *BubbleContainer;

@property (weak, nonatomic) IBOutlet UIImageView *BubbleImage;

@property (weak, nonatomic) IBOutlet UILabel *MessageTimeLabel;

@property (weak, nonatomic) IBOutlet UIView *MessageDeliverStatusPanel;

@property (weak, nonatomic) IBOutlet UIImageView *EditImageView;

@property (weak, nonatomic)  NSIndexPath *CellIndexPath;

- (void) SetupAll;

// Metrics

@property NSLayoutConstraint *BubbleContainerMarginTopConstraint;

@property NSLayoutConstraint *BubbleContainerMarginRightConstraint;

@property NSLayoutConstraint *BubbleContainerMarginBottomConstraint;

@property NSLayoutConstraint *BubbleContainerMarginLeftConstraint;

@property NSLayoutConstraint *BubbleWidthConstraint;

@property NSLayoutConstraint *MessageViewContactStatusPanelMarginTopConstraint;

@property NSLayoutConstraint *MessageViewContactStatusPanelHeightConstraint;

- (void) CollectSetupConstraints;

@end
