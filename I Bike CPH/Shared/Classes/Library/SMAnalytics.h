//
//  SMAnalytics.h
//  I Bike CPH
//
//  Created by Ivan Pavlovic on 12/11/2013.
//  Copyright (c) 2013 City of Copenhagen. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 * Google Analytics wrapper
 */
@interface SMAnalytics : NSObject

/**
 Convenience method for tracking event on Google Analytics shared instance.
 Example usage:
 @code [SMAnalytics trackEventWithCategory:@"Account" withAction:@"Save" withLabel:@"Data" withValue:0];
 @endcode
 @see https://developers.google.com/analytics/devguides/collection/ios for more information.
 @param category
 Label for the category for action
 @param action
 Label for the action
 @return YES always, for no particular reason (legacy)
 */
+ (BOOL)trackEventWithCategory:(NSString*)category withAction:(NSString*)action withLabel:(NSString*)label withValue:(NSInteger)value;
+ (BOOL)trackTimingWithCategory:(NSString*)category withValue:(NSTimeInterval)time withName:(NSString*)name withLabel:(NSString*)label;
+ (BOOL)trackSocial:(NSString*)social withAction:(NSString*)action withTarget:(NSString*)url;

@end
