//
//  SMViewController.m
//  I Bike CPH
//
//  Created by Ivan Pavlovic on 22/01/2013.
//  Copyright (c) 2013 City of Copenhagen. All rights reserved.
//

#import "SMMainViewController.h"

#import "SMLocationManager.h"
#import "SMSearchHistory.h"

#import "RMMarker.h"
#import "RMShape.h"

#import "SMiBikeCPHMapTileSource.h"
#import "RMOpenStreetMapSource.h"

#import "SMRouteNavigationController.h"
#import "SMAppDelegate.h"
#import "SMAnnotation.h"
#import "SMGeocoder.h"
#import <MapKit/MapKit.h>

#import "SMEnterRouteController.h"

#import "SMFavoritesUtil.h"

#import "SMTransportation.h"
#import "SMTransportationLine.h"
#import "SMStationInfo.h"
#import "SMLoadStationsView.h"

#import "UIView+LocateSubview.h"

@interface SMMainViewController () <SMAPIRequestDelegate>{
    BOOL pinWorking;
}

@property (weak, nonatomic) IBOutlet RMMapView *mapView;

@property (weak, nonatomic) IBOutlet FlickableView *centerView;
@property (weak, nonatomic) IBOutlet UIView *blockingView;
@property (weak, nonatomic) IBOutlet SMGPSTrackButton *buttonTrackUser;
@property (weak, nonatomic) IBOutlet UIButton *menuButton;
@property (weak, nonatomic) IBOutlet UIView *loaderView;

@property (weak, nonatomic) IBOutlet UIView *bottomDrawerView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *bottomDrawerViewConstraint;
@property (assign, nonatomic) BOOL bottomDrawerViewVisible;

@property (assign, nonatomic) BOOL animationShown;
@property (weak, nonatomic) IBOutlet UILabel *routeStreet;
@property (weak, nonatomic) IBOutlet UIButton *pinButton;

@property (nonatomic, strong) NSString * destination;
@property (nonatomic, strong) NSString * source;

@property (nonatomic, strong) NSString * findFrom;
@property (nonatomic, strong) NSString * findTo;
@property (nonatomic, strong) NSArray * findMatches;
@property (nonatomic, strong) SMAnnotation * destinationPin;

@property (nonatomic, strong) id jsonRoot;

@property (nonatomic, strong) CLLocation *startLoc;
@property (nonatomic, strong) CLLocation *endLoc;
@property (nonatomic, strong) NSString * startName;
@property (nonatomic, strong) NSString * endName;

@property (nonatomic, strong) SMAPIRequest * request;
@property (nonatomic, strong) SMLoadStationsView *loadStationsView;

@end


@implementation SMMainViewController {
    BOOL observersAdded;
}


#pragma mark - view lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    
    pinWorking = NO;
    
    
    // TODO
//    animationShown = NO;
    
    [SMLocationManager instance];
    
    self.mapView.tileSource = TILE_SOURCE;
    self.mapView.delegate = self;
    self.mapView.maxZoom = MAX_MAP_ZOOM;
    self.mapView.enableBouncing = YES;
    
    if ([SMLocationManager instance].lastValidLocation) {
        self.mapView.centerCoordinate = [SMLocationManager instance].lastValidLocation.coordinate;
        self.mapView.zoom = DEFAULT_MAP_ZOOM;
    } else {
        self.mapView.centerCoordinate = INIT_COORDINATE;
        self.mapView.zoom = INIT_ZOOM_LEVEL;
    }
    
    // Load overlays
    if (self.appDelegate.mapOverlays == nil) {
        self.appDelegate.mapOverlays = [[SMMapOverlays alloc] initWithMapView:nil];
    }
    [self.appDelegate.mapOverlays useMapView:self.mapView];
    [self.appDelegate.mapOverlays loadMarkers];
    
    if([SMTransportation instance].dataLoaded){
        [self loadLastRoute];
    }
}




- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self.navigationController setNavigationBarHidden:YES animated:YES];
    
    self.findFrom = @"";
    self.findTo = @"";
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [self.navigationController setNavigationBarHidden:NO animated:YES];
    
    self.mapView.userTrackingMode = RMUserTrackingModeNone;

    if(_loadStationsView){
        [self.loadStationsView.activityIndicatorView stopAnimating];
        [self.loadStationsView removeFromSuperview];
        _loadStationsView = nil;
    }
    
    if(observersAdded){
        observersAdded = NO;
        [self.mapView removeObserver:self forKeyPath:@"userTrackingMode"];
    }
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];

    // TODO: CykelPlanen
//    [SMUser user].tripRoute = nil;
//    [SMUser user].route = nil;
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didLoadTransformationData:) name:NOTIFICATION_DID_PARSE_DATA_KEY object:nil];
    if(![SMTransportation instance].dataLoaded){
        NSLog(@"DATA NOT LOADED... SHOWING VIEW");
        self.loadStationsView= [[SMLoadStationsView alloc] initWithFrame:self.view.bounds];
        [self.loadStationsView setup];
        [self.view addSubview:self.loadStationsView];
    }
    
    if (!observersAdded) {
        observersAdded = YES;
        [self.mapView addObserver:self forKeyPath:@"userTrackingMode" options:0 context:nil];
    }
}

//- (void)viewDidLayoutSubviews {
//    [super viewDidLayoutSubviews];
//    
//    [self checkBottomDrawerLayout];
//}

- (void)updateViewConstraints {
    [super updateViewConstraints];
    
    [self checkBottomDrawerLayout];
}


#pragma mark - Setters and Getters

- (void)setBottomDrawerViewVisible:(BOOL)bottomDrawerViewVisible
{
    if (bottomDrawerViewVisible != _bottomDrawerViewVisible) {
        _bottomDrawerViewVisible = bottomDrawerViewVisible;
        
        [UIView animateWithDuration:0.25 delay:0 usingSpringWithDamping:1 initialSpringVelocity:0 options:UIViewAnimationOptionBeginFromCurrentState animations:^{
            [self checkBottomDrawerLayout];
            [self.view layoutIfNeeded];
        } completion:^(BOOL finished) {
            
        }];
    }
}


#pragma mark - 

- (void)checkBottomDrawerLayout {
    self.bottomDrawerViewConstraint.constant = self.view.bounds.size.height - (self.bottomDrawerViewVisible ? self.bottomDrawerView.frame.size.height : 0);
}


#pragma mark -

-(void)didLoadTransformationData:(NSNotification*)notification{
    NSLog(@"NOTIFICATION");
    if(self.loadStationsView){
        [self performSelectorOnMainThread:@selector(hideLoadingView) withObject:nil waitUntilDone:NO];

    }else{
        [self performSelectorOnMainThread:@selector(loadLastRoute) withObject:nil waitUntilDone:NO];
    }
}

-(void)hideLoadingView{
    [UIView animateWithDuration:0.4 delay:0.0 options:0 animations:^{
        self.loadStationsView.alpha= 0.0;
    } completion:^(BOOL finished){
        [self.loadStationsView removeFromSuperview];
        _loadStationsView= nil;
        [self performSelectorOnMainThread:@selector(loadLastRoute) withObject:nil waitUntilDone:NO];
    }];
}
-(void)loadLastRoute{
    if ([[NSFileManager defaultManager] fileExistsAtPath: [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent: @"lastRoute.plist"]]) {
        NSDictionary * d = [NSDictionary dictionaryWithContentsOfFile: [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent: @"lastRoute.plist"]];
        
        NSString * st = [NSString stringWithFormat:@"Start: %@ (%f,%f) End: %@ (%f,%f)",CURRENT_POSITION_STRING, [d[@"startLat"] doubleValue], [d[@"startLong"] doubleValue], d[@"destination"], [d[@"endLat"] doubleValue], [d[@"endLong"] doubleValue]];
        debugLog(@"%@", st);
        if (![SMAnalytics trackEventWithCategory:@"Route:" withAction:@"Resume" withLabel:st withValue:0]) {
            debugLog(@"error in trackPageview");
        }
        
        // show new route
        CLLocation * cEnd = [[CLLocation alloc] initWithLatitude:[d[@"endLat"] floatValue] longitude:[d[@"endLong"] floatValue]];
        CLLocation * cStart = [[CLLocation alloc] initWithLatitude:[d[@"startLat"] floatValue] longitude:[d[@"startLong"] floatValue]];
        
        SMRequestOSRM * r = [[SMRequestOSRM alloc] initWithDelegate:self];
        [r setRequestIdentifier:@"rowSelectRoute"];
        [r setAuxParam:d[@"destination"]];
        [r findNearestPointForStart:cStart andEnd:cEnd];                
    }
}

- (void)longSingleTapOnMap:(RMMapView *)map at:(CGPoint)point {
    if (self.blockingView.alpha > 0) {
        return;
    }
    
    for (SMAnnotation * annotation in self.mapView.annotations) {
        if ([annotation.annotationType isEqualToString:@"marker"] && [annotation isKindOfClass:[SMAnnotation class]]) {
            if (annotation.calloutShown) {
                [annotation hideCallout];
            }
        }
    }
    
    CLLocationCoordinate2D coord = [self.mapView pixelToCoordinate:point];
    CLLocation * loc = [[CLLocation alloc] initWithLatitude:coord.latitude longitude:coord.longitude];
    debugLog(@"pin drop LOC: %@", loc);
    debugLog(@"pin drop POINT: %@", NSStringFromCGPoint(point));
    
    [self displayPinWithPoint:point atLocation:loc ];
    [self showPinDrop];
    [self displayDestinationNameWithLocation:loc];
}

- (void)displayPinWithPoint:(CGPoint)point atLocation:(CLLocation *)loc {
    UIImageView * im = [[UIImageView alloc] initWithFrame:CGRectMake(point.x - 17.0f, 0.0f, 34.0f, 34.0f)];
    [im setImage:[UIImage imageNamed:@"markerFinish"]];
    [self.mapView addSubview:im];
    [UIView animateWithDuration:0.2f animations:^{
        [im setFrame:CGRectMake(point.x - 17.0f, point.y - 34.0f, 34.0f, 34.0f)];
    } completion:^(BOOL finished) {
        debugLog(@"dropped pin");
        
        if (self.endMarkerAnnotation == nil) {
            [self.mapView removeAllAnnotations];
        } else {
            [self.mapView removeAnnotation:self.endMarkerAnnotation];
        }
        self.endMarkerAnnotation = [SMAnnotation annotationWithMapView:self.mapView coordinate:loc.coordinate andTitle:@""];
        self.endMarkerAnnotation.annotationType = @"marker";
        self.endMarkerAnnotation.annotationIcon = [UIImage imageNamed:@"markerFinish"];
        self.endMarkerAnnotation.anchorPoint = CGPointMake(0.5, 1.0);
        [self.mapView addAnnotation:self.endMarkerAnnotation];
        [self setDestinationAnnotation:self.endMarkerAnnotation withLocation:loc];
        
        [im removeFromSuperview];
    }];
}

- (void)setDestinationAnnotation:(SMAnnotation*)annotation withLocation:(CLLocation *)loc {
    self.destinationPin = annotation;
    
    self.destinationPin.subtitle = @"";
    self.destinationPin.delegate = self;
    self.destinationPin.routingCoordinate = loc;
}

- (void)displayDestinationNameWithString:(NSString*)str {
    [self.routeStreet setText:str];
}

- (void)displayDestinationNameWithLocation:(CLLocation*)loc{
    [SMGeocoder reverseGeocode:loc.coordinate completionHandler:^(NSDictionary *response, NSError *error) {
        NSLog(@"reverse geocode error: %@", error);
        NSString *title = response[@"title"];
        NSString *subtitle = response[@"subtitle"];
        NSString *text = title;
        if (subtitle.length) {
            text = [text stringByAppendingFormat:@"\n%@", subtitle];
        }
        if (text.length == 0) {
            text = [NSString stringWithFormat:@"%f, %f", loc.coordinate.latitude, loc.coordinate.longitude];
        }
        NSLog(@"Pin at: %@", text);
        self.routeStreet.text = text;
        
        NSPredicate * pred = [NSPredicate predicateWithFormat:@"SELF.name = %@ AND SELF.address = %@", self.routeStreet.text, self.routeStreet.text];
        NSArray * arr = [[SMFavoritesUtil getFavorites] filteredArrayUsingPredicate:pred];
        if ([arr count] > 0) {
            [self.pinButton setSelected:YES];
        } else {
            [self.pinButton setSelected:NO];
        }
        NSString *token = self.appDelegate.appSettings[@"auth_token"];
        if (token && [token isKindOfClass:[NSString class]] && [token isEqualToString:@""] == NO) {
            self.pinButton.enabled = YES;
        } else {
            self.pinButton.enabled = NO;
        }
        
        [self.destinationPin setTitle:title];
    }];
}

#pragma mark - rotation

- (NSUInteger)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskAll;
}


#pragma mark - button actions

- (IBAction)goToPin:(id)sender {
    [self annotationActivated:self.destinationPin];
    [self hidePinDrop];
}

- (void)delayedAddPin {
    CLLocation *location = [[CLLocation alloc] initWithLatitude:self.destinationPin.coordinate.latitude longitude:self.destinationPin.coordinate.longitude];
    FavoriteItem *item = [[FavoriteItem alloc] initWithName:self.routeStreet.text address:self.routeStreet.text location:location startDate:[NSDate date] endDate:[NSDate date] origin:FavoriteItemTypeUnknown];
    NSPredicate * pred = [NSPredicate predicateWithFormat:@"SELF.name = %@ AND SELF.address = %@", self.routeStreet.text, self.routeStreet.text];
    NSArray * arr = [[SMFavoritesUtil getFavorites] filteredArrayUsingPredicate:pred];
    SMFavoritesUtil * fv = [SMFavoritesUtil instance];
    fv.delegate = self;
    if ([arr count] > 0) {
        [self.pinButton setSelected:NO];
        FavoriteItem *item = arr.firstObject;
        [fv deleteFavoriteFromServer:item];
        // TODO
//        if (![SMAnalytics trackEventWithCategory:@"Favorites" withAction:@"Delete" withLabel:[NSString stringWithFormat:@"%@ - (%f, %f)", addFavName.text, self.locItem.location.coordinate.latitude, self.locItem.location.coordinate.longitude] withValue:0]) {
//            debugLog(@"error in trackEvent");
//        }
    } else {
        [self.pinButton setSelected:YES];
        [fv addFavoriteToServer:item];
        // TODO
//        if (![SMAnalytics trackEventWithCategory:@"Favorites" withAction:@"New" withLabel:[NSString stringWithFormat:@"%@ - (%f, %f)", addFavName.text, self.locItem.location.coordinate.latitude, self.locItem.location.coordinate.longitude] withValue:0]) {
//            debugLog(@"error in trackEvent");
//        }
    }
}

- (IBAction)pinAddToFavorites:(id)sender {
    if (pinWorking == NO) {
        pinWorking = YES;
        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(delayedAddPin) object:nil];
        [self performSelector:@selector(delayedAddPin) withObject:nil afterDelay:0.2f];
    }
}

- (void)showPinDrop {
    self.bottomDrawerViewVisible = YES;
    self.routeStreet.text = @"";
    
    // TODO
//    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(delayedAddPin) object:nil];
//    pinWorking = NO;
//    pinButton.enabled = NO;
}

- (void)hidePinDrop {
    self.bottomDrawerViewVisible = NO;
}

- (void)trackingOn {
    self.mapView.userTrackingMode = RMUserTrackingModeFollow;
}

- (IBAction)trackUser:(id)sender {
    if (self.buttonTrackUser.gpsTrackState != SMGPSTrackButtonStateNotFollowing) {
        debugLog(@"Warning: trackUser button state was invalid: 0x%0x", self.buttonTrackUser.gpsTrackState);
    }

    self.mapView.userTrackingMode = RMUserTrackingModeFollow;
    if ([SMLocationManager instance].hasValidLocation) {
        [self.mapView setCenterCoordinate:[SMLocationManager instance].lastValidLocation.coordinate];
    }
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"enterRouteSegue"]) {
        SMEnterRouteController *destViewController = segue.destinationViewController;
        [destViewController setDelegate:self];
    } else if ([segue.identifier isEqualToString:@"mainToRoute"]) {
        [self.mapView removeAllAnnotations];
        for (id v in self.mapView.subviews) {
            if ([v isKindOfClass:[SMCalloutView class]]) {
                [v removeFromSuperview];
            }
        }
        
        NSDictionary * params = (NSDictionary*)sender;
        SMRouteNavigationController *destViewController = segue.destinationViewController;
        [destViewController setStartLocation:params[@"start"]];
        [destViewController setEndLocation:params[@"end"]];
        [destViewController setDestination:self.destination];
        [destViewController setSource:self.source];
        [destViewController setJsonRoot:self.jsonRoot];
        
        CLLocation *endLocation = (CLLocation*)params[@"end"];
        CLLocation *startLocation = (CLLocation*)params[@"start"];
        NSDictionary * d = @{
                             @"endLat": @(endLocation.coordinate.latitude),
                             @"endLong": @(endLocation.coordinate.longitude),
                             @"startLat": @(startLocation.coordinate.latitude),
                             @"startLong": @(startLocation.coordinate.longitude),
                             @"destination": ((self.destination == nil) ? @"" : self.destination),
                             };
        
        NSString * s = [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent: @"lastRoute.plist"];
        BOOL x = [d writeToFile:s atomically:NO];
        if (x == NO) {
            NSLog(@"Temp route not saved!");
        }
    }
}


#pragma mark - route finder delegate

- (void)findRouteFrom:(CLLocationCoordinate2D)from to:(CLLocationCoordinate2D)to fromAddress:(NSString *)src toAddress:(NSString *)dst{
    [self findRouteFrom:from to:to fromAddress:src toAddress:dst withJSON:nil];
}

- (void)findRouteFrom:(CLLocationCoordinate2D)from to:(CLLocationCoordinate2D)to fromAddress:(NSString *)src toAddress:(NSString *)dst withJSON:(id)jsonRoot{
    CLLocation * start = [[CLLocation alloc] initWithLatitude:from.latitude longitude:from.longitude];
    CLLocation * end = [[CLLocation alloc] initWithLatitude:to.latitude longitude:to.longitude];    
    self.destination = (dst == nil ? @"" : dst);
    self.source = (src == nil ? @"" : src);
    self.jsonRoot = jsonRoot;
    [self performSegueWithIdentifier:@"mainToRoute" sender:@{@"start" : start, @"end" : end}];
}

#pragma mark - gesture recognizer delegate

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    return NO;
}

#pragma mark - mapView delegate

- (void)afterMapMove:(RMMapView *)map byUser:(BOOL)wasUserAction {
    [self checkCallouts];
}

- (void)checkCallouts {
    for (SMAnnotation * annotation in self.mapView.annotations) {
        if ([annotation.annotationType isEqualToString:@"marker"] && [annotation isKindOfClass:[SMAnnotation class]]) {
            if (annotation.calloutShown) {
                [annotation showCallout];
            }
        }
    }
}

- (void)mapViewRegionDidChange:(RMMapView *)mapView {
    
    float t = MAX((mapView.zoom / 10.0) - 1.0, 0.0)*2.0;
    float zoom = lerp(0.35, 1.5, t);
    
    for (SMAnnotation* an in mapView.annotations) {
        if ([an.annotationType isEqualToString:@"station"]) {
            RMMarker* marker = (RMMarker*)(an.layer);
            [marker updateBoundsWithZoom: zoom];
        }
    }

    [self checkCallouts];
}

float lerp(float a, float b, float t) {
    return b*t + (1.0-t)*a;
}

- (RMMapLayer *)mapView:(RMMapView *)aMapView layerForAnnotation:(SMAnnotation *)annotation {
    if ([annotation.annotationType isEqualToString:@"marker"] || [annotation.annotationType isEqualToString:@"station"]) {
        RMMarker * m = [[RMMarker alloc] initWithUIImage:annotation.annotationIcon anchorPoint:annotation.anchorPoint];
        return m;
    }

    if ([annotation.annotationType isEqualToString:@"path"]) {
        RMShape *path = [[RMShape alloc] initWithView:aMapView];
        [path setZPosition:-MAXFLOAT];
        [path setLineColor:[annotation.userInfo objectForKey:@"lineColor"]];
        [path setOpacity:PATH_OPACITY];
        [path setFillColor:[annotation.userInfo objectForKey:@"fillColor"]];
        [path setLineWidth:[[annotation.userInfo objectForKey:@"lineWidth"] floatValue]];
        path.scaleLineWidth = NO;
        
        if ([[annotation.userInfo objectForKey:@"closePath"] boolValue])
            [path closePath];
        
        @synchronized([annotation.userInfo objectForKey:@"linePoints"]) {
            for (CLLocation *location in [annotation.userInfo objectForKey:@"linePoints"]) {
                [path addLineToCoordinate:location.coordinate];
            }
        }
        return path;
    }
    
    if ([annotation.annotationType isEqualToString:@"line"]) {
        RMShape *line = [[RMShape alloc] initWithView:aMapView];
        [line setZPosition:-MAXFLOAT];
        [line setLineColor:[annotation.userInfo objectForKey:@"lineColor"]];
        [line setOpacity:PATH_OPACITY];
        [line setFillColor:[annotation.userInfo objectForKey:@"fillColor"]];
        [line setLineWidth:[[annotation.userInfo objectForKey:@"lineWidth"] floatValue]];
        line.scaleLineWidth = YES;
        
        CLLocation *start = [annotation.userInfo objectForKey:@"lineStart"];
        [line addLineToCoordinate:start.coordinate];
        CLLocation *end = [annotation.userInfo objectForKey:@"lineEnd"];
        [line addLineToCoordinate:end.coordinate];
        
        return line;
    }
    
    return nil;
}

- (void)afterMapZoom:(RMMapView *)map byUser:(BOOL)wasUserAction {
    [self checkCallouts];
}

- (void)mapView:(RMMapView *)mapView didUpdateUserLocation:(RMUserLocation *)userLocation {
    [self checkCallouts];
}

- (void)tapOnAnnotation:(SMAnnotation *)annotation onMap:(RMMapView *)map {
    for (id v in self.mapView.subviews) {
        if ([v isKindOfClass:[SMCalloutView class]]) {
            [v removeFromSuperview];
        }
    }
    [self.mapView removeAllAnnotations];
    [self hidePinDrop];
    
    BOOL visible = NO;
    if (annotation.calloutShown)
        visible = YES;
    
    // TODO: From CykelPlanen
//    for (SMAnnotation* ann in map.annotations) {
//        if ([ann isKindOfClass:[SMAnnotation class]]) {
//            [ann hideCallout];
//        }
//    }
//    NSLog(@"ANNOTATION SELECTED: %@", annotation.annotationType.lowercaseString);
//    if([annotation.annotationType.lowercaseString isEqualToString:@"station"]){
//        SMStationInfo* station= [annotation.userInfo objectForKey:@"station"];
//        //if(station){
//        [self showPinDrop];
//        [self displayDestinationNameWithString:station.name];
//        [self setDestinationAnnotation:annotation withLocation:station.location];
//        
//        if (visible)
//            [annotation hideCallout];
//        else
//            [annotation showCallout];
//        
//        RMMapLayer* layer= [self mapView:map layerForAnnotation:annotation];
//    }
}

#pragma mark - SMAnnotation delegate methods

- (void)annotationActivated:(SMAnnotation *)annotation {
    
    self.findFrom = @"";
    self.findTo = [NSString stringWithFormat:@"%@, %@", annotation.title, annotation.subtitle];
    self.findMatches = annotation.nearbyObjects;
    
    [self.view bringSubviewToFront:self.loaderView];
    [UIView animateWithDuration:0.4f animations:^{
        [self.loaderView setAlpha:1.0f];
    }];
    
    CLLocation * cEnd = [[CLLocation alloc] initWithLatitude:annotation.routingCoordinate.coordinate.latitude longitude:annotation.routingCoordinate.coordinate.longitude];
    CLLocation * cStart = [[CLLocation alloc] initWithLatitude:[SMLocationManager instance].lastValidLocation.coordinate.latitude longitude:[SMLocationManager instance].lastValidLocation.coordinate.longitude];
    
    
    // remove this if we need to find the closest point
    NSString * st = [NSString stringWithFormat:@"Start: %@ (%f,%f) End: %@ (%f,%f)", @"", cStart.coordinate.latitude, cStart.coordinate.longitude, @"", cEnd.coordinate.latitude, cEnd.coordinate.longitude];
    debugLog(@"%@", st);
    if (![SMAnalytics trackEventWithCategory:@"Route:" withAction:@"Pin" withLabel:st withValue:0]) {
        debugLog(@"error in trackPageview");
    }
    self.startName = CURRENT_POSITION_STRING;
    SMStationInfo* station= [annotation.userInfo objectForKey:@"station"];
    if(station){
        self.endName= station.name;
    }else{
        self.endName = annotation.title;
    }

    self.startLoc = cStart;
    self.endLoc = cEnd;
    SMRequestOSRM * r = [[SMRequestOSRM alloc] initWithDelegate:self];
    [r setAuxParam:@"startRoute"];
    [r getRouteFrom:cStart.coordinate to:cEnd.coordinate via:nil];
    // end routing
}


#pragma mark - nearby places delegate

- (void)nearbyPlaces:(SMNearbyPlaces *)owner foundLocations:(NSArray *)locations {
//    [self.destinationPin setNearbyObjects:locations];
    [self.routeStreet setText:owner.title];
    if ([self.routeStreet.text isEqualToString:@""]) {
        [self.routeStreet setText:[NSString stringWithFormat:@"%f, %f", owner.coord.coordinate.latitude, owner.coord.coordinate.longitude]];
    }
    
    NSPredicate * pred = [NSPredicate predicateWithFormat:@"SELF.name = %@ AND SELF.address = %@", self.routeStreet.text, self.routeStreet.text];
    NSArray * arr = [[SMFavoritesUtil getFavorites] filteredArrayUsingPredicate:pred];
    if ([arr count] > 0) {
        [self.pinButton setSelected:YES];
    } else {
        [self.pinButton setSelected:NO];
    }
    if ([self.appDelegate.appSettings objectForKey:@"auth_token"] && [[self.appDelegate.appSettings objectForKey:@"auth_token"] isEqualToString:@""] == NO) {
        pinWorking = NO;
        self.pinButton.enabled = YES;
    }
    
    [self showPinDrop];
}

#pragma mark - osrm request delegate

- (void)request:(SMRequestOSRM *)req finishedWithResult:(id)res {
    if ([req.requestIdentifier isEqualToString:@"getNearestForPinDrop"]) {
        NSDictionary * r = res;
        CLLocation * coord;
        if (r[@"mapped_coordinate"] && [r[@"mapped_coordinate"] isKindOfClass:[NSArray class]] && ([r[@"mapped_coordinate"] count] > 1)) {
            coord = [[CLLocation alloc] initWithLatitude:[r[@"mapped_coordinate"][0] doubleValue] longitude:[r[@"mapped_coordinate"][1] doubleValue]];
        } else {
            coord = req.coord;
        }
        SMNearbyPlaces * np = [[SMNearbyPlaces alloc] initWithDelegate:self];
        [np findPlacesForLocation:[[CLLocation alloc] initWithLatitude:coord.coordinate.latitude longitude:coord.coordinate.longitude]];
    } else if ([req.requestIdentifier isEqualToString:@"rowSelectRoute"]) {
        CLLocation * s = res[@"start"];
        CLLocation * e = res[@"end"];
        
        NSString * st = [NSString stringWithFormat:@"Start: %@ (%f,%f) End: %@ (%f,%f)", @"", s.coordinate.latitude, s.coordinate.longitude, @"", e.coordinate.latitude, e.coordinate.longitude];
        debugLog(@"%@", st);
        if (![SMAnalytics trackEventWithCategory:@"Route:" withAction:@"Pin" withLabel:st withValue:0]) {
            debugLog(@"error in trackPageview");
        }
        
        self.startName = CURRENT_POSITION_STRING;
        self.endName = req.auxParam;
        self.startLoc = s;
        self.endLoc = e;
        
        SMRequestOSRM * r = [[SMRequestOSRM alloc] initWithDelegate:self];
        [r setAuxParam:@"startRoute"];
        [r getRouteFrom:s.coordinate to:e.coordinate via:nil];
    } else if ([req.auxParam isEqualToString:@"startRoute"]){
        id jsonRoot = [NSJSONSerialization JSONObjectWithData:req.responseData options:NSJSONReadingAllowFragments error:nil];
        if (!jsonRoot || ([jsonRoot isKindOfClass:[NSDictionary class]] == NO) || ([jsonRoot[@"status"] intValue] != 0)) {
            UIAlertView * av = [[UIAlertView alloc] initWithTitle:nil message:translateString(@"error_route_not_found") delegate:nil cancelButtonTitle:translateString(@"OK") otherButtonTitles:nil];
            [av show];
        } else {
            [self findRouteFrom:self.startLoc.coordinate to:self.endLoc.coordinate fromAddress:self.startName toAddress:self.endName withJSON:jsonRoot];
        }
        [UIView animateWithDuration:0.4f animations:^{
            [self.loaderView setAlpha:0.0f];
        }];
    }
}

- (void)request:(SMRequestOSRM *)req failedWithError:(NSError *)error {
    [UIView animateWithDuration:0.4f animations:^{
        [self.loaderView setAlpha:0.0f];
    }];
}

#pragma mark - observers

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if (object == self.mapView && [keyPath isEqualToString:@"userTrackingMode"]) {
        if (self.mapView.userTrackingMode == RMUserTrackingModeFollow) {
            [self.buttonTrackUser newGpsTrackState:SMGPSTrackButtonStateFollowing];
        } else if (self.mapView.userTrackingMode == RMUserTrackingModeFollowWithHeading) {
            [self.buttonTrackUser newGpsTrackState:SMGPSTrackButtonStateFollowingWithHeading];
        } else if (self.mapView.userTrackingMode == RMUserTrackingModeNone) {
            [self.buttonTrackUser newGpsTrackState:SMGPSTrackButtonStateNotFollowing];
        }
    }
}


#pragma mark - api request delegate

- (void)request:(SMAPIRequest *)req completedWithResult:(NSDictionary *)result {
    
}

- (void)serverNotReachable {
    SMNetworkErrorView * v = [SMNetworkErrorView getFromNib];
    CGRect frame = v.frame;
    frame.origin.x = roundf((self.view.frame.size.width - v.frame.size.width) / 2.0f);
    frame.origin.y = roundf((self.view.frame.size.height - v.frame.size.height) / 2.0f);
    [v setFrame: frame];
    [v setAlpha:0.0f];
    [self.view addSubview:v];
    [UIView animateWithDuration:ERROR_FADE animations:^{
        v.alpha = 1.0f;
    } completion:^(BOOL finished) {
        [UIView animateWithDuration:ERROR_FADE delay:ERROR_WAIT options:UIViewAnimationOptionBeginFromCurrentState animations:^{
            v.alpha = 0.0f;
        } completion:^(BOOL finished) {
            [v removeFromSuperview];
        }];
    }];
}


#pragma mark - UIStatusBarStyle

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleDefault;
}

@end
