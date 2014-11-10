//
//  SMMapOverlays.m
//  I Bike CPH
//
//  Created by Igor Jerković on 7/29/13.
//  Copyright (c) 2013 City of Copenhagen. All rights reserved.
//

#import "SMMapOverlays.h"
#import "SMStationInfo.h"
#import "SMAnnotation.h"
#import "RMAnnotation.h"
#import "SMTransportation.h"
#import "SMTransportationLine.h"
#import "RMMarker.h"

//#define GEN_STATION_INDICES

@interface SMMapOverlays()
@property (nonatomic, weak) RMMapView* mpView;
@property (nonatomic, strong) NSString* source;
@property (nonatomic, strong) NSMutableArray* metroMarkers;
@property (nonatomic, strong) NSMutableArray* serviceMarkers;
@property (nonatomic, strong) NSMutableArray* stationMarkers;
@property (nonatomic, strong) NSMutableArray* localTrainMarkers;
@property (nonatomic, strong) NSMutableArray* bikeRouteCoords;
@property (nonatomic, strong) NSMutableArray* bikeRouteAnnotations;
@end

@implementation SMMapOverlays
-(SMMapOverlays*)initWithMapView:(RMMapView*)mapView {
    self = [super init];
    if(self) {
        self.mpView = mapView;
        
        self.pathVisible = NO;
        self.serviceMarkersVisible = NO;
        self.stationMarkersVisible = NO;
        self.metroMarkersVisible = NO;
        self.localTrainMarkersVisible = NO;
        
        self.bikeRouteCoords = nil;
        self.bikeRouteAnnotations = [[NSMutableArray alloc] init];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(loadTransportationPaths)
                                                     name:NOTIFICATION_STATIONS_FETCHED
                                                   object:nil];
    }
    return self;
}

- (void)useMapView:(RMMapView*)mapView {
    self.mpView = mapView;

#ifdef GEN_STATION_INDICES
    NSArray* stations = [self parseStationData];
    NSArray* lines = [self parseLinesData];
    
    NSMutableDictionary* dict = [[NSMutableDictionary alloc] init];
    int index = 0;
    for (NSDictionary* station in stations) {
        NSString* name = [station objectForKey:@"name"];
        NSString* stationType = [station objectForKey:@"type"];
        [dict setObject:[NSNumber numberWithInt:index] forKey:[NSString stringWithFormat:@"%@ %@", name, stationType]];
        index++;
    }
    
    for (NSDictionary* line in lines) {
        
        NSMutableArray* indices = [[NSMutableArray alloc] init];
        NSMutableString* strIndices = [[NSMutableString alloc] init];
        NSArray* stations = [line objectForKey:@"stations"];
        
        for (NSString* statName in [line objectForKey:@"stations"]) {
            // Find index of stationName in stations array
            //NSInteger index = [[dict objectForKey:stationName] integerValue];
            NSString* stationName = [NSString stringWithFormat:@"%@ %@", statName, [line objectForKey:@"type"]];
            if ( [dict objectForKey:stationName] ) {
                [indices addObject:[dict objectForKey:stationName]];
                [strIndices appendFormat:@"%@%@", [dict objectForKey:stationName], [statName isEqual:stations.lastObject] ? @"" : @"," ];
                //NSLog(@"Index of station: %@", [dict objectForKey:stationName]);
            } else {
                //NSLog(@"No match for %@", stationName);
            }
        }
        
        NSLog(@"{ \"name\" : \"%@\", \"stations\" : [ %@ ] }%@", [line objectForKey:@"name"], strIndices, [line isEqual:lines.lastObject] ? @"" : @",");
    }
#endif
}

- (void)loadBikeRouteData {
    
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
    NSArray* lines = [dict valueForKey:@"coordinates"];
    for (NSArray* line in lines) {
        NSMutableArray* polyLine = [[NSMutableArray alloc] init];
        int index = 0;
        for (NSArray* coords in line) {
            float lat = [[coords objectAtIndex:0] floatValue];
            float lon = [[coords objectAtIndex:1] floatValue];
            
//            NSLog(@"%f, %f", lat, lon);
            //CLLocationCoordinate2D point = CLLocationCoordinate2DMake(lon, lat);
//            CLLocation* location = [CLLocation alloc]
            CLLocation* location = [[CLLocation alloc] initWithLatitude:lon longitude:lat];
            [polyLine addObject:location];
            
        }
        
        CLLocation* startLoc = [polyLine objectAtIndex:0];
        CLLocationCoordinate2D start = startLoc.coordinate;
        RMAnnotation *calculatedPathAnnotation = [RMAnnotation annotationWithMapView:self.mpView coordinate:start andTitle:nil];
        calculatedPathAnnotation.annotationType = @"path";
        calculatedPathAnnotation.userInfo = @{
                                              @"linePoints" : [NSArray arrayWithArray:polyLine],
                                              @"lineColor" : [UIColor colorWithRed:245.0/255.0 green:130.0/255.0 blue:32.0/255.0 alpha:0.5],
                                              @"fillColor" : [UIColor clearColor],
                                              @"lineWidth" : [NSNumber numberWithFloat:4.0f],
                                              };
        
        [calculatedPathAnnotation setBoundingBoxFromLocations:[NSArray arrayWithArray:polyLine]];
        //[self.mpView addAnnotation:calculatedPathAnnotation];
        index++;
        
        [self.bikeRouteAnnotations addObject:calculatedPathAnnotation];
        
        }
}

- (NSArray*)parseStationData {
    
    NSString* filePath = [[NSBundle mainBundle] pathForResource:@"stations" ofType:@"json"];
    NSError* error;
    NSData* data = [NSData dataWithContentsOfFile:filePath];
    NSDictionary* dict = nil;
    if ( data ) {
        dict = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
        if ( error ) {
            NSLog(@"ERROR parsing %@: %@", filePath, error);
        }
    }
    NSArray* stations = [dict valueForKey:@"stations"];
    for (NSDictionary* station in stations) {
    
        NSString* name = [station objectForKey:@"name"];
        NSLog(@"STATION: %@", name);
    }
    
    return stations;
}

- (NSArray*)parseLinesData {
    NSString* filePath = [[NSBundle mainBundle] pathForResource:@"s-train-lines" ofType:@"json"];
    NSError* error;
    NSData* data = [NSData dataWithContentsOfFile:filePath];
    NSDictionary* dict = nil;
    if ( data ) {
        dict = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
        if ( error ) {
            NSLog(@"ERROR parsing %@: %@", filePath, error);
        }
    }
    NSArray* lines = [dict valueForKey:@"lines"];
    for (NSDictionary* line in lines) {
        
        NSString* name = [line objectForKey:@"name"];
        NSLog(@"LINE: %@", name);
    }
    
    return lines;
}

- (void)loadMetroMarkers {
    
    self.metroMarkers = [[NSMutableArray alloc] init];
    NSString* filePath = [[NSBundle mainBundle] pathForResource:@"metro-stations" ofType:@"json"];
    NSError* err;
    NSData* data = [NSData dataWithContentsOfFile:filePath];
    NSDictionary* dict = nil;
    if ( data ) {
        dict = [NSJSONSerialization JSONObjectWithData:data options:0 error:&err];
        NSLog(@"Error %@", err);
    }
    NSArray* stations = [dict valueForKey:@"stations"];
    //NSNumber* lon;
    //NSNumber* lat;
    
    for(NSDictionary* station in stations) {
        
        NSString* s = [station objectForKey:@"coords"];
        
        NSRange range = [s rangeOfString:@" "];
        //range.location = 0;
        NSString* sLongitude = [s substringToIndex:range.location];
        range.length = [s length] - range.location;
        NSString* sLatitude = [s substringWithRange:range];
        
        NSLog(@"METRO STATION: %f %f", [sLongitude floatValue], [sLatitude floatValue]);
        
        CLLocationCoordinate2D coord = CLLocationCoordinate2DMake([sLongitude floatValue], [sLatitude floatValue]); //lon, lat);
            //[self addMarkerToMapView:self.mpView withCoordinate:coord title:@"Marker" imageName:@"station_icon" annotationTitle:@"Marker text" alternateTitle:@"Marker alternate title"];
            
            NSString* imageName = @"metro_logo_pin";
            NSString* title = @"metro";
            //NSString* annotationTitle = @"title";
            //NSString* alternateTitle = @"alternate title";
            
            SMAnnotation *annotation = [SMAnnotation annotationWithMapView:self.mpView coordinate:coord andTitle:title];
        
            annotation.annotationType = @"station";
            annotation.annotationIcon = [UIImage imageNamed:imageName];
            annotation.anchorPoint = CGPointMake(0.5, 1.0);
            
//            NSMutableArray * arr = [[self.source componentsSeparatedByString:@","] mutableCopy];
//            annotation.title = annotationTitle;
//            
//            if ([annotation.title isEqualToString:@""] && alternateTitle) {
//                annotation.title = alternateTitle;
//            }
//            
//            annotation.subtitle = [[arr componentsJoinedByString:@","] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
            //[self.mpView addAnnotation:annotation];
            
            [self.metroMarkers addObject:annotation];
        }
    }

- (void)loadTransportationPaths {
    
    self.stationMarkers = [[NSMutableArray alloc] init];
    NSArray* lines= [SMTransportation instance].lines;
    
    //CLLocationCoordinate2D* array = malloc(sizeof(CLLocationCoordinate2D) * 100);
    
    NSArray* lineColors = @[[UIColor redColor], [UIColor greenColor], [UIColor yellowColor], [UIColor orangeColor], [UIColor cyanColor], [UIColor blackColor], [UIColor purpleColor]];
    int lineIndex = 0;
    
    for( SMTransportationLine* transportationLine in lines){
        
        NSMutableArray* points = [[NSMutableArray alloc] init];
        for(int i=0; i<transportationLine.stations.count; i++){
            SMStationInfo* stationLocation= [transportationLine.stations objectAtIndex:i];
            //[stationLocation fetchName];
            CLLocation* loc = [[CLLocation alloc] initWithLatitude:stationLocation.latitude longitude:stationLocation.longitude];
            [points addObject:loc];
        }
        
        CLLocation* startLoc = [points objectAtIndex:0];
        CLLocationCoordinate2D start = startLoc.coordinate;
        RMAnnotation *calculatedPathAnnotation = [RMAnnotation annotationWithMapView:self.mpView coordinate:start andTitle:nil];
        calculatedPathAnnotation.annotationType = @"path";
        calculatedPathAnnotation.userInfo = @{
                                          @"linePoints" : [NSArray arrayWithArray:points],
                                          @"lineColor" : [lineColors objectAtIndex:lineIndex],
                                          @"fillColor" : [UIColor clearColor],
                                          @"lineWidth" : [NSNumber numberWithFloat:2.0f],
                                          };
    
        [calculatedPathAnnotation setBoundingBoxFromLocations:[NSArray arrayWithArray:points]];
        [self.bikeRouteAnnotations addObject:calculatedPathAnnotation];
        //[self.mpView addAnnotation:calculatedPathAnnotation];
        lineIndex++;
        lineIndex = lineIndex % 7;
    }
}

- (void)loadMarkers {
    
    // Load bike route data
    [self loadBikeRouteData];
    
    self.stationMarkers = [[NSMutableArray alloc] init];
    self.serviceMarkers = [[NSMutableArray alloc] init];
    self.localTrainMarkers = [[NSMutableArray alloc] init];
    self.metroMarkers = [[NSMutableArray alloc] init];
    
    NSString* filePath = [[NSBundle mainBundle] pathForResource:@"stations" ofType:@"json"];
    NSError* err;
    NSData* data = [NSData dataWithContentsOfFile:filePath];
    NSDictionary* dict = nil;
    if ( data ) {
        dict = [NSJSONSerialization JSONObjectWithData:data options:0 error:&err];
        NSLog(@"Error %@", err);
    }
    NSArray* stations = [dict valueForKey:@"stations"];
    NSMutableArray* tempMarkers = [[NSMutableArray alloc] init];
    
    for(NSDictionary* station in stations) {
        
        NSString* s = [station objectForKey:@"coords"];
        
        NSRange range = [s rangeOfString:@" "];
        //range.location = 0;
        NSString* sLatitude = [s substringToIndex:range.location];
        range.length = [s length] - range.location;
        NSString* sLongitude = [s substringWithRange:range];
        
        NSString* type = [station objectForKey:@"type"];
        
        NSLog(@"STATION: %f %f", [sLongitude floatValue], [sLatitude floatValue]);
        
        CLLocationCoordinate2D coord = CLLocationCoordinate2DMake([sLongitude floatValue], [sLatitude floatValue]); //lon, lat);
        //[self addMarkerToMapView:self.mpView withCoordinate:coord title:@"Marker" imageName:@"station_icon" annotationTitle:@"Marker text" alternateTitle:@"Marker alternate title"];
        
        NSString* imageName = @"";
        if ([type isEqualToString:@"metro"]) {
            imageName = @"metro_logo_pin";
        } else if ([type isEqualToString:@"service"]) {
            imageName = @"service_pin";
        } else if ([type isEqualToString:@"s-train"]) {
            imageName = @"station_icon";
        } else if ([type isEqualToString:@"local-train"]) {
            imageName = @"local_train_icon";
        }
        
        NSString* title = @"metro";
        NSString* annotationTitle = [station objectForKey:@"name"]; //@"title";
        NSString* alternateTitle = @"alternate title";
        
        SMAnnotation *annotation = [SMAnnotation annotationWithMapView:self.mpView coordinate:coord andTitle:title];
        
        annotation.annotationType = @"station";
        SMStationInfo* st= [[SMTransportation instance] stationWithName:[station objectForKey:@"name"]];
        if(st)
            annotation.userInfo= @{@"station" : st};
        annotation.annotationIcon = [UIImage imageNamed:imageName];
        annotation.anchorPoint = CGPointMake(0.5, 1.0);
        NSMutableArray * arr = [[self.source componentsSeparatedByString:@","] mutableCopy];
        annotation.title = annotationTitle;
        annotation.subtitle = alternateTitle;
        annotation.calloutShown = NO;
        [annotation hideCallout];
        
        if ([annotation.title isEqualToString:@""] && alternateTitle) {
            annotation.title = alternateTitle;
        }
        annotation.subtitle = [[arr componentsJoinedByString:@","] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        annotation.subtitle = alternateTitle;
        [annotation.calloutView.markerIcon setImage:annotation.annotationIcon];
        //[self.mpView addAnnotation:annotation];
        
        [tempMarkers addObject:annotation];
        
        if ([type isEqualToString:@"metro"]) {
            [self.metroMarkers addObject:annotation];
        } else if ([type isEqualToString:@"service"]) {
            [self.serviceMarkers addObject:annotation];
        } else if ([type isEqualToString:@"s-train"]) {
            [self.stationMarkers addObject:annotation];
        } else if ([type isEqualToString:@"local-train"]) {
            [self.localTrainMarkers addObject:annotation];
        }

    }
    
    for (SMAnnotation* annotation in tempMarkers)
    for (SMAnnotation* a in tempMarkers) {
        if ( a != annotation ) {
            if ( a.coordinate.latitude == annotation.coordinate.latitude && a.coordinate.longitude == annotation.coordinate.longitude ) {
                NSLog(@"Annotation same coords!");
                //annotation.calloutShown = YES;
                CGRect frame = a.calloutView.calloutLabel.frame;
                frame.origin.x += 18;
                [a.calloutView.calloutLabel setFrame:frame];
                [annotation.calloutView.calloutLabel setFrame:frame];
                [annotation.calloutView.markerIcon setImage:annotation.annotationIcon];
                [a.calloutView.markerIcon setImage:annotation.annotationIcon];
                
                [annotation.calloutView.markerIcon2 setImage:a.annotationIcon];
                [a.calloutView.markerIcon2 setImage:a.annotationIcon];
                
                [annotation showCallout];
                [annotation hideCallout];
                [a showCallout];
                [a hideCallout];
            }
        }
    }
    
    [self calcMetroData];
    
    [self toggleMarkers];
}

- (void)calcMetroData {
    float totalDistance = 0.0f;
    int numStations = [self.metroMarkers count];
   
    float* times = (float*)malloc(numStations * sizeof(float));
    
    int i=0;
    for (i=0; i<numStations; i++) {
        SMAnnotation* station = [self.metroMarkers objectAtIndex:i];
        SMAnnotation* nextStation = [self.metroMarkers objectAtIndex:MIN(i+1, numStations-1)];
        
        // Get aprox. distance to next station
        float x0 = station.coordinate.longitude;
        float y0 = station.coordinate.latitude;
        
        float x1 = nextStation.coordinate.longitude;
        float y1 = nextStation.coordinate.latitude;
        
        float distance = sqrtf((x1 - x0)*(x1 - x0) + (y1 - y0)*(y1 - y0));
        NSLog(@"%@ -> %@ Distance: %4.4f", station.title, nextStation.title, distance*100);
        
        totalDistance += distance;
        times[i] = distance;
    }
    
    NSLog(@"Total distance: %4.4f", totalDistance*100);
    NSLog(@"Average distance: %4.4f", totalDistance*100 / i);
    
    self.metroTimingConst = [[NSMutableArray alloc] init];
    
    for (i=0; i<numStations; i++) {
        times[i] /= totalDistance / numStations;
        [self.metroTimingConst addObject:[NSNumber numberWithFloat:times[i]]];
    }
}

- (void)oldLoadMarkers {
    
//    if ( !self.mpView ) {
//        return;
//    }
    
    self.stationMarkers = [[NSMutableArray alloc] init];
    NSArray* lines= [SMTransportation instance].lines;
    
    for( SMTransportationLine* transportationLine in lines){
        
        for(int i=0; i<transportationLine.stations.count; i++){
            SMStationInfo* stationLocation= [transportationLine.stations objectAtIndex:i];
            //[stationLocation fetchName];

            CLLocationCoordinate2D coord = CLLocationCoordinate2DMake(stationLocation.latitude, stationLocation.longitude);
            //[self addMarkerToMapView:self.mpView withCoordinate:coord title:@"Marker" imageName:@"station_icon" annotationTitle:@"Marker text" alternateTitle:@"Marker alternate title"];
            
            NSString* imageName = @"station_icon";
            NSString* title = @"station";
            NSString* annotationTitle = @"Station";
            NSString* alternateTitle = @"alternate title";
            
            SMAnnotation *annotation = [SMAnnotation annotationWithMapView:self.mpView coordinate:coord andTitle:title];
            annotation.annotationType = @"station";
            annotation.annotationIcon = [UIImage imageNamed:imageName];
            annotation.anchorPoint = CGPointMake(0.5, 1.0);
            NSMutableArray* arr = [[self.source componentsSeparatedByString:@","] mutableCopy];
            annotation.title = annotationTitle;
            
            if ([annotation.title isEqualToString:@""] && alternateTitle) {
                annotation.title = alternateTitle;
            }
            
//            annotation.userInfo= @{keyZIndex: [NSNumber numberWithInt:MAP_LEVEL_STATIONS]};
            
            annotation.subtitle = [[arr componentsJoinedByString:@","] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
            //[self.mpView addAnnotation:annotation];
            
            [self.stationMarkers addObject:annotation];
            
        }
    }
      
    // Add metro markers
    self.metroMarkers = [[NSMutableArray alloc] init];
    NSString* filePath = [[NSBundle mainBundle] pathForResource:@"metro-stations" ofType:@"json"];
    NSError* err;
    NSData* data = [NSData dataWithContentsOfFile:filePath];
    NSDictionary* dict = nil;
    if ( data ) {
        dict = [NSJSONSerialization JSONObjectWithData:data options:0 error:&err];
        NSLog(@"Error %@", err);
    }
    NSArray* stations = [dict valueForKey:@"stations"];
    NSNumber* lon;
    NSNumber* lat;
    
    for(NSDictionary* station in stations) {
        
        NSString* s = [station objectForKey:@"coords"];
        
        NSRange range = [s rangeOfString:@" "];
        //range.location = 0;
        NSString* sLatitude = [s substringToIndex:range.location];
        range.length = [s length] - range.location;
        NSString* sLongitude = [s substringWithRange:range];
        
        NSLog(@"METRO STATION: %f %f", [sLongitude floatValue], [sLatitude floatValue]);
        
        CLLocationCoordinate2D coord = CLLocationCoordinate2DMake([sLongitude floatValue], [sLatitude floatValue]); //lon, lat);
        //[self addMarkerToMapView:self.mpView withCoordinate:coord title:@"Marker" imageName:@"station_icon" annotationTitle:@"Marker text" alternateTitle:@"Marker alternate title"];
        
        NSString* imageName = @"metro_logo_pin";
        NSString* title = @"metro";
        NSString* annotationTitle = @"title";
        NSString* alternateTitle = @"alternate title";
        
        SMAnnotation *annotation = [SMAnnotation annotationWithMapView:self.mpView coordinate:coord andTitle:title];
        
        annotation.annotationType = @"station";
        annotation.annotationIcon = [UIImage imageNamed:imageName];
        annotation.anchorPoint = CGPointMake(0.5, 1.0);
        NSMutableArray * arr = [[self.source componentsSeparatedByString:@","] mutableCopy];
        annotation.title = annotationTitle;
        
        if ([annotation.title isEqualToString:@""] && alternateTitle) {
            annotation.title = alternateTitle;
        }
        annotation.subtitle = [[arr componentsJoinedByString:@","] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        //[self.mpView addAnnotation:annotation];
        
        [self.metroMarkers addObject:annotation];
    }


    // Add service markers
    self.serviceMarkers = [[NSMutableArray alloc] init];
    filePath = [[NSBundle mainBundle] pathForResource:@"service_stations" ofType:@"json"];

    data = [NSData dataWithContentsOfFile:filePath];
    dict = nil;
    if ( data ) {
        dict = [NSJSONSerialization JSONObjectWithData:data options:0 error:&err];
        NSLog(@"Error %@", err);
    }
    stations = [dict valueForKey:@"stations"];
    
    for(NSDictionary* station in stations){
        
        NSString* stationName = [station objectForKey:@"name"];
        NSDictionary* coords = [station objectForKey:@"point"];
        
        lon = [coords objectForKey:@"long"];
        lat = [coords objectForKey:@"lat"];
        SMStationInfo* stationInfo= [[SMStationInfo alloc] initWithLongitude:lon.doubleValue latitude:lat.doubleValue name:stationName];
        
        //[self.serviceMarkers addObject:stationInfo];
        
        NSLog(@"SERVICE STATION: %f %f %@", stationInfo.longitude, stationInfo.latitude, stationInfo.name);
        
        NSString* imageName = @"service_pin";
        NSString* title = @"service";
        NSString* annotationTitle = stationName;
        NSString* alternateTitle = stationName;
        
        CLLocationCoordinate2D coord = CLLocationCoordinate2DMake(lon.floatValue, lat.floatValue);
        SMAnnotation *annotation = [SMAnnotation annotationWithMapView:self.mpView coordinate:coord andTitle:title];
        annotation.annotationType = @"station";
        annotation.annotationIcon = [UIImage imageNamed:imageName];
        annotation.anchorPoint = CGPointMake(0.5, 1.0);
        
        NSMutableArray * arr = [[self.source componentsSeparatedByString:@","] mutableCopy];
        annotation.title = annotationTitle;
        
        if ([annotation.title isEqualToString:@""] && alternateTitle) {
            annotation.title = alternateTitle;
        }
        
        annotation.subtitle = [[arr componentsJoinedByString:@","] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        //[self.mpView addAnnotation:annotation];
        [self.serviceMarkers addObject:annotation];
    }
    
    [self toggleMarkers];
}

-(void)toggleMarkers{
    
    //[self drawPaths];
    
    if ( self.pathVisible ) {
        [self.mpView addAnnotations:self.bikeRouteAnnotations];
    } else {
        [self.mpView removeAnnotations:self.bikeRouteAnnotations];
    }
    
    if ( self.metroMarkersVisible ) {
        [self.mpView addAnnotations:self.metroMarkers];
    } else {
        [self.mpView removeAnnotations:self.metroMarkers];
    }
    
    if ( self.serviceMarkersVisible ) {
        [self.mpView addAnnotations:self.serviceMarkers];
    } else {
        [self.mpView removeAnnotations:self.serviceMarkers];
    }
    
    if ( self.stationMarkersVisible ) {
        [self.mpView addAnnotations:self.stationMarkers];
    } else {
        [self.mpView removeAnnotations:self.stationMarkers];
    }
    
    if ( self.localTrainMarkersVisible ) {
        [self.mpView addAnnotations:self.localTrainMarkers];
    } else {
        [self.mpView removeAnnotations:self.localTrainMarkers];
    }
    
        
//    float t = MAX((self.mpView.zoom / 10.0) - 1.0, 0.0)*2.0;
//    float zoom = lerp(0.35, 1.5, t);
//    NSLog(@"Map ZOOM: %f", self.mpView.zoom);
//    
//    for (SMAnnotation* an in self.mpView.annotations) {
//        if ([an.annotationType isEqualToString:@"station"]) {
//            RMMarker* marker = (RMMarker*)(an.layer);
//            [marker updateBoundsWithZoom: zoom];
//        }
//    }
    
    [self.mpView setZoom:self.mpView.zoom+0.0001];

//    [self.mpView setNeedsLayout];
}

- (void)toggleMarkers:(NSString*)markerType state:(BOOL)state {
    if ( [markerType isEqualToString:@"metro"] ) {
        self.metroMarkersVisible = state;
        
    } else if ( [markerType isEqualToString:@"service"] ) {
        self.serviceMarkersVisible = state;
        
    } else if ( [markerType isEqualToString:@"station"] ) {
        self.stationMarkersVisible = state;
        
    }else if([markerType isEqualToString:@"path"]){
        self.pathVisible= state;
        
    } else if ([markerType isEqualToString:@"local-trains"]) {
        self.localTrainMarkersVisible = state;
    }
    
    [self toggleMarkers];
    NSLog(@"Toggle markers: %@ %d", markerType, state);
}

//float lerp(float a, float b, float t) {
//    return (1.0-t)*a + t*b;
//}

@end
