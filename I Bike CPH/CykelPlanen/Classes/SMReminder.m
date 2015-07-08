//
//  SMReminder.m
//  I Bike CPH
//
//  Created by Nikola Markovic on 7/10/13.
//  Copyright (c) 2013 City of Copenhagen. All rights reserved.
//

#import "SMReminder.h"

#define REMINDERS_FILE_NAME @"reminders.plist"

@implementation SMReminder

+ (void)clear {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = paths.firstObject;
    NSString *path = [documentsDirectory stringByAppendingPathComponent:REMINDERS_FILE_NAME];

    // Delete file
    [[NSFileManager defaultManager] removeItemAtPath:path error:nil];
    // Remove all scheduled local notifications
    [[UIApplication sharedApplication] cancelAllLocalNotifications];
}

@end
