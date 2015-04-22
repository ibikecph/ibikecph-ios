//
//  SMWay.h
//  I Bike CPH
//
//  Created by Nikola Markovic on 7/23/13.
//  Copyright (c) 2013 City of Copenhagen. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 * SMWay. Has reference string, mutable array of nodes, role string. Used in SMTransportation.
 */
@interface SMWay : NSObject

@property(nonatomic, strong) NSString* ref;
@property(nonatomic, strong) NSMutableArray* nodes;
@property(nonatomic, strong) NSString* role;

@end
