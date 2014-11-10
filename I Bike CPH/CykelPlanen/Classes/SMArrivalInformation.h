//
//  SMArrivalInformation.h
//  I Bike CPH
//
//  Created by Nikola Markovic on 8/12/13.
//  Copyright (c) 2013 City of Copenhagen. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SMStationInfo.h"
#import "SMArrivalMapping.h"
@interface SMArrivalInformation : NSObject

@property(nonatomic, strong) SMStationInfo* station;
@property(nonatomic, strong) NSMutableArray* mappings;

-(void)addArrivalTime:(SMTime*)pTime forDays:(NSArray*)days;
-(void)addDepartureTime:(SMTime*)pTime forDays:(NSArray*)days;
-(SMArrivalMapping*)mappingForDayAtIndex:(int)index;
-(BOOL)hasInfoForDayAtIndex:(int)index;
@end
