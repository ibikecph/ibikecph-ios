//
//  SMUser.h
//  I Bike CPH
//
//  Created by Nikola Markovic on 7/25/13.
//  Copyright (c) 2013 City of Copenhagen. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SMTripRoute.h"
#import "SMRoute.h"

@interface SMUser : NSObject

+(SMUser*)user;

@property(nonatomic, strong) SMTripRoute* tripRoute;
@property(nonatomic, strong) SMRoute* route;
@end
