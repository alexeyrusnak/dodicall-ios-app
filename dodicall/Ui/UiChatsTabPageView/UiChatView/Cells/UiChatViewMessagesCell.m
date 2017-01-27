//
//  UiChatViewMessagesCell.m
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

#import "UiChatViewMessagesCell.h"

@implementation UiChatViewMessagesCell
{
    BOOL Awaked;
}

- (void)awakeFromNib
{
    if(Awaked)
        return;
    
    self.BubbleContainer = (UIView *)[self viewWithTag:BubbleContainerTag];
    
    self.MessageTimeLabel = (UILabel *)[self viewWithTag:MessageTimeLabelTag];
    
    self.MessageContactStatusPanel = (UIView *)[self viewWithTag:MessageContactStatusPanelTag];
    
    self.MessageContactStatusPanelStatus = (UIView *)[self viewWithTag:MessageContactStatusPanelStatusTag];
    
    self.MessageContactStatusPanelContactTitle = (UILabel *)[self viewWithTag:MessageContactStatusPanelContactTitleTag];
    
    self.MessageDeliverStatusPanel = (UIView *)[self viewWithTag:MessageDeliverStatusPanelTag];
    
    self.EditImageView = (UIImageView *)[self viewWithTag:EditImageViewTag];
    
    [self CollectSetupConstraints];
    
    Awaked = YES;
}

- (void) SetupAll
{
    CGFloat BubbleWidth = self.ViewModel.TextSize.width + 2*MessageTextViewMarginLeft;
    
    if([self.ViewModel.MessageDirection isEqualToString:UiChatMessageDirectionTypeOutgoing])
    {
        if(self.ViewModel.DeliveryStatus)
        {
            if(BubbleWidth < MessageViewDeliveryStatusPanelWidth + MessageViewTimeLabelWidth)
            {
                BubbleWidth = MessageViewDeliveryStatusPanelWidth + MessageViewTimeLabelWidth;
            }
            
            [self.MessageDeliverStatusPanel setAlpha:1];
            [self.MessageDeliverStatusPanel setHidden:NO];
        }
        else
        {
            [self.MessageDeliverStatusPanel setAlpha:0];
            [self.MessageDeliverStatusPanel setHidden:YES];
        }
        
        
    }
    
    if([self.ViewModel.WasEdited boolValue])
    {
        [self.EditImageView setAlpha:1];
        
        if([self.ChatView.ViewModel.EditModeEnabled boolValue])
            BubbleWidth -= MessageEditIconWidthWithMargin;
    }
    else
    {
        [self.EditImageView setAlpha:0];
    }
    
    if(BubbleWidth < MessageViewTimeLabelWidth + MessageViewOutgoingTimeLabelMarginLeft + MessageViewOutgoingTimeLabelMarginRight)
    {
        BubbleWidth = MessageViewTimeLabelWidth + MessageViewOutgoingTimeLabelMarginLeft + MessageViewOutgoingTimeLabelMarginRight;
    }
    
    self.BubbleWidthConstraint.constant = BubbleWidth;
    
    [self.MessageTimeLabel setText:self.ViewModel.MessageTime];
    
    if(self.MessageContactStatusPanel)
    {
        if(!self.ViewModel.IsMultyChatMessage)
        {
            [self.MessageContactStatusPanel setHidden:YES];
            self.MessageViewContactStatusPanelHeightConstraint.constant = 0;
        }
        else
        {
            [self.MessageContactStatusPanelContactTitle setText:self.ViewModel.MessageSenderTitle];
            [self.MessageContactStatusPanel setHidden:NO];
            self.MessageViewContactStatusPanelHeightConstraint.constant = MessageViewContactStatusPanelHeight;
        }
    }
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    
    [super setSelected:selected animated:animated];
    
}

#pragma mark Metrics

- (void) CollectSetupConstraints
{
    
    for(NSLayoutConstraint *Constraint in self.contentView.constraints)
    {
        if([Constraint.identifier isEqualToString:@"BubbleContainerMarginTop"])
        {
            self.BubbleContainerMarginTopConstraint = Constraint;
            
            self.BubbleContainerMarginTopConstraint.constant = BubbleContainerMarginTop;
        }
        
        else if([Constraint.identifier isEqualToString:@"BubbleContainerMarginRight"])
        {
            self.BubbleContainerMarginRightConstraint = Constraint;
            
            self.BubbleContainerMarginRightConstraint.constant = BubbleContainerMarginRight;
        }
        
        else if([Constraint.identifier isEqualToString:@"BubbleContainerMarginBottom"])
        {
            self.BubbleContainerMarginBottomConstraint = Constraint;
            
            self.BubbleContainerMarginBottomConstraint.constant = BubbleContainerMarginBottom;
        }
        
        else if([Constraint.identifier isEqualToString:@"BubbleContainerMarginLeft"])
        {
            self.BubbleContainerMarginLeftConstraint = Constraint;
            
            self.BubbleContainerMarginLeftConstraint.constant = BubbleContainerMarginLeft;
        }
        
        else if([Constraint.identifier isEqualToString:@"MessageViewContactStatusPanelMarginTop"])
        {
            self.MessageViewContactStatusPanelMarginTopConstraint = Constraint;
            
            self.MessageViewContactStatusPanelMarginTopConstraint.constant = MessageViewContactStatusPanelMarginTop;
        }
    }
    
    for(NSLayoutConstraint *Constraint in self.BubbleContainer.constraints)
    {
        if([Constraint.identifier isEqualToString:@"BubbleWidth"])
            self.BubbleWidthConstraint = Constraint;
    }
    
    if(self.MessageContactStatusPanel)
    {
        for(NSLayoutConstraint *Constraint in self.MessageContactStatusPanel.constraints)
        {
            if([Constraint.identifier isEqualToString:@"MessageViewContactStatusPanelHeight"])
                self.MessageViewContactStatusPanelHeightConstraint = Constraint;
        }
    }
}

@end
