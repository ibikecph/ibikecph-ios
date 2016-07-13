//
//  SMTripRoute.m
//  I Bike CPH
//
//  Created by Nikola Markovic on 7/5/13.
//  Copyright (c) 2013 City of Copenhagen. All rights reserved.
//

#import "SMBrokenRouteInfo.h"
#import "SMRouteTransportationInfo.h"
#import "SMSingleRouteInfo.h"
#import "SMStationInfo.h"
#import "SMTransportation.h"
#import "SMTransportationLine.h"
#import "SMTripRoute.h"

@implementation SMTripRoute {
    NSBlockOperation *searchingOperation;
    NSMutableArray *internalRoutes;
}

- (id)initWithRoute:(SMRoute *)route
{
    self = [super init];

    if (self) {
        self.fullRoute = route;
        self.brokenRoutes = @[ route ];
    }

    return self;
}

- (BOOL)breakRoute
{
    if (!self.fullRoute) return NO;

    __weak SMTripRoute *selfRef = self;

    searchingOperation = [NSBlockOperation blockOperationWithBlock:^{
      [selfRef breakRouteInBackground];
    }];

    searchingOperation.completionBlock = ^{
      // todo Change state
      if ([selfRef.delegate respondsToSelector:@selector(didCalculateRouteDistances:)]) [selfRef.delegate didCalculateRouteDistances:selfRef];
    };

    if ([self.delegate respondsToSelector:@selector(didStartBreakingRoute:)]) [self.delegate didStartBreakingRoute:self];

    [[SMTransportation transportationQueue] addOperation:searchingOperation];

    return YES;
}

- (void)breakRouteInBackground
{
    CLLocation *start = [self start];
    CLLocation *end = [self end];
    NSMutableArray *transportationRoutesTemp = [NSMutableArray new];
    double routeDistance = [start distanceFromLocation:end];

    NSArray *lines = [SMTransportation sharedInstance].lines;

    for (SMTransportationLine *transportationLine in lines) {
        for (int i = 0; i < transportationLine.stations.count; i++) {
            SMStationInfo *stationLocation = [transportationLine.stations objectAtIndex:i];

            for (int j = 0; j < transportationLine.stations.count; j++) {
                if (i == j) continue;

                SMStationInfo *stationLocationDest = [transportationLine.stations objectAtIndex:j];

                float bikeDistanceToSourceStation = [start distanceFromLocation:stationLocation.location];
                float bikeDistanceFromDestinationStation = [end distanceFromLocation:stationLocationDest.location];
                float bikeDistance = bikeDistanceToSourceStation + bikeDistanceFromDestinationStation;

                if (bikeDistance > routeDistance) continue;

                SMSingleRouteInfo *singleRouteInfo =
                    [[SMSingleRouteInfo alloc] init];  // WithStart:stationLocation.location end:stationLocationDest.location
                                                       // transportationLine:transportationLine bikeDistance:bikeDistance];
                singleRouteInfo.sourceStation = stationLocation;
                singleRouteInfo.destStation = stationLocationDest;

                singleRouteInfo.type = transportationLine.type;

                singleRouteInfo.transportationLine = transportationLine;
                singleRouteInfo.bikeDistance = bikeDistance;
                singleRouteInfo.distance1 = bikeDistanceToSourceStation;
                singleRouteInfo.distance2 = bikeDistanceFromDestinationStation;

                if (![transportationRoutesTemp containsObject:singleRouteInfo]) {
                    [transportationRoutesTemp addObject:singleRouteInfo];
                }
            }
        }
    }

    self.transportationRoutes =
        [transportationRoutesTemp sortedArrayUsingComparator:^NSComparisonResult(SMSingleRouteInfo *r1, SMSingleRouteInfo *r2) {
          if (r1.bikeDistance < r2.bikeDistance)
              return NSOrderedAscending;
          else
              return NSOrderedDescending;
        }];
}

- (NSArray *)sortedEndStationsForTransportationLine:(SMTransportationLine *)pTransportationLine
{
    NSArray *endDistances = [pTransportationLine.stations sortedArrayUsingComparator:^NSComparisonResult(SMStationInfo *s1, SMStationInfo *s2) {
      if ([s1.location distanceFromLocation:[self end]] < [s2.location distanceFromLocation:[self end]])
          return NSOrderedAscending;
      else
          return NSOrderedDescending;
    }];

    return endDistances;
}

- (float)bikeDistanceForStart:(CLLocation *)start
                          end:(CLLocation *)end
        sourceStationLocation:(CLLocation *)source
                   desination:(CLLocation *)destination
{
    return [start distanceFromLocation:source] + [end distanceFromLocation:destination];
}
#pragma mark child notifications

- (CLLocation *)start
{
    return [self.fullRoute getStartLocation];
}

- (CLLocation *)end
{
    return [self.fullRoute getEndLocation];
}

#pragma mark - getters&setters

- (void)setBrokenRouteInfo:(SMBrokenRouteInfo *)pBrokenRouteInfo
{
    _brokenRouteInfo = pBrokenRouteInfo;

    if (pBrokenRouteInfo.sourceStation && pBrokenRouteInfo) {
        [self performSelectorOnMainThread:@selector(createSplitRoutes) withObject:nil waitUntilDone:NO];
    }
}

- (void)createSplitRoutes
{
    SMRoute *startRoute =
        [[SMRoute alloc] initWithRouteStart:[self start].coordinate andEnd:self.brokenRouteInfo.sourceStation.location.coordinate andDelegate:self];
    SMRoute *endRoute = [[SMRoute alloc] initWithRouteStart:self.brokenRouteInfo.destinationStation.location.coordinate
                                                     andEnd:[self end].coordinate
                                                andDelegate:self];

    SMRoute *transportRoute = [self newTransportationRoute];

    self.brokenRoutes = @[ startRoute, transportRoute, endRoute ];
}

- (SMRoute *)newTransportationRoute
{
    BOOL returning = NO;
    NSInteger sourceIndex = [self.brokenRouteInfo.transportationLine.stations indexOfObject:self.brokenRouteInfo.sourceStation];
    NSInteger destIndex = [self.brokenRouteInfo.transportationLine.stations indexOfObject:self.brokenRouteInfo.destinationStation];
    if (sourceIndex > destIndex) {
        returning = YES;
    }

    NSMutableArray *instructions = [NSMutableArray new];
    NSMutableArray *waypoints = [NSMutableArray new];
    if (!returning) {
        for (NSInteger i = sourceIndex; i <= destIndex; i++) {
            SMStationInfo *station = self.brokenRouteInfo.transportationLine.stations[i];
            SMTurnInstruction *turnInstruction = [self newTurnInstructionWithStation:station];
            [instructions addObject:turnInstruction];
            [waypoints addObject:station.location];
        }
    }
    else {
        for (NSInteger i = sourceIndex; i >= destIndex; i--) {
            SMStationInfo *station = self.brokenRouteInfo.transportationLine.stations[i];
            SMTurnInstruction *turnInstruction = [self newTurnInstructionWithStation:station];
            [instructions addObject:turnInstruction];
            [waypoints addObject:station.location];
        }
    }
    SMRoute *transportRoute = [[SMRoute alloc] init];
    transportRoute.turnInstructions = instructions;
    transportRoute.waypoints = waypoints;
    //    transportRoute.routeType = SMRouteTypeTransport;

    return transportRoute;
}

- (SMTurnInstruction *)newTurnInstructionWithStation:(SMStationInfo *)station
{
    SMTurnInstruction *turnInstruction = [SMTurnInstruction new];
    turnInstruction.wayName = station.name;
    turnInstruction.location = station.location;
    turnInstruction.imageName = [SMStationInfo imageNameForType:station.type];
    return turnInstruction;
}

- (void)updateTurn:(BOOL)firstElementRemoved
{
}
- (void)reachedDestination
{
}
- (void)updateRoute
{
}

- (void)startRoute:(SMRoute *)route
{
    for (SMRoute *route in self.brokenRoutes) {
        if (!route.waypoints) {
            return;
        }
    }

    for (SMRoute *route in self.brokenRoutes) {
        if (![route getEndLocation] || ![route getStartLocation]) {
            if ([self.delegate respondsToSelector:@selector(didFailBreakingRoute:)]) {
                [self.delegate didFailBreakingRoute:self];
                return;
            }
        }
    }

    if ([self.delegate respondsToSelector:@selector(didFinishBreakingRoute:)]) {
        [self.delegate didFinishBreakingRoute:self];
    }
}

- (void)routeNotFound
{
    if ([self.delegate respondsToSelector:@selector(didFailBreakingRoute:)]) {
        [self.delegate didFailBreakingRoute:self];
    }
}

- (void)serverError
{
}

@end
