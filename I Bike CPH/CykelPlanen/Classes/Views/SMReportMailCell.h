//
//  SMReportMailCell.h
//  I Bike CPH
//
//  Created by Igor Jerković on 7/23/13.
//  Copyright (c) 2013 City of Copenhagen. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SMReportMailCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UIButton *checkboxMail;
@property (weak, nonatomic) IBOutlet UITextView *email;
- (IBAction)checkboxSelected:(id)sender;

+ (CGFloat)getHeight;

@end
