//
//  SMSingleRouteInfo.h
//  I Bike CPH
//
//  Created by Nikola Markovic on 7/8/13.
//  Copyright (c) 2013 City of Copenhagen. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SMStationInfo.h"

@class SMTransportationLine;

@interface SMSingleRouteInfo : NSObject

@property(nonatomic, strong) SMStationInfo* sourceStation;
@property(nonatomic, strong) SMStationInfo* destStation;
@property(nonatomic, strong) SMTransportationLine* transportationLine;
@property(nonatomic, assign) SMStationInfoType type;

@property(nonatomic, assign) double bikeDistance;
@property(nonatomic, assign) double distance1;
@property(nonatomic, assign) double distance2;

-(CLLocation*) startLocation;
-(CLLocation*) endLocation;


@end
