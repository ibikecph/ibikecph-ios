//
//  SMReminder.m
//  I Bike CPH
//
//  Created by Nikola Markovic on 7/10/13.
//  Copyright (c) 2013 City of Copenhagen. All rights reserved.
//

#import "SMReminder.h"

#define REMINDERS_FILE_NAME @"reminders.plist"
#define KEY_REMINDER_SHOWN @"KeyReminderShown"
#define KEY_DAYS @"KeyDays"

@implementation SMReminder{
    NSMutableDictionary* reminderDict;
    NSMutableDictionary* days;
}

+(SMReminder*)sharedInstance{
    static SMReminder* instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance= [SMReminder new];
    });
    return instance;
}

-(id)init{
    if(self=[super init]){
        [self load];
    }
    return self;
}

-(void)load{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *path = [documentsDirectory stringByAppendingPathComponent:REMINDERS_FILE_NAME];

    reminderDict= [NSDictionary dictionaryWithContentsOfFile:path];
    
    if(!reminderDict){ // no reminders set, yet
        reminderDict= [NSMutableDictionary new];
    }
    
    days= [[NSMutableDictionary alloc] initWithDictionary:[reminderDict objectForKey:KEY_DAYS]];
    
    if(!days){
        days= [NSMutableDictionary new];
        [reminderDict setObject:days forKey:KEY_DAYS];
    }
    
}

-(void)save{
    if(!reminderDict) // can't save a nil dictionary
        return;
    
    [reminderDict setObject:@YES forKey:KEY_REMINDER_SHOWN];
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *path = [documentsDirectory stringByAppendingPathComponent:REMINDERS_FILE_NAME];
    
    if([reminderDict writeToFile:path atomically:YES]){
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0L), ^{
            [self scheduleReminderNotifications];            
        });

    }
}

-(void)scheduleReminderNotifications{
    // remove all notifications
    [[UIApplication sharedApplication] cancelAllLocalNotifications];

    NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    NSDate* now= [NSDate new];

    const int SECONDS_IN_DAY = 60*60*24;
    for(int i=0; i<7; i++){
        NSDate* currentDate = [now dateByAddingTimeInterval:i*SECONDS_IN_DAY-1];
        NSDate* dayBeforeDate = [now dateByAddingTimeInterval:(i-1)*SECONDS_IN_DAY-1];
            
        NSCalendar* cal = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
        NSDateComponents* components = [cal components:NSYearCalendarUnit|NSMonthCalendarUnit|NSDayCalendarUnit fromDate:dayBeforeDate];
        [components setHour:20];    // 8pm
        NSDate* dayBefore8pm = [cal dateFromComponents:components];
        
        NSDateComponents *weekdayComponents =[gregorian components:NSWeekdayCalendarUnit fromDate:currentDate];
        NSInteger weekday = [weekdayComponents weekday]-2;
        NSNumber* notifyNum = [days objectForKey:[NSNumber numberWithInt:weekday].stringValue];
        if(notifyNum && [notifyNum boolValue ]){

            UILocalNotification* notification= [UILocalNotification new];

            //NSDate* fireDate= currentDate;
            [notification setTimeZone:[NSTimeZone defaultTimeZone]];
            [notification setFireDate:dayBefore8pm];                                // fireDate
            notification.soundName= UILocalNotificationDefaultSoundName;
            notification.repeatInterval= NSWeekCalendarUnit;
            [notification setAlertAction:@"Open App"];
            [notification setAlertBody:@"reminder_alert_text".localized];
            
            NSLog(@"Alarm set %@", [dayBefore8pm descriptionWithLocale:[NSLocale systemLocale]]);

            [notification setHasAction:YES];
            [[UIApplication sharedApplication] scheduleLocalNotification:notification];
        }
        NSLog(@"%@ %@",currentDate, (notifyNum.boolValue)?@"yes":@"no");
    }

}

-(void)setReminder:(BOOL)shouldRemind forDay:(Day)day save:(BOOL)shouldSave{
    if(!days){
        if(![reminderDict objectForKey:KEY_DAYS]){
            days= [NSMutableDictionary new];
        }else{
            days= [reminderDict objectForKey:KEY_DAYS];
        }

    }
    [days setObject:[NSNumber numberWithBool:shouldRemind] forKey:[NSNumber numberWithInt:day].stringValue];
    [reminderDict setObject:days forKey:KEY_DAYS];
    
    if(shouldSave){
        [self save];
    }
}

-(void)setReminder:(BOOL)shouldRemind forDay:(Day)day{
    [self setReminder:shouldRemind forDay:day save:YES];
}

-(BOOL)hasReminderForDay:(Day)day{
    NSNumber* notifyNum= [days objectForKey:[NSString stringWithFormat:@"%d",day]];
    return notifyNum && notifyNum.intValue;
}

-(BOOL)isReminderScreenShown{
    if(!reminderDict){
        return NO;
    }
    
    NSNumber* shown= [reminderDict objectForKey:KEY_REMINDER_SHOWN];
    return shown && shown.boolValue==YES;
}

@end
