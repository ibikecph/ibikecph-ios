//
//  SMTravelInfo.m
//  I Bike CPH
//
//  Created by Nikola Markovic on 8/5/13.
//  Copyright (c) 2013 City of Copenhagen. All rights reserved.
//

#import "SMArrivalInfo.h"

@implementation SMArrivalInfo

-(id)initWithDepartures:(NSArray*)pDepartures arrivals:(NSArray*)pArrivals{
    if(self= [super init]){
        self.departures= pDepartures;
        self.arrivals= pArrivals;
    }
    return self;
}

@end
