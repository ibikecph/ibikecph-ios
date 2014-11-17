//
//  SMRouteTimeInfo.h
//  I Bike CPH
//
//  Created by Nikola Markovic on 8/6/13.
//  Copyright (c) 2013 City of Copenhagen. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SMSingleRouteInfo.h"

/**
 * Route time information. Has route information (SMSingleRouteInfo), source time, and destination time.
 */
@interface SMRouteTimeInfo : NSObject

-(id)initWithRouteInfo:(SMSingleRouteInfo*)routeInfo sourceTime:(SMTime*)sourceTime destinationTime:(SMTime*)destTime;

@property(nonatomic, strong) SMSingleRouteInfo* routeInfo;
@property(nonatomic, strong) SMTime* sourceTime;
@property(nonatomic, strong) SMTime* destTime;
@end
