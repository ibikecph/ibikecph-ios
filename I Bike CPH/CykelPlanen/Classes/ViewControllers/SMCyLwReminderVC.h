//
//  SMCyReminderVC.h
//  Cykelsuperstierne
//
//  Created by Rasko on 6/26/13.
//  Copyright (c) 2013 Rasko Gojkovic. All rights reserved.
//

#import <UIKit/UIKit.h>
//#import "SMCyBaseVC.h" // FIXME: Clean up outcommented code

/**
 * View controller to set bike reminders when onboarding.
 */
@interface SMCyLwReminderVC : UIViewController //SMCyBaseVC

@property (weak, nonatomic) IBOutlet UISwitch *swMonday;
@property (weak, nonatomic) IBOutlet UISwitch *swTuesday;
@property (weak, nonatomic) IBOutlet UISwitch *swWednesday;
@property (weak, nonatomic) IBOutlet UISwitch *swThursday;
@property (weak, nonatomic) IBOutlet UISwitch *swFriday;


- (IBAction)saveReminder:(UIButton *)sender;
- (IBAction)skip:(UIButton *)sender;
@end
