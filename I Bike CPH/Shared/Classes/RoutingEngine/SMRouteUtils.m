//
//  SMRouteUtils.m
//  testRouteMe
//
//  Created by Rasko Gojkovic on 6/10/13.
//  Copyright (C) 2013 City of Copenhagen.
//
//  This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0.
//  If a copy of the MPL was not distributed with this file, You can obtain one at
//  http://mozilla.org/MPL/2.0/.
//

#import "NSString+Relevance.h"
#import "SMRouteConsts.h"
#import "SMRouteUtils.h"

@implementation SMRouteUtils

// Format time duration string (choose between seconds and hours)
NSString *formatTime(float seconds)
{
    return seconds > 60.0f ? [NSString stringWithFormat:@"%.0f %@", seconds / 60.0f, TIME_MINUTES_SHORT]
                           : [NSString stringWithFormat:@"%.0f %@", seconds, TIME_MINUTES_SHORT];
}

// Format time passed between two dates
NSString *formatTimePassed(NSDate *startDate, NSDate *endDate)
{
    NSCalendar *cal = [NSCalendar currentCalendar];
    NSDateComponents *comp = [cal components:(NSCalendarUnitDay | NSCalendarUnitHour | NSCalendarUnitMinute | NSCalendarUnitSecond)
                                    fromDate:startDate
                                      toDate:endDate
                                     options:0];

    NSString *timestr = @"";
    if (comp.day > 0) {
        timestr = [timestr stringByAppendingFormat:@"%li%@ ", (long)comp.day, TIME_DAYS_SHORT];
    }
    if (comp.hour > 0) {
        timestr = [timestr stringByAppendingFormat:@"%li%@ ", (long)comp.hour, TIME_HOURS_SHORT];
    }
    if (comp.minute > 0) {
        timestr = [timestr stringByAppendingFormat:@"%li%@ ", (long)comp.minute, TIME_MINUTES_SHORT];
    }
    if (comp.second > 0) {
        timestr = [timestr stringByAppendingFormat:@"%li%@", (long)comp.second, TIME_SECONDS_SHORT];
    }
    return timestr;
}

NSString *formatTimeLeft(NSInteger seconds)
{
    NSMutableArray *arr = [NSMutableArray array];

    NSInteger x = seconds / 86400;
    if (x > 0) {
        [arr addObject:[NSString stringWithFormat:@"%02li", (long)x]];
    }
    seconds = seconds % 86400;
    x = seconds / 3600;
    if (x > 0 || [arr count] > 0) {
        [arr addObject:[NSString stringWithFormat:@"%02li", (long)x]];
    }
    seconds = seconds % 3600;
    x = seconds / 60;
    if (x > 0 || [arr count] > 0) {
        [arr addObject:[NSString stringWithFormat:@"%02li", (long)x]];
    }
    seconds = seconds % 60;
    if ([arr count] > 0) {
        [arr addObject:[NSString stringWithFormat:@"%02li", (long)seconds]];
    }
    else {
        [arr addObject:@"00"];
        [arr addObject:[NSString stringWithFormat:@"%02li", (long)seconds]];
    }
    return [arr componentsJoinedByString:@":"];
}

NSString *expectedArrivalTime(NSInteger seconds)
{
    NSDate *d = [NSDate dateWithTimeInterval:seconds sinceDate:[NSDate date]];
    NSDateFormatter *df = [NSDateFormatter new];
    [df setDateFormat:@"HH:mm"];
    return [df stringFromDate:d];
}

+ (NSString *)formatDistanceInMeters:(float)distanceInMeters
{
    if (distanceInMeters < 5) {
        return @"";
    }
    else if (distanceInMeters <= 94) {
        return [NSString stringWithFormat:@"%.0f %@", roundf(distanceInMeters / 10.0f) * 10, DISTANCE_M_SHORT];
    }
    else if (distanceInMeters < 1000) {
        return [NSString stringWithFormat:@"%.0f %@", roundf(distanceInMeters / 100.0f) * 100, DISTANCE_M_SHORT];
    }
    else {
        return [NSString stringWithFormat:@"%.1f %@", distanceInMeters / 1000.0f, DISTANCE_KM_SHORT];
    }
}

+ (NSString *)routeFilenameFromTimestampForExtension:(NSString *)ext
{
    double tmpd = [[NSDate date] timeIntervalSince1970];
    NSString *path = nil;
    // CHECK IF FILE WITH NEW CURRENT DATE EXISTS
    for (;;) {
        path = [[[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:@"routes"]
            stringByAppendingPathComponent:[NSString stringWithFormat:@"%f.%@", tmpd, ext]];
        if ([[NSFileManager defaultManager] fileExistsAtPath:path])  // Does file already exist?
        {
            // IF YES INC BY 1 millisecond
            tmpd += 0.000001;
        }
        else {
            break;
        }
    }
    [[NSFileManager defaultManager] createDirectoryAtPath:[[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject]
                                                              stringByAppendingPathComponent:@"routes"]
                              withIntermediateDirectories:YES
                                               attributes:@{}
                                                    error:nil];
    return path;
}

+ (NSInteger)pointsForName:(NSString *)name address:(NSString *)address terms:(NSString *)terms
{
    NSMutableArray *termsArray = [NSMutableArray array];
    terms = [terms stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    for (NSString *str in [terms componentsSeparatedByString:@" "]) {
        if ([termsArray indexOfObject:str] == NSNotFound) {
            [termsArray addObject:str];
        }
    }
    NSInteger total = 0;

    NSInteger points = [name numberOfOccurenciesOfString:terms];
    if (points > 0) {
        total += points * POINTS_EXACT_NAME;
    }
    else {
        for (NSString *str in termsArray) {
            points = [name numberOfOccurenciesOfString:str];
            if (points > 0) {
                total += points * POINTS_PART_NAME;
            }
        }
    }

    points = [address numberOfOccurenciesOfString:terms];
    if (points > 0) {
        total += points * POINTS_EXACT_ADDRESS;
    }
    else {
        for (NSString *str in termsArray) {
            points = [address numberOfOccurenciesOfString:str];
            if (points > 0) {
                total += points * POINTS_PART_NAME;
            }
        }
    }

    return total;
}

@end