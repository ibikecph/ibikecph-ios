//
//  SMUser.m
//  I Bike CPH
//
//  Created by Nikola Markovic on 7/25/13.
//  Copyright (c) 2013 City of Copenhagen. All rights reserved.
//

#import "SMUser.h"

@implementation SMUser

+(SMUser*)user{
    static SMUser* INSTANCE;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        INSTANCE= [SMUser new];
    });
    
    return INSTANCE;
}

@end
