//
//  SMSingleRouteInfo.m
//  I Bike CPH
//
//  Created by Nikola Markovic on 7/8/13.
//  Copyright (c) 2013 City of Copenhagen. All rights reserved.
//

#import "SMSingleRouteInfo.h"

@implementation SMSingleRouteInfo

-(CLLocation*) startLocation{
    return self.sourceStation.location;
}

-(CLLocation*) endLocation{
    return self.destStation.location;
}

-(BOOL)isEqual:(id)object{
    SMSingleRouteInfo* other= object;
    BOOL equal=[other.sourceStation isEqual:self.sourceStation] && [other.destStation isEqual:self.destStation];
    return equal;
}
@end
