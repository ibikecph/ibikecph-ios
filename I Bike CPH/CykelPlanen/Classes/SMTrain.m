//
//  SMTrain.m
//  I Bike CPH
//
//  Created by Nikola Markovic on 8/12/13.
//  Copyright (c) 2013 City of Copenhagen. All rights reserved.
//

#import "SMTrain.h"
#import "SMRouteTimeInfo.h"
@implementation SMTrain

-(SMArrivalInformation*)informationForStation:(SMStationInfo*)station{
    if(!self.arrivalInformation){
        self.arrivalInformation= [NSMutableArray new];
    }
    
    SMArrivalInformation* arrivalInfo;
    NSArray* st= [self.arrivalInformation filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"SELF.station == %@",station]];
    if(st.count==0){
        arrivalInfo= [SMArrivalInformation new];
        arrivalInfo.station= station;
//        NSLog(@"New station %@",station.name);
        
        [self.arrivalInformation addObject:arrivalInfo];
    }else{
        NSAssert(st.count==1, @"Invalid arrival info count");
        arrivalInfo= st[0];
    }
    return arrivalInfo;
}

-(NSArray*)routeTimestampsForSourceStation:(SMStationInfo*)sourceSt destinationStation:(SMStationInfo*)destinationSt forDay:(int)dayIndex time:(SMTime*)time{
    BOOL hasSource= NO;
    BOOL hasDestination= NO;
    BOOL departure= NO;
    SMArrivalInformation* srcAI;
    SMArrivalInformation* destAI;
    for(SMArrivalInformation* arrivalInformation in self.arrivalInformation){
        if([arrivalInformation.station isEqual:sourceSt] && [arrivalInformation hasInfoForDayAtIndex:dayIndex]){
            hasSource= YES;
            srcAI= arrivalInformation;

            if(hasDestination){
                departure= NO;
                break;
            }
        }else if([arrivalInformation.station isEqual:destinationSt] && [arrivalInformation hasInfoForDayAtIndex:dayIndex]){
            hasDestination= YES;
            destAI= arrivalInformation;
            
            if(hasSource){
                departure= YES;
                break;
            }

        }
    }

    if(hasSource && hasDestination){
        SMArrivalMapping* srcMapping= [srcAI mappingForDayAtIndex:dayIndex];
        SMArrivalMapping* destMapping= [destAI mappingForDayAtIndex:dayIndex];
        NSArray* srcArr;
        NSArray* destArr;
        if(departure){
            srcArr= srcMapping.departures;
            destArr= destMapping.departures;
        }else{
            srcArr= srcMapping.arrivals;
            destArr= destMapping.arrivals;
        }
        
        NSMutableArray* times= [NSMutableArray new];
        int index= 0;
        int smallest= 0;
        int smallestDiff= INT_MAX;
        for(SMTime* lTime in srcArr){

            SMTime* diffTime= [time differenceFrom:lTime];
            NSNumber* diff= [NSNumber numberWithInt:diffTime.hour*60+diffTime.minutes];
            NSLog(@"%@ %d",lTime.description, diff.intValue);
            if(diff.intValue<smallestDiff && diff.intValue>=0){
                NSLog(@"Smallest is %@",diffTime);
                smallestDiff= diff.intValue;
                smallest= index;
            }
            index++;
        }
        
        for(int i=0; i<3; i++){
            SMRouteTimeInfo* timeInfo= [SMRouteTimeInfo new];

            timeInfo.sourceTime=[srcArr objectAtIndex:(smallest+i)%srcArr.count];
            timeInfo.destTime=[destArr objectAtIndex:(smallest+i)%srcArr.count];
            [times addObject:timeInfo];
        }
        return times;
    }
    return nil;
}
@end
