//
//  SMRelation.h
//  I Bike CPH
//
//  Created by Nikola Markovic on 7/23/13.
//  Copyright (c) 2013 City of Copenhagen. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 * Route relation. Has reference number, ways mutable array and nodes mutable array. FIXME: ways and nodes are external mutable objects that can be nillified.
 */
@interface SMRelation : NSObject

@property(nonatomic, strong) NSNumber* ref;
@property(nonatomic, strong) NSMutableArray* ways;
@property(nonatomic, strong) NSMutableArray* nodes;

@end
