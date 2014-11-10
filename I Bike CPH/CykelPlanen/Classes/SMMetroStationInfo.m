//
//  SMMetroStationInfo.m
//  I Bike CPH
//
//  Created by Nikola Markovic on 8/19/13.
//  Copyright (c) 2013 City of Copenhagen. All rights reserved.
//

#import "SMMetroStationInfo.h"

@implementation SMMetroStationInfo

-(id)initWithStation:(SMStationInfo*)station timeOffset:(NSNumber*)offset{
    if(self=[super init]){
        self.station= station;
        self.timeOffset= offset;
    }
    return self;
}
@end
