//
//  SMTravelInfo.h
//  I Bike CPH
//
//  Created by Nikola Markovic on 8/5/13.
//  Copyright (c) 2013 City of Copenhagen. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SMStationInfo.h"

@interface SMArrivalInfo : NSObject

-(id)initWithDepartures:(NSArray*)departures arrivals:(NSArray*)arrivals;

@property(nonatomic, strong) NSArray* departures;
@property(nonatomic, strong) NSArray* arrivals;
@property(nonatomic, strong) SMStationInfo* station;

@end
