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
@property(nonatomic) CLLocationManager *locationManager;
@property(nonatomic) CLLocation *lastValidLocation;
@property(nonatomic) BOOL hasValidLocation;
@property(nonatomic) BOOL locationServicesEnabled;
@end

@implementation SMLocationManager

+ (SMLocationManager *)sharedInstance
{
    static SMLocationManager *sharedInstance;

    if (sharedInstance == nil) {
        sharedInstance = [SMLocationManager new];
    }

    return sharedInstance;
}

- (id)init
{
    self = [super init];

    if (self != nil) {
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

- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status
{
    if (status == kCLAuthorizationStatusAuthorizedAlways) {
        [self startUpdating];
        self.locationServicesEnabled = YES;
    }
    else if (status == kCLAuthorizationStatusAuthorizedWhenInUse) {
        //TODO navigation notifications will not work when app is in the background, maybe we should
        //somehow let the user know this, or at least gracefully handle the case and not try to push notifications
        [self startUpdating];
        self.locationServicesEnabled = YES;
    }
    else {
        [self stopUpdating];
        self.locationServicesEnabled = NO;
    }
}

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations
{
    CLLocation *lastLocation = locations.lastObject;

    self.hasValidLocation = NO;

    if (!signbit(lastLocation.horizontalAccuracy)) {
        self.hasValidLocation = YES;
        self.lastValidLocation = lastLocation;
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:@"refreshPosition" object:self userInfo:@{ @"locations" : locations }];
}

- (void)locationManager:(CLLocationManager *)manager didUpdateHeading:(CLHeading *)newHeading
{
    
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error
{
    NSLog(@"didFailWithError");
    if ([error domain] == kCLErrorDomain) {
        switch ([error code]) {
            case kCLErrorDenied:
                [self stopUpdating];
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

- (void)startUpdating
{
    if (self.locationManager != nil) {
        [self.locationManager startUpdatingLocation];
        [self.locationManager startUpdatingHeading];
        [self.locationManager startMonitoringSignificantLocationChanges];
        self.locationManager.desiredAccuracy = kCLLocationAccuracyBest;
    }
}

- (void)idleUpdating
{
    if (self.locationManager != nil) {
        [self.locationManager startUpdatingLocation];
        [self.locationManager startUpdatingHeading];
        [self.locationManager startMonitoringSignificantLocationChanges];
        self.locationManager.desiredAccuracy = kCLLocationAccuracyThreeKilometers;
    }
}

- (void)stopUpdating
{
    if (self.locationManager != nil) {
        [self.locationManager stopUpdatingLocation];
        [self.locationManager stopMonitoringSignificantLocationChanges];
        [self.locationManager stopUpdatingHeading];
    }
}

#pragma mark - Properties

- (BOOL)allowsBackgroundLocationUpdates
{
    return self.locationManager.allowsBackgroundLocationUpdates;
}

- (void)setAllowsBackgroundLocationUpdates:(BOOL)allowsBackgroundLocationUpdates
{
    self.locationManager.allowsBackgroundLocationUpdates = allowsBackgroundLocationUpdates;
}

- (CLHeading *)lastHeading
{
    return self.locationManager.heading;
}

@end
