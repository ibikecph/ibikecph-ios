//
//  SMRoute.m
//  I Bike CPH
//
//  Created by Petra Markovic on 1/28/13.
//  Copyright (C) 2013 City of Copenhagen.  All rights reserved.
//
//  This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0.
//  If a copy of the MPL was not distributed with this file, You can obtain one at
//  http://mozilla.org/MPL/2.0/.
//

#import "SMGPSUtil.h"
#import "SMLocationManager.h"
#import "SMRoute.h"
#import "SMRouteUtils.h"

@interface SMRoute ()

@property(nonatomic, strong) SMRequestOSRM *request;
@property(nonatomic, strong) CLLocation *lastRecalcLocation;
@property(nonatomic, strong) NSObject *recalcMutex;
@property(nonatomic, strong) NSMutableArray *allTurnInstructions;
@property(nonatomic) NSUInteger nextWaypoint;
@property(nonatomic) NSInteger lastVisitedWaypointIndex;
@property(nonatomic) BOOL snapArrow;
@property(nonatomic) NSInteger longestDistance;
@property(nonatomic) BOOL recalculationInProgress;
@property(nonatomic) CGFloat tripDistance;

@end

@implementation SMRoute

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.routeType = SMRouteTypeBike;
        self.distanceLeft = -1;
        self.tripDistance = -1;
        self.lastVisitedWaypointIndex = -1;
        self.recalculationInProgress = NO;
        self.lastRecalcLocation = [[CLLocation alloc] initWithLatitude:0 longitude:0];
        self.recalcMutex = [NSObject new];
        self.osrmServer = OSRM_SERVER;
        self.nextWaypoint = 0;
        self.transportLine = @"";
        self.maxMarginRadius = 30;
    }
    return self;
}

- (instancetype)initWithRouteStart:(CLLocationCoordinate2D)start end:(CLLocationCoordinate2D)end delegate:(id<SMRouteDelegate>)delegate
{
    self = [self init];
    if (self) {
        [self setDelegate:delegate];
        SMRequestOSRM *r = [[SMRequestOSRM alloc] initWithDelegate:self];
        [self setRequest:r];
        [r setOsrmServer:self.osrmServer];
        [r setAuxParam:@"startRoute"];
        [r getRouteFrom:start to:end via:nil];
    }
    return self;
}

- (instancetype)initWithRouteJSON:(NSDictionary *)routeJSON
                         delegate:(id<SMRouteDelegate>)delegate
{
    self = [self init];
    if (self) {
        [self setDelegate:delegate];
        [self setupRoute:routeJSON];
    }
    return self;
}

- (instancetype)initWithRouteStart:(CLLocationCoordinate2D)start
                               end:(CLLocationCoordinate2D)end
                         routeJSON:(NSDictionary *)routeJSON
                          delegate:(id<SMRouteDelegate>)delegate
{
    if (routeJSON) {
        return [self initWithRouteJSON:routeJSON delegate:delegate];
    }
    return [self initWithRouteStart:start end:end delegate:delegate];
}

- (void)recalculateRoute:(CLLocation *)loc
{
    @synchronized(self.recalcMutex)
    {
        if (self.recalculationInProgress) {
            return;
        }
    }

    self.snapArrow = NO;

    CGFloat distance = [loc distanceFromLocation:self.lastRecalcLocation];
    if (distance < MIN_DISTANCE_FOR_RECALCULATION) {
        return;
    }
    debugLog(@"Distance: %f", distance);
    self.lastRecalcLocation = loc;

    @synchronized(self.recalcMutex)
    {
        self.recalculationInProgress = YES;
    }
    debugLog(@"Recalculating route!");

    if (self.delegate && [self.delegate respondsToSelector:@selector(routeRecalculationStarted)]) {
        [self.delegate routeRecalculationStarted];
    }

    CLLocation *end = [self getEndLocation];
    if (!loc || !end) return;

    SMRequestOSRM *r = [[SMRequestOSRM alloc] initWithDelegate:self];
    [self setRequest:r];
    [r setOsrmServer:self.osrmServer];
    [r setAuxParam:@"routeRecalc"];

    // Uncomment code below if previous part of the route needs to be displayed.
    //        NSMutableArray *viaPoints = [NSMutableArray array];
    //        for (SMTurnInstruction *turn in self.pastTurnInstructions)
    //            [viaPoints addObject:turn.loc];
    //        [viaPoints addObject:loc];
    //        [r getRouteFrom:((CLLocation *)[self.waypoints objectAtIndex:0]).coordinate to:end.coordinate via:viaPoints];

    [r getRouteFrom:loc.coordinate to:end.coordinate via:nil destinationHint:self.destinationHint];
}

- (CLLocation *)getStartLocation
{
    return (self.waypoints && self.waypoints.count > 0) ? [self.waypoints objectAtIndex:0] : NULL;
}

- (CLLocation *)getEndLocation
{
    return (self.waypoints && self.waypoints.count > 0) ? [self.waypoints lastObject] : NULL;
}

- (BOOL)parseFromOSRMv5JSONRoot:(NSDictionary *)jsonRoot
{
    NSArray *routes = jsonRoot[@"routes"];
    if (!routes) {
        // This is not a full JSON object, probably a leg
        return [self parseFromOSRMv5JSONLeg:jsonRoot];
    }
    
    NSDictionary *route;
    if (![routes isKindOfClass:[NSArray class]] || routes.count == 0) {
        return NO;
    }
    route = [routes firstObject];

    NSArray *waypoints = jsonRoot[@"waypoints"];
    if ([waypoints isKindOfClass:[NSArray class]] && (waypoints.count > 1)) {
        NSDictionary *destinationWaypoint = waypoints.lastObject;
        self.destinationHint = destinationWaypoint[@"hint"];
    }

    @synchronized(self.waypoints)
    {
        double polylinePrecision = [SMRouteSettings sharedInstance].route_polyline_precision;
        polylinePrecision /= 10;
        self.waypoints = [SMGPSUtil decodePolyline:route[@"geometry"] precision:polylinePrecision].mutableCopy;
    }

    if (self.waypoints.count < 2) {
        return NO;
    }

    NSArray *legs = route[@"legs"];
    NSDictionary *leg;
    if (![legs isKindOfClass:[NSArray class]] || legs.count == 0) {
        return NO;
    }
    leg = [legs firstObject];
    
    return [self parseFromOSRMv5JSONLeg:leg];
}

- (BOOL)parseFromOSRMv5JSONLeg:(NSDictionary *)leg
{
    @synchronized(self.turnInstructions)
    {
        self.turnInstructions = [NSMutableArray array];
    }
    @synchronized(self.pastTurnInstructions)
    {
        self.pastTurnInstructions = [NSMutableArray array];
    }
    self.estimatedTimeForRoute = [leg[@"duration"] integerValue];
    self.estimatedRouteDistance = [leg[@"distance"] integerValue];

    self.destinationHint = nil;
    
    NSString *type = leg[@"type"];
    if (type != nil) {
        if ([type isEqualToString:@"BIKE"]) {
            self.routeType = SMRouteTypeBike;
        }
        else if ([type isEqualToString:@"S"]) {
            self.routeType = SMRouteTypeSTrain;
        }
        else if ([type isEqualToString:@"M"]) {
            self.routeType = SMRouteTypeMetro;
        }
        else if ([type isEqualToString:@"WALK"]) {
            self.routeType = SMRouteTypeWalk;
        }
        else if ([type isEqualToString:@"IC"] || [type isEqualToString:@"LYN"] || [type isEqualToString:@"REG"] || [type isEqualToString:@"TOG"]) {
            self.routeType = SMRouteTypeTrain;
        }
        else if ([type isEqualToString:@"BUS"] || [type isEqualToString:@"EXB"] || [type isEqualToString:@"NB"] || [type isEqualToString:@"TB"]) {
            self.routeType = SMRouteTypeBus;
        }
        else if ([type isEqualToString:@"F"]) {
            self.routeType = SMRouteTypeFerry;
        }
    }
    
    NSNumber *startDate = leg[@"departure_time"];
    if (startDate) {
        self.startDate = [NSDate dateWithTimeIntervalSince1970:startDate.doubleValue];
    }
    NSNumber *endDate = leg[@"arrival_time"];
    if (endDate) {
        self.endDate = [NSDate dateWithTimeIntervalSince1970:endDate.doubleValue];
    }
    
    self.startDescription = leg[@"start_point"];
    self.endDescription = leg[@"end_point"];
    
    
    NSString *geometry = leg[@"geometry"];
    if (geometry && self.waypoints.count == 0) {
        @synchronized(self.waypoints)
        {
            double polylinePrecision = [SMRouteSettings sharedInstance].route_polyline_precision;
            polylinePrecision /= 10;
            self.waypoints = [SMGPSUtil decodePolyline:geometry precision:polylinePrecision].mutableCopy;
        }

        if (self.waypoints.count < 2) {
            return NO;
        }
    }

    NSArray *steps = leg[@"steps"];
    if (steps.count > 1 && !self.startDescription && !self.endDescription) {
        self.startDescription = steps.firstObject[@"name"];
        [self ifNecessaryTranslateStreetname:self.startDescription];
        self.endDescription = steps.lastObject[@"name"];
        [self ifNecessaryTranslateStreetname:self.endDescription];
    }
    if ([steps isKindOfClass:[NSArray class]] && steps.count > 0) {
        int prevLengthInMeters = 0;
        for (NSDictionary *step in steps) {
            SMTurnInstruction *instruction = [[SMTurnInstruction alloc] init];
            instruction.osrmVersion = TurnInstructionOSRMVersion5;

            instruction.wayName = step[@"name"];
            if ([instruction.wayName rangeOfString:@"\\{.+\\:.+\\}" options:NSRegularExpressionSearch].location != NSNotFound) {
                instruction.wayName = translateString(instruction.wayName);
            }

            instruction.timeInSeconds = [step[@"duration"] intValue];
            instruction.lengthInMeters = prevLengthInMeters;
            prevLengthInMeters = [step[@"distance"] intValue];

            NSDictionary *maneuver = step[@"maneuver"];
            [instruction setDirectionAbbreviationWithBearingAfter:[maneuver[@"bearing_after"] unsignedIntegerValue]];
            [instruction setManeuverTypeWithString:maneuver[@"type"]];
            [instruction setManeuverModifierWithString:maneuver[@"modifier"]];

            if ([maneuver[@"type"] isEqualToString:@"roundabout"] || [maneuver[@"type"] isEqualToString:@"rotary"]) {
                instruction.ordinalDirection = [NSString stringWithFormat:@"%lu", [maneuver[@"exit"] unsignedIntegerValue]];
            }
            else {
                instruction.ordinalDirection = @"1";
            }

            NSString *mode = step[@"mode"];
            if ([mode isEqualToString:@"cycling"]) {
                instruction.routeType = SMRouteTypeBike;
            }
            else if ([mode isEqualToString:@"pushing bike"]) {
                instruction.routeType = SMRouteTypeWalk;
            }
            else {
                instruction.routeType = self.routeType;
            }

            NSArray *location = maneuver[@"location"];
            if ([location isKindOfClass:[NSArray class]] && location.count == 2) {
                instruction.location = [[CLLocation alloc] initWithLatitude:[location[1] floatValue] longitude:[location[0] floatValue]];
                
            }

            CLLocationDistance minDistance = CLLocationDistanceMax;
            int minDistanceWaypointIndex = 0;
            for (int i = 0; i < self.waypoints.count; i++) {
                CLLocationDistance distance = [instruction.location distanceFromLocation:self.waypoints[i]];
                if (distance < minDistance) {
                    minDistance = distance;
                    minDistanceWaypointIndex = i;
                }
            }
            instruction.waypointsIndex = minDistanceWaypointIndex;
            instruction.fixedLengthWithUnit = [SMRouteUtils formatDistanceInMeters:prevLengthInMeters];

            @synchronized(self.turnInstructions)
            {
                [self.turnInstructions addObject:instruction];
            }
        }

        self.longestDistance = 0.0f;
        self.longestStreet = @"";

        NSArray *summaryPoints = [leg[@"summary"] componentsSeparatedByString:@", "];
        if (summaryPoints.count > 1) {
            self.longestStreet = summaryPoints.firstObject;
        }

        if (!self.longestStreet || [self.longestStreet stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet].length == 0) {
            for (int i = 1; i < self.turnInstructions.count - 1; i++) {
                SMTurnInstruction *inst = self.turnInstructions[i];
                if (inst.lengthInMeters > self.longestDistance) {
                    self.longestDistance = inst.lengthInMeters;
                    SMTurnInstruction *inst1 = self.turnInstructions[i - 1];
                    self.longestStreet = inst1.wayName;
                }
            }
        }

        [self ifNecessaryTranslateStreetname:self.longestStreet];
    }

    @synchronized(self.turnInstructions)
    {
        self.allTurnInstructions = [NSMutableArray arrayWithArray:self.turnInstructions];
    }

    self.lastVisitedWaypointIndex = -1;

    self.snapArrow = NO;
    return YES;
}

- (void)ifNecessaryTranslateStreetname:(NSString *)streetname
{
    if ([streetname rangeOfString:@"\\{.+\\:.+\\}" options:NSRegularExpressionSearch].location != NSNotFound) {
        streetname = translateString(streetname);
    }
}

- (void)updateDistances:(CLLocation *)loc
{
    if (self.tripDistance < 0.0) {
        self.tripDistance = 0.0;
    }
    if (self.visitedLocations.count > 0) {
        self.tripDistance += [loc distanceFromLocation:((CLLocation *)self.visitedLocations.lastObject)];
    }

    if (self.distanceLeft < 0.0) {
        self.distanceLeft = self.estimatedRouteDistance;
    } else if (self.turnInstructions.count > 0) {
        // calculate distance from location to the next turn
        SMTurnInstruction *nextTurn = self.turnInstructions[0];
        nextTurn.lengthInMeters = [self calculateDistanceToNextTurn:loc];
        @synchronized(self.turnInstructions)
        {
            [self.turnInstructions setObject:nextTurn atIndexedSubscript:0];
        }
        self.distanceLeft = nextTurn.lengthInMeters;

        // calculate distance from next turn to the end of the route
        for (int i = 1; i < self.turnInstructions.count; i++) {
            self.distanceLeft += ((SMTurnInstruction *)self.turnInstructions[i]).lengthInMeters;
        }
        //        debugLog(@"Total distance left: %.1f", self.distanceLeft);
    }
}

- (NSDictionary *)save
{
    return @{
        @"data" : [NSKeyedArchiver archivedDataWithRootObject:self.visitedLocations],
        @"polyline" : [SMGPSUtil encodePolyline:self.visitedLocations]
    };
}

/*
 * Calculates distance from given location to next turn
 */
- (CGFloat)calculateDistanceToNextTurn:(CLLocation *)loc
{
    if (self.turnInstructions.count == 0) {
        return 0.0f;
    }

    SMTurnInstruction *nextTurn = self.turnInstructions[0];

    // If first turn still hasn't been reached, return linear distance to it.
    if (self.pastTurnInstructions.count == 0) {
        return [loc distanceFromLocation:nextTurn.location];
    }

    NSUInteger firstIndex = self.lastVisitedWaypointIndex >= 0 ? self.lastVisitedWaypointIndex + 1 : 0;
    CGFloat distance = 0.0f;
    if (firstIndex < self.waypoints.count) {
        distance = [loc distanceFromLocation:self.waypoints[firstIndex]];
        if (nextTurn.waypointsIndex <= self.waypoints.count) {
            for (NSUInteger i = firstIndex; i < nextTurn.waypointsIndex; i++) {
                double d = [((CLLocation *)self.waypoints[i]) distanceFromLocation:self.waypoints[i + 1]];
                distance += d;
            }
        }
    }

    //    debugLog(@"Distance to next turn: %.1f", distance);
    return distance;
}

- (CGFloat)calculateDistanceTraveled
{
    if (self.tripDistance >= 0) {
        return self.tripDistance;
    }
    CGFloat distance = 0.0f;

    if (self.visitedLocations.count > 1) {
        CLLocation *startLoc = ((CLLocation *)self.visitedLocations.firstObject);
        for (int i = 1; i < self.visitedLocations.count; i++) {
            CLLocation *loc = ((CLLocation *)self.visitedLocations[i]);
            distance += [loc distanceFromLocation:startLoc];
            startLoc = loc;
        }
    }

    self.tripDistance = roundf(distance);

    return self.tripDistance;
}

- (NSString *)timePassed
{
    if (self.visitedLocations.count > 1) {
        NSDate *startDate = ((CLLocation *)self.visitedLocations.firstObject).timestamp;
        NSDate *endDate = ((CLLocation *)self.visitedLocations.lastObject).timestamp;
        return formatTimePassed(startDate, endDate);
    }
    return @"";
}

- (void)setupRoute:(id)jsonRoot
{
    if ([self parseFromOSRMv5JSONRoot:jsonRoot]) {
        self.tripDistance = 0.0f;
        @synchronized(self.pastTurnInstructions)
        {
            self.pastTurnInstructions = [NSMutableArray array];
        }

        if ([SMLocationManager sharedInstance].hasValidLocation) {
            [self updateDistances:[SMLocationManager sharedInstance].lastValidLocation];
        }
    }
}

#pragma mark - osrm request delegate

- (void)request:(SMRequestOSRM *)req failedWithError:(NSError *)error
{
    if ([req.auxParam isEqualToString:@"routeRecalc"]) {
        @synchronized(self.recalcMutex)
        {
            self.recalculationInProgress = NO;
        }
        if ([req.auxParam isEqualToString:@"routeRecalc"] && self.delegate) {
            dispatch_async(dispatch_get_main_queue(), ^{
              [self.delegate serverError];
            });
        }
    }
}

- (void)serverNotReachable
{
}

- (void)request:(SMRequestOSRM *)req finishedWithResult:(id)res
{
    if ([req.auxParam isEqualToString:@"startRoute"]) {
        NSString *response = [[NSString alloc] initWithData:req.responseData encoding:NSUTF8StringEncoding];
        if (response) {
            id jsonRoot = [NSJSONSerialization JSONObjectWithData:req.responseData options:NSJSONReadingAllowFragments error:nil];
            if (![jsonRoot isKindOfClass:[NSDictionary class]] || ![jsonRoot[@"code"] isEqualToString:@"Ok"]) {
                if (self.delegate) {
                    [self.delegate routeNotFound];
                };
                return;
            }
            [self setupRoute:jsonRoot];
            if (self.delegate && [self.delegate respondsToSelector:@selector(startRoute:)]) {
                [self.delegate startRoute:self];
            }
        }
    }
    else if ([req.auxParam isEqualToString:@"routeRecalc"]) {
        NSString *response = [[NSString alloc] initWithData:req.responseData encoding:NSUTF8StringEncoding];
        if (response) {
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
              id jsonRoot = [NSJSONSerialization JSONObjectWithData:req.responseData options:NSJSONReadingAllowFragments error:nil];
              if (![jsonRoot isKindOfClass:[NSDictionary class]] || ![jsonRoot[@"code"] isEqualToString:@"Ok"]) {
                  if (self.delegate) {
                      dispatch_async(dispatch_get_main_queue(), ^{
                        [self.delegate routeRecalculationDone];
                        return;
                      });
                  }
              };

              BOOL done = [self parseFromOSRMv5JSONRoot:jsonRoot];
              if (done) {
                  if ([SMLocationManager sharedInstance].hasValidLocation) {
                      [self updateDistances:[SMLocationManager sharedInstance].lastValidLocation];
                  }
                  dispatch_async(dispatch_get_main_queue(), ^{
                    if (self.delegate && [self.delegate respondsToSelector:@selector(routeRecalculationDone)]) {
                        [self.delegate routeRecalculationDone];
                    }
                    [self.delegate updateRoute];
                    @synchronized(self.recalcMutex)
                    {
                        self.recalculationInProgress = NO;
                    }
                  });
              }
            });
        }
    }
}

#pragma mark - new methods

- (void)updateSegmentBasedOnWaypoint
{
    //    debugLog(@"updateSegmentBasedOnWaypoint!!!!");
    if (!self.delegate) {
        NSLog(@"Warning: delegate not set while in updateSegment()!");
        return;
    }

    NSMutableArray *past = [NSMutableArray array];
    NSMutableArray *future = [NSMutableArray array];
    for (SMTurnInstruction *currentTurnInstruction in self.allTurnInstructions) {
        if (self.lastVisitedWaypointIndex < currentTurnInstruction.waypointsIndex) {
            [future addObject:currentTurnInstruction];
        }
        else {
            [past addObject:currentTurnInstruction];
        }
    }
    @synchronized(self.turnInstructions)
    {
        self.pastTurnInstructions = past;
        self.turnInstructions = future;
    }

    [self.delegate updateTurn:YES];

    if (self.turnInstructions.count == 0) {
        [self.delegate reachedDestination];
    }
}

- (BOOL)findNearestRouteSegmentForLocation:(CLLocation *)loc withMaxDistance:(CGFloat)maxDistance
{
    double min = MAXFLOAT;

    locLog(@"Last visited waypoint index: %lu", (long)self.lastVisitedWaypointIndex);

    if (self.routeType != SMRouteTypeBike && self.routeType != SMRouteTypeWalk) {
        for (NSUInteger i = 0; i < self.waypoints.count - 1; i++) {
            CLLocation *a = self.waypoints[i];
            CLLocation *b = self.waypoints[i + 1];
            CGFloat distanceFromStartPoint = [a distanceFromLocation:loc];
            if (distanceFromStartPoint < maxDistance) {
                min = distanceFromStartPoint;
                self.lastVisitedWaypointIndex = i - 1;  // Keep previous as last visited
                self.snapArrow = YES;
                self.lastCorrectedLocation = loc;
                return min < maxDistance;
            }
            CGFloat distanceFromLine = distanceFromLineInMeters(loc.coordinate, a.coordinate, b.coordinate);
            if (distanceFromLine <= min) {
                min = distanceFromLine;
                self.lastVisitedWaypointIndex = i;
                self.snapArrow = YES;
                self.lastCorrectedLocation = loc;
                return min < maxDistance;
            }
        }
    }

    /**
     * first check the most likely position
     */
    NSInteger startPoint = MAX(self.lastVisitedWaypointIndex, 0);
    if (min > maxDistance) {
        for (NSUInteger i = startPoint; i < MIN(self.waypoints.count - 1, startPoint + 5); i++) {
            CLLocation *a = self.waypoints[i];
            CLLocation *b = self.waypoints[i + 1];
            double d = distanceFromLineInMeters(loc.coordinate, a.coordinate, b.coordinate);
            if (d < 0.0) {
                continue;
            }
            if (d <= min) {
                min = d;
                self.lastVisitedWaypointIndex = i;
            }
            if (min < 2) {
                // Close enough :)
                break;
            }
        }
    }

    /**
     * then check the remaining waypoints
     */
    if (min > maxDistance) {
        locLog(@"entered FUTURE block!");
        startPoint = MIN(self.waypoints.count - 1, startPoint + 5);
        for (NSUInteger i = startPoint; i < self.waypoints.count-1; i++) {
            CLLocation *a = [self.waypoints objectAtIndex:i];
            CLLocation *b = [self.waypoints objectAtIndex:(i + 1)];
            double d = distanceFromLineInMeters(loc.coordinate, a.coordinate, b.coordinate);
            if (d < 0.0) {
                continue;
            }
            if (d <= min) {
                min = d;
                self.lastVisitedWaypointIndex = i;
            }
            if (min < 2) {
                // Close enough :)
                break;
            }
        }
    }
    /**
     * check if the user went back
     */
    if (min > maxDistance) {
        locLog(@"entered PAST block!");
        startPoint = 0;
        for (NSUInteger i = startPoint; i < MIN(self.waypoints.count - 1, self.lastVisitedWaypointIndex); i++) {
            CLLocation *a = [self.waypoints objectAtIndex:i];
            CLLocation *b = [self.waypoints objectAtIndex:(i + 1)];
            double d = distanceFromLineInMeters(loc.coordinate, a.coordinate, b.coordinate);
            if (d < 0.0) {
                continue;
            }
            if (d <= min) {
                min = d;
                self.lastVisitedWaypointIndex = i;
            }
            if (min < 2) {
                // Close enough :)
                break;
            }
        }
    }

    if (self.lastVisitedWaypointIndex < 0) {
        // Check the distance from start
        min = [loc distanceFromLocation:self.waypoints.firstObject];
        // If we are less than 5m away from start snap the arrow
        // heading is left as sent by the GPS so that you know if you're moving in the wrong direction
        if (min < 5) {
            self.lastVisitedWaypointIndex = 0;

            CLLocation *a = self.waypoints[self.lastVisitedWaypointIndex];
            CLLocation *b = self.waypoints[self.lastVisitedWaypointIndex + 1];
            CLLocationCoordinate2D coord = closestCoordinate(loc.coordinate, a.coordinate, b.coordinate);

            self.lastCorrectedLocation = [[CLLocation alloc] initWithCoordinate:coord
                                                                       altitude:loc.altitude
                                                             horizontalAccuracy:loc.horizontalAccuracy
                                                               verticalAccuracy:loc.verticalAccuracy
                                                                         course:loc.course
                                                                          speed:loc.speed
                                                                      timestamp:loc.timestamp];
        }
    }
    else if (min <= maxDistance && self.lastVisitedWaypointIndex >= 0) {

        CLLocation *a = self.waypoints[self.lastVisitedWaypointIndex];
        CLLocation *b = self.waypoints[self.lastVisitedWaypointIndex + 1];
        CLLocationCoordinate2D coord = closestCoordinate(loc.coordinate, a.coordinate, b.coordinate);

        if ([a distanceFromLocation:b] > 0.0f) {
            locLog(@"=========");
            locLog(@"Last visited waypoint index: %li", (long)self.lastVisitedWaypointIndex);
            locLog(@"Loc A: (%f, %f)", a.coordinate.latitude, a.coordinate.longitude);
            locLog(@"Loc B: (%f, %f)", b.coordinate.latitude, b.coordinate.longitude);
            locLog(@"Closest: (%f %f)", coord.latitude, coord.longitude);
            locLog(@"=========");
        }
        self.lastCorrectedLocation = [[CLLocation alloc] initWithCoordinate:coord
                                                                   altitude:loc.altitude
                                                         horizontalAccuracy:loc.horizontalAccuracy
                                                           verticalAccuracy:loc.verticalAccuracy
                                                                     course:loc.course
                                                                      speed:loc.speed
                                                                  timestamp:loc.timestamp];
        self.snapArrow = YES;
    }
    else {
        locLog(@"too far from location");
        self.snapArrow = NO;
        self.lastCorrectedLocation = loc;
    }
    return min > maxDistance;
}

- (void)visitLocation:(CLLocation *)loc
{
    self.snapArrow = YES;
    int maxD = loc.horizontalAccuracy >= 0 ? MAX(loc.horizontalAccuracy / 3 + 20, self.maxMarginRadius) : self.maxMarginRadius;

    BOOL isTooFar = NO;
    @synchronized(self.visitedLocations)
    {
        [self updateDistances:loc];
        [self.visitedLocations addObject:loc];
        isTooFar = [self findNearestRouteSegmentForLocation:loc withMaxDistance:maxD];
        [self updateSegmentBasedOnWaypoint];
    }

    @synchronized(self.turnInstructions)
    {
        if (self.turnInstructions.count <= 0) return;
    }

    @synchronized(self.recalcMutex)
    {
        if (self.recalculationInProgress) {
            return;
        }
    }

    // Check if we are finishing:
    double distanceToFinish =
        MIN([self.lastCorrectedLocation distanceFromLocation:[self getEndLocation]], [loc distanceFromLocation:[self getEndLocation]]);
    double speed = loc.speed > 0 ? loc.speed : 5;
    int timeToFinish = 100;
    if (speed > 0) {
        timeToFinish = distanceToFinish / speed;
        locLog(@"finishing in %ds %.0fm max distance: %.0fm", timeToFinish, roundf(distanceToFinish), roundf(maxD));
    }
    /**
     * are we close to the finish (< X meters or 3s left)?
     */
    if (distanceToFinish < self.maxMarginRadius || timeToFinish <= 3) {
        [self.delegate reachedDestination];
        return;
    }

    if (isTooFar) {
        // Don't recalculate for non-bike or non-walk routes
        if (self.routeType != SMRouteTypeBike && self.routeType != SMRouteTypeWalk) {
            return;
        }
        self.snapArrow = NO;
        self.lastVisitedWaypointIndex = -1;
        [self recalculateRoute:loc];
    }
}

#pragma mark - Getters

- (NSMutableArray *)visitedLocations
{
    if (!_visitedLocations) {
        _visitedLocations = [NSMutableArray array];
    }
    return _visitedLocations;
}

@end