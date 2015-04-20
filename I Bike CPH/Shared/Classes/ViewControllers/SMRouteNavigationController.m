//
//  SMRouteNavigationController.m
//  I Bike CPH
//
//  Created by Ivan Pavlovic on 29/01/2013.
//  Copyright (c) 2013 City of Copenhagen. All rights reserved.
//

#import "SMRouteNavigationController.h"

#import "RMMapView.h"
#import "RMShape.h"
#import "RMPath.h"
#import "RMMarker.h"
#import "RMAnnotation.h"
#import "RMUserLocation.h"

#import "SMiBikeCPHMapTileSource.h"
#import "RMOpenStreetMapSource.h"

#import "SMLocationManager.h"

#import "SMTurnInstruction.h"
#import "SMRoute.h"
#import "SMDirectionCell.h"
#import "SMDirectionTopCell.h"
#import "SMReportErrorController.h"
#import "PSTAlertController.h"

#import "SMUtil.h"
#import "SMRouteUtils.h"

#import "SMAnnotation.h"
#import "SMSwipableView.h"

#import "SMDirectionsFooter.h"
#import "SMSearchHistory.h"
#import "SMRouteTypeSelectCell.h"


#import "SMTransportation.h"
#import "SMGeocoder.h"
#import "SMMapManager.h"
#include "float.h"

#if defined(CYKEL_PLANEN)
#import "SMTripRoute.h"
#import "SMBreakRouteViewController.h"
#import "SMMapOverlays.h"
#endif

static NSString *const neCoordinate = @"neCoordinate";
static NSString *const swCoordinate = @"swCoordinate";

typedef enum {
    directionsFullscreen,
    directionsNormal,
    directionsMini,
    directionsHidden
} DirectionsState;

@interface SMRouteNavigationController () <RouteTypeHandlerDelegateObjc> {
    DirectionsState currentDirectionsState;
    CGFloat lastDirectionsPos;
    CGFloat touchOffset;
    BOOL overviewShown;
    RMUserTrackingMode oldTrackingMode;
    BOOL shouldShowOverview;

#if defined(CYKEL_PLANEN)
    SMRoute *fullRoute;
    SMRoute *nextRoute;
    SMTripRoute *tempTripRoute;
    SMRoute *tempRoute;
#endif
}
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *instructionHeightConstraint;

@property (nonatomic, strong) SMRoute *route;
#if defined(CYKEL_PLANEN)
@property (nonatomic, strong) SMTripRoute *brokenRoute;
#endif
@property (nonatomic, strong) IBOutlet RMMapView * mapView;
@property int directionsShownCount; // How many directions are shown in the directions table at the moment:
                                    // -1 means no direction is shown and minimized directions view is not shown (this happens before first call to showDirections())
                                    // 0 means no direction is shown and minimized directions view is shown
                                    // > 3 means directions table is maximized
@property (nonatomic, strong) NSMutableSet * recycledItems;
@property (nonatomic, strong) NSMutableSet * activeItems;
@property (nonatomic, strong) NSArray * instructionsForScrollview;
@property BOOL pulling;
@property (nonatomic, strong) NSString * osrmServer;

@property BOOL pathVisible;

@end

@implementation SMRouteNavigationController

#define MAX_SEGMENTS 1
#define MAX_TABLE 80.0f

#define keyZIndex @"keyZIndex"
#define MAP_LEVEL_STATIONS 80
#define MAP_LEVEL_METRO 80
#define MAP_LEVEL_SERVICES 80

- (void)viewDidLoad {
    [super viewDidLoad];

#if defined(CYKEL_PLANEN)
    [breakRouteButton.imageView setContentMode:UIViewContentModeScaleAspectFill];
#else 
    breakRouteButton.hidden = YES;
#endif
    
    self.osrmServer = [RouteTypeHandler sharedInstance].server;
    
    self.pulling = NO;

    self.recycledItems = [NSMutableSet set];
    self.activeItems = [NSMutableSet set];
    [instructionsView setBackgroundColor:[UIColor colorWithPatternImage:[UIImage imageNamed:@"tableViewBG"]]];
    self.updateSwipableView = YES;
    
    self.currentlyRouting = NO;
    overviewShown = NO;
    self.directionsShownCount = -1;

    [SMLocationManager instance];

    self.mapView.contentScaleFactor = 0.5;
    self.mapView.tileSource = TILE_SOURCE;
    self.mapView.delegate = self;
    self.mapView.maxZoom = MAX_MAP_ZOOM;
    self.mapView.triggerUpdateOnHeadingChange = NO;
    self.mapView.displayHeadingCalibration = NO;
    self.mapView.enableBouncing = YES;
    self.mapView.routingDelegate = nil;
    self.mapView.userTrackingMode = RMUserTrackingModeFollow;
    self.mapView.showsUserLocation = YES;
    
    [self setDirectionsState:directionsHidden];
    
    labelTimeLeft.text = @"";
    labelDistanceLeft.text = @"";
    
    SMDirectionsFooter * v = [SMDirectionsFooter getFromNib];
    [v.label setText:@"ride_report_a_problem".localized];
    [v setDelegate:self];
    [tblDirections setTableFooterView:v];
    
    if (self.startLocation && self.endLocation) {
        [self start:self.startLocation.coordinate end:self.endLocation.coordinate withJSON:self.jsonRoot];
    }
    
    self.pathVisible = YES;
    
#if defined(CYKEL_PLANEN)
    // Setup map overlays
    if (self.appDelegate.mapOverlays == nil) {
        self.appDelegate.mapOverlays = [[SMMapOverlays alloc] initWithMapView:self.mapView];
    }
    [self.appDelegate.mapOverlays useMapView:self.mapView];
    [self.appDelegate.mapOverlays loadMarkers];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onStationsFetched:) name:NOTIFICATION_STATIONS_FETCHED object:nil];
#endif
}

-(void)onStationsFetched:(NSNotification*)notification{}

    
- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self.navigationController setNavigationBarHidden:YES animated:YES];
    
#if defined(CYKEL_PLANEN)
    if([SMUser user].route){
        self.route = [SMUser user].route;
        self.startLocation = [self.route getStartLocation];
        self.endLocation = [self.route getEndLocation];
    }
    
    if ([SMUser user].tripRoute) {
        self.brokenRoute = [SMUser user].tripRoute;
    }
#endif
    
    if (self.startLocation && self.endLocation) {
        [self start:self.startLocation.coordinate end:self.endLocation.coordinate withJSON:self.jsonRoot];
    }
    [self.mapView addObserver:self forKeyPath:@"userTrackingMode" options:0 context:nil];
    [self.mapView addObserver:self forKeyPath:@"zoom" options:0 context:nil];
    [self addObserver:self forKeyPath:@"currentlyRouting" options:0 context:nil];
    [swipableView addObserver:self forKeyPath:@"hidden" options:0 context:nil];
   
    [self.mapView rotateMap:0.0];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [tblDirections reloadData];
    if (self.currentlyRouting) {
        [UIApplication sharedApplication].idleTimerDisabled = YES;
    } else {
        [UIApplication sharedApplication].idleTimerDisabled = NO;
    }
}


- (void)viewWillDisappear:(BOOL)animated {
    [self.navigationController setNavigationBarHidden:NO animated:YES];
    
    [UIApplication sharedApplication].idleTimerDisabled = NO;
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self removeObserver:self forKeyPath:@"currentlyRouting" context:nil];
    [swipableView removeObserver:self forKeyPath:@"hidden" context:nil];
    [self.mapView removeObserver:self forKeyPath:@"userTrackingMode" context:nil];
    [self.mapView removeObserver:self forKeyPath:@"zoom" context:nil];
    [super viewWillDisappear:animated];
}

- (void)dealloc {
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark - Route

#if defined(CYKEL_PLANEN)
-(void)removeAllMarkers{
    [self hideRouteAnnotation];   
}

-(void)toggleMarkers{
    if (self.pathVisible) {
        [self showRouteAnnotation];
    } else {
        [self hideRouteAnnotation];
    }
}
#endif

#pragma mark - custom methods

#define LATITUDE_PADDING 0.25f
#define LONGITUDE_PADDING 0.10f

- (void)showRouteOverview {
    oldTrackingMode = RMUserTrackingModeNone;
    [self setDirectionsState:directionsHidden];
    [self.mapView rotateMap:0];
#if defined(CYKEL_PLANEN)
    [self hideRouteAnnotation];
#else
    for (RMAnnotation *annotation in self.mapView.annotations) {
        if ([annotation.annotationType isEqualToString:@"path"]) {
            [self.mapView removeAnnotation:annotation];
        }
    }
#endif
    routeOverview.hidden = NO;
    [UIView animateWithDuration:0.4f delay:0.0f options:UIViewAnimationOptionBeginFromCurrentState animations:^{
        routeOverview.alpha = 1.0f;
    } completion:^(BOOL finished) {
        
    }];
    overviewShown = YES;
    self.currentlyRouting = NO;
    
    /**
     * hide this if time should not be shown
     */
    progressView.hidden = YES;
    labelDistanceLeft.text = formatDistance(self.route.estimatedRouteDistance);
    labelTimeLeft.text = expectedArrivalTime(self.route.estimatedTimeForRoute);
    /**
     * end hide
     */
    
    [self setDirectionsState:directionsNormal];
    // Display new path
#if defined(CYKEL_PLANEN)  
    NSDictionary *coordinates = [self showRouteAnnotation];
#else
    NSDictionary *coordinates = [self addRouteAnnotation:self.route];
#endif
    self.mapView.routingDelegate = self;
    [tblDirections reloadData];
    
    [self reloadSwipableView];
    
    overviewTimeDistance.text = [NSString stringWithFormat:@"%@, %0.f min, via %@", formatDistance(self.route.estimatedRouteDistance), ceilf(self.route.estimatedTimeForRoute / 60.0f), self.route.longestStreet];
    
    NSArray *a = [self.destination componentsSeparatedByString:@","];
    NSString *streetName = a[0];
    overviewDestination.lineBreakMode = NSLineBreakByCharWrapping;
    overviewDestinationBottom.lineBreakMode = NSLineBreakByWordWrapping;
    
    
    overviewDestination.text = nil;
    overviewDestinationBottom.text = nil;
    if(streetName) {
        NSArray *splittedString = [self splitString:streetName];
        
        overviewDestination.text = splittedString[0];
        
        if (splittedString.count > 1) {
            overviewDestinationBottom.text = splittedString[1];
        }
    }
    
    self.automaticallyAdjustsScrollViewInsets = NO;
    
    [self zoomOut:coordinates];
    
    //[self performSelector:@selector(zoomOut:) withObject:coordinates afterDelay:1.0f];
    
    if (![SMAnalytics trackEventWithCategory:@"Route" withAction:@"Overview" withLabel:self.destination withValue:0]) {
        debugLog(@"error in trackEvent");
    }
    
    self.mapView.userTrackingMode = RMUserTrackingModeNone;
}

- (void)zoomOut:(NSDictionary*)coordinates {
    CLLocationCoordinate2D ne = ((CLLocation*)[coordinates objectForKey:neCoordinate]).coordinate;
    CLLocationCoordinate2D sw = ((CLLocation*)[coordinates objectForKey:swCoordinate]).coordinate;
    
    float latDiff = (ne.latitude - sw.latitude);
    float lonDiff = (ne.longitude - sw.longitude);
    
    //TODO: check if start or end are in top-left or bottom-right corrner (18%)
    // if so, move them a little bit more inside so they dont fell under buttons
    float borderCheck = 0.18f;
    
    
    BOOL topLeftObscured =(
                           (ne.latitude - self.route.locationStart.latitude < borderCheck*latDiff &&  self.route.locationStart.longitude - sw.longitude < borderCheck*lonDiff) ||
                           (ne.latitude - self.route.locationEnd.latitude < borderCheck*latDiff &&  self.route.locationEnd.longitude - sw.longitude < borderCheck*lonDiff)
                           );
    
    BOOL bottomRightObscured =(
                               (self.route.locationStart.latitude - sw.latitude < borderCheck*latDiff && ne.longitude - self.route.locationStart.longitude < borderCheck*lonDiff) ||
                               (self.route.locationStart.latitude - sw.latitude < borderCheck*latDiff && ne.longitude - self.route.locationStart.longitude < borderCheck*lonDiff)
                               );
    
    if(topLeftObscured) {
        ne.latitude +=  latDiff * borderCheck;
        sw.longitude -= lonDiff * borderCheck;
    }
    
    if(bottomRightObscured){
        ne.longitude += lonDiff * borderCheck;
        sw.latitude -= latDiff * borderCheck;
    }
    
    /////////////////////////////////////////
    
    
    ne.latitude +=  latDiff * LATITUDE_PADDING * 1.75f;
    ne.longitude += lonDiff * LONGITUDE_PADDING;
    
    sw.latitude -= latDiff * LATITUDE_PADDING;
    sw.longitude -= lonDiff * LONGITUDE_PADDING;
    
    
    [self.mapView setCenterCoordinate:CLLocationCoordinate2DMake((ne.latitude+sw.latitude) / 2.0, (ne.longitude+sw.longitude) / 2.0)];
    [self.mapView zoomWithLatitudeLongitudeBoundsSouthWest:sw northEast:ne animated:YES];
}

- (NSArray *)splitString:(NSString *)str {
    // split into words
    NSMutableArray* words= [[NSMutableArray alloc] initWithArray:[str componentsSeparatedByCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@" "]]];
    NSString* base= [words objectAtIndex:0];
    int splitWordIndex= -1;
    
    if(![self string:base fitsLabelWidth:overviewDestination] ){
        splitWordIndex= 0;
    }else{
        NSString* newStr= [NSString stringWithString:base];
        for(int i=1; i<words.count; i++){
            // append the next word
            NSString* newWord= [words objectAtIndex:i];
            newStr= [newStr stringByAppendingFormat:@" %@",newWord];
            
            // check if it fits the first line
            if(![self string:newStr fitsLabelWidth:overviewDestination]){
                splitWordIndex= i;
                break;
            }
        }
    }

    if(splitWordIndex==-1){
        // everything can fit the single line
        return [NSArray arrayWithObject:str];
    }
    
    NSString* newWord= [words objectAtIndex:splitWordIndex];
    NSString* newStr= [NSString stringWithString:base];
    for(int i=1; i<=splitWordIndex; i++){
        newStr= [newStr stringByAppendingFormat:@" %@",[words objectAtIndex:i]];
    }

    // get the index where the string should be clipped
    NSInteger clipIndex= [self fitString:newStr intoLabel:overviewDestination size:overviewDestination.frame.size];
    NSInteger index= (splitWordIndex==0)?clipIndex : newWord.length-(newStr.length-clipIndex);
    
    BOOL noSplit= NO;
    if ([self isStringSplittable:newWord atIndex:index]) {
        [words replaceObjectAtIndex:splitWordIndex withObject:[self splitString:newWord lastCharacterIndex:index]];
    }else{
        noSplit= YES;
    }

    NSString* topString= @"";
    NSString* bottomString= @"";
    NSString* hyphenedString= [words objectAtIndex:splitWordIndex];
    int toIndex= splitWordIndex;
    int fromIndex= splitWordIndex+1;
    if(noSplit){
        fromIndex--;
    }
    for(int i=0; i<toIndex; i++){
        topString= [topString stringByAppendingFormat:@"%@%@",[words objectAtIndex:i],(i==toIndex-1)?@"":@" "];
    }

    NSRange range= [hyphenedString rangeOfCharacterFromSet:[NSCharacterSet characterSetWithCharactersInString:@"-"]];
    if(!noSplit && range.location != NSNotFound){
        topString= [topString stringByAppendingString:[hyphenedString substringToIndex:range.location+1]];
        bottomString= [bottomString stringByAppendingFormat:@"%@ ",[hyphenedString substringFromIndex:range.location+1]];
    }
    
    for(int i=fromIndex; i<words.count; i++){
        bottomString= [bottomString stringByAppendingFormat:@"%@%@",[words objectAtIndex:i],( i==words.count-1)?@"":@" "];
    }
    NSArray* arr= [NSArray arrayWithObjects:topString, bottomString, nil];
    
    return arr;
}

- (BOOL)isStringSplittable:(NSString *)str atIndex:(NSInteger)index {
    BOOL breakable= NO;
    if(str.length>1 && index<str.length)
        while (index>0) {
            NSString* subStr= [str substringWithRange:NSMakeRange(index, 1)];
            // don't check for vowels if the substring is nil
            if(!subStr)
                continue;
            // check if the substring ends with a vowel
            if( ![self isVowel:subStr]){
                breakable= YES;
                break;
            }
        index--;
        }
    return breakable && str.length>=4 && index>0 && index<str.length-2;
}
- (BOOL)string:(NSString *)str fitsLabelWidth:(UILabel *)lbl {
    return [str sizeWithFont:lbl.font].width <= lbl.frame.size.width;
}

- (NSString *)splitString:(NSString *)str lastCharacterIndex:(NSInteger)index{
    NSMutableString *newStr = [NSMutableString stringWithString:str];
    
    if (index<0) {
        return nil;
    }
    for(NSInteger i = index; i>0; i--){
        NSString* subStr= [str substringWithRange:NSMakeRange(i, 1)];
        // don't check for vowels if the substring is nil
        if(!subStr)
            continue;
        // check if the substring ends with a vowel
        if( ![self isVowel:subStr]){
            // if not, we split the string at the index
            [newStr insertString:@"-" atIndex:i+1];

            return newStr;
        }
    }
    
    [newStr insertString:@"-" atIndex:index+1];
    return newStr;
}

-(BOOL)isVowel:(NSString*)chr{
    if(!chr)
        return NO;
    return [chr isEqualToString:@"a"] || [chr isEqualToString:@"e"] || [chr isEqualToString:@"i"] || [chr isEqualToString:@"o"] || [chr isEqualToString:@"u"] || [chr isEqualToString:@"æ"] || [chr isEqualToString:@"ø"] || [chr isEqualToString:@"å"];

}

- (NSUInteger)fitString:(NSString *)string intoLabel:(UILabel *)label size:(CGSize)size
{
    UIFont *font = label.font;

    CGSize sizeForString= [string sizeWithFont:font];
    if (sizeForString.width >= size.width-1) // sizeWithFont rounding
    {
        NSString *adjustedString;
        
        for (NSUInteger i = 1; i < [string length]; i++)
        {
            adjustedString = [[string substringToIndex:i] stringByAppendingFormat:@"-"];
            CGSize sizeWithFont = [adjustedString sizeWithFont:font];
            if (sizeWithFont.width >= size.width-1)
                return i - 1;
        }
    }
    
    return [string length];
}

#if defined(CYKEL_PLANEN)
- (IBAction)onBreakRoute:(id)sender {

    if ([SMLocationManager instance].hasValidLocation == NO) {
        UIAlertView * av = [[UIAlertView alloc] initWithTitle:nil message:@"error_no_gps_location".localized delegate:nil cancelButtonTitle:@"OK".localized otherButtonTitles:nil];
        [av show];
        return;
    } else {
        if (self.currentlyRouting) {
            // get current location
            CLLocation *currentLocation = [[SMLocationManager instance] lastValidLocation];
            // get new route ( currentPosition -> destination )
            tempRoute = [[SMRoute alloc] initWithRouteStart:currentLocation.coordinate andEnd:[fullRoute getEndLocation].coordinate andDelegate:self];
            // create a trip route
            tempTripRoute = [[SMTripRoute alloc] initWithRoute:tempRoute];
        } else {
            [self performSegueWithIdentifier:@"breakRoute" sender:self];            
        }
    }
}
#endif

- (IBAction)startRouting:(id)sender {
    if ([SMLocationManager instance].hasValidLocation == NO) {
        UIAlertView * av = [[UIAlertView alloc] initWithTitle:nil message:@"error_no_gps_location".localized delegate:nil cancelButtonTitle:@"OK".localized otherButtonTitles:nil];
        [av show];
        return;
    }else{
        [self startRouting];
    }
}

- (void)addMarkers:(NSArray*)markers {
    for (int i=0; i<[markers count]; i++) {
        NSDictionary *marker = markers[i];
        
        double latitude = [(NSNumber *)marker[@"latitude"] doubleValue];
        double longitude = [(NSNumber *)marker[@"longitude"] doubleValue];
        CLLocationCoordinate2D coord = CLLocationCoordinate2DMake(latitude, longitude);
        
        NSString *title = marker[@"title"];
        NSString *image = marker[@"imageName"];
        NSString *annotation = marker[@"annotation"];
        NSString *alternateTitle = marker[@"alternateTitle"];
        
        [self addMarkerToMapView:self.mapView withCoordinate:coord title:title imageName:image annotationTitle:annotation alternateTitle:alternateTitle];
    }
}

- (void)startRouting {
#if defined(CYKEL_PLANEN)
    
    fullRoute = self.route;
    fullRoute.delegate = nil;
    NSAssert(self.brokenRoute.brokenRoutes.count>0, @"Invalid routes.");
    self.route = [self.brokenRoute.brokenRoutes objectAtIndex:0];
#endif
    
    overviewShown = NO;
    
    self.route.delegate= self;
    
    routeOverview.hidden = YES;
    
    self.currentlyRouting = YES;
    [self resetZoom];
    [self.mapView setCenterCoordinate:CLLocationCoordinate2DMake(self.route.locationStart.latitude,self.route.locationStart.longitude)];
    [labelDistanceLeft setText:formatDistance(self.route.estimatedRouteDistance)];
    [labelTimeLeft setText:expectedArrivalTime(self.route.estimatedTimeForRoute)];

    [self.mapView setUserTrackingMode:RMUserTrackingModeFollowWithHeading];
    [self.mapView rotateMap:self.route.lastCorrectedHeading];

    [self renderMinimizedDirectionsViewFromInstruction];
    CGRect frame = self.mapFade.frame;
    frame.size.height = 0.0f;
    self.mapFade.frame = frame;
    
    [recalculatingView setAlpha:1.0f];
    [UIView animateWithDuration:0.3f animations:^{
        [recalculatingView setAlpha:0.0f];
    }];
    if (![SMAnalytics trackEventWithCategory:@"Route" withAction:@"Start" withLabel:self.destination withValue:0]) {
        debugLog(@"error in trackEvent");
    }
    self.mapFade.alpha= 0;
}

- (void)newRouteType {
    oldTrackingMode = RMUserTrackingModeNone;
    [self.mapView setUserTrackingMode:RMUserTrackingModeNone];
    self.route.delegate = nil;
    self.route = nil;
    self.mapView.delegate = nil;
    SMRequestOSRM * r = [[SMRequestOSRM alloc] initWithDelegate:self];
    [r setAuxParam:@"startRoute"];
    [r setOsrmServer:self.osrmServer];
    [r getRouteFrom:self.startLocation.coordinate to:self.endLocation.coordinate via:nil];
    CGRect fr = self.mapFade.frame;
    fr.size.height = 0.0f;
    self.mapFade.frame = fr;
}

- (void)start:(CLLocationCoordinate2D)from end:(CLLocationCoordinate2D)to  withJSON:(id)jsonRoot{
    
    if (self.mapView.delegate == nil) {
        self.mapView.delegate = self;
    }
    
    for (RMAnnotation *annotation in self.mapView.annotations) {
        [self.mapView removeAnnotation:annotation];
    }
    
#if defined(CYKEL_PLANEN)
    if(!self.route){

        if([SMUser user].route){
            self.route= [[SMUser user] route];
        } else {
            self.route = [[SMRoute alloc] initWithRouteStart:from andEnd:to andDelegate:self andJSON:jsonRoot];
            self.route.osrmServer = self.osrmServer;
        }
    }
    if (!self.brokenRoute) {
        self.brokenRoute = [[SMTripRoute alloc] initWithRoute:self.route];
    }
    if (!self.route) {
        return;
    }
    
    // station markers
    for (int i=0; i<self.brokenRoute.brokenRoutes.count; i++) {
        SMRoute *route= [self.brokenRoute.brokenRoutes objectAtIndex:i];
        NSArray *locations;
        if (i==0 && i!=self.brokenRoute.brokenRoutes.count-1){
            // first route, display only destination
            locations= @[route.getEndLocation];
        } else if(i!=0 && i==self.brokenRoute.brokenRoutes.count-1) {
            // last route, display only source
            locations= @[route.getStartLocation];
        } else if(i!=0 && i!=self.brokenRoute.brokenRoutes.count-1) {
            locations= @[route.getStartLocation, route.getEndLocation];
        }
        
        if (locations) {
            for (CLLocation * loc in locations){
                [self addMarkerToMapView:self.mapView withCoordinate:CLLocationCoordinate2DMake(loc.coordinate.latitude, loc.coordinate.longitude) title:@"S" imageName:@"metro_icon" annotationTitle:nil alternateTitle:nil];
            }
        }
    }
    
    // start marker (A)
    NSMutableArray *arr = [[self.source componentsSeparatedByString:@","] mutableCopy];
    NSString *startTitle = [[arr objectAtIndex:0] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    [arr removeObjectAtIndex:0];
    [self addMarkerToMapView:self.mapView withCoordinate:from title:@"A" imageName:@"a_pin" annotationTitle:startTitle alternateTitle:@"marker_start".localized];
    
    // end marker (B)
    arr = [[self.destination componentsSeparatedByString:@","] mutableCopy];
    NSString *endTitle = [arr[0] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    [arr removeObjectAtIndex:0];
    [self addMarkerToMapView:self.mapView withCoordinate:to title:@"B" imageName:@"b_pin" annotationTitle:endTitle alternateTitle:nil];

#else

    self.route = [[SMRoute alloc] initWithRouteStart:from andEnd:to andDelegate:self andJSON:jsonRoot];
    self.route.osrmServer = self.osrmServer;
    if (!self.route) {
        return;
    }
    
    SMAnnotation *startMarkerAnnotation = [SMAnnotation annotationWithMapView:self.mapView coordinate:from andTitle:@"A"]; /// START
    startMarkerAnnotation.annotationType = @"marker";
    startMarkerAnnotation.annotationIcon = [UIImage imageNamed:@"markerStart"];
    startMarkerAnnotation.anchorPoint = CGPointMake(0.5, 1.0);
    NSMutableArray * arr = [[self.source componentsSeparatedByString:@","] mutableCopy];
    startMarkerAnnotation.title = [[arr objectAtIndex:0] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if ([startMarkerAnnotation.title isEqualToString:@""]) {
        startMarkerAnnotation.title = @"marker_start".localized;
    }
    [arr removeObjectAtIndex:0];
    startMarkerAnnotation.subtitle = [[arr componentsJoinedByString:@","] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    [self.mapView addAnnotation:startMarkerAnnotation];
    
    SMAnnotation *endMarkerAnnotation = [SMAnnotation annotationWithMapView:self.mapView coordinate:to andTitle:@"B"];
    endMarkerAnnotation.annotationType = @"marker";
    endMarkerAnnotation.annotationIcon = [UIImage imageNamed:@"markerFinish"];
    endMarkerAnnotation.anchorPoint = CGPointMake(0.5, 1.0);
    arr = [[self.destination componentsSeparatedByString:@","] mutableCopy];
    endMarkerAnnotation.title = [[arr objectAtIndex:0] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    [arr removeObjectAtIndex:0];
    endMarkerAnnotation.subtitle = [[arr componentsJoinedByString:@","] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    [self.mapView addAnnotation:endMarkerAnnotation];
#endif

    [self.mapView setCenterCoordinate:CLLocationCoordinate2DMake(from.latitude,from.longitude)];
    
    [self showRouteOverview];
}

- (void)addMarkerToMapView:(RMMapView *)mapView withCoordinate:(CLLocationCoordinate2D)coord title:(NSString *)title imageName:(NSString *)imageName annotationTitle:(NSString*)annotationTitle alternateTitle:(NSString *)alternateTitle {
    SMAnnotation *annotation = [SMAnnotation annotationWithMapView:mapView coordinate:coord andTitle:title];
    annotation.annotationType = @"marker";
    annotation.annotationIcon = [UIImage imageNamed:imageName];
    annotation.anchorPoint = CGPointMake(0.5, 1.0);
    NSMutableArray *arr = [self.source componentsSeparatedByString:@","].mutableCopy;
    annotation.title = annotationTitle;

    if ([annotation.title isEqualToString:@""] && alternateTitle) {
        annotation.title = alternateTitle;
    }

    annotation.subtitle = [[arr componentsJoinedByString:@","] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    [self.mapView addAnnotation:annotation];
}

- (void) renderMinimizedDirectionsViewFromInstruction {
    if (self.route.turnInstructions.count > 0) {
        SMTurnInstruction *nextTurn = [self.route.turnInstructions objectAtIndex:0];
        [labelDistanceToNextTurn setText:formatDistance(nextTurn.lengthInMeters)];
        imgNextTurnDirection.image = nextTurn.directionIcon;
    } else {
        [minimizedInstructionsView setHidden:YES];
    }
}

- (NSDictionary *)addRouteAnnotation:(SMRoute *)route {
    return [self addRouteAnnotation:route lineColor:[Styler tintColor]];
}

- (NSDictionary *)addRouteAnnotation:(SMRoute *)route lineColor:(UIColor *)color {
    RMAnnotation *calculatedPathAnnotation = [RMAnnotation annotationWithMapView:self.mapView coordinate:[route getStartLocation].coordinate andTitle:nil];
    calculatedPathAnnotation.annotationType = @"path";
    calculatedPathAnnotation.userInfo = @{
                                         @"linePoints" : [NSArray arrayWithArray:route.waypoints],
                                         @"lineColor" : color,
                                         @"fillColor" : [UIColor clearColor],
                                         @"lineWidth" : [NSNumber numberWithFloat:10.0f],
                                         };
    [calculatedPathAnnotation setBoundingBoxFromLocations:[NSArray arrayWithArray:route.waypoints]];
    [self.mapView addAnnotation:calculatedPathAnnotation];
    return @{
             neCoordinate : calculatedPathAnnotation.neCoordinate,
             swCoordinate : calculatedPathAnnotation.swCoordinate
             };
}

#if defined(CYKEL_PLANEN)
- (NSDictionary *)showRouteAnnotation {
    for (SMRoute *route in self.brokenRoute.brokenRoutes) {
        if (route.routeType == SMRouteTypeNormal) {
            [self addRouteAnnotation:route];
        }
        if (route.routeType == SMRouteTypeTransport) {
            [self addRouteAnnotation:route lineColor:[[Styler tintColor] colorWithAlphaComponent:0.3]];
        }
    }
    
    // Bounding box from full route
    RMAnnotation *calculatedPathAnnotation = [RMAnnotation annotationWithMapView:self.mapView coordinate:self.brokenRoute.fullRoute.getStartLocation.coordinate andTitle:nil];
    [calculatedPathAnnotation setBoundingBoxFromLocations:[NSArray arrayWithArray:self.brokenRoute.fullRoute.waypoints]];
    return @{
             neCoordinate : calculatedPathAnnotation.neCoordinate,
             swCoordinate : calculatedPathAnnotation.swCoordinate
             };
}

- (void)hideRouteAnnotation {
    for (RMAnnotation* annotation in self.mapView.annotations) {
        if ([annotation.annotationType isEqual:@"path"]) {
            [self.mapView removeAnnotation:annotation];
        }
    }
}
#endif

- (void)resetZoom {
    [self.mapView setZoom:DEFAULT_MAP_ZOOM];
    [self.mapView zoomByFactor:1 near:[self.mapView coordinateToPixel:[SMLocationManager instance].lastValidLocation.coordinate] animated:YES];
}

- (void)zoomToLocation:(CLLocation*)loc temporary:(BOOL)isTemp {
    [self.mapView setUserTrackingMode:RMUserTrackingModeNone];
    [self.mapView setCenterCoordinate:loc.coordinate];
    
    if (buttonTrackUser.gpsTrackState != SMGPSTrackButtonStateNotFollowing) {
        [buttonTrackUser newGpsTrackState:SMGPSTrackButtonStateNotFollowing];
        if (isTemp) {
            [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(resetZoomTurn) object:nil];
            [self performSelector:@selector(resetZoomTurn) withObject:nil afterDelay:ZOOM_TO_TURN_DURATION];
        }
    }
}

- (void)saveRoute {
    if (self.route && self.route.visitedLocations && ([self.route.visitedLocations count] > 0)) {
        NSDictionary *dt = [self.route save];
        NSData * data = dt[@"data"];
        NSDictionary * d = @{
                             @"startDate" : [NSKeyedArchiver archivedDataWithRootObject:((CLLocation *)self.route.visitedLocations.firstObject).timestamp],
                             @"endDate" : [NSKeyedArchiver archivedDataWithRootObject:((CLLocation *)self.route.visitedLocations.lastObject).timestamp],
                             @"visitedLocations" : data,
                             @"fromName" : self.source,
                             @"toName" : self.destination,
                             @"fromLocation" : [NSKeyedArchiver archivedDataWithRootObject:self.startLocation],
                             @"toLocation" : [NSKeyedArchiver archivedDataWithRootObject:self.endLocation]
                             };
        BOOL x = [d writeToFile:[SMRouteUtils routeFilenameFromTimestampForExtension:@"plist"] atomically:YES];
        if (x == NO) {
            NSLog(@"Route not saved!");
        }
        
        if ([self.appDelegate.appSettings objectForKey:@"auth_token"]) {
            SMSearchHistory * sh = [SMSearchHistory instance];
            [sh addFinishedRouteToServer:@{
                 @"startDate" : ((CLLocation *)self.route.visitedLocations.firstObject).timestamp,
                 @"endDate" : ((CLLocation *)self.route.visitedLocations.lastObject).timestamp,
                 @"visitedLocations" : dt[@"polyline"],
                 @"fromName" : self.source,
                 @"toName" : self.destination,
                 @"fromLocation" : self.startLocation,
                 @"toLocation" : self.endLocation
             }];
        }
    }
}

#if defined(CYKEL_PLANEN)
- (void)saveRoute:(SMTripRoute *)pRoute {
    NSMutableArray* routesArr = [NSMutableArray new];
    BOOL shouldSaveRoute= NO;
    for(SMRoute *iRoute in pRoute.brokenRoutes){
        if(iRoute.visitedLocations && iRoute.visitedLocations.count>0){
            shouldSaveRoute= YES;
            break;
        }
    }
    
    for(SMRoute* iRoute in pRoute.brokenRoutes){
        if (shouldSaveRoute) {
            NSDictionary *dt = [iRoute save];
            NSData * data = [dt objectForKey:@"data"];
            NSDictionary * d = @{
                                 @"startDate" : [NSKeyedArchiver archivedDataWithRootObject:[[iRoute.visitedLocations objectAtIndex:0] objectForKey:@"date"]],
                                 @"endDate" : [NSKeyedArchiver archivedDataWithRootObject:[[iRoute.visitedLocations lastObject] objectForKey:@"date"]],
                                 @"visitedLocations" : data,
                                 @"fromName" : self.source,
                                 @"toName" : self.destination,
                                 @"fromLocation" : [NSKeyedArchiver archivedDataWithRootObject:self.startLocation],
                                 @"toLocation" : [NSKeyedArchiver archivedDataWithRootObject:self.endLocation]
                                 };
            [routesArr addObject:d];
        }
    }
    
    if(routesArr.count>0){
        BOOL x = [routesArr writeToFile:[SMRouteUtils routeFilenameFromTimestampForExtension:@"plist"] atomically:YES];
        if (x == NO) {
            NSLog(@"Route not saved!");
        }
    }
}
#endif

#pragma mark - mapView delegate

- (void)checkCallouts {
    for (SMAnnotation * annotation in self.mapView.annotations) {
        if ([annotation.annotationType isEqualToString:@"station"] && [annotation isKindOfClass:[SMAnnotation class]]) {
            if (annotation.calloutShown) {
                [annotation showCallout];
            }
        }
        if ([annotation.annotationType isEqualToString:@"marker"] && [annotation isKindOfClass:[SMAnnotation class]]) {
            if (annotation.calloutShown) {
                [annotation showCallout];
            }
        }
    }
}

- (void)mapViewRegionDidChange:(RMMapView *)mapView {

    float t = MAX((mapView.zoom / 10.0) - 1.0, 0.0)*2.0;
    // lerp(1.5, 0.35, t)
    float zoom = (1.0-t)*0.35 + t*1.5;

    for (SMAnnotation* an in mapView.annotations) {
        if ([an.annotationType isEqualToString:@"station"]) {
            if (an.layer) {
                RMMarker* marker = (RMMarker*)(an.layer);
                [marker updateBoundsWithZoom: zoom];
            }
        }
    }
    
    [self checkCallouts];
}

- (void)tapOnAnnotation:(SMAnnotation *)annotation onMap:(RMMapView *)map {
    if ([annotation.annotationType isEqualToString:@"marker"]) {
        for (id v in self.mapView.subviews) {
            if ([v isKindOfClass:[SMCalloutView class]]) {
                [v removeFromSuperview];
            }
        }
        
        if ([annotation calloutShown]) {
            [annotation hideCallout];
        } else {
            [annotation showCallout];
        }
    }
    if ( [annotation.annotationType isEqualToString:@"station"]) {
        [annotation showCallout];
        for (id v in self.mapView.subviews) {
            if ([v isKindOfClass:[SMCalloutView class]]) {
                [v removeFromSuperview];
            }
        }
    }
}

- (RMMapLayer *)mapView:(RMMapView *)aMapView layerForAnnotation:(RMAnnotation *)annotation {
    if ([annotation.annotationType isEqualToString:@"path"]) {
//        RMPath * path = [[RMPath alloc] initWithView:aMapView];
        RMShape *path = [[RMShape alloc] initWithView:aMapView];
        [path setZPosition:-MAXFLOAT];
        [path setLineColor:annotation.userInfo[@"lineColor"]];
        [path setOpacity:PATH_OPACITY];
        [path setFillColor:annotation.userInfo[@"fillColor"]];
        [path setLineWidth:[annotation.userInfo[@"lineWidth"] floatValue]];
        path.scaleLineWidth = NO;

        if ([annotation.userInfo[@"closePath"] boolValue])
            [path closePath];

        @synchronized(annotation.userInfo[@"linePoints"]) {
            for (CLLocation *location in annotation.userInfo[@"linePoints"]) {
                [path addLineToCoordinate:location.coordinate];
            }
        }

        return path;
    }
    
    if ([annotation.annotationType isEqualToString:@"line"]) {
        RMShape *line = [[RMShape alloc] initWithView:aMapView];
        [line setZPosition:-MAXFLOAT];
        [line setLineColor:annotation.userInfo[@"lineColor"]];
        [line setOpacity:PATH_OPACITY];
        [line setFillColor:annotation.userInfo[@"fillColor"]];
        [line setLineWidth:[annotation.userInfo[@"lineWidth"] floatValue]];
        line.scaleLineWidth = YES;

        CLLocation *start = annotation.userInfo[@"lineStart"];
        [line addLineToCoordinate:start.coordinate];
        CLLocation *end = annotation.userInfo[@"lineEnd"];
        [line addLineToCoordinate:end.coordinate];

        return line;
    }
    
    if ([annotation.annotationType isEqualToString:@"marker"] || [annotation.annotationType isEqualToString:@"station"]) {
        NSNumber* zIndex= [annotation.userInfo objectForKey:keyZIndex];
        int z= 100;
        if(zIndex && ![zIndex isEqual:[NSNull null]]){
            z= zIndex.intValue;
        }
        RMMarker * rm = [[RMMarker alloc] initWithUIImage:annotation.annotationIcon anchorPoint:annotation.anchorPoint];
        [rm setZPosition:z];
        return rm;
    }
    
    return nil;
}

- (void)updateData:(RMUserLocation *)userLocation {
    [self.route visitLocation:userLocation.location];
    
    [self setDirectionsState:currentDirectionsState];
    
    [self reloadFirstSwipableView];
    
    [labelDistanceLeft setText:formatDistance(self.route.distanceLeft)];
    
    CGFloat percent = 0;
    @try {
        if ((self.route.distanceLeft + self.route.tripDistance) > 0) {
            percent = self.route.tripDistance / (self.route.distanceLeft + self.route.tripDistance);
        }
    }
    @catch (NSException *exception) {
        percent = 0;
    }
    @finally {
        
    }
    
    
    CGFloat time = self.route.distanceLeft * self.route.estimatedTimeForRoute / self.route.estimatedRouteDistance;
    [labelTimeLeft setText:expectedArrivalTime(time)];
}

- (void)mapView:(RMMapView *)mapView didUpdateUserLocation:(RMUserLocation *)userLocation {
   
#if defined(CYKEL_PLANEN)
    
    if ([fullRoute getEndLocation] && [self location:userLocation.location matchesLocation:[fullRoute getEndLocation] distance:LOCATION_END_DISTANCE]){ // check if we reached the end of the route
        // we reached end
        [self reachedEndOfRoute];
        return;
    }
    
    if (self.currentlyRouting && self.route && userLocation) {
        [self.route visitLocation:userLocation.location];
        
        [self setDirectionsState:currentDirectionsState];
        
        [self reloadFirstSwipableView];
        
        [labelDistanceLeft setText:formatDistance(self.route.distanceLeft)];
        
        CGFloat percent = 0;
        @try {
            if ((self.route.distanceLeft + self.route.tripDistance) > 0) {
                percent = self.route.tripDistance / (self.route.distanceLeft + self.route.tripDistance);
            }
        }
        @catch (NSException *exception) {
            percent = 0;
        }
        
        CGFloat time = self.route.distanceLeft * self.route.estimatedTimeForRoute / self.route.estimatedRouteDistance;
        [labelTimeLeft setText:expectedArrivalTime(time)];
        
        [tblDirections reloadData];
        [self renderMinimizedDirectionsViewFromInstruction];
    } else if(nextRoute && userLocation) { // next route exists and userlocation is valid
        if([self location:[nextRoute getStartLocation] matchesLocation:userLocation.location distance:LOCATION_STATION_DISTANCE_ON_BUS] ){ // check if we reached the beginning of the next route
            NSLog(@"Next route");
            self.route= nextRoute;
            self.route.delegate= self;
        }
    }
    
#else
    
    if (self.currentlyRouting && self.route && userLocation) {
        [self updateData:userLocation];
        
        [tblDirections reloadData];
        [self renderMinimizedDirectionsViewFromInstruction];
        
    }
    
#endif
    
}

-(BOOL)location:(CLLocation*)loc1 matchesLocation:(CLLocation*)loc2 distance:(double)pDistance{
    return [loc1 distanceFromLocation:loc2] < pDistance;
}

#if defined(CYKEL_PLANEN)
-(BOOL)location:(CLLocation*)loc1 matchesLocation:(CLLocation*)loc2{
    return [self location:loc1 matchesLocation:loc2 distance:LOCATION_DEFAULT_DISTANCE];
}
#endif

- (void)beforeMapMove:(RMMapView *)map byUser:(BOOL)wasUserAction {
    if (wasUserAction) {
        debugLog(@"before map move");
        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(resetZoomTurn) object:nil];
        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(trackingOn) object:nil];
    }
    [self checkCallouts];
}

- (void)afterMapZoom:(RMMapView *)map byUser:(BOOL)wasUserAction {
    debugLog(@"After map zoom!!!! wasUserAction = %d", wasUserAction);
    if (wasUserAction) {
        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(resetZoomTurn) object:nil];
        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(trackingOn) object:nil];
    }
    [self checkCallouts];
}

#pragma mark - route delegate

#if defined(CYKEL_PLANEN)
-(void)didStartBreakingRoute:(SMRoute *)route{

}

-(void)didFinishBreakingRoute:(SMRoute *)route{
    
}

-(void)didFailBreakingRoute:(SMRoute *)route{
    
}

-(void)didCalculateRouteDistances:(SMTripRoute*)route{
    
}
#endif

- (void)routeNotFound {
    self.currentlyRouting = NO;
    
    [labelDistanceLeft setText:@""];
    [labelTimeLeft setText:@""];
    
    [self setDirectionsState:directionsHidden];
    
    UIAlertView * av = [[UIAlertView alloc] initWithTitle:@"Error".localized message:@"error_route_not_found".localized delegate:nil cancelButtonTitle:@"OK".localized otherButtonTitles:nil];
    [av show];
}

- (void)startRoute:(SMRoute *)route {
#if defined(CYKEL_PLANEN)
    if (route == tempRoute){
        [self performSegueWithIdentifier:@"breakRoute" sender:self];
        return;
    }
#endif
    if (overviewShown) {
        return;
    }
    currentDirectionsState = directionsNormal;
    routeOverview.hidden = YES;
    
    // Display new path
#if defined(CYKEL_PLANEN)
    for (SMRoute *route in self.brokenRoute.brokenRoutes){
        [self addRouteAnnotation:route];
        break;
    }
#else
    [self addRouteAnnotation:self.route];
#endif
    
    self.mapView.routingDelegate = self;
    
    
    [tblDirections reloadData];
    
    [self setDirectionsState:directionsNormal];
    
    self.currentlyRouting = YES;
    
    [self reloadSwipableView];
    
    [self.mapView setCenterCoordinate:CLLocationCoordinate2DMake(self.route.locationStart.latitude,self.route.locationStart.longitude)];
    
    [labelDistanceLeft setText:formatDistance(self.route.estimatedRouteDistance)];
    [labelTimeLeft setText:expectedArrivalTime(self.route.estimatedTimeForRoute)];
    
    [recalculatingView setAlpha:1.0f];
    [UIView animateWithDuration:0.3f animations:^{
        [recalculatingView setAlpha:0.0f];
    }];
}

- (void)updateTurn:(BOOL)firstElementRemoved {

    @synchronized(self.route.turnInstructions) {
        
        [self reloadSwipableView];
        
        if (firstElementRemoved) {
            if ([tblDirections numberOfRowsInSection:0] > 0) {
                [tblDirections reloadData];
            }
        }
        
        [self setDirectionsState:currentDirectionsState];
        
        [tblDirections performSelector:@selector(reloadData) withObject:nil afterDelay:0.4];        
        [self renderMinimizedDirectionsViewFromInstruction];
    }
}

- (void)reachedDestination {
#if defined(CYKEL_PLANEN)
    NSInteger index = [self.brokenRoute.brokenRoutes indexOfObject:self.route];
    if (index != self.brokenRoute.brokenRoutes.count-1) { // if current route isn't the last route
        nextRoute = self.brokenRoute.brokenRoutes[index+1]; // we set the nextRoute
        self.route.delegate = nil; // remove the delegate from the old route
        self.route = nil;
        return;
    } else {
        [self reachedEndOfRoute];
    }
#else 
    [self reachedEndOfRoute];
#endif
}

-(void)reachedEndOfRoute{
    [self updateTurn:NO];

    CGFloat distance = [self.route calculateDistanceTraveled];
    [finishDistance setText:formatDistance(distance)];
    [finishTime setText:[self.route timePassed]];

    /**
     * save route data
     */
    [self saveRoute];
    
    self.currentlyRouting = NO;
    
    [labelDistanceLeft setText:@""];
    [labelTimeLeft setText:@""];
    NSArray * a = [self.destination componentsSeparatedByString:@","];
    [finishDestination setText:[a objectAtIndex:0]];
    
    [[NSFileManager defaultManager] removeItemAtPath:[[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent: @"lastRoute.plist"] error:nil];

    /**
     * don't show destination notification
     */
    
    [self setDirectionsState:directionsHidden];
    [labelDistanceLeft setText:@""];
    [labelTimeLeft setText:@""];
    
    /**
     * enable screen time out
     */
    [UIApplication sharedApplication].idleTimerDisabled = NO;

    /**
     * remove delegate so we don't correct position and heading any more
     */
    self.mapView.routingDelegate = nil;
    
    /**
     * hide the route
     */
    for (RMAnnotation *annotation in self.mapView.annotations) {
        if ([annotation.annotationType isEqualToString:@"path"]) {
            [self.mapView removeAnnotation:annotation];
        }
    }
    /**
     * show actual route travelled
     */
    //        [self showRouteTravelled];
    
    
    if (![SMAnalytics trackEventWithCategory:@"Route" withAction:@"Finished" withLabel:self.destination withValue:0]) {
        debugLog(@"error in trackEvent");
    }
    
    [self.mapView setUserTrackingMode:RMUserTrackingModeFollow];
    
    CGRect fr = self.mapFade.frame;
    fr.size.height = 0.0f;
    self.mapFade.frame = fr;

    
    CGRect frame = finishView.frame;
    frame.origin.y = self.view.frame.size.height;
    [finishView setFrame:frame];
    [finishStreet setText:self.destination];
    [UIView animateWithDuration:0.4f delay:0.0f options:UIViewAnimationOptionBeginFromCurrentState animations:^{
        CGRect frame = finishView.frame;
        frame.origin.y = self.view.frame.size.height - finishView.frame.size.height;
        [finishView setFrame:frame];
        
        frame = buttonTrackUser.frame;
        frame.origin.y = finishView.frame.origin.y - 65.0f;
        [buttonTrackUser setFrame:frame];
    } completion:^(BOOL finished) {
        [closeButton setHidden:YES];
    }];

}

- (void)showRouteTravelled {
    for (RMAnnotation *annotation in self.mapView.annotations) {
        if ([annotation.annotationType isEqualToString:@"path"]) {
            [self.mapView removeAnnotation:annotation];
        }
    }
    NSMutableArray * arr = [NSMutableArray arrayWithCapacity:self.route.visitedLocations];
    for (CLLocation *location in self.route.visitedLocations) {
        [arr addObject:location];
    }
    
    CLLocation * loc = nil;
    if (arr && [arr count] > 0) {
        loc = [arr objectAtIndex:0];
    }
    
    RMAnnotation *calculatedPathAnnotation = [RMAnnotation annotationWithMapView:self.mapView coordinate:loc.coordinate andTitle:nil];
    calculatedPathAnnotation.annotationType = @"path";
    calculatedPathAnnotation.userInfo = @{
                                          @"linePoints" : [NSArray arrayWithArray:arr],
                                          @"lineColor" : [Styler tintColor],
                                          @"fillColor" : [UIColor clearColor],
                                          @"lineWidth" : [NSNumber numberWithFloat:10.0f],
                                          };
    [calculatedPathAnnotation setBoundingBoxFromLocations:[NSArray arrayWithArray:arr]];
    [self.mapView addAnnotation:calculatedPathAnnotation];
}

- (void) updateRoute {
    // Remove previous path and display new one
    [noConnectionView setAlpha:0.0f];
    for (RMAnnotation *annotation in self.mapView.annotations) {
        if ([annotation.annotationType isEqualToString:@"path"]) {
            [self.mapView removeAnnotation:annotation];
        }
    }
    [self addRouteAnnotation:self.route];

    [tblDirections reloadData];
}

- (void)routeRecalculationStarted {
    dispatch_async(dispatch_get_main_queue(), ^{
        [recalculatingView setAlpha:0.0f];
        [UIView animateWithDuration:0.3f animations:^{
            [recalculatingView setAlpha:1.0f];
        }];
    });
}

- (void)routeRecalculationDone {
    dispatch_async(dispatch_get_main_queue(), ^{
        [noConnectionView setAlpha:0.0f];
        [recalculatingView setAlpha:1.0f];
        [self reloadSwipableView];
        [UIView animateWithDuration:0.3f animations:^{
            [recalculatingView setAlpha:0.0f];
        }];
    });
}

- (void)serverError {
    dispatch_async(dispatch_get_main_queue(), ^{
        [UIView animateWithDuration:0.3f animations:^{
            [recalculatingView setAlpha:0.0f];
//            [noConnectionView setAlpha:1.0f];
        }];
        
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
    });
}

#pragma mark - button actions

- (IBAction)reportError:(id)sender {
    [self performSegueWithIdentifier:@"reportError" sender:nil];
}

- (IBAction)hideFinishView:(id)sender {
    [UIView animateWithDuration:0.4f animations:^{
        [finishFadeView setAlpha:0.0f];
    }];
}

- (IBAction)tappedCloseButton:(id)sender {
    PSTAlertController *alertController = [PSTAlertController alertControllerWithTitle:@"route_stop_title".localized message:nil preferredStyle:PSTAlertControllerStyleActionSheet];
    [alertController addCancelActionWithHandler:nil];
    
    [alertController addAction:[PSTAlertAction actionWithTitle:@"ride_report_a_problem".localized handler:^(PSTAlertAction *action) {
        [self performSegueWithIdentifier:@"routeToReport" sender:nil];
    }]];
    
    [alertController addAction:[PSTAlertAction actionWithTitle:@"stop_ride".localized handler:^(PSTAlertAction *action) {
        [self goBack];
    }]];
    
    [alertController showWithSender:self controller:self animated:YES completion:nil];
}

- (void)goBack {
    self.currentlyRouting = NO;
    
    self.mapView.delegate = nil;
    self.mapView.routingDelegate = nil;
    self.mapView.userTrackingMode = RMUserTrackingModeNone;
    self.mapView = nil;

    [[NSFileManager defaultManager] removeItemAtPath:[[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent: @"lastRoute.plist"] error:nil];
    
    [self saveRoute];
 
    [self dismiss];
}

- (void)trackingOn {
    debugLog(@"trackingOn() btn state = 0x%0x, prev btn state = 0x%0x", buttonTrackUser.gpsTrackState, buttonTrackUser.prevGpsTrackState);
    if (buttonTrackUser.gpsTrackState == SMGPSTrackButtonStateNotFollowing) {
        if (self.currentlyRouting == NO) {
            self.mapView.userTrackingMode = RMUserTrackingModeFollow;
        } else if (buttonTrackUser.prevGpsTrackState == SMGPSTrackButtonStateFollowing) {
            self.mapView.userTrackingMode = RMUserTrackingModeFollow;
        } else {
            self.mapView.userTrackingMode = RMUserTrackingModeFollowWithHeading;
        }
    } else if (buttonTrackUser.gpsTrackState == SMGPSTrackButtonStateFollowing && self.currentlyRouting) {
        self.mapView.userTrackingMode = RMUserTrackingModeFollowWithHeading;
    } else {
        // next state is follow
        self.mapView.userTrackingMode = RMUserTrackingModeFollow;
    }
}

-(IBAction)trackUser:(id)sender {
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(resetZoomTurn) object:nil];
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(trackingOn) object:nil];

    CLLocationCoordinate2D center;
    if ([SMLocationManager instance].hasValidLocation)
        center = [SMLocationManager instance].lastValidLocation.coordinate;
    else
        center = self.startLocation.coordinate;
    [self.mapView setCenterCoordinate:center animated:NO];

    [self trackingOn];

}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if (([segue.identifier isEqualToString:@"routeToReport"]) ){
        SMReportErrorController *destViewController = segue.destinationViewController;
        NSMutableArray * arr = [NSMutableArray array];
        if (self.route) {
            @synchronized(self.route.pastTurnInstructions) {
                if (self.route) {
                    for (SMTurnInstruction * t in self.route.pastTurnInstructions) {
                        [arr addObject:[t fullDescriptionString]];
                    }                    
                }
            }
            @synchronized(self.route.turnInstructions) {
                if (self.route) {
                    for (SMTurnInstruction * t in self.route.turnInstructions) {
                        [arr addObject:[t fullDescriptionString]];
                    }
                }
            }
        }
        destViewController.routeDirections = arr;
        destViewController.destination = self.destination;
        destViewController.source = self.source;
        destViewController.destinationLoc = self.endLocation;
        destViewController.sourceLoc = self.startLocation;
    }
#if defined(CYKEL_PLANEN)
    else if([segue.identifier isEqualToString:@"breakRoute"]){
        SMBreakRouteViewController *brVC= segue.destinationViewController;
        brVC.sourceName = self.source;
        brVC.destinationName = self.destination;
        
        [SMGeocoder reverseGeocode:self.startLocation.coordinate completionHandler:^(KortforItem *item, NSError *error) {
            NSString* address = [NSString stringWithFormat:@"%@ %@", item.street, item.number];
            if ( [address isEqualToString:self.source] ) {
                brVC.sourceAddress = [NSString stringWithFormat:@"%@ %@", item.zip, item.city];
            } else {
                brVC.sourceAddress = address;
            }
            [brVC.tableView reloadData];
        }];
        
        [SMGeocoder reverseGeocode:self.endLocation.coordinate completionHandler:^(KortforItem *item, NSError *error) {
            NSString *address = [NSString stringWithFormat:@"%@ %@", item.street, item.number];
            if ( [address isEqualToString:self.destination] ) {
                brVC.destinationAddress = [NSString stringWithFormat:@"%@ %@", item.zip, item.city];
            } else {
                brVC.destinationAddress = address;
            }
            
            [brVC.tableView reloadData];
        }];
        
        if (self.currentlyRouting) {
            brVC.tripRoute = tempTripRoute;
            brVC.fullRoute = [brVC.tripRoute.brokenRoutes objectAtIndex:0];
        } else {
            brVC.tripRoute = self.brokenRoute;
        }
    }
#endif
}

#pragma mark - UITableViewDataSource methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.route.turnInstructions.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSInteger i = [indexPath row];
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:(i == 0 ? @"topDirectionCell" : @"directionCell")];

    if (i >= 0 && i < self.route.turnInstructions.count) {
        SMTurnInstruction *turn = (SMTurnInstruction *)[self.route.turnInstructions objectAtIndex:i];
        /**
         * Replace "Destination reached" message with your address
         */
        if (turn.drivingDirection == 15) {
            turn.wayName = self.destination;
            turn.shortDescriptionString = turn.descriptionString;
        }
        if (i == 0) {
            [(SMDirectionTopCell *)cell renderViewFromInstruction:turn];
        }
        else {
            [(SMDirectionCell *)cell renderViewFromInstruction:turn];
        }
    }
    return cell;
}


#pragma mark - UITableViewDelegate methods

- (void)resetZoomTurn {
    if (buttonTrackUser.gpsTrackState == SMGPSTrackButtonStateNotFollowing)
        [self trackUser:nil];
}


#pragma mark - directions table

/**
 * set new direction state
 */
- (void)setDirectionsState:(DirectionsState)state {
    if (self.pulling) {
        return;
    }
    switch (state) {
        case directionsFullscreen: {
            [tblDirections setScrollEnabled:YES];
            CGFloat newY = mapContainer.frame.origin.y + MAX_TABLE;
            [self repositionInstructionsView:newY + 1];
            lastDirectionsPos = newY + 1;
        }
            break;
        case directionsNormal: {
            [instructionsView setHidden:NO];
            [minimizedInstructionsView setHidden:YES];
            int maxY = self.view.frame.size.height - tblDirections.frame.origin.y;
            CGFloat tblHeight = 0.0f;
            CGFloat newY = 0;
            @synchronized(self.route.turnInstructions) {
                if ([self.route.turnInstructions count] > 0) {
                    tblHeight = 80;
                }
            }
            newY = maxY - tblHeight;
            [self repositionInstructionsView:newY + 1];
            lastDirectionsPos = newY + 1;
            [swipableView setHidden:NO];
            [tblDirections setScrollEnabled:NO];
        }
            break;
        case directionsMini:
            [instructionsView setHidden:YES];
            [minimizedInstructionsView setHidden:NO];
            [self repositionInstructionsView:self.view.frame.size.height];
            [tblDirections setScrollEnabled:NO];
            lastDirectionsPos = self.view.frame.size.height;
            break;
        case directionsHidden:
            [instructionsView setHidden:YES];
            [minimizedInstructionsView setHidden:YES];
            [self repositionInstructionsView:self.view.frame.size.height];
            lastDirectionsPos = self.view.frame.size.height;
            break;
        default:
            break;
    }
    currentDirectionsState = state;
}

- (void)repositionInstructionsView:(CGFloat)newY {
    CGFloat newHeight = self.view.frame.size.height - newY;
    self.instructionHeightConstraint.constant = newHeight;
    
    CGFloat fadeRegion = self.view.frame.size.height / 2;
    if (newY < fadeRegion) {
        self.mapFade.alpha = 0.8 * (1 - newY / fadeRegion);
    } else {
        self.mapFade.alpha = 0;
    }
}

- (void)setNewDirections:(CGFloat)newY {
    switch (currentDirectionsState) {
        case directionsFullscreen:
            if (newY > lastDirectionsPos + 20.0f) {
                [self setDirectionsState:directionsNormal];
                buttonTrackUser.hidden = NO;
            } else {
                [self setDirectionsState:directionsFullscreen];
                buttonTrackUser.hidden = YES;
            }
            break;
        case directionsNormal:
            if (newY < lastDirectionsPos - 20.0f) {
                [self setDirectionsState:directionsFullscreen];
                buttonTrackUser.hidden = YES;
            } else {
                [self setDirectionsState:directionsNormal];
                buttonTrackUser.hidden = NO;
            }
            break;
        case directionsHidden:
            buttonTrackUser.hidden = NO;
            break;
        default:
            break;
    }
}

- (IBAction)onPanGestureDirections:(UIPanGestureRecognizer *)sender {
    if([tblDirections numberOfSections]>0 && [tblDirections numberOfRowsInSection:0]>=1 ){
        [tblDirections scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] atScrollPosition:UITableViewScrollPositionTop animated:NO];
    }
    [instructionsView setHidden:NO];
    [minimizedInstructionsView setHidden:YES];
    if (sender.state == UIGestureRecognizerStateEnded) {
        self.pulling = NO;
        float newY = [sender locationInView:self.view].y;
        [self setNewDirections:newY];
        [self.mapView setUserTrackingMode:oldTrackingMode];
    } else if (sender.state == UIGestureRecognizerStateChanged) {
        self.pulling = YES;
        [swipableView setHidden:YES];
        float newY = MAX([sender locationInView:self.view].y - touchOffset, self.mapView.frame.origin.y);
        [self repositionInstructionsView:newY];
    } else if (sender.state == UIGestureRecognizerStateBegan) {
        self.pulling = YES;
        oldTrackingMode = self.mapView.userTrackingMode;
        [self.mapView setUserTrackingMode:RMUserTrackingModeNone];
        touchOffset = [sender locationInView:instructionsView].y;
        [swipableView setHidden:YES];
        [buttonTrackUser setHidden:YES];
    }
}

#pragma mark - swipable view


- (void)drawArrows {
    if (swipableView.hidden) {
        [swipeLeftArrow setHidden:YES];
        [swipeRightArrow setHidden:YES];
    } else {
        [swipeLeftArrow setHidden:NO];
        [swipeRightArrow setHidden:NO];
        NSInteger start = MAX(0, floor(swipableView.contentOffset.x / self.view.frame.size.width));
        if (start == 0) {
            [swipeLeftArrow setHidden:YES];
        }
        if (start == [self.instructionsForScrollview count] - 1) {
            [swipeRightArrow setHidden:YES];
        }
    }
}

- (SMSwipableView*)getRecycledItemOrCreate {
    SMSwipableView * cell = [self.recycledItems anyObject];
    if (cell == nil) {
        cell = [SMSwipableView getFromNib];
    } else {
        [self.recycledItems removeObject:cell];
    }
    //[cell setBackgroundColor:[UIColor colorWithPatternImage:[UIImage imageNamed:@"tableViewBG"]]];
    return cell;
}

- (void)reloadFirstSwipableView {
    for (SMSwipableView * cell in self.activeItems) {
        if (cell.position == 0) {
            SMTurnInstruction *turn = (SMTurnInstruction *)[self.instructionsForScrollview objectAtIndex:0];
            [cell renderViewFromInstruction:turn];
        }
    }
}

- (void)reloadSwipableView {
    SMTurnInstruction * instr = nil;
    NSInteger start = MAX(0, floor(swipableView.contentOffset.x / self.view.frame.size.width));
    @synchronized(self.instructionsForScrollview) {
        if ([self.instructionsForScrollview count] > start || start > 0) {
            instr = [self.instructionsForScrollview objectAtIndex:start];
        }
#if defined(CYKEL_PLANEN)
        NSMutableArray *arr = [NSMutableArray new];
        for(SMRoute *route in self.brokenRoute.brokenRoutes){
            [arr addObjectsFromArray:route.turnInstructions];
        }
        self.instructionsForScrollview = [NSArray arrayWithArray:arr];
#else
        self.instructionsForScrollview = [NSArray arrayWithArray:self.route.turnInstructions];
#endif
        
        for (SMSwipableView * cell in self.activeItems) {
            cell.position = -1;
            [self.recycledItems addObject:cell];
            [cell removeFromSuperview];
        }
        [self.activeItems minusSet:self.recycledItems];
        [swipableView setContentSize:CGSizeMake(self.view.frame.size.width * ([self.instructionsForScrollview count]), swipableView.frame.size.height)];
        if (instr) {
            NSInteger pos = [self.instructionsForScrollview indexOfObject:instr];
//            NSLog(@"*** Pos: %d Start:%d", pos, start);
            if (pos != NSNotFound && pos > 0) {
                [swipableView setContentOffset:CGPointMake(pos*self.view.frame.size.width, 0.0f) animated:YES];
            } else {
                [swipableView setContentOffset:CGPointZero animated:YES];
            }
        }
        [self showVisible:NO];
    }    
}

- (BOOL)isVisible:(NSUInteger)index {
    for (SMSwipableView * cell in self.activeItems) {
        if (cell.position == index) {
            return YES;
        }
    }
    return NO;
}

- (void)showVisible:(BOOL)reload {
    @synchronized(self.instructionsForScrollview) {
        NSInteger start = MAX(0, floor(swipableView.contentOffset.x / self.view.frame.size.width));
        NSUInteger end = MIN(ceil(swipableView.contentOffset.x / self.view.frame.size.width), [self.instructionsForScrollview count] - 1);
        for (SMSwipableView * cell in self.activeItems) {
            if (cell.position < start || cell.position > end) {
                cell.position = -1;
                [self.recycledItems addObject:cell];
                [cell removeFromSuperview];
            }
        }
        [self.activeItems minusSet:self.recycledItems];
        
        if (start < [self.instructionsForScrollview count] && end < [self.instructionsForScrollview count]) {
            for (int i = start; i <= end; i++) {
                SMSwipableView * cell = nil;
                if ([self isVisible:i] == NO) {
                    cell = [self getRecycledItemOrCreate];
                    [self.activeItems addObject:cell];
                    cell.position = i;
                    SMTurnInstruction *turn = (SMTurnInstruction *)[self.instructionsForScrollview objectAtIndex:i];
                    [cell setFrame:CGRectMake(i*swipableView.frame.size.width, 0, swipableView.frame.size.width, swipableView.frame.size.height)];
                    [cell renderViewFromInstruction:turn];
                    [swipableView addSubview:cell];
                }
            }
            
            if (start == end) {
                if (start == 0) {
                    /**
                     * start tracking the user if we're back to first instruction
                     * we also start updating the swipable view
                     */
                    self.updateSwipableView = YES;
                    if (reload && overviewShown == NO) {
                        [self resetZoomTurn];                        
                    }
                } else {
                    /**
                     * we're not on the first instruction
                     */
                    self.updateSwipableView = NO;
                    SMTurnInstruction *turn = (SMTurnInstruction *)[self.instructionsForScrollview objectAtIndex:start];
                    [self zoomToLocation:turn.loc temporary:NO];
                }
                [self drawArrows];
            } else {
                self.updateSwipableView = NO;
            }
        }
        [swipableView setContentSize:CGSizeMake(swipableView.contentSize.width, swipableView.frame.size.height)];
        NSLog(@"%f", swipableView.frame.size.height);
    }
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    [self showVisible:YES];
}

#pragma mark - observers

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if (object == self && [keyPath isEqualToString:@"currentlyRouting"]) {
        /**
         * hide/show views depending on whether we're currently routing or not
         */
        if (self.currentlyRouting) {
            [progressView setHidden:NO];
            [UIApplication sharedApplication].idleTimerDisabled = YES;
        } else {
            [self setDirectionsState:directionsHidden];
            [minimizedInstructionsView setHidden:YES];
            [progressView setHidden:YES];
            [UIApplication sharedApplication].idleTimerDisabled = NO;
        }
    } else if (object == swipableView && [keyPath isEqualToString:@"hidden"]) {
        /**
         * observer that hides directions table when swipable view is shown
         */
        if (swipableView.hidden) {
            [tblDirections setAlpha:1.0f];
        } else {
            [tblDirections setAlpha:0.0f];
        }
        [self drawArrows];
    } else if (object == self.mapView && [keyPath isEqualToString:@"zoom"]) {
        NSLog(@"Zoom: %f", self.mapView.zoom);
    } else if (object == self.mapView && [keyPath isEqualToString:@"userTrackingMode"]) {
        if (self.mapView.userTrackingMode == RMUserTrackingModeFollow) {
            [buttonTrackUser newGpsTrackState:SMGPSTrackButtonStateFollowing];
        } else if (self.mapView.userTrackingMode == RMUserTrackingModeFollowWithHeading) {
            [buttonTrackUser newGpsTrackState:SMGPSTrackButtonStateFollowingWithHeading];
        } else if (self.mapView.userTrackingMode == RMUserTrackingModeNone) {
            [buttonTrackUser newGpsTrackState:SMGPSTrackButtonStateNotFollowing];
        }
    }
}

#pragma mark - routing delegate

- (double) getCorrectedHeading {
    return [self.route getCorrectedHeading];
}

- (CLLocation *)getCorrectedPosition {
    return self.route.lastCorrectedLocation;
}

- (BOOL)isOnPath {
    return [self.route isOnPath];
}

#pragma mark - footer delegate

- (void)viewTapped:(id)view {
    [self reportError:nil];
}

#pragma mark - osrm request delegate

- (void)request:(SMRequestOSRM *)req finishedWithResult:(id)res {
    if ([req.auxParam isEqualToString:@"startRoute"]){
        id jsonRoot = [NSJSONSerialization JSONObjectWithData:req.responseData options:NSJSONReadingAllowFragments error:nil];
        if (!jsonRoot || ([jsonRoot isKindOfClass:[NSDictionary class]] == NO) || ([jsonRoot[@"status"] intValue] != 0)) {
            UIAlertView * av = [[UIAlertView alloc] initWithTitle:nil message:@"error_route_not_found".localized delegate:nil cancelButtonTitle:@"OK".localized otherButtonTitles:nil];
            [av show];
        } else {
            self.jsonRoot = jsonRoot;
            if (self.startLocation && self.endLocation) {
                [self start:self.startLocation.coordinate end:self.endLocation.coordinate withJSON:self.jsonRoot];
            }
            [UIView animateWithDuration:0.2f delay:0.0f options:UIViewAnimationOptionBeginFromCurrentState animations:^{
                CGRect frame = centerView.frame;
                frame.origin.x = centerView.startPos;
                [centerView setFrame:frame];
            } completion:^(BOOL finished) {
            }];
        }
    }
}

- (void)request:(SMRequestOSRM *)req failedWithError:(NSError *)error {}

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

#if defined(CYKEL_PLANEN)
- (void)toggleBreakRouteButton {
    breakRouteButton.userInteractionEnabled = YES;
    [breakRouteButton setImage:[UIImage imageNamed:@"break_route"] forState:UIControlStateNormal];
}

- (BOOL)breakRouteButtonEnabled{
    return !self.currentlyRouting;
}
#endif

- (void)setDestination:(NSString *)pDestination {
    _destination= pDestination;
}



#pragma mark - RouteTypeHandlerDelegateObjc

- (void)routeTypeHandlerChanged:(NSString *)toServer {
    self.osrmServer = toServer;
    [self newRouteType];
}

#pragma mark - UIStatusBarStyle

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleDefault;
}

@end
