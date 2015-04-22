//
//  SMWay.m
//  I Bike CPH
//
//  Created by Nikola Markovic on 7/23/13.
//  Copyright (c) 2013 City of Copenhagen. All rights reserved.
//

#import "SMWay.h"

@implementation SMWay

-(id)init{
    if(self= [super init]){
        self.nodes= [NSMutableArray new];
    }
    return self;
}

@end
