//
//  UiChatViewMessagesCellOutgoingText.m
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
#import "UiChatViewMessagesCellOutgoingText.h"
#import "UiNavRouter.h"

@implementation UiChatViewMessagesCellOutgoingText

- (void)awakeFromNib {
    
    [super awakeFromNib];
    
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    
    [super setSelected:selected animated:animated];
    
}

-(BOOL) canPerformAction:(SEL)action withSender:(id)sender
{
    return (action == @selector(Edit:) || action == @selector(Delete:));
}

/*
-(BOOL)canBecomeFirstResponder
{
    return YES;
}
 */

-(void) Edit: (id) sender
{
    if(self.ChatView)
    {
        if([self.ChatView.ViewModel.EditModeEnabled boolValue])
            [self.ChatView.ViewModel EnableEditMode: NO];
        
        [UiChatsTabNavRouter ShowEditMessageViewForMessage:self.ViewModel.MessageData];
    }
}

-(void) Delete: (id) sender
{
    if(self.ChatView)
    {
        
        [self.MessageTextView setSelectedRange:NSMakeRange(0, 0)];
        [self.MessageTextView resignFirstResponder];
        
        [self.ChatView.ViewModel SelectCell:YES withMessagesCellModel:self.ViewModel];
        
        [self.ChatView.ViewModel SetSelected:self.ViewModel];
        
        [self.ChatView.ViewModel EnableEditMode: YES];
        
    }
}

@end
