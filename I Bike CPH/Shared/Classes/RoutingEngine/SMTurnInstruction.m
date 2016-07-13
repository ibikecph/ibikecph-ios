//
//  SMTurnInstructions.m
//  I Bike CPH
//
//  Created by Petra Markovic on 1/28/13.
//  Copyright (C) 2013 City of Copenhagen.  All rights reserved.
//
//  This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0.
//  If a copy of the MPL was not distributed with this file, You can obtain one at
//  http://mozilla.org/MPL/2.0/.
//

#import "SMTurnInstruction.h"

@interface SMTurnInstruction ()
@property (nonatomic, assign) OSRMV5ManeuverType maneuverType;
@property (nonatomic, assign) OSRMV5ManeuverModifier maneuverModifier;
@end

@implementation SMTurnInstruction
@synthesize turnDirection = _turnDirection;

// Returns full direction names for abbreviations N NE E SE S SW W NW
NSString *directionString(NSString *abbreviation)
{
    NSString *s = translateString([@"direction_" stringByAppendingString:abbreviation]);
    return s;
}

// Returns only string representation of the driving direction
- (void)generateDescriptionString
{
    NSString *key = [@"direction_" stringByAppendingFormat:@"%d", self.turnDirection];
    if (self.routeType == SMRouteTypeBike || self.routeType == SMRouteTypeWalk) {
        NSString *desc =
            [NSString stringWithFormat:translateString(key), translateString([@"direction_number_" stringByAppendingString:self.ordinalDirection])];
        self.descriptionString = desc;
    }
    else {
        self.descriptionString = [NSString stringWithFormat:translateString(key), self.routeLineDestination];
    }
}

- (void)generateStartDescriptionString
{
    if (self.routeType == SMRouteTypeBike || self.routeType == SMRouteTypeWalk) {
        NSString *key = [@"first_direction_" stringByAppendingFormat:@"%d", self.turnDirection];
        NSString *desc =
            [NSString stringWithFormat:translateString(key), translateString([@"direction_" stringByAppendingString:self.directionAbbreviation]),
                                       translateString([@"direction_number_" stringByAppendingString:self.ordinalDirection])];
        self.descriptionString = desc;
    }
    else {
        NSString *key = [@"direction_" stringByAppendingFormat:@"%d", self.turnDirection];
        self.descriptionString = [NSString stringWithFormat:translateString(key), self.routeLineStart, self.routeLineName, self.routeLineDestination];
    }
}

- (void)generateShortDescriptionString
{
    self.shortDescriptionString = self.wayName;
}

// Returns only string representation of the driving direction including wayname
- (void)generateFullDescriptionString
{
    NSString *key = [@"direction_" stringByAppendingFormat:@"%d", self.turnDirection];

    if (self.routeType == SMRouteTypeBike || self.routeType == SMRouteTypeWalk) {
        if (self.turnDirection != 0 && self.turnDirection != 15 && self.turnDirection != 100) {
            self.fullDescriptionString = [NSString stringWithFormat:@"%@ %@", translateString(key), self.wayName];
            return;
        }
        self.fullDescriptionString = [NSString stringWithFormat:@"%@", translateString(key)];
    }
    else if (self.turnDirection == 18) {
        self.fullDescriptionString =
            [NSString stringWithFormat:translateString(key), self.routeLineStart, self.routeLineName, self.routeLineDestination];
    }
    else if (self.turnDirection == 19) {
        self.fullDescriptionString = [NSString stringWithFormat:translateString(key), self.routeLineDestination];
    }
}

- (UIImage *)directionIcon
{
    return [UIImage imageNamed:self.imageName];
}

// Full textual representation of the object, used mainly for debugging
- (NSString *)description
{
    return [NSString stringWithFormat:@"%@ %@ [SMTurnInstruction: %d, %@, (%f, %f)]", [self descriptionString], self.wayName,
                                      self.lengthInMeters, self.directionAbbreviation,
                                      self.location.coordinate.latitude, self.location.coordinate.longitude];
}

- (void)setTurnDirection:(OSRMV4TurnDirection)turnDirection
{
    _turnDirection = turnDirection;
    self.imageName = [self imageNameForTurnDirection:self.turnDirection];
}

- (void)setRouteType:(SMRouteType)routeType
{
    _routeType = routeType;

    if (self.turnDirection == 18 || self.turnDirection == 19) {  // For public transport, override icon.
        switch (self.routeType) {
            case SMRouteTypeSTrain:
                self.imageName = @"STrainDirection";
                break;
            case SMRouteTypeTrain:
                self.imageName = @"TrainDirection";
                break;
            case SMRouteTypeBus:
                self.imageName = @"BusDirection";
                break;
            case SMRouteTypeFerry:
                self.imageName = @"FerryDirection";
                break;
            case SMRouteTypeMetro:
                self.imageName = @"MetroDirection";
                break;
            case SMRouteTypeWalk:
                self.imageName = @"WalkDirection";
                break;
            default:
                break;
        }
    }
}

#pragma mark - Getters

- (NSString *)roundedDistanceToNextTurn
{
    int moduloLength = self.lengthInMeters % 10;
    return [NSString stringWithFormat:@"%i",self.lengthInMeters - moduloLength + (moduloLength < 5 ? 0 : 10)];
}

#pragma mark - Helper methods

- (void)setManeuverTypeWithString:(NSString *)maneuverTypeString
{
    if ([maneuverTypeString isEqualToString:@"turn"]) {
        self.maneuverType = OSRMV5ManueverTypeTurn;
    } else if ([maneuverTypeString isEqualToString:@"new name"]) {
        self.maneuverType = OSRMV5ManueverTypeNewName;
    } else if ([maneuverTypeString isEqualToString:@"depart"]) {
        self.maneuverType = OSRMV5ManueverTypeDepart;
    } else if ([maneuverTypeString isEqualToString:@"arrive"]) {
        self.maneuverType = OSRMV5ManueverTypeArrive;
    } else if ([maneuverTypeString isEqualToString:@"merge"]) {
        self.maneuverType = OSRMV5ManueverTypeMerge;
    } else if ([maneuverTypeString isEqualToString:@"ramp"]) {
        self.maneuverType = OSRMV5ManueverTypeRamp;
    } else if ([maneuverTypeString isEqualToString:@"on ramp"]) {
        self.maneuverType = OSRMV5ManueverTypeOnRamp;
    } else if ([maneuverTypeString isEqualToString:@"off ramp"]) {
        self.maneuverType = OSRMV5ManueverTypeOffRamp;
    } else if ([maneuverTypeString isEqualToString:@"fork"]) {
        self.maneuverType = OSRMV5ManueverTypeFork;
    } else if ([maneuverTypeString isEqualToString:@"end of road"]) {
        self.maneuverType = OSRMV5ManueverTypeEndOfRoad;
    } else if ([maneuverTypeString isEqualToString:@"use lane"]) {
        self.maneuverType = OSRMV5ManueverTypeUseLane;
    } else if ([maneuverTypeString isEqualToString:@"continue"]) {
        self.maneuverType = OSRMV5ManueverTypeContinue;
    } else if ([maneuverTypeString isEqualToString:@"roundabout"]) {
        self.maneuverType = OSRMV5ManueverTypeRoundabout;
    } else if ([maneuverTypeString isEqualToString:@"rotary"]) {
        self.maneuverType = OSRMV5ManueverTypeRotary;
    } else if ([maneuverTypeString isEqualToString:@"roundabout turn"]) {
        self.maneuverType = OSRMV5ManueverTypeRoundaboutTurn;
    } else if ([maneuverTypeString isEqualToString:@"notification"]) {
        self.maneuverType = OSRMV5ManueverTypeNotification;
    }
}

- (void)setManeuverModifierWithString:(NSString *)maneuverModifierString
{
    if ([maneuverModifierString isEqualToString:@"uturn"]) {
        self.maneuverModifier = OSRMV5ManueverModifierUTurn;
    } else if ([maneuverModifierString isEqualToString:@"sharp right"]) {
        self.maneuverModifier = OSRMV5ManueverModifierSharpRight;
    } else if ([maneuverModifierString isEqualToString:@"right"]) {
        self.maneuverModifier = OSRMV5ManueverModifierRight;
    } else if ([maneuverModifierString isEqualToString:@"slight right"]) {
        self.maneuverModifier = OSRMV5ManueverModifierSlightRight;
    } else if ([maneuverModifierString isEqualToString:@"straight"]) {
        self.maneuverModifier = OSRMV5ManueverModifierStraight;
    } else if ([maneuverModifierString isEqualToString:@"slight left"]) {
        self.maneuverModifier = OSRMV5ManueverModifierSlightLeft;
    } else if ([maneuverModifierString isEqualToString:@"left"]) {
        self.maneuverModifier = OSRMV5ManueverModifierLeft;
    } else if ([maneuverModifierString isEqualToString:@"sharp left"]) {
        self.maneuverModifier = OSRMV5ManueverModifierSharpLeft;
    }
}

- (NSString *)imageNameForTurnDirection:(OSRMV4TurnDirection)turnDirection
{
    switch (turnDirection) {
        case OSRMV4TurnDirectionNoTurn:
            return @"no icon";
            break;
        case OSRMV4TurnDirectionGoStraight:
            return @"up";
            break;
        case OSRMV4TurnDirectionTurnSlightRight:
            return @"right-ward";
            break;
        case OSRMV4TurnDirectionTurnRight:
            return @"right";
            break;
        case OSRMV4TurnDirectionTurnSharpRight:
            return @"right";
            break;
        case OSRMV4TurnDirectionUTurn:
            return @"u-turn";
            break;
        case OSRMV4TurnDirectionTurnSharpLeft:
            return @"left";
            break;
        case OSRMV4TurnDirectionTurnLeft:
            return @"left";
            break;
        case OSRMV4TurnDirectionTurnSlightLeft:
            return @"left-ward";
            break;
        case OSRMV4TurnDirectionReachViaPoint:
            return @"location";
            break;
        case OSRMV4TurnDirectionHeadOn:
            return @"up";
            break;
        case OSRMV4TurnDirectionEnterRoundAbout:
            return @"roundabout";
            break;
        case OSRMV4TurnDirectionLeaveRoundAbout:
            return @"roundabout";
            break;
        case OSRMV4TurnDirectionStayOnRoundAbout:
            return @"roundabout";
            break;
        case OSRMV4TurnDirectionStartAtEndOfStreet:
            return @"up";
            break;
        case OSRMV4TurnDirectionReachedYourDestination:
            return @"flag";
            break;
        case OSRMV4TurnDirectionStartPushingBikeInOneway:
            return @"walk";
            break;
        case OSRMV4TurnDirectionStopPushingBikeInOneway:
            return @"bike";
            break;
        case OSRMV4TurnDirectionBoardPublicTransport:
            return @"near-destination";
            break;
        case OSRMV4TurnDirectionUnboardPublicTransport:
            return @"near-destination";
            break;
        default:
            return @"";
            break;
    }
}

@end