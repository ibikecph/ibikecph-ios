//
//  SMTrain.h
//  I Bike CPH
//
//  Created by Nikola Markovic on 8/12/13.
//  Copyright (c) 2013 City of Copenhagen. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SMArrivalInformation.h"

/**
 * Train. Has arrival information for stations. FIXME: arrival inforamtion is exposed as mutable/nilable array. Used in SMRouteInfoViewController, SMTransportation.
 */
@interface SMTrain : NSObject

@property(nonatomic, strong) NSMutableArray* arrivalInformation;

-(SMArrivalInformation*)informationForStation:(SMStationInfo*)station;
-(NSArray*)routeTimestampsForSourceStation:(SMStationInfo*)sourceSt destinationStation:(SMStationInfo*)destinationSt forDay:(int)dayIndex time:(SMTime*)time;

@end
