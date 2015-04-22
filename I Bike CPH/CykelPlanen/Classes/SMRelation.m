//
//  SMRelation.m
//  I Bike CPH
//
//  Created by Nikola Markovic on 7/23/13.
//  Copyright (c) 2013 City of Copenhagen. All rights reserved.
//

#import "SMRelation.h"

@implementation SMRelation

-(id)init{
    if(self= [super init]){
        self.ways= [NSMutableArray new];
        self.nodes= [NSMutableArray new];
    }
    return self;
}

@end
