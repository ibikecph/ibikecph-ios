//
//  SMReminderTableViewCell.m
//  I Bike CPH
//
//  Created by Igor Jerković on 7/12/13.
//  Copyright (c) 2013 City of Copenhagen. All rights reserved.
//

#import "SMReminderTableViewCell.h"

@interface SMReminderTableViewCell()
@property (weak, nonatomic) IBOutlet UILabel *day;
@property (weak, nonatomic) IBOutlet UISwitch *reminderSwitch;
@end

@implementation SMReminderTableViewCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        
    }
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];
    
}

- (IBAction)onSwitchSet:(UISwitch *)sender {
    // Save reminders
    [self stateChanged:sender];
    NSLog(@"Reminder set %d for %d", (int)self.reminderSwitch.isOn, self.currentDay);
}

-(void)stateChanged:(id)sender{
    [[SMReminder sharedInstance] setReminder:self.reminderSwitch.isOn forDay:self.currentDay];
}

- (void)setupWithTitle:(NSString*)title {
    [self.day setText:title];
    [self.reminderSwitch addTarget:self action:@selector(stateChanged:) forControlEvents:UIControlEventValueChanged];
    [self.reminderSwitch setOn:[[SMReminder sharedInstance] hasReminderForDay:self.currentDay]  animated:NO];
}

@end
