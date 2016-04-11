//
//  SMLocationManager.m
//  TestMap
//
//  Created by Ivan Pavlovic on 11/1/12.
//  Copyright (C) 2013 City of Copenhagen.  All rights reserved.
//
//  This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0.
//  If a copy of the MPL was not distributed with this file, You can obtain one at 
//  http://mozilla.org/MPL/2.0/.
//

#import "SMLocationManager.h"
#import <CoreLocation/CoreLocation.h>

@interface SMLocationManager ()
@property (nonatomic) CLLocationManager *locationManager;
@property (nonatomic) CLLocation *lastValidLocation;
@property (nonatomic) BOOL hasValidLocation;
@property (nonatomic) BOOL locationServicesEnabled;
@end

@implementation SMLocationManager

+ (SMLocationManager *)instance {
	static SMLocationManager *instance;
	
	if (instance == nil) {
		instance = [SMLocationManager new];
	}
	
	return instance;
}

- (id)init {
	self = [super init];
	
	if (self != nil)
	{
		self.hasValidLocation = NO;
		self.locationManager = [CLLocationManager new];
        self.locationManager.delegate = self;
        self.locationManager.desiredAccuracy = kCLLocationAccuracyBest;
        self.locationManager.distanceFilter = kCLDistanceFilterNone;
		
        self.locationServicesEnabled = NO;
        [self.locationManager requestAlwaysAuthorization];
	}
	return self;
}

- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status {
    if (status == kCLAuthorizationStatusAuthorizedAlways) {
        
        [self.locationManager startUpdatingLocation];
        [self.locationManager startMonitoringSignificantLocationChanges];
        
        self.locationServicesEnabled = YES;
    }
}

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations {
   
    CLLocation *lastLocation = locations.lastObject;
    
	self.hasValidLocation = NO;
	
	if (!signbit(lastLocation.horizontalAccuracy)) {
		self.hasValidLocation = YES;
		self.lastValidLocation = lastLocation;
	}
    [[NSNotificationCenter defaultCenter] postNotificationName:@"refreshPosition" object:self userInfo:@{@"locations" : locations}];
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error
{
	NSLog(@"didFailWithError");
	if ([error domain] == kCLErrorDomain)
	{
		switch ([error code])
		{
			case kCLErrorDenied:
				[self.locationManager stopUpdatingLocation];
                self.locationServicesEnabled = NO;
                NSLog(@"Location services denied!");
				break;
			case kCLErrorLocationUnknown:
                NSLog(@"Location unknown!");
				break;
            default:
                NSLog(@"Location error: %@", error.localizedDescription);
		}
	}
}

#pragma mark - Location services

- (void)start {
    if (self.locationManager != nil) {
        [self.locationManager startUpdatingLocation];
        [self.locationManager startMonitoringSignificantLocationChanges];
        self.locationManager.desiredAccuracy = kCLLocationAccuracyBest;
    }
}

- (void)idle {
    if (self.locationManager != nil) {
        [self.locationManager startUpdatingLocation];
        [self.locationManager startMonitoringSignificantLocationChanges];
        self.locationManager.desiredAccuracy = kCLLocationAccuracyThreeKilometers;
    }
}

- (void)stop {
    if (self.locationManager != nil) {
        [self.locationManager stopUpdatingLocation];
        [self.locationManager stopMonitoringSignificantLocationChanges];
    }
}

@end