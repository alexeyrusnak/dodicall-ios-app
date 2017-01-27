//
//  UiHistoryStatisticsCell.h
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

@interface UiHistoryStatisticsCell : UITableViewCell

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *LeadingToNameLeft;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *LeadingToLockLeft;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *LeadingToNameRight;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *LeadingToLockRight;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *TrailingToPlus;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *TrailingToSuperview;



@property (weak, nonatomic) IBOutlet UIButton *MessageButton;
@property (weak, nonatomic) IBOutlet UIButton *CallButton;
@property (weak, nonatomic) IBOutlet UIButton *AddButton;

@property (weak, nonatomic) IBOutlet UILabel *TitleLabel;

@property (weak, nonatomic) IBOutlet UILabel *TitleIndicatorLabel;

@property (weak, nonatomic) IBOutlet UIImageView *AvatarImage;

@property (weak, nonatomic) IBOutlet UIImageView *DodicallImage;

@property (weak, nonatomic) IBOutlet UIImageView *IncomingEncryptedImage;

@property (weak, nonatomic) IBOutlet UIImageView *OutgoingEncryptedImage;

@property (weak, nonatomic) IBOutlet UILabel *DateLabel;

@property (weak, nonatomic) IBOutlet UILabel *IncomingSuccessfulLabel;


@property (weak, nonatomic) IBOutlet UILabel *IncomingUnsuccessfulLabel;

@property (weak, nonatomic) IBOutlet UILabel *OutgoingSuccessfulLabel;

@property (weak, nonatomic) IBOutlet UILabel *OutgoingUnsuccessfulLabel;

@end
