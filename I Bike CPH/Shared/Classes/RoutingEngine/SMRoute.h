//
//  SMRoute.h
//  I Bike CPH
//
//  Created by Petra Markovic on 1/28/13.
//  Copyright (C) 2013 City of Copenhagen.  All rights reserved.
//
//  This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0.
//  If a copy of the MPL was not distributed with this file, You can obtain one at
//  http://mozilla.org/MPL/2.0/.
//

#import <CoreLocation/CoreLocation.h>
#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, SMRouteType) {
    SMRouteTypeBike = 0,
    SMRouteTypeWalk = 1,
    SMRouteTypeSTrain = 2,
    SMRouteTypeMetro = 3,
    SMRouteTypeBus = 4,
    SMRouteTypeFerry = 5,
    SMRouteTypeTrain = 6,
};

#import "SMRequestOSRM.h"
#import "SMTurnInstruction.h"

@class SMRoute;

@protocol SMRouteDelegate<NSObject>
@required
- (void)updateTurn:(BOOL)firstElementRemoved;
- (void)reachedDestination;
- (void)updateRoute;
- (void)startRoute:(SMRoute *)route;
- (void)routeNotFound;
- (void)serverError;

@optional
- (void)routeRecalculationStarted;
- (void)routeRecalculationDone;
@end

@interface SMRoute : NSObject<SMRequestOSRMDelegate>

@property(nonatomic, weak) id<SMRouteDelegate> delegate;

@property(nonatomic, strong) NSMutableArray *waypoints;
@property(nonatomic, strong) NSMutableArray *pastTurnInstructions;  // turn instructions from first to the last passed turn
@property(nonatomic, strong) NSMutableArray *turnInstructions;      // turn instruction from next to the last
@property(nonatomic, strong) NSMutableArray *visitedLocations;
@property(nonatomic, assign) SMRouteType routeType;

@property(nonatomic) CGFloat distanceLeft;
@property CLLocationCoordinate2D locationStart;
@property CLLocationCoordinate2D locationEnd;
@property NSString *startDescription;
@property NSString *endDescription;
@property NSDate *startDate;
@property NSDate *endDate;
@property NSString *transportLine;
@property NSInteger estimatedTimeForRoute;
@property NSInteger estimatedRouteDistance;
@property NSString *destinationHint;
@property CGFloat maxMarginRadius;
@property(nonatomic, assign) CGFloat estimatedAverageSpeed;

@property(nonatomic, strong) CLLocation *lastCorrectedLocation;

@property(nonatomic, strong) NSString *longestStreet;

@property(nonatomic, strong) NSString *osrmServer;

- (void)visitLocation:(CLLocation *)loc;
- (CLLocation *)getStartLocation;
- (CLLocation *)getEndLocation;
- (NSDictionary *)save;

- (CGFloat)calculateDistanceTraveled;
- (NSString *)timePassed;

- (id)initWithRouteStart:(CLLocationCoordinate2D)start end:(CLLocationCoordinate2D)end delegate:(id<SMRouteDelegate>)delegate;
- (id)initWithRouteStart:(CLLocationCoordinate2D)start
                     end:(CLLocationCoordinate2D)end
                delegate:(id<SMRouteDelegate>)delegate
               routeJSON:(NSDictionary *)routeJSON;
- (void)recalculateRoute:(CLLocation *)loc;

@end