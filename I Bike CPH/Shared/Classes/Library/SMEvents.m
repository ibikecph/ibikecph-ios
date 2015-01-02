//
//  SMEvents.m
//  I Bike CPH
//
//  Created by Ivan Pavlovic on 28/01/2013.
//  Copyright (c) 2013 City of Copenhagen. All rights reserved.
//

#import "SMEvents.h"

#import <EventKit/EventKit.h>
#import "SMAppDelegate.h"

@implementation SMEvents

- (void)getLocalEvents {
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDateComponents *addTime = [[NSDateComponents alloc] init];
    addTime.day = CALENDAR_MAX_DAYS;
    NSDate *toDate = [calendar dateByAddingComponents:addTime toDate:[NSDate date] options:0];
    
    EKEventStore * es = [[EKEventStore alloc] init];
    if ([es respondsToSelector:@selector(requestAccessToEntityType:completion:)]) {
        [es requestAccessToEntityType:EKEntityTypeEvent completion:^(BOOL granted, NSError *error) {
            if (granted) {                
                NSPredicate * pred = [es predicateForEventsWithStartDate:[NSDate date] endDate:toDate calendars:nil];
                NSArray * arr = [es eventsMatchingPredicate:pred];
//                debugLog(@"Found events (iOS6): %@", arr);
                if (arr && self.delegate) {
                    NSMutableArray * ret = [NSMutableArray arrayWithCapacity:[arr count]];
                    for (EKEvent * ek in arr) {
                        if (ek.location) {
                            NSString * title = @"";
                            NSString * location = @"";
                            NSDate * startDate = [NSDate date];
                            NSDate * endDate = [NSDate date];
                            
                            if (ek.title) {
                                title = ek.title;
                            }
                            location = ek.location;
                            if (ek.startDate) {
                                startDate = ek.startDate;
                                endDate = startDate;
                            }
                            if (ek.endDate) {
                                endDate = ek.endDate;
                            }
                            
                            [ret addObject:@{
                             @"name" : title,
                             @"address" : location,
                             @"startDate" : startDate,
                             @"endDate" : endDate,
                             @"source" : @"ios"
                             }];
                        }
                    }
                    [self.delegate localEventsFound:ret];
                }
            }
        }];
    } else {
        NSPredicate * pred = [es predicateForEventsWithStartDate:[NSDate date] endDate:toDate calendars:nil];
        NSArray * arr = [es eventsMatchingPredicate:pred];
//        debugLog(@"Found events (iOS5): %@", arr);
        if (arr && self.delegate) {
            NSMutableArray * ret = [NSMutableArray arrayWithCapacity:[arr count]];
            for (EKEvent * ek in arr) {
                if (ek.location) {
                    NSString * title = @"";
                    NSString * location = @"";
                    NSDate * startDate = [NSDate date];
                    NSDate * endDate = [NSDate date];
                    
                    if (ek.title) {
                        title = ek.title;
                    }
                    location = ek.location;
                    if (ek.startDate) {
                        startDate = ek.startDate;
                        endDate = startDate;
                    }
                    if (ek.endDate) {
                        endDate = ek.endDate;
                    }
                    
                    [ret addObject:@{
                     @"name" : title,
                     @"address" : location,
                     @"startDate" : startDate,
                     @"endDate" : endDate,
                     @"source" : @"ios"
                     }];
                }
            }
            [self.delegate localEventsFound:ret];
        }
    }
}

- (void)getAllEvents {
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDateComponents *addTime = [[NSDateComponents alloc] init];
    addTime.day = CALENDAR_MAX_DAYS;
    NSDate *toDate = [calendar dateByAddingComponents:addTime toDate:[NSDate date] options:0];
    
    EKEventStore * es = [[EKEventStore alloc] init];
    if ([es respondsToSelector:@selector(requestAccessToEntityType:completion:)]) {
        [es requestAccessToEntityType:EKEntityTypeEvent completion:^(BOOL granted, NSError *error) {
            if (granted) {
                NSPredicate * pred = [es predicateForEventsWithStartDate:[NSDate date] endDate:toDate calendars:nil];
                NSArray * arr = [es eventsMatchingPredicate:pred];
                //                debugLog(@"Found events (iOS6): %@", arr);
                if (arr && self.delegate) {
                    NSMutableArray * ret = [NSMutableArray arrayWithCapacity:[arr count]];
                    for (EKEvent * ek in arr) {
                        if (ek.location) {
                            NSString * title = @"";
                            NSString * location = @"";
                            NSDate * startDate = [NSDate date];
                            NSDate * endDate = [NSDate date];
                            
                            if (ek.title) {
                                title = ek.title;
                            }
                            location = ek.location;
                            if (ek.startDate) {
                                startDate = ek.startDate;
                                endDate = startDate;
                            }
                            if (ek.endDate) {
                                endDate = ek.endDate;
                            }
                            
                            [ret addObject:@{
                             @"name" : title,
                             @"address" : location,
                             @"startDate" : startDate,
                             @"endDate" : endDate,
                             @"source" : @"ios"
                             }];
                        }
                    }
                    [self.delegate localEventsFound:ret];
                }
            }
        }];
    } else {
        NSPredicate * pred = [es predicateForEventsWithStartDate:[NSDate date] endDate:toDate calendars:nil];
        NSArray * arr = [es eventsMatchingPredicate:pred];
        //        debugLog(@"Found events (iOS5): %@", arr);
        if (arr && self.delegate) {
            NSMutableArray * ret = [NSMutableArray arrayWithCapacity:[arr count]];
            for (EKEvent * ek in arr) {
                if (ek.location) {
                    NSString * title = @"";
                    NSString * location = @"";
                    NSDate * startDate = [NSDate date];
                    NSDate * endDate = [NSDate date];
                    
                    if (ek.title) {
                        title = ek.title;
                    }
                    location = ek.location;
                    if (ek.startDate) {
                        startDate = ek.startDate;
                        endDate = startDate;
                    }
                    if (ek.endDate) {
                        endDate = ek.endDate;
                    }
                    
                    [ret addObject:@{
                     @"name" : title,
                     @"address" : location,
                     @"startDate" : startDate,
                     @"endDate" : endDate,
                     @"source" : @"ios"
                     }];
                }
            }
            [self.delegate localEventsFound:ret];
        }
    }
}

@end
