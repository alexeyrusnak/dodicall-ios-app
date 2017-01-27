//
//  UiChatViewMessagesCellInfoText.m
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

#import "UiChatViewMessagesCellInfoText.h"

@implementation UiChatViewMessagesCellInfoText
{
    BOOL Awaked;
}


- (void)awakeFromNib
{
    if(Awaked)
        return;
    
    self.MessageTextView = (UITextView *)[self viewWithTag:MessageTextViewTag];
    
    [self CollectSetupConstraints];
    
    Awaked = YES;
    
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];
}

- (void) SetupAll
{
    if(self.ViewModel.MessageAttributedText)
    {
        [self.MessageTextView setAttributedText:self.ViewModel.MessageAttributedText];
    }
    else
    {
        [self.MessageTextView setText:self.ViewModel.MessageText];
    }
    
}

#pragma mark Metrics

- (void) CollectSetupConstraints
{
    
    for(NSLayoutConstraint *Constraint in self.contentView.constraints)
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
