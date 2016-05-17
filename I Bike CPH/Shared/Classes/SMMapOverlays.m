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
#import "UIColor+Hex.h"

@interface SMMapOverlays ()
@property(nonatomic, weak) MapView *mapView;
@property(nonatomic, readonly) NSArray *cycleSuperHighwayLocations;
@property(nonatomic, readonly) NSArray *bikeServiceStationLocations;
@property(nonatomic, readonly) NSArray *harborRingLocations;
@property(nonatomic, readonly) NSArray *greenPathsLocations;
@property(nonatomic) NSArray *cycleSuperHighwayAnnotations;
@property(nonatomic) NSArray *bikeServiceStationAnnotations;
@property(nonatomic) NSArray *harborRingAnnotations;
@property(nonatomic) NSArray *greenPathsAnnotations;
@property(nonatomic, readonly) UIColor *cycleSuperHighwayAnnotationColor;
@property(nonatomic, readonly) UIColor *harborRingAnnotationColor;
@property(nonatomic, readonly) UIColor *greenPathsAnnotationColor;
@end

@implementation SMMapOverlays

@synthesize cycleSuperHighwayLocations = _cycleSuperHighwayLocations;
@synthesize bikeServiceStationLocations = _bikeServiceStationLocations;
@synthesize harborRingLocations = _harborRingLocations;
@synthesize greenPathsLocations = _greenPathsLocations;
@synthesize cycleSuperHighwayAnnotationColor = _cycleSuperHighwayAnnotationColor;
@synthesize harborRingAnnotationColor = _harborRingAnnotationColor;
@synthesize greenPathsAnnotationColor = _greenPathsAnnotationColor;

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
    if (settings.overlays.showCycleSuperHighways) {
        [self.mapView addAnnotations:self.cycleSuperHighwayAnnotations];
    }

    // Show/hide Cycle Service Stations
    [self.mapView removeAnnotations:self.bikeServiceStationAnnotations];
    if (settings.overlays.showBikeServiceStations) {
        [self.mapView addAnnotations:self.bikeServiceStationAnnotations];
    }
    
    // Show/hide Harbor Ring
    [self.mapView removeAnnotations:self.harborRingAnnotations];
    if (settings.overlays.showHarborRing) {
        [self.mapView addAnnotations:self.harborRingAnnotations];
    }
    
    // Show/hide Green Paths
    [self.mapView removeAnnotations:self.greenPathsAnnotations];
    if (settings.overlays.showGreenPaths) {
        [self.mapView addAnnotations:self.greenPathsAnnotations];
    }

    [self.mapView.mapView setZoom:self.mapView.mapView.zoom + 0.0001];
}

- (void)updateCycleSuperHighwayAnnotations
{
    self.cycleSuperHighwayAnnotations = [self annotationsFromLocations:self.cycleSuperHighwayLocations color:self.cycleSuperHighwayAnnotationColor];
}

- (void)updateBikeServiceStationAnnotations
{
    self.bikeServiceStationAnnotations = @[];
    if (!self.mapView) {
        return;
    }
    NSMutableArray *ma = [NSMutableArray new];
    for (NSString *coordinates in self.bikeServiceStationLocations) {
        NSRange range = [coordinates rangeOfString:@" "];
        NSString *latitude = [coordinates substringToIndex:range.location];
        range.length = [coordinates length] - range.location;
        NSString *longitude = [coordinates substringWithRange:range];
        CLLocationCoordinate2D coord = CLLocationCoordinate2DMake([longitude floatValue], [latitude floatValue]);
        ServiceStationsAnnotation *annotation = [[ServiceStationsAnnotation alloc] initWithMapView:self.mapView coordinate:coord];
        [ma addObject:annotation];
    }
    self.bikeServiceStationAnnotations = ma.copy;
}

- (void)updateHarborRingAnnotations
{
    self.harborRingAnnotations = [self annotationsFromLocations:self.harborRingLocations color:self.harborRingAnnotationColor];
}

- (void)updateGreenPathsAnnotations
{
    self.greenPathsAnnotations = [self annotationsFromLocations:self.greenPathsLocations color:self.greenPathsAnnotationColor];
}

#pragma mark - Getters

- (NSArray *)cycleSuperHighwayLocations
{
    if (!_cycleSuperHighwayLocations) {
        _cycleSuperHighwayLocations = [self locationsFromGeoJSONFileWithName:@"cycle_super_highways" extension:@"geojson"];
    }
    return _cycleSuperHighwayLocations;
}

- (UIColor *)cycleSuperHighwayAnnotationColor
{
    if (!_cycleSuperHighwayAnnotationColor) {
        _cycleSuperHighwayAnnotationColor = [self annotationColorFromGeoJSONFileWithName:@"cycle_super_highways" extension:@"geojson"];
    }
    return _cycleSuperHighwayAnnotationColor;
}

- (NSArray *)bikeServiceStationLocations
{
    if (!_bikeServiceStationLocations) {
        NSDictionary *JSONDictionary = [self JSONDictionaryFromFileWithName:@"stations" extension:@"json"];
        NSArray *stations = JSONDictionary[@"stations"];
        NSMutableArray *ma = [NSMutableArray new];
        for (NSDictionary *station in stations) {
            // Only import service stations
            if (![station[@"type"] isEqualToString:@"service"]) {
                continue;
            }
            NSString *coordinates = station[@"coords"];
            [ma addObject:coordinates];
        }
        _bikeServiceStationLocations = ma.copy;
    }
    return _bikeServiceStationLocations;
}

- (NSArray *)harborRingLocations
{
    if (!_harborRingLocations) {
        _harborRingLocations = [self locationsFromGeoJSONFileWithName:@"havneringen" extension:@"geojson"];
    }
    return _harborRingLocations;
}

- (UIColor *)harborRingAnnotationColor
{
    if (!_harborRingAnnotationColor) {
        _harborRingAnnotationColor = [self annotationColorFromGeoJSONFileWithName:@"havneringen" extension:@"geojson"];
    }
    return _harborRingAnnotationColor;
}

- (NSArray *)greenPathsLocations
{
    if (!_greenPathsLocations) {
        _greenPathsLocations = [self locationsFromGeoJSONFileWithName:@"groenne_stier" extension:@"geojson"];
    }
    return _greenPathsLocations;
}

- (UIColor *)greenPathsAnnotationColor
{
    if (!_greenPathsAnnotationColor) {
        _greenPathsAnnotationColor = [self annotationColorFromGeoJSONFileWithName:@"groenne_stier" extension:@"geojson"];
    }
    return _greenPathsAnnotationColor;
}

#pragma mark - Setters

- (void)setMapView:(MapView *)mapView
{
    _mapView = mapView;
    [self updateCycleSuperHighwayAnnotations];
    [self updateBikeServiceStationAnnotations];
    [self updateHarborRingAnnotations];
    [self updateGreenPathsAnnotations];
}

#pragma mark - Helpers

- (NSDictionary *)JSONDictionaryFromFileWithName:(NSString *)name extension:(NSString *)extension
{
    NSString *filePath = [[NSBundle mainBundle] pathForResource:name ofType:extension];
    if (!filePath) {
        NSLog(@"Could not find file %@.%@",name, extension);
        return nil;
    }
    NSError *err;
    NSData *data = [NSData dataWithContentsOfFile:filePath options:0 error:&err];
    if (err) {
        NSLog(@"Could not create data object from file %@.%@: %@", name, extension, err);
        return nil;
    }
    NSDictionary *dictionary = [NSJSONSerialization JSONObjectWithData:data options:0 error:&err];
    if (err) {
        NSLog(@"Could not parse JSON from file %@.%@: %@", name, extension, err);
        return nil;
    }
    return dictionary;
}

- (NSArray *)annotationsFromLocations:(NSArray *)locations color:(UIColor *)color
{
    if (!self.mapView) {
        return @[];
    }
    NSMutableArray *ma = [NSMutableArray new];
    for (NSUInteger i = 0; i < locations.count; i++) {
        NSArray *locationsSubArray = locations[i];
        Annotation *annotation = [self.mapView addPathWithLocations:locationsSubArray lineColor:color lineWidth:4.0];
        [ma addObject:annotation];
    }
    return ma.copy;
}

- (NSArray *)locationsFromGeoJSONFileWithName:(NSString *)name extension:(NSString *)extension
{
    NSDictionary *JSONDictionary = [self JSONDictionaryFromFileWithName:name extension:extension];
    NSArray *features = JSONDictionary[@"features"];
    NSMutableArray *ma = [NSMutableArray new];
    for (NSDictionary *feature in features) {
        NSArray *coordinates = [[feature objectForKey:@"geometry"] objectForKey:@"coordinates"];
        NSMutableArray *locations = [NSMutableArray new];
        for (NSArray *coordinate in coordinates) {
            float longitude = [coordinate[0] floatValue];
            float latitude = [coordinate[1] floatValue];
            CLLocation *location = [[CLLocation alloc] initWithLatitude:latitude longitude:longitude];
            [locations addObject:location];
        }
        [ma addObject:locations];
    }
    return ma.copy;
}

- (UIColor *)annotationColorFromGeoJSONFileWithName:(NSString *)name extension:(NSString *)extension
{
    NSDictionary *JSONDictionary = [self JSONDictionaryFromFileWithName:name extension:extension];
    NSDictionary *properties = JSONDictionary[@"properties"];
    if (properties) {
        NSString *colorString = properties[@"color"];
        if (colorString) {
            return [UIColor hex_colorFromStringWithHexRGBValue:colorString alpha:0.5f];
        }
    }
    return [[Styler tintColor] colorWithAlphaComponent:0.5f];
}

@end