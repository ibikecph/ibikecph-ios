//
//  SMRequestOSRM.m
//  I Bike CPH
//
//  Created by Ivan Pavlovic on 06/02/2013.
//  Copyright (C) 2013 City of Copenhagen.  All rights reserved.
//
//  This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0.
//  If a copy of the MPL was not distributed with this file, You can obtain one at
//  http://mozilla.org/MPL/2.0/.
//

#import "NSString+URLEncode.h"
#import "Reachability.h"
#import "SMGPSUtil.h"
#import "SMRequestOSRM.h"
#import "SMRouteConsts.h"
#import "SMGPSUtil.h"

@interface SMRequestOSRM ()
@property(nonatomic, strong) NSURLConnection *conn;
@property(nonatomic, strong) NSString *currentRequest;

@property(nonatomic, strong) CLLocation *startLoc;
@property(nonatomic, strong) CLLocation *endLoc;
@property NSInteger locStep;

@property NSInteger currentZ;
@property(nonatomic, strong) NSDictionary *originalJSON;
@property(nonatomic, strong) NSString *originalStartHint;
@property(nonatomic, strong) NSString *originalDestinationHint;

@property(nonatomic, strong) NSArray *originalViaPoints;
@property CLLocationCoordinate2D originalStart;
@property CLLocationCoordinate2D originalEnd;

@property (nonatomic, assign) NSUInteger latestHTTPStatusCode;
@property (nonatomic, copy) NSString *brokenJourneyToken;
@property (nonatomic) NSDate *brokenJourneyTimeoutDate;

@end

static dispatch_queue_t reachabilityQueue;

@implementation SMRequestOSRM

#define DEFAULT_Z 18
#define MINIMUM_Z 10

- (id)initWithDelegate:(id<SMRequestOSRMDelegate>)dlg
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
      reachabilityQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0L);
    });

    self = [super init];
    if (self) {
        [self setDelegate:dlg];
        self.locStep = 0;
        self.osrmServer = OSRM_SERVER;
    }
    return self;
}

- (BOOL)serverReachable
{
    Reachability *r = [Reachability reachabilityWithHostName:OSRM_HOSTNAME];
    NetworkStatus s = [r currentReachabilityStatus];
    if (s == NotReachable) {
        if (self.delegate && [self.delegate respondsToSelector:@selector(serverNotReachable)]) {
            [self.delegate serverNotReachable];
        }
        NSMutableDictionary *details = [NSMutableDictionary dictionary];
        [details setValue:@"Network error!" forKey:NSLocalizedDescriptionKey];
        NSError *error = [NSError errorWithDomain:@"" code:0 userInfo:details];
        if (self.delegate && [self.delegate respondsToSelector:@selector(request:failedWithError:)]) {
            [self.delegate request:self failedWithError:error];
        }
        return NO;
    }
    return YES;
}

- (void)findNearestPointForLocation:(CLLocation *)loc
{
    [self runBlockIfServerReachable:^{
      self.currentRequest = @"findNearestPointForLocation:";
      self.coord = loc;
        NSMutableString *requestString = [self.osrmServer stringByReplacingOccurrencesOfString:@"route" withString:@"nearest"].mutableCopy;
        [requestString appendFormat:@"%.6f,%.6f", loc.coordinate.longitude, loc.coordinate.latitude];
      NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:requestString]];
      [request setValue:USER_AGENT forHTTPHeaderField:@"User-Agent"];
      if (self.conn) {
          [self.conn cancel];
          self.conn = nil;
      }
      self.responseData = [NSMutableData data];
      NSURLConnection *c = [[NSURLConnection alloc] initWithRequest:request delegate:self startImmediately:NO];
      self.conn = c;
      [self.conn start];
    }];
}

// via may be null
- (void)getRouteFrom:(CLLocationCoordinate2D)start to:(CLLocationCoordinate2D)end via:(NSArray *)viaPoints
{
    [self getRouteFrom:start to:end via:viaPoints destinationHint:nil];
}

- (void)getRouteFrom:(CLLocationCoordinate2D)start
                  to:(CLLocationCoordinate2D)end
                 via:(NSArray *)viaPoints
     destinationHint:(NSString *)destinationHint
{
    self.originalJSON = nil;
    self.originalStart = start;
    self.originalEnd = end;
    self.originalViaPoints = viaPoints;
    self.originalDestinationHint = destinationHint;
    self.originalStartHint = nil;
    [self getRouteFrom:start to:end via:viaPoints startHint:nil destinationHint:destinationHint andZ:DEFAULT_Z];
}

- (void)getRouteFrom:(CLLocationCoordinate2D)start
                  to:(CLLocationCoordinate2D)end
                 via:(NSArray *)viaPoints
           startHint:(NSString *)startHint
     destinationHint:(NSString *)destinationHint
                andZ:(NSInteger)z
{
    [self runBlockIfServerReachable:^{

      self.currentZ = z;
      self.currentRequest = @"getRouteFrom:to:via:";

      BOOL isBrokenRoute = [self isBrokenJourneyURLInString:self.osrmServer];

      NSMutableString *requestString = self.osrmServer.mutableCopy;

      if (!isBrokenRoute) {
          // Start coordinates
          [requestString appendFormat:@"%.6f,%.6f", start.longitude, start.latitude];
          
          if (viaPoints.count > 0) {
              for (CLLocation *point in viaPoints) {
                  [requestString appendFormat:@";%.6f,%.6f", point.coordinate.longitude, point.coordinate.latitude];
              }
          }
          
          // End coordinates
          [requestString appendFormat:@";%.6f,%.6f", end.longitude, end.latitude];
          
          // Constant options
          [requestString appendFormat:@"?overview=full&geometries=polyline&steps=true&alternatives=false"];
          
          // Hints
          NSString *sh = (startHint.length > 0) ? startHint : @"";
          NSString *dh = (destinationHint.length > 0) ? destinationHint : @"";
          if (sh.length > 0 || dh.length > 0) {
              [requestString appendFormat:@"&hints=%@;%@", sh, dh];
          }
          // Set bearing
          CLHeading *heading = SMLocationManager.sharedInstance.lastHeading;
          if (heading) {
              NSUInteger destinationHeading = (NSUInteger)[SMGPSUtil bearingBetweenStartCoordinate:start endCoordinate:end];
              NSUInteger trueHeading = (NSUInteger)heading.trueHeading;
              NSUInteger headingRange = 90;
              [requestString appendFormat:@"&bearings=%lu,%lu;%lu,%lu", (unsigned long)trueHeading, (unsigned long)headingRange, (unsigned long)destinationHeading, (unsigned long)headingRange];
          }
      }

      debugLog(@"%@", requestString);

      NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:requestString]];
      [req setValue:USER_AGENT forHTTPHeaderField:@"User-Agent"];
      if (isBrokenRoute) {
          [req setValue:@"application/vnd.ibikecph.v1" forHTTPHeaderField:@"Accept"];
          [req setHTTPMethod:@"POST"];
          NSString *postString = [NSString stringWithFormat:@"loc[]=%.6f,%.6f&loc[]=%.6f,%.6f", start.latitude, start.longitude, end.latitude, end.longitude];
          [req setHTTPBody:[postString dataUsingEncoding:NSUTF8StringEncoding]];
      }
      if (self.conn) {
          [self.conn cancel];
          self.conn = nil;
      }
      self.responseData = [NSMutableData data];
      NSURLConnection *c = [[NSURLConnection alloc] initWithRequest:req delegate:self startImmediately:NO];
      self.conn = c;
      [self.conn start];
    }];
}

- (void)findNearestPointForStart:(CLLocation *)start andEnd:(CLLocation *)end
{
    [self runBlockIfServerReachable:^{
      self.currentRequest = @"findNearestPointForStart:andEnd:";
      NSMutableString *requestString = [self.osrmServer stringByReplacingOccurrencesOfString:@"route" withString:@"nearest"].mutableCopy;
      if (self.locStep == 0) {
          self.startLoc = start;
          self.endLoc = end;
          [requestString appendFormat:@"%.6f,%.6f", start.coordinate.longitude, start.coordinate.latitude];
      }
      else {
          [requestString appendFormat:@"%.6f,%.6f", end.coordinate.longitude, end.coordinate.latitude];
      }
      self.locStep += 1;
      NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:requestString]];
      [request setValue:USER_AGENT forHTTPHeaderField:@"User-Agent"];
      if (self.conn) {
          [self.conn cancel];
          self.conn = nil;
      }
      self.responseData = [NSMutableData data];
      NSURLConnection *c = [[NSURLConnection alloc] initWithRequest:request delegate:self startImmediately:NO];
      self.conn = c;
      [self.conn start];

    }];
    //    if ([self serverReachable] == NO) {
    //        return;
    //    }
}

- (BOOL)isBrokenJourneyURLInString:(NSString *)string
{
    return [string rangeOfString:SMRouteSettings.sharedInstance.broken_journey_server].location != NSNotFound;
}

- (void)scheduleBrokenJourneyPoll
{
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
      NSString *requestString = [NSMutableString stringWithFormat:@"%@/%@", self.osrmServer, self.brokenJourneyToken];
      NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:requestString]];
      [request setValue:USER_AGENT forHTTPHeaderField:@"User-Agent"];
      [request setValue:@"application/vnd.ibikecph.v1" forHTTPHeaderField:@"Accept"];
        
      if (self.conn) {
          [self.conn cancel];
          self.conn = nil;
      }
      self.responseData = [NSMutableData data];
      NSURLConnection *c = [[NSURLConnection alloc] initWithRequest:request delegate:self startImmediately:NO];
      self.conn = c;
      [self.conn start];
    });
}

- (void)setBrokenJourneyToken:(NSString *)brokenJourneyToken
{
    _brokenJourneyToken = [brokenJourneyToken stringByAddingPercentEncodingWithAllowedCharacters:NSCharacterSet.alphanumericCharacterSet];
}

#pragma mark - Block methods

- (void)runBlockIfServerReachable:(void (^)(void))block
{
    __weak SMRequestOSRM *selfRef = self;
    __weak NSThread *threadRef = [NSThread currentThread];
    dispatch_async(reachabilityQueue, ^{
      if ([selfRef serverReachable]) {
          [selfRef performSelector:@selector(runBlock:) onThread:threadRef withObject:block waitUntilDone:NO];
      }
    });
}

- (void)runBlock:(void (^)(void))block
{
    block();
}

#pragma mark - NSURLConnectionDataDelegate

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    [self.responseData appendData:data];
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    self.latestHTTPStatusCode = [(NSHTTPURLResponse *)response statusCode];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    if ([self.responseData length] > 0) {
        NSString *str = [[NSString alloc] initWithData:self.responseData encoding:NSUTF8StringEncoding];
        debugLog(@"%@", str);
        id r = [NSJSONSerialization JSONObjectWithData:self.responseData options:NSJSONReadingAllowFragments error:nil];
        if ([self.currentRequest isEqualToString:@"findNearestPointForStart:andEnd:"]) {
            if (self.locStep > 1) {
                if ([r[@"waypoints"] isKindOfClass:[NSArray class]] && ([r[@"waypoints"] count] > 0)) {
                    NSDictionary *waypoint = [(NSArray *)r[@"waypoints"] firstObject];
                    if ([waypoint[@"location"] isKindOfClass:[NSArray class]] && ([waypoint[@"location"] count] > 1)) {
                        self.endLoc = [[CLLocation alloc] initWithLatitude:[waypoint[@"location"][0] doubleValue]
                                                                 longitude:[waypoint[@"location"][1] doubleValue]];
                    }
                }
                if ([self.delegate conformsToProtocol:@protocol(SMRequestOSRMDelegate)]) {
                    [self.delegate request:self finishedWithResult:@{ @"start" : self.startLoc, @"end" : self.endLoc }];
                }
                self.locStep = 0;
            }
            else {
                if ([r[@"waypoints"] isKindOfClass:[NSArray class]] && ([r[@"waypoints"] count] > 0)) {
                    NSDictionary *waypoint = [(NSArray *)r[@"waypoints"] firstObject];
                    if ([waypoint[@"location"] isKindOfClass:[NSArray class]] && ([waypoint[@"location"] count] > 1)) {
                        self.startLoc = [[CLLocation alloc] initWithLatitude:[waypoint[@"location"][0] doubleValue]
                                                                   longitude:[waypoint[@"location"][1] doubleValue]];
                    }
                }
                [self findNearestPointForStart:self.startLoc andEnd:self.endLoc];
            }
        }
        else if ([self.currentRequest isEqualToString:@"findNearestPointForLocation:"]) {
            if ([self.delegate conformsToProtocol:@protocol(SMRequestOSRMDelegate)]) {
                [self.delegate request:self finishedWithResult:r];
            }
        }
        else {
            if ([self isBrokenJourneyURLInString:connection.originalRequest.URL.absoluteString]) {
                // Yes, this whole bit is hackish
                if (self.latestHTTPStatusCode == 200) {
                    if ([r isKindOfClass:NSDictionary.class] && r[@"token"]) {
                        // Start polling for broken journey
                        self.brokenJourneyToken = r[@"token"];
                        self.brokenJourneyTimeoutDate = [NSDate dateWithTimeIntervalSinceNow:20];
                        [self scheduleBrokenJourneyPoll];
                        return;
                    } else {
                        // Broken journey is presumably ready
                        if ([self.delegate conformsToProtocol:@protocol(SMRequestOSRMDelegate)]) {
                            [self.delegate request:self finishedWithResult:r];
                        }
                        return;
                    }
                } else if (self.latestHTTPStatusCode == 422) {
                    if ([self.brokenJourneyTimeoutDate compare:[NSDate date]] != NSOrderedAscending) {
                        // Broken journey still not ready; continue polling
                        [self scheduleBrokenJourneyPoll];
                        return;
                    }
                }
                
                // Something's wrong...
                NSError *error = [NSError errorWithDomain:@"" code:0 userInfo:@{NSLocalizedDescriptionKey:@"Unable to get broken journey!"}];
                if ([self.delegate conformsToProtocol:@protocol(SMRequestOSRMDelegate)]) {
                    [self.delegate request:self failedWithError:error];
                }
                return;
            }

            if (!r || ([r isKindOfClass:[NSDictionary class]] == NO) || ![r[@"code"] isEqualToString:@"Ok"]) {
                if (self.currentZ == DEFAULT_Z) {
                    if (self.originalJSON) {
                        if ([self.delegate conformsToProtocol:@protocol(SMRequestOSRMDelegate)]) {
                            [self.delegate request:self finishedWithResult:self.originalJSON];
                        }
                    }
                    else {
                        [self getRouteFrom:self.originalStart
                                        to:self.originalEnd
                                       via:self.originalViaPoints
                                 startHint:self.originalStartHint
                           destinationHint:self.originalDestinationHint
                                      andZ:MINIMUM_Z];
                    }
                }
                else {
                    if ([self.delegate conformsToProtocol:@protocol(SMRequestOSRMDelegate)]) {
                        [self.delegate request:self finishedWithResult:r];
                    }
                }
            }
            else {
                if (self.currentZ == DEFAULT_Z) {
                    if ([self.delegate conformsToProtocol:@protocol(SMRequestOSRMDelegate)]) {
                        [self.delegate request:self finishedWithResult:r];
                    }
                }
                else {
                    self.originalJSON = r;
                    if ([r[@"waypoints"] isKindOfClass:[NSArray class]] && ([r[@"waypoints"] count] > 1)) {
                        NSDictionary *startWaypoint = [(NSArray *)r[@"waypoints"] objectAtIndex:0];
                        if ([startWaypoint[@"hint"] isKindOfClass:[NSString class]]) {
                            self.originalStartHint = startWaypoint[@"hint"];
                        }
                        NSDictionary *destinationWaypoint = [(NSArray *)r[@"waypoints"] objectAtIndex:1];
                        if ([destinationWaypoint[@"hint"] isKindOfClass:[NSString class]]) {
                            self.originalDestinationHint = destinationWaypoint[@"hint"];
                        }
                    }
                    if ([r[@"routes"] isKindOfClass:[NSArray class]]) {
                        NSDictionary *firstRoute = [(NSArray *)r[@"routes"] firstObject];
                        NSArray *points =
                            [SMGPSUtil decodePolyline:firstRoute[@"geometry"] precision:[SMRouteSettings sharedInstance].route_polyline_precision];
                        CLLocationCoordinate2D start = ((CLLocation *)[points objectAtIndex:0]).coordinate;
                        CLLocationCoordinate2D end = ((CLLocation *)[points lastObject]).coordinate;
                        [self getRouteFrom:start
                                        to:end
                                       via:self.originalViaPoints
                                 startHint:self.originalStartHint
                           destinationHint:self.originalDestinationHint
                                      andZ:DEFAULT_Z];
                    }
                    else {
                        [self getRouteFrom:self.originalStart
                                        to:self.originalEnd
                                       via:self.originalViaPoints
                                 startHint:self.originalStartHint
                           destinationHint:self.originalDestinationHint
                                      andZ:DEFAULT_Z];
                    }
                }
            }
        }
    }
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    NSLog(@"Connection didFailWithError %@", error.localizedDescription);
    if ([self.delegate conformsToProtocol:@protocol(SMRequestOSRMDelegate)]) {
        [self.delegate request:self failedWithError:error];
    }
}

@end