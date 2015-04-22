//
//  SMReminder.h
//  I Bike CPH
//
//  Created by Nikola Markovic on 7/10/13.
//  Copyright (c) 2013 City of Copenhagen. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum {
    DayUndefined= -1,
    DayMonday= 0,
    DayTuesday= 1,
    DayWednesday= 2,
    DayThursday= 3,
    DayFriday= 4
} Day;

/**
 * Handler for bike reminders.
 */
@interface SMReminder : NSObject

+(SMReminder*)sharedInstance;
-(void)setReminder:(BOOL)shouldRemind forDay:(Day)day;
-(void)setReminder:(BOOL)shouldRemind forDay:(Day)day save:(BOOL)shouldSave;
-(BOOL)hasReminderForDay:(Day)day;
-(void)save;
-(BOOL)isReminderScreenShown;
@end
