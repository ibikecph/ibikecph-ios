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

@interface SMMapOverlays ()
@property(nonatomic, weak) MapView *mapView;
@property(nonatomic, readonly) NSArray *cycleServiceStationLocations;
@property(nonatomic, readonly) NSArray *cycleSuperHighwayLocations;
@property(nonatomic) NSArray *cycleServiceStationAnnotations;
@property(nonatomic) NSArray *cycleSuperHighwayAnnotations;
@end

@implementation SMMapOverlays

@synthesize cycleServiceStationLocations = _cycleServiceStationLocations;
@synthesize cycleSuperHighwayLocations = _cycleSuperHighwayLocations;
@synthesize cycleServiceStationAnnotations = _cycleServiceStationAnnotations;
@synthesize cycleSuperHighwayAnnotations = _cycleSuperHighwayAnnotations;

- (SMMapOverlays *)initWithMapView:(MapView *)mapView
{
    self = [super init];
    if (self) {
        self.mapView = mapView;
    }
    return self;
}

- (void)useMapView:(MapView *)mapView
{
    self.mapView = mapView;
}

- (void)updateOverlays
{
    if (!self.mapView) {
        return;
    }

    Settings *settings = [Settings sharedInstance];

    // Show/hide Cycle Super Highways
    [self.mapView removeAnnotations:self.cycleSuperHighwayAnnotations];
    if (settings.overlays.cycleSuperHighways) {
        [self.mapView addAnnotations:self.cycleSuperHighwayAnnotations];
    }

    // Show/hide Cycle Service Stations
    [self.mapView removeAnnotations:self.cycleServiceStationAnnotations];
    if (settings.overlays.bikeServiceStations) {
        [self.mapView addAnnotations:self.cycleServiceStationAnnotations];
    }

    [self.mapView.mapView setZoom:self.mapView.mapView.zoom + 0.0001];
}
- (void)updateCycleSuperHighwayAnnotations
{
    self.cycleSuperHighwayAnnotations = @[];
    if (!self.mapView) {
        return;
    }
    NSMutableArray *ma = [NSMutableArray new];
    for (NSArray *locations in self.cycleSuperHighwayLocations) {
        UIColor *color = [[Styler tintColor] colorWithAlphaComponent:0.5];
        Annotation *annotation = [self.mapView addPathWithLocations:locations lineColor:color lineWidth:4.0];
        [ma addObject:annotation];
    }
    self.cycleSuperHighwayAnnotations = ma.copy;
}

- (void)updateCycleServiceStationAnnotations
{
    self.cycleServiceStationAnnotations = @[];
    if (!self.mapView) {
        return;
    }
    NSMutableArray *ma = [NSMutableArray new];
    for (NSString *coordinates in self.cycleServiceStationLocations) {
        NSRange range = [coordinates rangeOfString:@" "];
        NSString *latitude = [coordinates substringToIndex:range.location];
        range.length = [coordinates length] - range.location;
        NSString *longitude = [coordinates substringWithRange:range];
        CLLocationCoordinate2D coord = CLLocationCoordinate2DMake([longitude floatValue], [latitude floatValue]);
        ServiceStationsAnnotation *annotation = [[ServiceStationsAnnotation alloc] initWithMapView:self.mapView coordinate:coord];
        [ma addObject:annotation];
    }
    self.cycleServiceStationAnnotations = ma.copy;
}

#pragma mark - Getters

- (NSArray *)cycleServiceStationLocations
{
    if (!_cycleServiceStationLocations) {
        NSString *filePath = [[NSBundle mainBundle] pathForResource:@"stations" ofType:@"json"];
        NSError *err;
        NSData *data = [NSData dataWithContentsOfFile:filePath];
        NSDictionary *dict = nil;
        if (data) {
            dict = [NSJSONSerialization JSONObjectWithData:data options:0 error:&err];
            NSLog(@"Error %@", err);
        }
        NSArray *stations = dict[@"stations"];
        NSMutableArray *ma = [NSMutableArray new];
        for (NSDictionary *station in stations) {
            // Only import service stations
            if (![station[@"type"] isEqualToString:@"service"]) {
                continue;
            }
            NSString *coordinates = station[@"coords"];
            [ma addObject:coordinates];
        }
        _cycleServiceStationLocations = ma.copy;
    }
    return _cycleServiceStationLocations;
}

- (NSArray *)cycleSuperHighwayLocations
{
    if (!_cycleSuperHighwayLocations) {
        NSMutableArray *ma = [NSMutableArray new];
        NSString *filePath = [[NSBundle mainBundle] pathForResource:@"cycle_super_highways" ofType:@"json"];
        NSError *error;
        NSData *data = [NSData dataWithContentsOfFile:filePath];
        NSDictionary *dict;
        if (data) {
            dict = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
            if (error) {
                NSLog(@"ERROR parsing %@: %@", filePath, error);
            }
        }
        NSArray *lines = dict[@"coordinates"];
        for (NSArray *line in lines) {
            NSMutableArray *locations = [NSMutableArray new];
            for (NSArray *coords in line) {
                float lat = [coords[0] floatValue];
                float lon = [coords[1] floatValue];
                CLLocation *location = [[CLLocation alloc] initWithLatitude:lon longitude:lat];
                [locations addObject:location];
            }
            [ma addObject:locations];
        }
        _cycleSuperHighwayLocations = ma.copy;
    }
    return _cycleSuperHighwayLocations;
}

#pragma mark - Setters

- (void)setMapView:(MapView *)mapView
{
    _mapView = mapView;
    [self updateCycleSuperHighwayAnnotations];
    [self updateCycleServiceStationAnnotations];
}

@end