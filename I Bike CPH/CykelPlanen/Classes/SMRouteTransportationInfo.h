//
//  SMBrokenRouteInfo.h
//  I Bike CPH
//
//  Created by Nikola Markovic on 7/5/13.
//  Copyright (c) 2013 City of Copenhagen. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SMTransportationLine.h"

@interface SMRouteTransportationInfo : NSObject

@property(nonatomic, strong) NSArray* startingStationsSorted;
@property(nonatomic, strong) NSArray* endingStationsSorted;
@property(nonatomic, strong) SMTransportationLine* transportationLine;

@end