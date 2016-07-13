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
    [self updateImageName];
}

#pragma mark - Setters

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

- (void)setDirectionAbbreviationWithBearingAfter:(NSUInteger)bearingAfter
{
    if (bearingAfter < 23) {
        self.directionAbbreviation = @"N";
    } else if (bearingAfter < 23 + 45) {
        self.directionAbbreviation = @"NE";
    } else if (bearingAfter < 23 + 45 * 2) {
        self.directionAbbreviation = @"E";
    } else if (bearingAfter < 23 + 45 * 3) {
        self.directionAbbreviation = @"SE";
    } else if (bearingAfter < 23 + 45 * 4) {
        self.directionAbbreviation = @"S";
    } else if (bearingAfter < 23 + 45 * 5) {
        self.directionAbbreviation = @"SW";
    } else if (bearingAfter < 23 + 45 * 6) {
        self.directionAbbreviation = @"W";
    } else if (bearingAfter < 23 + 45 * 7) {
        self.directionAbbreviation = @"NW";
    } else {
        self.directionAbbreviation = @"N";
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
    [self updateImageName];
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
    [self updateImageName];
}

- (void)updateImageName
{
    switch (self.osrmVersion) {
        case TurnInstructionOSRMVersion4:
            [self updateImageNameForOSRMV4];
            break;
        case TurnInstructionOSRMVersion5:
            [self updateImageNameForOSRMV5];
            break;
    }
}

- (void)updateImageNameForOSRMV4
{
    switch (self.turnDirection) {
        case OSRMV4TurnDirectionNoTurn:
            self.imageName = @"no icon";
            break;
        case OSRMV4TurnDirectionGoStraight:
            self.imageName = @"up";
            break;
        case OSRMV4TurnDirectionTurnSlightRight:
            self.imageName = @"right-ward";
            break;
        case OSRMV4TurnDirectionTurnRight:
            self.imageName = @"right";
            break;
        case OSRMV4TurnDirectionTurnSharpRight:
            self.imageName = @"right";
            break;
        case OSRMV4TurnDirectionUTurn:
            self.imageName = @"u-turn";
            break;
        case OSRMV4TurnDirectionTurnSharpLeft:
            self.imageName = @"left";
            break;
        case OSRMV4TurnDirectionTurnLeft:
            self.imageName = @"left";
            break;
        case OSRMV4TurnDirectionTurnSlightLeft:
            self.imageName = @"left-ward";
            break;
        case OSRMV4TurnDirectionReachViaPoint:
            self.imageName = @"location";
            break;
        case OSRMV4TurnDirectionHeadOn:
            self.imageName = @"up";
            break;
        case OSRMV4TurnDirectionEnterRoundAbout:
            self.imageName = @"roundabout";
            break;
        case OSRMV4TurnDirectionLeaveRoundAbout:
            self.imageName = @"roundabout";
            break;
        case OSRMV4TurnDirectionStayOnRoundAbout:
            self.imageName = @"roundabout";
            break;
        case OSRMV4TurnDirectionStartAtEndOfStreet:
            self.imageName = @"up";
            break;
        case OSRMV4TurnDirectionReachedYourDestination:
            self.imageName = @"flag";
            break;
        case OSRMV4TurnDirectionStartPushingBikeInOneway:
            self.imageName = @"walk";
            break;
        case OSRMV4TurnDirectionStopPushingBikeInOneway:
            self.imageName = @"bike";
            break;
        case OSRMV4TurnDirectionBoardPublicTransport:
            self.imageName = @"near-destination";
            break;
        case OSRMV4TurnDirectionUnboardPublicTransport:
            self.imageName = @"near-destination";
            break;
        default:
            self.imageName = @"";
            break;
    }
}

- (void)updateImageNameForOSRMV5
{
    switch (self.maneuverType) {
        case OSRMV5ManueverTypeDepart:
            self.imageName = @"bike";
            break;
        case OSRMV5ManueverTypeArrive:
            self.imageName = @"near-destination";
            break;
        case OSRMV5ManueverTypeRoundabout:
        case OSRMV5ManueverTypeRotary:
        case OSRMV5ManueverTypeRoundaboutTurn:
            self.imageName = @"roundabout";
            break;
//        case OSRMV5ManueverTypeTurn:
//        case OSRMV5ManueverTypeNewName:
//        case OSRMV5ManueverTypeMerge:
//        case OSRMV5ManueverTypeRamp:
//        case OSRMV5ManueverTypeOnRamp:
//        case OSRMV5ManueverTypeOffRamp:
//        case OSRMV5ManueverTypeFork:
//        case OSRMV5ManueverTypeEndOfRoad:
//        case OSRMV5ManueverTypeUseLane:
//        case OSRMV5ManueverTypeContinue:
//        case OSRMV5ManueverTypeNotification:
        default:
            switch (self.maneuverModifier) {
                case OSRMV5ManueverModifierStraight:
                    self.imageName = @"up";
                    break;
                case OSRMV5ManueverModifierUTurn:
                    self.imageName = @"u-turn";
                    break;
                case OSRMV5ManueverModifierLeft:
                case OSRMV5ManueverModifierSharpLeft:
                    self.imageName = @"left";
                    break;
                case OSRMV5ManueverModifierSlightLeft:
                    self.imageName = @"left-ward";
                    break;
                case OSRMV5ManueverModifierRight:
                case OSRMV5ManueverModifierSharpRight:
                    self.imageName = @"right";
                    break;
                case OSRMV5ManueverModifierSlightRight:
                    self.imageName = @"right-ward";
                    break;
            }
            break;
            
    }
}

@end