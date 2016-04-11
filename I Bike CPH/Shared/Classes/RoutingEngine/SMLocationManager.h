//
//  SMLocationManager.h
//  TestMap
//
//  Created by Ivan Pavlovic on 11/1/12.
//  Copyright (C) 2013 City of Copenhagen.  All rights reserved.
//
//  This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0.
//  If a copy of the MPL was not distributed with this file, You can obtain one at 
//  http://mozilla.org/MPL/2.0/.
//

#import <Foundation/Foundation.h> 
#import <CoreLocation/CoreLocation.h>

@interface SMLocationManager : NSObject<CLLocationManagerDelegate>

@property (nonatomic, readonly) BOOL hasValidLocation;
@property (nonatomic, readonly) CLLocation *lastValidLocation;
@property (nonatomic, readonly) BOOL locationServicesEnabled;

+ (SMLocationManager *)instance;
- (void)start;
- (void)idle;
- (void)stop;

@end