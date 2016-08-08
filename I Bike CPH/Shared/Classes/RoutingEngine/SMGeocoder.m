//
//  SMGeocoder.m
//  I Bike CPH
//
//  Created by Ivan Pavlovic on 07/02/2013.
//  Copyright (C) 2013 City of Copenhagen.  All rights reserved.
//
//  This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0.
//  If a copy of the MPL was not distributed with this file, You can obtain one at
//  http://mozilla.org/MPL/2.0/.
//

#import "NSString+URLEncode.h"
#import "SMAddressParser.h"
#import "SMGeocoder.h"
#import "SMLocationManager.h"
#import <AddressBook/AddressBook.h>
#import <AddressBookUI/AddressBookUI.h>
#import <CoreLocation/CoreLocation.h>
#import <MapKit/MapKit.h>

@implementation SMGeocoder

+ (void)reverseGeocode:(CLLocationCoordinate2D)coord
           synchronous:(BOOL)synchronous
     completionHandler:(void (^)(KortforItem *kortforItem, NSError *error))handler
{
    [SMGeocoder kortReverseGeocode:coord synchronous:synchronous completionHandler:handler];
}

+ (void)kortReverseGeocode:(CLLocationCoordinate2D)coord
               synchronous:(BOOL)synchronous
         completionHandler:(void (^)(KortforItem *kortforItem, NSError *error))handler
{
    NSString *URLString =
        [[NSString stringWithFormat:@"https://kortforsyningen.kms.dk/"
                                    @"?servicename=%@&hits=10&method=nadresse&geop=%lf,%lf&georef=EPSG:4326&georad=%d&outgeoref=EPSG:4326&login=%@&"
                                    @"password=%@&geometry=false",
                                    KORT_SERVICE, coord.longitude, coord.latitude, KORT_SEARCH_RADIUS, [SMRouteSettings sharedInstance].kort_username,
                                    [SMRouteSettings sharedInstance].kort_password] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    debugLog(@"Kort: %@", URLString);
    NSURLRequest *req = [NSURLRequest requestWithURL:[NSURL URLWithString:URLString]];

    void (^completion)(NSURLResponse *, NSData *, NSError *) = ^(NSURLResponse *response, NSData *data, NSError *error) {
      if (error) {
          handler(nil, error);
          return;
      }
      if (!data) {
          handler(nil, [NSError errorWithDomain:NSOSStatusErrorDomain
                                           code:1
                                       userInfo:@{
                                           NSLocalizedDescriptionKey : @"Wrong data returned from the OIOREST"
                                       }]);
      }

      NSString *s = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
      id res = [NSJSONSerialization JSONObjectWithData:data
                                               options:NSJSONReadingAllowFragments
                                                 error:nil];
      if (res == nil || [res isKindOfClass:[NSDictionary class]] == NO) {
          handler(nil, [NSError errorWithDomain:NSOSStatusErrorDomain
                                           code:1
                                       userInfo:@{
                                           NSLocalizedDescriptionKey : [NSString stringWithFormat:@"Wrong data returned from the KORT: %@", s]
                                       }]);
          return;
      }
      NSDictionary *json = (NSDictionary *)res;

      NSMutableCharacterSet *set = [NSMutableCharacterSet whitespaceAndNewlineCharacterSet];
      [set addCharactersInString:@","];

      // Kortfor
      NSMutableArray *kortforItems = [NSMutableArray new];
      for (NSDictionary *feature in json[@"features"]) {
          KortforItem *item = [[KortforItem alloc] initWithJsonDictionary:feature];

          // TODO: Move address formatting to modelclasses
          NSString *formattedAddress =
              [[NSString stringWithFormat:@"%@ %@, %@ %@", item.street, item.number, item.zip, item.city] stringByTrimmingCharactersInSet:set];
          item.name = formattedAddress;
          item.address = formattedAddress;
          [kortforItems addObject:item];
      }
      // Sort
      NSArray *sortedKortforItems = [kortforItems sortedArrayUsingComparator:^NSComparisonResult(KortforItem *obj1, KortforItem *obj2) {
        long first = obj1.distance;
        long second = obj2.distance;

        if (first < second)
            return NSOrderedAscending;
        else if (first > second)
            return NSOrderedDescending;
        else
            return NSOrderedSame;
      }];

      KortforItem *item = sortedKortforItems.firstObject;
      if (!item) {
          NSError *error = [NSError errorWithDomain:NSOSStatusErrorDomain
                                               code:1
                                           userInfo:@{
                                               NSLocalizedDescriptionKey : [NSString stringWithFormat:@"No items returned from the KORT: %@", s]
                                           }];
          handler(nil, error);
          return;
      }
      handler(item, nil);
    };

    if (synchronous) {
        NSURLResponse *response;
        NSError *error;
        NSData *data = [NSURLConnection sendSynchronousRequest:req returningResponse:&response error:&error];
        completion(response, data, error);
    }
    else {
        [NSURLConnection sendAsynchronousRequest:req queue:[NSOperationQueue mainQueue] completionHandler:completion];
    }
}

@end