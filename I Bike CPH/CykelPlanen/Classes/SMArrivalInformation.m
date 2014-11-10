//
//  SMArrivalInformation.m
//  I Bike CPH
//
//  Created by Nikola Markovic on 8/12/13.
//  Copyright (c) 2013 City of Copenhagen. All rights reserved.
//

#import "SMArrivalInformation.h"

@implementation SMArrivalInformation

-(SMArrivalMapping*)mappingForDayAtIndex:(int)index{
    NSNumber* num= [NSNumber numberWithInt:index];
    for(SMArrivalMapping* mapping in self.mappings){
        if([mapping.days containsObject:num]){
            return mapping;
        }
    }
    
    return nil;
}

-(void)addArrivalTime:(SMTime*)pTime forDays:(NSArray*)days{
//    NSLog(@"Adding arrival time %d:%d for %@",pTime.hour, pTime.minutes, self.station.name);
    for(SMArrivalMapping* mapping in self.mappings){
        if([mapping daysMatch:days]){
            [mapping addArrivalTime:pTime];
            return;
        }
    }
    
    SMArrivalMapping* arrivalMapping= [SMArrivalMapping new];
    arrivalMapping.days= days;
    [arrivalMapping addArrivalTime:pTime];
    [self.mappings addObject:arrivalMapping];
}

-(void)addDepartureTime:(SMTime*)pTime forDays:(NSArray*)days{
//        NSLog(@"Adding departure time %d:%d for %@",pTime.hour, pTime.minutes, self.station.name);
    for(SMArrivalMapping* mapping in self.mappings){
        if([mapping daysMatch:days]){
            [mapping addDepartureTime:pTime];
            return;
        }
    }
    
    SMArrivalMapping* arrivalMapping= [SMArrivalMapping new];
    arrivalMapping.days= days;
    [arrivalMapping addDepartureTime:pTime];
    [self.mappings addObject:arrivalMapping];
}

-(NSMutableArray*)mappings{
    if(!_mappings){
        _mappings= [NSMutableArray new];
    }
    return _mappings;
}

-(BOOL)hasInfoForDayAtIndex:(int)index{
    NSNumber* num= [NSNumber numberWithInt:index];
    for(SMArrivalMapping* mapping in self.mappings){
        if([mapping.days containsObject:num]){
            return YES;
        }
    }
    
    return NO;
}
@end
