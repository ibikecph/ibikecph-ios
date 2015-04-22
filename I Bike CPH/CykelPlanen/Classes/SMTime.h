//
//  SMTime.h
//  I Bike CPH
//
//  Created by Nikola Markovic on 8/6/13.
//  Copyright (c) 2013 City of Copenhagen. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 * Time to calculate difference between two and format to string. Has hours and minutes. Used in SMDepartureInfo, SMRouteInfoViewController, SMTransportation, SMTransportationLine.
 */
@interface SMTime : NSObject

+(SMTime*)timeFromString:(NSString*)timeString;
-(id)initWithTime:(SMTime*)time;

@property(nonatomic, assign) int hour;
@property(nonatomic, assign) int minutes;

-(int)differenceInMinutesFrom:(SMTime *)other;
-(SMTime*)differenceFrom:(SMTime*)other;
-(BOOL)isBetween:(SMTime*)first and:(SMTime*)second;
-(void)addMinutes:(int)mins;
@end
