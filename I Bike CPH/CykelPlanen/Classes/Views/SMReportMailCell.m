//
//  SMReportMailCell.m
//  I Bike CPH
//
//  Created by Igor Jerković on 7/23/13.
//  Copyright (c) 2013 City of Copenhagen. All rights reserved.
//

#import "SMReportMailCell.h"

@implementation SMReportMailCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (IBAction)checkboxSelected:(id)sender {
    if (self.checkboxMail.selected) {
        [self.checkboxMail setSelected:NO];
    } else {
        [self.checkboxMail setSelected:YES];
    }
}

+ (CGFloat)getHeight {
    return 120;
}

@end
