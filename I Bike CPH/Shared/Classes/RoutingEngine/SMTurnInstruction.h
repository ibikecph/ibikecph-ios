//
//  SMTurnInstructions.h
//  I Bike CPH
//
//  Created by Petra Markovic on 1/28/13.
//  Copyright (C) 2013 City of Copenhagen.  All rights reserved.
//
//  This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0.
//  If a copy of the MPL was not distributed with this file, You can obtain one at
//  http://mozilla.org/MPL/2.0/.
//

#import "SMRoute.h"
#import <CoreLocation/CoreLocation.h>
#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, OSRMV4TurnDirection) {
    OSRMV4TurnDirectionNoTurn = 0,  // Give no instruction at all
    OSRMV4TurnDirectionGoStraight = 1,
    OSRMV4TurnDirectionTurnSlightRight = 2,
    OSRMV4TurnDirectionTurnRight = 3,
    OSRMV4TurnDirectionTurnSharpRight = 4,
    OSRMV4TurnDirectionUTurn = 5,
    OSRMV4TurnDirectionTurnSharpLeft = 6,
    OSRMV4TurnDirectionTurnLeft = 7,
    OSRMV4TurnDirectionTurnSlightLeft = 8,
    OSRMV4TurnDirectionReachViaPoint = 9,
    OSRMV4TurnDirectionHeadOn = 10,
    OSRMV4TurnDirectionEnterRoundAbout = 11,
    OSRMV4TurnDirectionLeaveRoundAbout = 12,
    OSRMV4TurnDirectionStayOnRoundAbout = 13,
    OSRMV4TurnDirectionStartAtEndOfStreet = 14,
    OSRMV4TurnDirectionReachedYourDestination = 15,
    OSRMV4TurnDirectionStartPushingBikeInOneway = 16,
    OSRMV4TurnDirectionStopPushingBikeInOneway = 17,
    OSRMV4TurnDirectionBoardPublicTransport = 18,
    OSRMV4TurnDirectionUnboardPublicTransport = 19,
    OSRMV4TurnDirectionReachingDestination = 100
};

/**
 * \ingroup libs
 * Turn instruction object
 */
@interface SMTurnInstruction : NSObject {
    // We need this array to calculate the location, since we only keep array index of the turn location (waypointsIndex),
    // not the locaiton itself.
    // We keep index so we know where turn location in this array of route locations is.
    // (needed for some SMRoute distance calculations, see where waypointsIndex is used in SMRoute.m)
    //    __weak NSArray *waypoints;
}

@property(nonatomic, assign) OSRMV4TurnDirection drivingDirection;
@property(nonatomic, strong) NSString *ordinalDirection;
@property(nonatomic, strong) NSString *wayName;
@property int lengthInMeters;
@property int timeInSeconds;
@property(nonatomic, strong) NSString *lengthWithUnit;
@property(nonatomic, readonly) NSString *roundedDistanceToNextTurn;
@property(nonatomic, strong) NSString *imageName;
@property(nonatomic, assign) SMRouteType routeType;
@property(nonatomic, strong) NSString *routeLineName;
@property(nonatomic, strong) NSString *routeLineStart;
@property(nonatomic, strong) NSString *routeLineDestination;
@property(nonatomic, strong) NSDate *routeLineTime;
/**
 * Length to next turn in units (km or m)
 * This value will not auto update
 */
@property(nonatomic, strong) NSString *fixedLengthWithUnit;
@property(nonatomic, strong) NSString *directionAbrevation;  // N: north, S: south, E: east, W: west, NW: North West, ...
@property float azimuth;

/**
 * Indicate type of transport
 *
 * 1 - bike
 * 2 - walking
 * 3 - ferry
 * 4 - train
 */
@property NSInteger vehicle;

@property int waypointsIndex;
@property(nonatomic, strong) CLLocation *loc;

@property(nonatomic, strong) NSString *shortDescriptionString;
@property(nonatomic, strong) NSString *descriptionString;
@property(nonatomic, strong) NSString *fullDescriptionString;

- (CLLocation *)getLocation;

// Returns only string representation of the driving direction
//- (NSString *)descriptionString;
// Returns only string representation of the driving direction including wayname
//- (NSString *)fullDescriptionString; // including wayname

- (UIImage *)directionIcon;

- (void)generateDescriptionString;
- (void)generateStartDescriptionString;
- (void)generateFullDescriptionString;
- (void)generateShortDescriptionString;

@end
