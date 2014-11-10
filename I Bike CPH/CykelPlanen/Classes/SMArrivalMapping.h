//
//  SMArrivalMapping.h
//  I Bike CPH
//
//  Created by Nikola Markovic on 8/12/13.
//  Copyright (c) 2013 City of Copenhagen. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SMArrivalMapping : NSObject

@property(nonatomic, strong) NSMutableArray* arrivals;
@property(nonatomic, strong) NSMutableArray* departures;
@property(nonatomic, strong) NSArray* days;

-(BOOL)daysMatch:(NSArray*)days;

-(void)addArrivalTime:(SMTime*)time;
-(void)addDepartureTime:(SMTime*)time;

@end
