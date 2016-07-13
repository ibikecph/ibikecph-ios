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
@property (nonatomic) NSString *shortDescriptionString;
@property (nonatomic) NSString *descriptionString;
@property (nonatomic) NSString *fullDescriptionString;
@end

@implementation SMTurnInstruction
@synthesize turnDirection = _turnDirection;

- (void)generateShortDescriptionString
{
    self.shortDescriptionString = self.wayName;
}

// Returns only string representation of the driving direction
- (void)generateDescriptionString
{
    switch (self.osrmVersion) {
        case TurnInstructionOSRMVersion4: {
            NSString *key = [@"direction_" stringByAppendingFormat:@"%lu", (unsigned long)self.turnDirection];
            if (self.routeType == SMRouteTypeBike || self.routeType == SMRouteTypeWalk) {
                NSString *description =
                    [NSString stringWithFormat:translateString(key), translateString([@"direction_number_" stringByAppendingString:self.ordinalDirection])];
                self.descriptionString = description;
            }
            else {
                self.descriptionString = [NSString stringWithFormat:translateString(key), self.routeLineDestination];
            }
            break;
        }
        case TurnInstructionOSRMVersion5: {
            self.descriptionString = [self OSRMV5Instruction];
        }
    }
}

- (void)generateStartDescriptionString
{
    switch (self.osrmVersion) {
        case TurnInstructionOSRMVersion4:
            if (self.routeType == SMRouteTypeBike || self.routeType == SMRouteTypeWalk) {
                NSString *key = [@"first_direction_" stringByAppendingFormat:@"%lu", (unsigned long)self.turnDirection];
                NSString *description =
                    [NSString stringWithFormat:translateString(key),
                                               translateString([@"direction_" stringByAppendingString:self.directionAbbreviation]),
                                               translateString([@"direction_number_" stringByAppendingString:self.ordinalDirection])];
                self.descriptionString = description;
            }
            else {
                NSString *key = [@"direction_" stringByAppendingFormat:@"%lu", (unsigned long)self.turnDirection];
                self.descriptionString = [NSString stringWithFormat:translateString(key), self.routeLineStart, self.routeLineName, self.routeLineDestination];
            }
            break;
        case TurnInstructionOSRMVersion5: {
            self.descriptionString = [self OSRMV5Instruction];
            break;
        }
    }
}

// Returns only string representation of the driving direction including wayname
- (void)generateFullDescriptionString
{
    switch (self.osrmVersion) {
        case TurnInstructionOSRMVersion4: {
            NSString *key = [@"direction_" stringByAppendingFormat:@"%lu", (unsigned long)self.turnDirection];
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
            break;
        }
        case TurnInstructionOSRMVersion5: {
            self.fullDescriptionString = [self OSRMV5Instruction];
            break;
        }
    }
}

#pragma mark - Setters

- (void)setTurnDirection:(OSRMV4TurnDirection)turnDirection
{
    _turnDirection = turnDirection;
    [self updateImageName];
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

- (UIImage *)directionIcon
{
    return [UIImage imageNamed:self.imageName];
}


- (NSString *)shortDescriptionString
{
    if (!_shortDescriptionString) {
        [self generateShortDescriptionString];
    }
    return _shortDescriptionString;
}

- (NSString *)descriptionString
{
    if (!_descriptionString) {
        [self generateDescriptionString];
    }
    return _descriptionString;
}

- (NSString *)fullDescriptionString
{
    if (!_fullDescriptionString) {
        [self generateFullDescriptionString];
    }
    return _fullDescriptionString;
}

- (NSString *)roundedDistanceToNextTurn
{
    int moduloLength = self.lengthInMeters % 10;
    return [NSString stringWithFormat:@"%i",self.lengthInMeters - moduloLength + (moduloLength < 5 ? 0 : 10)];
}

#pragma mark - Helper methods

- (NSString *)OSRMV5Instruction
{
    NSString *string;
    BOOL addModifier = NO;
    NSString *modifierString = [self stringForManeuverModifier:self.maneuverModifier];
    NSString *modifierDisplayString = [modifierString stringByReplacingOccurrencesOfString:@"_" withString:@" "];
    switch (self.maneuverType) {
        case OSRMV5ManeuverTypeTurn:
        case OSRMV5ManeuverTypeEndOfRoad:
        case OSRMV5ManeuverTypeFork:
        case OSRMV5ManeuverTypeNewName:
        case OSRMV5ManeuverTypeNotification:
        case OSRMV5ManeuverTypeRoundaboutTurn:
            string = @"turn";
            addModifier = YES;
            break;
        case OSRMV5ManeuverTypeContinue:
            string = @"continue";
            addModifier = YES;
            break;
        case OSRMV5ManeuverTypeMerge:
            string = @"merge";
            addModifier = YES;
            break;
        case OSRMV5ManeuverTypeDepart:
            string = translateString(@"depart");
            string = [string stringByReplacingOccurrencesOfString:@"{{heading}}" withString:modifierDisplayString];
            break;
        case OSRMV5ManeuverTypeArrive:
            string = translateString(@"arrive");
            string = [string stringByReplacingOccurrencesOfString:@"{{side}}" withString:modifierDisplayString];
            break;
        case OSRMV5ManeuverTypeRoundabout:
            string = translateString(@"roundabout");
//            string = [string stringByReplacingOccurrencesOfString:@"%{exit}" withString:self.displayName];
            break;
        case OSRMV5ManeuverTypeRotary:
            string = translateString(@"rotary");
//            string = [string stringByReplacingOccurrencesOfString:@"%{exit}" withString:self.displayName];
            break;
        case OSRMV5ManeuverTypeOnRamp:
            string = translateString(@"on_ramp");
            break;
        case OSRMV5ManeuverTypeOffRamp:
            string = translateString(@"off_ramp");
            break;
        default:
            string = nil;
            break;
    }
    if (addModifier) {
        string = [string stringByAppendingFormat:@"_%@",modifierString];
        string = [translateString(string) stringByReplacingOccurrencesOfString:@"{{name}}" withString:self.wayName];
    }
    if ([string rangeOfString:@"{{name}}"].location == NSNotFound) {
        string = [string stringByReplacingOccurrencesOfString:@"{{name}}" withString:self.wayName];
    }
    return string;
}

- (void)setManeuverTypeWithString:(NSString *)maneuverTypeString
{
    if ([maneuverTypeString isEqualToString:@"turn"]) {
        self.maneuverType = OSRMV5ManeuverTypeTurn;
    } else if ([maneuverTypeString isEqualToString:@"new name"]) {
        self.maneuverType = OSRMV5ManeuverTypeNewName;
    } else if ([maneuverTypeString isEqualToString:@"depart"]) {
        self.maneuverType = OSRMV5ManeuverTypeDepart;
    } else if ([maneuverTypeString isEqualToString:@"arrive"]) {
        self.maneuverType = OSRMV5ManeuverTypeArrive;
    } else if ([maneuverTypeString isEqualToString:@"merge"]) {
        self.maneuverType = OSRMV5ManeuverTypeMerge;
    } else if ([maneuverTypeString isEqualToString:@"ramp"]) {
        self.maneuverType = OSRMV5ManeuverTypeRamp;
    } else if ([maneuverTypeString isEqualToString:@"on ramp"]) {
        self.maneuverType = OSRMV5ManeuverTypeOnRamp;
    } else if ([maneuverTypeString isEqualToString:@"off ramp"]) {
        self.maneuverType = OSRMV5ManeuverTypeOffRamp;
    } else if ([maneuverTypeString isEqualToString:@"fork"]) {
        self.maneuverType = OSRMV5ManeuverTypeFork;
    } else if ([maneuverTypeString isEqualToString:@"end of road"]) {
        self.maneuverType = OSRMV5ManeuverTypeEndOfRoad;
    } else if ([maneuverTypeString isEqualToString:@"use lane"]) {
        self.maneuverType = OSRMV5ManeuverTypeUseLane;
    } else if ([maneuverTypeString isEqualToString:@"continue"]) {
        self.maneuverType = OSRMV5ManeuverTypeContinue;
    } else if ([maneuverTypeString isEqualToString:@"roundabout"]) {
        self.maneuverType = OSRMV5ManeuverTypeRoundabout;
    } else if ([maneuverTypeString isEqualToString:@"rotary"]) {
        self.maneuverType = OSRMV5ManeuverTypeRotary;
    } else if ([maneuverTypeString isEqualToString:@"roundabout turn"]) {
        self.maneuverType = OSRMV5ManeuverTypeRoundaboutTurn;
    } else if ([maneuverTypeString isEqualToString:@"notification"]) {
        self.maneuverType = OSRMV5ManeuverTypeNotification;
    }
    [self updateImageName];
}

- (void)setManeuverModifierWithString:(NSString *)maneuverModifierString
{
    if ([maneuverModifierString isEqualToString:@"uturn"]) {
        self.maneuverModifier = OSRMV5ManeuverModifierUTurn;
    } else if ([maneuverModifierString isEqualToString:@"sharp right"]) {
        self.maneuverModifier = OSRMV5ManeuverModifierSharpRight;
    } else if ([maneuverModifierString isEqualToString:@"right"]) {
        self.maneuverModifier = OSRMV5ManeuverModifierRight;
    } else if ([maneuverModifierString isEqualToString:@"slight right"]) {
        self.maneuverModifier = OSRMV5ManeuverModifierSlightRight;
    } else if ([maneuverModifierString isEqualToString:@"straight"]) {
        self.maneuverModifier = OSRMV5ManeuverModifierStraight;
    } else if ([maneuverModifierString isEqualToString:@"slight left"]) {
        self.maneuverModifier = OSRMV5ManeuverModifierSlightLeft;
    } else if ([maneuverModifierString isEqualToString:@"left"]) {
        self.maneuverModifier = OSRMV5ManeuverModifierLeft;
    } else if ([maneuverModifierString isEqualToString:@"sharp left"]) {
        self.maneuverModifier = OSRMV5ManeuverModifierSharpLeft;
    }
    [self updateImageName];
}

- (NSString *)stringForManeuverModifier:(OSRMV5ManeuverModifier)maneuverModifier
{
    switch (self.maneuverModifier) {
        case OSRMV5ManeuverModifierStraight:
            return @"straight";
            break;
        case OSRMV5ManeuverModifierUTurn:
            return @"uturn";
            break;
        case OSRMV5ManeuverModifierLeft:
            return @"left";
            break;
        case OSRMV5ManeuverModifierSharpLeft:
            return @"sharp_left";
            break;
        case OSRMV5ManeuverModifierSlightLeft:
            return @"slight_left";
            break;
        case OSRMV5ManeuverModifierRight:
            return @"right";
            break;
        case OSRMV5ManeuverModifierSharpRight:
            return @"shartp_right";
            break;
        case OSRMV5ManeuverModifierSlightRight:
            return @"slight_right";
            break;
    }
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
        case OSRMV5ManeuverTypeDepart:
            self.imageName = @"bike";
            break;
        case OSRMV5ManeuverTypeArrive:
            self.imageName = @"near-destination";
            break;
        case OSRMV5ManeuverTypeRoundabout:
        case OSRMV5ManeuverTypeRotary:
        case OSRMV5ManeuverTypeRoundaboutTurn:
            self.imageName = @"roundabout";
            break;
//        case OSRMV5ManeuverTypeTurn:
//        case OSRMV5ManeuverTypeNewName:
//        case OSRMV5ManeuverTypeMerge:
//        case OSRMV5ManeuverTypeRamp:
//        case OSRMV5ManeuverTypeOnRamp:
//        case OSRMV5ManeuverTypeOffRamp:
//        case OSRMV5ManeuverTypeFork:
//        case OSRMV5ManeuverTypeEndOfRoad:
//        case OSRMV5ManeuverTypeUseLane:
//        case OSRMV5ManeuverTypeContinue:
//        case OSRMV5ManeuverTypeNotification:
        default:
            switch (self.maneuverModifier) {
                case OSRMV5ManeuverModifierStraight:
                    self.imageName = @"up";
                    break;
                case OSRMV5ManeuverModifierUTurn:
                    self.imageName = @"u-turn";
                    break;
                case OSRMV5ManeuverModifierLeft:
                case OSRMV5ManeuverModifierSharpLeft:
                    self.imageName = @"left";
                    break;
                case OSRMV5ManeuverModifierSlightLeft:
                    self.imageName = @"left-ward";
                    break;
                case OSRMV5ManeuverModifierRight:
                case OSRMV5ManeuverModifierSharpRight:
                    self.imageName = @"right";
                    break;
                case OSRMV5ManeuverModifierSlightRight:
                    self.imageName = @"right-ward";
                    break;
            }
            break;
            
    }
}

@end