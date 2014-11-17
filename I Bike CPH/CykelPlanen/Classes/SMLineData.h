//
//  SMLineData.h
//  I Bike CPH
//
//  Created by Nikola Markovic on 8/5/13.
//  Copyright (c) 2013 City of Copenhagen. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SMDepartureInfo.h"
#import "SMArrivalInfo.h"
#import "SMStationInfo.h"

/**
 * Line data. Has departure info, and multiple arrival infos.
 */
@interface SMLineData : NSObject

@property(nonatomic, strong) SMDepartureInfo* departureInfo;
@property(nonatomic, strong) NSMutableArray* arrivalInfos;

@end
