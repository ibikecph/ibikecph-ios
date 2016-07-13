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
@property CGFloat distanceFromRoute;
@property(nonatomic, strong) NSMutableArray *allTurnInstructions;
@property NSUInteger nextWaypoint;
@end

@implementation SMRoute

- (id)init
{
    self = [super init];
    if (self) {
        self.routeType = SMRouteTypeBike;
        self.distanceLeft = -1;
        self.tripDistance = -1;
        self.caloriesBurned = -1;
        self.averageSpeed = -1;
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

- (id)initWithRouteStart:(CLLocationCoordinate2D)start andEnd:(CLLocationCoordinate2D)end andDelegate:(id<SMRouteDelegate>)dlg
{
    return [self initWithRouteStart:start andEnd:end andDelegate:dlg andJSON:nil];
}

- (id)initWithRouteStart:(CLLocationCoordinate2D)start
                  andEnd:(CLLocationCoordinate2D)end
             andDelegate:(id<SMRouteDelegate>)dlg
                 andJSON:(NSDictionary *)routeJSON
{
    self = [self init];
    if (self) {
        self.routeType = SMRouteTypeBike;
        [self setLocationStart:start];
        [self setLocationEnd:end];
        [self setDelegate:dlg];
        if (routeJSON == nil) {
            SMRequestOSRM *r = [[SMRequestOSRM alloc] initWithDelegate:self];
            [self setRequest:r];
            [r setOsrmServer:self.osrmServer];
            [r setAuxParam:@"startRoute"];
            [r getRouteFrom:start to:end via:nil];
        }
        else {
            [self setupRoute:routeJSON];
        }
    }
    return self;
}

- (double)getCorrectedHeading
{
    return self.lastCorrectedHeading;
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

- (BOOL)approachingFinish
{
    return self.turnInstructions.count == 1;
}

- (CLLocation *)getStartLocation
{
    if (self.waypoints && self.waypoints.count > 0) return [self.waypoints objectAtIndex:0];
    return NULL;
}

- (CLLocation *)getEndLocation
{
    if (self.waypoints && self.waypoints.count > 0) return [self.waypoints lastObject];
    return NULL;
}

- (CLLocation *)getFirstVisitedLocation
{
    if (self.visitedLocations && self.visitedLocations.count > 0) return ((CLLocation *)self.visitedLocations.firstObject);
    return NULL;
}

- (CLLocation *)getLastVisitedLocation
{
    if (self.visitedLocations && self.visitedLocations.count > 0) return ((CLLocation *)self.visitedLocations.lastObject);
    return NULL;
}

- (BOOL)parseFromJson:(NSDictionary *)jsonRoot delegate:(id<SMRouteDelegate>)dlg
{
    // Hacks incoming!
    if (jsonRoot[@"route_summary"]) {
        // This is presumably JSON from an OSRM V4 source
        return [self parseFromOSRMV4JSON:jsonRoot delegate:dlg];
    }
    else {
        // This is presumably JSON from an OSRM V5 source
        return [self parseFromOSRMV5JSON:jsonRoot delegate:dlg];
    }
}

- (BOOL)parseFromOSRMV4JSON:(NSDictionary *)jsonRoot delegate:(id<SMRouteDelegate>)dlg
{
    NSString *type = jsonRoot[@"route_summary"][@"type"];
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

    double polylinePrecision = [SMRouteSettings sharedInstance].route_polyline_precision;
    switch (self.routeType) {
        case SMRouteTypeBike:
            break;
        default:
            polylinePrecision /= 10;
            break;
    }

    @synchronized(self.waypoints)
    {
        self.waypoints = [SMGPSUtil decodePolyline:jsonRoot[@"route_geometry"] precision:polylinePrecision].mutableCopy;
    }

    if (self.waypoints.count < 2) {
        return NO;
    }

    @synchronized(self.turnInstructions)
    {
        self.turnInstructions = [NSMutableArray array];
    }
    @synchronized(self.pastTurnInstructions)
    {
        self.pastTurnInstructions = [NSMutableArray array];
    }
    NSDictionary *summary = jsonRoot[@"route_summary"];
    self.estimatedTimeForRoute = [summary[@"total_time"] integerValue];
    self.estimatedRouteDistance = [summary[@"total_distance"] integerValue];
    self.startDescription = summary[@"start_point"];
    self.endDescription = summary[@"end_point"];
    NSNumber *startDate = summary[@"departure_time"];
    if (startDate) {
        self.startDate = [NSDate dateWithTimeIntervalSince1970:startDate.doubleValue];
    }
    NSNumber *endDate = summary[@"arrival_time"];
    if (endDate) {
        self.endDate = [NSDate dateWithTimeIntervalSince1970:endDate.doubleValue];
    }
    NSString *transportLine = summary[@"name"];
    if (transportLine) {
        self.transportLine = transportLine;
    }
    else {
        self.transportLine = @"";
    }
    self.routeChecksum = nil;
    self.destinationHint = nil;

    if (jsonRoot[@"hint_data"] && jsonRoot[@"hint_data"][@"checksum"]) {
        self.routeChecksum = [NSString stringWithFormat:@"%@", jsonRoot[@"hint_data"][@"checksum"]];
    }

    if (jsonRoot[@"hint_data"] && jsonRoot[@"hint_data"][@"locations"] && [jsonRoot[@"hint_data"][@"locations"] isKindOfClass:[NSArray class]]) {
        self.destinationHint = [NSString stringWithFormat:@"%@", [jsonRoot[@"hint_data"][@"locations"] lastObject]];
    }

    NSArray *routeInstructions = jsonRoot[@"route_instructions"];
    if (routeInstructions && routeInstructions.count > 0) {
        int prevLengthInMeters = 0;
        BOOL isFirst = YES;
        for (id jsonObject in routeInstructions) {
            SMTurnInstruction *instruction = [[SMTurnInstruction alloc] init];

            NSArray *arr = [[NSString stringWithFormat:@"%@", jsonObject[0]] componentsSeparatedByString:@"-"];
            int pos = [(NSString *)arr[0] intValue];

            if (pos <= 19) {
                instruction.turnDirection = pos;
                instruction.routeType = self.routeType;
                instruction.routeLineName = self.transportLine;
                if (pos == 18) {
                    instruction.routeLineStart = self.startDescription;
                    instruction.routeLineDestination = self.endDescription;
                    instruction.routeLineTime = self.startDate;
                }
                else if (pos == 19) {
                    instruction.routeLineStart = self.startDescription;
                    instruction.routeLineDestination = self.endDescription;
                    instruction.routeLineTime = self.endDate;
                }
                if (arr.count > 1 && arr[1]) {
                    instruction.ordinalDirection = arr[1];
                }
                else {
                    instruction.ordinalDirection = @"";
                }
                instruction.wayName = (NSString *)jsonObject[1];

                if ([instruction.wayName rangeOfString:@"\\{.+\\:.+\\}" options:NSRegularExpressionSearch].location != NSNotFound) {
                    instruction.wayName = translateString(instruction.wayName);
                }

                instruction.lengthInMeters = prevLengthInMeters;
                prevLengthInMeters = [(NSNumber *)jsonObject[2] intValue];
                /**
                 * Save length to next turn with units so we don't have to generate it each time
                 * It's formatted just the way we like it
                 */
                instruction.fixedLengthWithUnit = [SMRouteUtils formatDistanceInMeters:prevLengthInMeters];
                instruction.directionAbbreviation = (NSString *)jsonObject[6];

                if (isFirst) {
                    [instruction generateStartDescriptionString];
                    isFirst = NO;
                }
                else {
                    [instruction generateDescriptionString];
                }
                [instruction generateFullDescriptionString];

                [instruction generateShortDescriptionString];

                int position = [(NSNumber *)jsonObject[3] intValue];
                instruction.waypointsIndex = position;

                if (self.waypoints && position >= 0 && position < self.waypoints.count) {
                    instruction.location = self.waypoints[position];
                }

                @synchronized(self.turnInstructions)
                {
                    [self.turnInstructions addObject:instruction];
                }
            }
        }

        self.longestDistance = 0.0f;
        self.longestStreet = @"";

        if ([jsonRoot[@"route_name"] isKindOfClass:[NSArray class]] && [jsonRoot[@"route_name"] count] > 0) {
            self.longestStreet = [jsonRoot[@"route_name"] firstObject];
        }
        if (self.longestStreet == nil ||
            [[self.longestStreet stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] isEqualToString:@""]) {
            for (int i = 1; i < self.turnInstructions.count - 1; i++) {
                SMTurnInstruction *inst = self.turnInstructions[i];
                if (inst.lengthInMeters > self.longestDistance) {
                    self.longestDistance = inst.lengthInMeters;
                    SMTurnInstruction *inst1 = self.turnInstructions[i - 1];
                    self.longestStreet = inst1.wayName;
                }
            }
        }

        if ([self.longestStreet rangeOfString:@"\\{.+\\:.+\\}" options:NSRegularExpressionSearch].location != NSNotFound) {
            self.longestStreet = translateString(self.longestStreet);
        }
    }

    @synchronized(self.turnInstructions)
    {
        self.allTurnInstructions = [NSMutableArray arrayWithArray:self.turnInstructions];
    }

    self.lastVisitedWaypointIndex = -1;

    CLLocation *a = self.waypoints[0];
    CLLocation *b = self.waypoints[1];
    self.lastCorrectedHeading = [SMGPSUtil bearingBetweenStartLocation:a andEndLocation:b];

    self.snapArrow = NO;
    return YES;
}

- (BOOL)parseFromOSRMV5JSON:(NSDictionary *)jsonRoot delegate:(id<SMRouteDelegate>)dlg
{
    NSArray *routes = jsonRoot[@"routes"];
    NSDictionary *route;
    if (![routes isKindOfClass:[NSArray class]] || routes.count == 0) {
        return NO;
    }
    route = [routes firstObject];

    NSArray *legs = route[@"legs"];
    NSDictionary *leg;
    if (![legs isKindOfClass:[NSArray class]] || legs.count == 0) {
        return NO;
    }
    leg = [legs firstObject];

    @synchronized(self.waypoints)
    {
        double polylinePrecision = [SMRouteSettings sharedInstance].route_polyline_precision;
        polylinePrecision /= 10;
        self.waypoints = [SMGPSUtil decodePolyline:route[@"geometry"] precision:polylinePrecision].mutableCopy;
    }

    if (self.waypoints.count < 2) {
        return NO;
    }

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

    NSArray *waypoints = jsonRoot[@"waypoints"];
    if ([waypoints isKindOfClass:[NSArray class]] && (waypoints.count > 1)) {
        NSDictionary *destinationWaypoint = waypoints.lastObject;
        self.destinationHint = destinationWaypoint[@"hint"];
    }

    NSArray *steps = leg[@"steps"];
    if (steps.count > 1) {
        self.startDescription = steps.firstObject[@"name"];
        [self ifNecessaryTranslateStreetname:self.startDescription];
        self.endDescription = steps.lastObject[@"name"];
        [self ifNecessaryTranslateStreetname:self.endDescription];
    }
    if ([steps isKindOfClass:[NSArray class]] && steps.count > 0) {
        int prevLengthInMeters = 0;
        BOOL isFirst = YES;
        for (NSDictionary *step in steps) {
            SMTurnInstruction *instruction = [[SMTurnInstruction alloc] init];

            OSRMV4TurnDirection turnDirection;
            NSDictionary *maneuver = step[@"maneuver"];
            NSString *maneuverType = maneuver[@"turn"];
            NSString *maneuverModifier = maneuver[@"modifier"];
            if ([maneuverType isEqualToString:@"turn"] || [maneuverType isEqualToString:@"continue"]) {
                if ([maneuverModifier isEqualToString:@"uturn"]) {
                    turnDirection = OSRMV4TurnDirectionUTurn;
                }
                else if ([maneuverType isEqualToString:@"sharp right"]) {
                    turnDirection = OSRMV4TurnDirectionTurnSharpRight;
                }
                else if ([maneuverType isEqualToString:@"right"]) {
                    turnDirection = OSRMV4TurnDirectionTurnRight;
                }
                else if ([maneuverType isEqualToString:@"slight right"]) {
                    turnDirection = OSRMV4TurnDirectionTurnSlightRight;
                }
                else if ([maneuverType isEqualToString:@"straight"]) {
                    turnDirection = OSRMV4TurnDirectionGoStraight;
                }
                else if ([maneuverType isEqualToString:@"sharp left"]) {
                    turnDirection = OSRMV4TurnDirectionTurnSharpLeft;
                }
                else if ([maneuverType isEqualToString:@"left"]) {
                    turnDirection = OSRMV4TurnDirectionTurnLeft;
                }
                else if ([maneuverType isEqualToString:@"slight left"]) {
                    turnDirection = OSRMV4TurnDirectionTurnSlightLeft;
                }
            }
            else if ([maneuverType isEqualToString:@"depart"]) {
                turnDirection = OSRMV4TurnDirectionHeadOn;
            }
            else if ([maneuverType isEqualToString:@"arrive"]) {
                turnDirection = OSRMV4TurnDirectionReachedYourDestination;
            }
            else if ([maneuverType isEqualToString:@"roundabout"]) {
                turnDirection = OSRMV4TurnDirectionEnterRoundAbout;
            }

            if (turnDirection <= OSRMV4TurnDirectionUnboardPublicTransport) {
                instruction.turnDirection = turnDirection;
                instruction.routeType = self.routeType;
                instruction.routeLineName = self.transportLine;
                if (turnDirection == OSRMV4TurnDirectionBoardPublicTransport) {
                    instruction.routeLineStart = self.startDescription;
                    instruction.routeLineDestination = self.endDescription;
                    instruction.routeLineTime = self.startDate;
                }
                else if (turnDirection == OSRMV4TurnDirectionUnboardPublicTransport) {
                    instruction.routeLineStart = self.startDescription;
                    instruction.routeLineDestination = self.endDescription;
                    instruction.routeLineTime = self.endDate;
                }

                instruction.ordinalDirection = @"";
                instruction.wayName = step[@"name"];

                if ([instruction.wayName rangeOfString:@"\\{.+\\:.+\\}" options:NSRegularExpressionSearch].location != NSNotFound) {
                    instruction.wayName = translateString(instruction.wayName);
                }

                instruction.lengthInMeters = prevLengthInMeters;
                prevLengthInMeters = [step[@"distance"] intValue];
                /**
                 * Save length to next turn with units so we don't have to generate it each time
                 * It's formatted just the way we like it
                 */
                instruction.fixedLengthWithUnit = [SMRouteUtils formatDistanceInMeters:prevLengthInMeters];
                instruction.directionAbbreviation = @"";

                if (isFirst) {
                    [instruction generateStartDescriptionString];
                    isFirst = NO;
                }
                else {
                    [instruction generateDescriptionString];
                }
                [instruction generateFullDescriptionString];

                [instruction generateShortDescriptionString];

                instruction.waypointsIndex = 0;

                NSArray *location = maneuver[@"location"];
                if ([location isKindOfClass:[NSArray class]] && location.count == 2) {
                    instruction.location = [[CLLocation alloc] initWithLatitude:[location[1] integerValue] longitude:[location[0] integerValue]];
                }

                @synchronized(self.turnInstructions)
                {
                    [self.turnInstructions addObject:instruction];
                }
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

    CLLocation *a = self.waypoints[0];
    CLLocation *b = self.waypoints[1];
    self.lastCorrectedHeading = [SMGPSUtil bearingBetweenStartLocation:a andEndLocation:b];

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
    }

    else if (self.turnInstructions.count > 0) {
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

    if ([self.visitedLocations count] > 1) {
        CLLocation *startLoc = ((CLLocation *)self.visitedLocations.firstObject);
        for (int i = 1; i < [self.visitedLocations count]; i++) {
            CLLocation *loc = ((CLLocation *)self.visitedLocations[i]);
            distance += [loc distanceFromLocation:startLoc];
            startLoc = loc;
        }
    }

    self.tripDistance = roundf(distance);

    return self.tripDistance;
}

- (CGFloat)calculateAverageSpeed
{
    CGFloat distance = [self calculateDistanceTraveled];
    CGFloat avgSpeed = 0.0f;
    if ([self.visitedLocations count] > 1) {
        NSDate *startLoc = ((CLLocation *)self.visitedLocations.firstObject).timestamp;
        NSDate *endLoc = ((CLLocation *)self.visitedLocations.lastObject).timestamp;
        if ([endLoc timeIntervalSinceDate:startLoc] > 0) {
            avgSpeed = distance / ([endLoc timeIntervalSinceDate:startLoc]);
        }
    }
    self.averageSpeed = roundf(avgSpeed * 30.6) / 10.0f;
    return self.averageSpeed;
}

- (NSString *)timePassed
{
    if ([self.visitedLocations count] > 1) {
        NSDate *startDate = ((CLLocation *)self.visitedLocations.firstObject).timestamp;
        NSDate *endDate = ((CLLocation *)self.visitedLocations.lastObject).timestamp;
        return formatTimePassed(startDate, endDate);
    }
    return @"";
}

- (CGFloat)calculateCaloriesBurned
{
    if (self.caloriesBurned >= 0) {
        return self.caloriesBurned;
    }

    CGFloat avgSpeed = [self calculateAverageSpeed];
    CGFloat timeSpent = 0.0f;
    if ([self.visitedLocations count] > 1) {
        NSDate *startLoc = ((CLLocation *)self.visitedLocations.firstObject).timestamp;
        NSDate *endLoc = ((CLLocation *)self.visitedLocations.lastObject).timestamp;
        timeSpent = [endLoc timeIntervalSinceDate:startLoc] / 3600.0f;
    }

    return self.caloriesBurned = caloriesBurned(avgSpeed, timeSpent);
}

- (void)setupRoute:(id)jsonRoot
{
    if ([self parseFromJson:jsonRoot delegate:nil]) {
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

              BOOL done = [self parseFromJson:jsonRoot delegate:nil];
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

- (BOOL)isOnPath
{
    return self.snapArrow;
}

#pragma mark - new methods

- (void)updateSegmentBasedOnWaypoint
{
    //    debugLog(@"updateSegmentBasedOnWaypoint!!!!");
    if (!self.delegate) {
        NSLog(@"Warning: delegate not set while in updateSegment()!");
        return;
    }

    //    NSUInteger currentIndex = 0;
    NSMutableArray *past = [NSMutableArray array];
    NSMutableArray *future = [NSMutableArray array];
    for (int i = 0; i < self.allTurnInstructions.count; i++) {
        SMTurnInstruction *currentTurn = self.allTurnInstructions[i];
        if (self.lastVisitedWaypointIndex < currentTurn.waypointsIndex) {
            //            currentIndex = i;
            [future addObject:currentTurn];
        }
        else {
            [past addObject:currentTurn];
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
                self.distanceFromRoute = min;
                self.snapArrow = YES;
                self.lastCorrectedLocation = loc;
                return min < maxDistance;
            }
            CGFloat distanceFromLine = distanceFromLineInMeters(loc.coordinate, a.coordinate, b.coordinate);
            if (distanceFromLine <= min) {
                min = distanceFromLine;
                self.lastVisitedWaypointIndex = i;
                self.distanceFromRoute = min;
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
        for (NSUInteger i = startPoint; i < MIN(self.waypoints.count - 1, startPoint + 5); i++) {
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
            if (d < 0.0) continue;
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
        /**
         * check the distance from start
         */
        min = [loc distanceFromLocation:self.waypoints[0]];
        /**
         * if we are less then 5m away from start snap the arrow
         *
         * heading is left as sent by the GPS so that you know if you're moving in the wrong direction
         */
        if (min < 5) {
            self.distanceFromRoute = min;
            self.lastVisitedWaypointIndex = 0;

            CLLocation *a = self.waypoints[self.lastVisitedWaypointIndex];
            CLLocation *b = self.waypoints[self.lastVisitedWaypointIndex + 1];
            CLLocationCoordinate2D coord = closestCoordinate(loc.coordinate, a.coordinate, b.coordinate);

            self.lastCorrectedHeading = [SMGPSUtil bearingBetweenStartLocation:loc andEndLocation:a];
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
        self.distanceFromRoute = min;

        CLLocation *a = self.waypoints[self.lastVisitedWaypointIndex];
        CLLocation *b = self.waypoints[self.lastVisitedWaypointIndex + 1];
        CLLocationCoordinate2D coord = closestCoordinate(loc.coordinate, a.coordinate, b.coordinate);

        if ([a distanceFromLocation:b] > 0.0f) {
            locLog(@"=========");
            locLog(@"Last visited waypoint index: %li", (long)self.lastVisitedWaypointIndex);
            locLog(@"Loc A: (%f, %f)", a.coordinate.latitude, a.coordinate.longitude);
            locLog(@"Loc B: (%f, %f)", b.coordinate.latitude, b.coordinate.longitude);
            self.lastCorrectedHeading = [SMGPSUtil bearingBetweenStartLocation:a andEndLocation:b];
            locLog(@"Heading: %f", self.lastCorrectedHeading);
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
        if (!self.visitedLocations) self.visitedLocations = [NSMutableArray array];
        [self.visitedLocations addObject:loc];
        self.distanceFromRoute = MAXFLOAT;
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

@end