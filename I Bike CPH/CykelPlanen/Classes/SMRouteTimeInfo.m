//
//  SMRouteTimeInfo.m
//  I Bike CPH
//
//  Created by Nikola Markovic on 8/6/13.
//  Copyright (c) 2013 City of Copenhagen. All rights reserved.
//

#import "SMRouteTimeInfo.h"

@implementation SMRouteTimeInfo

-(id)initWithRouteInfo:(SMSingleRouteInfo*)routeInfo sourceTime:(SMTime*)sourceTime destinationTime:(SMTime*)destTime{
    if(self= [super init]){
        self.routeInfo= routeInfo;
        self.sourceTime= sourceTime;
        self.destTime= destTime;
    }
    return self;
}
@end
