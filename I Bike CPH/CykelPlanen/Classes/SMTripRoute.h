//
//  SMTripRoute.h
//  I Bike CPH
//
//  Created by Nikola Markovic on 7/5/13.
//  Copyright (c) 2013 City of Copenhagen. All rights reserved.
//

#import "SMBrokenRouteInfo.h"
#import "SMRoute.h"
#import "SMTransportationLine.h"
#import <Foundation/Foundation.h>
@class SMTripRoute;

@protocol SMBreakRouteDelegate<NSObject>
- (void)didStartBreakingRoute:(SMTripRoute *)route;
- (void)didFinishBreakingRoute:(SMTripRoute *)route;
- (void)didFailBreakingRoute:(SMTripRoute *)route;
- (void)didCalculateRouteDistances:(SMTripRoute *)route;
@end

/**
 * Trip route. Has bool if valid, full route, broken route information, broken routes (array of SMRoutes that compose this route), transportation
 * route (sorted by bike distance), delegate. Used in SMUser.
 */
@interface SMTripRoute : NSObject<SMRouteDelegate>

- (id)initWithRoute:(SMRoute *)route;

@property(nonatomic, readonly) BOOL isValid;

@property(nonatomic, strong) SMRoute *fullRoute;
@property(nonatomic, strong) SMBrokenRouteInfo *brokenRouteInfo;
@property(nonatomic, strong) NSArray *brokenRoutes;          // array of SMRoutes that compose this route
@property(nonatomic, strong) NSArray *transportationRoutes;  // sorted by bike distance
@property(nonatomic, weak) id<SMBreakRouteDelegate> delegate;

- (BOOL)breakRoute;
- (NSArray *)sortedEndStationsForTransportationLine:(SMTransportationLine *)pTransportationLine;

- (CLLocation *)start;
- (CLLocation *)end;
@end
