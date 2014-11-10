//
//  SMStationsCache.h
//  I Bike CPH
//
//  Created by Nikola Markovic on 7/26/13.
//  Copyright (c) 2013 City of Copenhagen. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SMTransportation.h"
@interface SMStationsCache : NSObject

+(SMStationsCache*)instance;

-(void)load:(SMTransportation*)transportation;
-(void)save:(SMTransportation*)transportation;

@end
