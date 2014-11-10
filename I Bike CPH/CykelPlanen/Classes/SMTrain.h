//
//  SMTrain.h
//  I Bike CPH
//
//  Created by Nikola Markovic on 8/12/13.
//  Copyright (c) 2013 City of Copenhagen. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SMArrivalInformation.h"

@interface SMTrain : NSObject

@property(nonatomic, strong) NSMutableArray* arrivalInformation;

-(SMArrivalInformation*)informationForStation:(SMStationInfo*)station;
-(NSArray*)routeTimestampsForSourceStation:(SMStationInfo*)sourceSt destinationStation:(SMStationInfo*)destinationSt forDay:(int)dayIndex time:(SMTime*)time;

@end
