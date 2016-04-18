//
//  SMMapOverlays.m
//  I Bike CPH
//
//  Created by Igor Jerković on 7/29/13.
//  Copyright (c) 2013 City of Copenhagen. All rights reserved.
//

#import "SMMapOverlays.h"

#import "SMStationInfo.h"
#import "SMTransportation.h"
#import "SMTransportationLine.h"

@interface SMMapOverlays()
@property (nonatomic, weak) MapView* mapView;
@property (nonatomic, strong) NSString* source;
@property (nonatomic, strong) NSMutableArray* serviceMarkers;
@property (nonatomic, strong) NSMutableArray* bikeRouteLocations;
@property (nonatomic, strong) NSMutableArray* bikeRouteAnnotations;
@end

@implementation SMMapOverlays

-(SMMapOverlays*)initWithMapView:(MapView*)mapView {
    self = [super init];
    if(self) {
        self.mapView = mapView;
        
        [self loadBikeRouteData];
        [self loadServiceMarkers];
    }
    return self;
}

- (void)useMapView:(MapView*)mapView {
    self.mapView = mapView;
}

- (void)loadBikeRouteData {
    self.bikeRouteLocations = [NSMutableArray new];
    self.bikeRouteAnnotations = [NSMutableArray new];
    
    NSString* filePath = [[NSBundle mainBundle] pathForResource:@"farum-route" ofType:@"json"];
    NSError* error;
    NSData* data = [NSData dataWithContentsOfFile:filePath];
    NSDictionary* dict = nil;
    if ( data ) {
        dict = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
        if ( error ) {
            NSLog(@"ERROR parsing %@: %@", filePath, error);
        }
    }
    NSArray* lines = dict[@"coordinates"];
    for (NSArray* line in lines) {
        NSMutableArray* locations = [NSMutableArray new];
        for (NSArray* coords in line) {
            float lat = [coords[0] floatValue];
            float lon = [coords[1] floatValue];
            CLLocation* location = [[CLLocation alloc] initWithLatitude:lon longitude:lat];
            [locations addObject:location];
        }
        [self.bikeRouteLocations addObject:locations];
    }
}

- (void)loadServiceMarkers {
    self.serviceMarkers = [NSMutableArray new];
    
    NSString* filePath = [[NSBundle mainBundle] pathForResource:@"stations" ofType:@"json"];
    NSError* err;
    NSData* data = [NSData dataWithContentsOfFile:filePath];
    NSDictionary* dict = nil;
    if ( data ) {
        dict = [NSJSONSerialization JSONObjectWithData:data options:0 error:&err];
        NSLog(@"Error %@", err);
    }
    NSArray* stations = dict[@"stations"];
    
    for (NSDictionary* station in stations) {
        // Only import service stations
        if (![station[@"type"] isEqualToString:@"service"]) {
            continue;
        }
        
        // Coordinate
        NSString* s = station[@"coords"];
        NSRange range = [s rangeOfString:@" "];
        NSString* sLatitude = [s substringToIndex:range.location];
        range.length = [s length] - range.location;
        NSString* sLongitude = [s substringWithRange:range];
        CLLocationCoordinate2D coord = CLLocationCoordinate2DMake([sLongitude floatValue], [sLatitude floatValue]);
        // Annotation
        ServiceStationsAnnotation *annotation = [[ServiceStationsAnnotation alloc] initWithMapView:self.mapView coordinate:coord];
        // Add annotation to array
        [self.serviceMarkers addObject:annotation];
    }
}

- (void)loadMarkers {
    // Load bike route data
    [self loadBikeRouteData];
    // Service markers
    [self loadServiceMarkers];
    
    [self updateOverlays];
}

- (void)updateOverlays {
    
    [self.mapView removeAnnotations:self.bikeRouteAnnotations];
    [self.bikeRouteAnnotations removeAllObjects];
    if ([Settings sharedInstance].overlays.cycleSuperHighways) {
        for (NSArray *locations in self.bikeRouteLocations) {
            UIColor *color = [[Styler tintColor] colorWithAlphaComponent:0.5];
            Annotation *pathAnnotation = [self.mapView addPathWithLocations:locations lineColor:color lineWidth:4.0];
            [self.bikeRouteAnnotations addObject:pathAnnotation];
        }
        [self.mapView addAnnotations:self.bikeRouteAnnotations];
    }
    [self.mapView removeAnnotations:self.serviceMarkers];
    if ([Settings sharedInstance].overlays.bikeServiceStations) {
        [self.mapView addAnnotations:self.serviceMarkers];
    }
    
    [self.mapView.mapView setZoom:self.mapView.mapView.zoom+0.0001];
}


@end
