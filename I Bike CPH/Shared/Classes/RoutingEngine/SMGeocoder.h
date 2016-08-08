//
//  SMGeocoder.h
//  I Bike CPH
//
//  Created by Ivan Pavlovic on 07/02/2013.
//  Copyright (C) 2013 City of Copenhagen.  All rights reserved.
//
//  This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0.
//  If a copy of the MPL was not distributed with this file, You can obtain one at
//  http://mozilla.org/MPL/2.0/.
//

#import <CoreLocation/CoreLocation.h>
#import <Foundation/Foundation.h>

@class KortforItem;

@interface SMGeocoder : NSObject

+ (void)reverseGeocode:(CLLocationCoordinate2D)coord
           synchronous:(BOOL)synchronous
     completionHandler:(void (^)(KortforItem *kortforItem, NSError *error))handler;

@end