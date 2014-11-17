//
//  SMReportMailCell.h
//  I Bike CPH
//
//  Created by Igor Jerković on 7/23/13.
//  Copyright (c) 2013 City of Copenhagen. All rights reserved.
//

#import <UIKit/UIKit.h>

/**
 * Table view cell for report. Has check box button, and email text view. Used in SMReportErrorController
 */
@interface SMReportMailCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UIButton *checkboxMail;
@property (weak, nonatomic) IBOutlet UITextView *email;
- (IBAction)checkboxSelected:(id)sender;

+ (CGFloat)getHeight;

@end
