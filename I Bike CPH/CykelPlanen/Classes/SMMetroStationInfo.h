//
//  SMMetroStationInfo.h
//  I Bike CPH
//
//  Created by Nikola Markovic on 8/19/13.
//  Copyright (c) 2013 City of Copenhagen. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 * Metro station information. Has station and time offset.
 */
@interface SMMetroStationInfo : NSObject

-(id)initWithStation:(SMStationInfo*)station timeOffset:(NSNumber*)number;

@property(nonatomic, strong) SMStationInfo* station;
@property(nonatomic, strong) NSNumber* timeOffset;
@end
