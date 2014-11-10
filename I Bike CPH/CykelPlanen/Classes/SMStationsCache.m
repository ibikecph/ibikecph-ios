//
//  SMStationsCache.m
//  I Bike CPH
//
//  Created by Nikola Markovic on 7/26/13.
//  Copyright (c) 2013 City of Copenhagen. All rights reserved.
//

#import "SMStationsCache.h"

@implementation SMStationsCache

#define CACHE_FILE_NAME @"StationsCached.data"
#define KEY_LINES @"KeyLines"

+(SMStationsCache*)instance{
    static SMStationsCache* INSTANCE;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        INSTANCE= [SMStationsCache new];
    });
    return INSTANCE;
}


-(void)load:(SMTransportation*)transportation{

    
}

-(void)save:(SMTransportation*)transportation{
    
}

@end
