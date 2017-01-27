//
//  UiChatViewMessagesCellText.m
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

#import "UiChatViewMessagesCellText.h"

#import "ChatsManager.h"

#import "NUIRenderer.h"

#import "ContactsManager.h"

@implementation UiChatViewMessagesCellText
{
    BOOL Awaked;
}

- (void)awakeFromNib
{
    if(Awaked)
        return;
    
    [super awakeFromNib];
    
    self.MessageTextView = (UITextView *)[self viewWithTag:MessageTextViewTag];
    
    self.AvatarImageView = (UIImageView *)[self viewWithTag:AvatarViewTag];
    
    [self.MessageTextView.textContainer setLineFragmentPadding:MessageTextViewLineFragmentPadding];
 
    [self CollectSetupConstraints];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    
    [super setSelected:selected animated:animated];
    
}

- (void) SetupAll
{
    [super SetupAll];
    
    [self.MessageTextView setSelectedRange:NSMakeRange(0, 0)];
    
    if(self.ViewModel.MessageAttributedText)
    {
        [self.MessageTextView setAttributedText:self.ViewModel.MessageAttributedText];
    }
    else
    {
        [self.MessageTextView setText:self.ViewModel.MessageText];
    }
    
    [self SetOutgoingMessageDeliveryStatus];
    
    @weakify(self);
    [[[ContactsManager AvatarImageSignalForPathSignal:RACObserve(self.ViewModel, AvatarPath) WithTakeUntil:self.rac_prepareForReuseSignal] deliverOnMainThread] subscribeNext:^(UIImage *Image) {
        @strongify(self);
        self.AvatarImageView.image = Image;
    }];
}

- (void) SetOutgoingMessageDeliveryStatus
{
    if([self.ViewModel.MessageDirection isEqualToString:UiChatMessageDirectionTypeOutgoing])
    {
        UILabel *DeliveryStatusLabel = (UILabel *)[self viewWithTag:MessageDeliverStatusLabelTag];
        
        UIImageView *DeliveryStatusInd0 = (UIImageView *)[self viewWithTag:MessageDeliverStatusIndicator0Tag];
        
        UIImageView *DeliveryStatusInd1 = (UIImageView *)[self viewWithTag:MessageDeliverStatusIndicator1Tag];
        
        UIImageView *DeliveryStatusInd2 = (UIImageView *)[self viewWithTag:MessageDeliverStatusIndicator2Tag];
        
        UIImageView *DeliveryStatusInd3 = (UIImageView *)[self viewWithTag:MessageDeliverStatusIndicator3Tag];
        
        
        switch ([self.ViewModel.DeliveryStatus intValue]) {
            case ChatsMessageDeliveryStatusDeliveredToServer:
                [DeliveryStatusLabel setText:NSLocalizedString(@"Title_ChatsMessageDeliveryStatusDeliveredToServer", nil)];
                
                DeliveryStatusInd0.nuiClass = DeliveryStatusIndicatorOn;
                DeliveryStatusInd1.nuiClass = DeliveryStatusIndicatorOn;
                DeliveryStatusInd2.nuiClass = DeliveryStatusIndicatorOff;
                DeliveryStatusInd3.nuiClass = DeliveryStatusIndicatorOff;
                break;
                
            default:
                
                [DeliveryStatusLabel setText:NSLocalizedString(@"Title_ChatsMessageDeliveryStatusSended", nil)];
                
                DeliveryStatusInd0.nuiClass = DeliveryStatusIndicatorOn;
                DeliveryStatusInd1.nuiClass = DeliveryStatusIndicatorOff;
                DeliveryStatusInd2.nuiClass = DeliveryStatusIndicatorOff;
                DeliveryStatusInd3.nuiClass = DeliveryStatusIndicatorOff;
                
                break;
        }
        
        [NUIRenderer renderView:DeliveryStatusInd0 withClass:DeliveryStatusInd0.nuiClass];
        [NUIRenderer renderView:DeliveryStatusInd1 withClass:DeliveryStatusInd1.nuiClass];
        [NUIRenderer renderView:DeliveryStatusInd2 withClass:DeliveryStatusInd2.nuiClass];
        [NUIRenderer renderView:DeliveryStatusInd3 withClass:DeliveryStatusInd3.nuiClass];
        
    }
}

#pragma mark Metrics

- (void) CollectSetupConstraints
{
    
    [super CollectSetupConstraints];
    
    for(NSLayoutConstraint *Constraint in self.BubbleContainer.constraints)
    {
        if([Constraint.identifier isEqualToString:@"MessageTextViewMarginTop"])
        {
            self.MessageTextViewMarginTopConstraint = Constraint;
            
            self.MessageTextViewMarginTopConstraint.constant = MessageTextViewMarginTop;
        }
        
        else if([Constraint.identifier isEqualToString:@"MessageTextViewMarginBottom"])
        {
            self.MessageTextViewMarginBottomConstraint = Constraint;
            
            self.MessageTextViewMarginBottomConstraint.constant = MessageTextViewMarginBottom;
        }
        
        else if([Constraint.identifier isEqualToString:@"MessageTextViewMarginLeft"])
        {
            self.MessageTextViewMarginLeftConstraint = Constraint;
            
            self.MessageTextViewMarginLeftConstraint.constant = MessageTextViewMarginLeft;
        }
        
        else if([Constraint.identifier isEqualToString:@"MessageTextViewMarginRight"])
        {
            self.MessageTextViewMarginRightConstraint = Constraint;
            
            self.MessageTextViewMarginRightConstraint.constant = MessageTextViewMarginRight;
        }
    }
    
}

@end
