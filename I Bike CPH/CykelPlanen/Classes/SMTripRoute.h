//
//  SMTripRoute.h
//  I Bike CPH
//
//  Created by Nikola Markovic on 7/5/13.
//  Copyright (c) 2013 City of Copenhagen. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SMRoute.h"
#import "SMBrokenRouteInfo.h"
#import "SMTransportationLine.h"
@class SMTripRoute;

@protocol SMBreakRouteDelegate <NSObject>
- (void) didStartBreakingRoute:(SMTripRoute*)route;
- (void) didFinishBreakingRoute:(SMTripRoute*)route;
- (void) didFailBreakingRoute:(SMTripRoute*)route;
- (void) didCalculateRouteDistances:(SMTripRoute*)route;
@end

@interface SMTripRoute : NSObject<SMRouteDelegate>

-(id) initWithRoute:(SMRoute*)route;

@property(nonatomic, readonly) BOOL isValid;

@property(nonatomic, strong) SMRoute* fullRoute;
@property(nonatomic, strong) SMBrokenRouteInfo* brokenRouteInfo;
@property(nonatomic, strong) NSArray* brokenRoutes; // array of SMRoutes that compose this route
@property(nonatomic, strong) NSArray* transportationRoutes; // sorted by bike distance
@property(nonatomic, weak) id<SMBreakRouteDelegate> delegate;

-(BOOL) breakRoute;
-(NSArray*)sortedEndStationsForTransportationLine:(SMTransportationLine*)pTransportationLine;

-(CLLocation *)start;
-(CLLocation *)end;
@end
