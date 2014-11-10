//
//  SMArrivalMapping.m
//  I Bike CPH
//
//  Created by Nikola Markovic on 8/12/13.
//  Copyright (c) 2013 City of Copenhagen. All rights reserved.
//

#import "SMArrivalMapping.h"

@implementation SMArrivalMapping

-(BOOL)daysMatch:(NSArray*)pDays{
    if(self.days.count != pDays.count){
        return NO;
    }
    int index= 0;
    for(NSNumber* num in self.days){
        if(num.intValue != ((NSNumber*)pDays[index]).intValue)
            return NO;
        index++;
    }
    return YES;
}

-(void)addArrivalTime:(SMTime*)pTime{
    [self.arrivals addObject:pTime];
}

-(void)addDepartureTime:(SMTime*)pTime{
    [self.departures addObject:pTime];
}

-(NSMutableArray*)arrivals{
    if(!_arrivals){
        _arrivals= [NSMutableArray new];
    }
    return _arrivals;
}

-(NSMutableArray*)departures{
    if(!_departures){
        _departures= [NSMutableArray new];
    }
    return _departures;
}
@end
