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

#import "SMUtil.h"
#import "SMRouteUtils.h"

#import "SMAnnotation.h"
#import "SMSwipableView.h"

#import "SMDirectionsFooter.h"
#import "SMSearchHistory.h"
#import "SMRouteTypeSelectCell.h"
#import "SMTripRoute.h"
#import "SMBreakRouteViewController.h"
#import "SMTransportation.h"
#import "SMGeocoder.h"
#import "SMMapManager.h"
#include "float.h"

#import "SMMapOverlays.h"

typedef enum {
    directionsFullscreen,
    directionsNormal,
    directionsMini,
    directionsHidden
} DirectionsState;

@interface SMRouteNavigationController () {
    DirectionsState currentDirectionsState;
    CGFloat lastDirectionsPos;
    CGFloat touchOffset;
    BOOL overviewShown;
    RMUserTrackingMode oldTrackingMode;
    BOOL shouldShowOverview;

    SMRoute* fullRoute;
    SMRoute* nextRoute;
    
    SMTripRoute* tempTripRoute;
    SMRoute* tempRoute;
}
@property (weak, nonatomic) IBOutlet UIImageView *cargoHandleImageView;
@property (weak, nonatomic) IBOutlet UITableView *cargoTableView;

@property (nonatomic, strong) NSArray* cargoItems;
@property (nonatomic, strong) SMRoute *route;
@property (nonatomic, strong) SMTripRoute* brokenRoute;
@property (nonatomic, strong) IBOutlet RMMapView * mpView;
@property int directionsShownCount; // How many directions are shown in the directions table at the moment:
                                    // -1 means no direction is shown and minimized directions view is not shown (this happens before first call to showDirections())
                                    // 0 means no direction is shown and minimized directions view is shown
                                    // > 3 means directions table is maximized
@property (nonatomic, strong) NSMutableSet * recycledItems;
@property (nonatomic, strong) NSMutableSet * activeItems;
@property (nonatomic, strong) NSArray * instructionsForScrollview;
@property BOOL pulling;
@property (nonatomic, strong) NSString * osrmServer;

@property (nonatomic, strong) NSMutableArray* stationMarkers;
@property (nonatomic, strong) NSMutableArray* metroMarkers;
@property (nonatomic, strong) NSMutableArray* serviceMarkers;
@property BOOL stationMarkersVisible;
@property BOOL metroMarkersVisible;
@property BOOL serviceMarkersVisible;
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

    [breakRouteButton.imageView setContentMode:UIViewContentModeScaleAspectFill];
    UIImageView* imageView= [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"mover"]];
    
    imageView.center= CGPointMake(pullHandleImageView.bounds.size.width/2, pullHandleImageView.frame.size.height-imageView.frame.size.height/2-5);
    [pullHandleImageView addSubview:imageView];
    shouldShowOverview = NO;
    
    self.osrmServer = OSRM_SERVER;
    self.pulling = NO;

    self.recycledItems = [NSMutableSet set];
    self.activeItems = [NSMutableSet set];
    [instructionsView setBackgroundColor:[UIColor colorWithPatternImage:[UIImage imageNamed:@"tableViewBG"]]];
    self.updateSwipableView = YES;
    
    self.currentlyRouting = NO;
    overviewShown = NO;
    self.directionsShownCount = -1;

    [SMLocationManager instance];

    self.mpView.contentScaleFactor= 0.5;
    
    [self.mpView setTileSource:TILE_SOURCE];
    [self.mpView setDelegate:self];
    [self.mpView setMaxZoom:MAX_MAP_ZOOM];

    [self setDirectionsState:directionsHidden];
    
    [self.mpView setUserTrackingMode:RMUserTrackingModeNone];
    [self.mpView setTriggerUpdateOnHeadingChange:NO];
    [self.mpView setDisplayHeadingCalibration:NO];
    [self.mpView setEnableBouncing:NO];
    [self.mpView setRoutingDelegate:nil];
    
    [self.mpView setZoom:DEFAULT_MAP_ZOOM];

    [labelTimeLeft setText:@""];
    [labelDistanceLeft setText:@""];
    
    SMDirectionsFooter * v = [SMDirectionsFooter getFromNib];
    [v.label setText:translateString(@"ride_report_a_problem")];
    [v setDelegate:self];
    [tblDirections setTableFooterView:v];
    
    if (self.startLocation && self.endLocation) {
        [self start:self.startLocation.coordinate end:self.endLocation.coordinate withJSON:self.jsonRoot];
    }
    
    [centerView setupForHorizontalSwipeWithStart:0.0f andEnd:260.0f andStart:0.0f andPullView:self.cargoHandleImageView];
    
    // setup cargo items
    
    self.cargoItems= OSRM_SERVERS;
    [self.cargoTableView setTableFooterView:[[UIView alloc] initWithFrame:CGRectZero]];
    [self.cargoTableView reloadData];
    [self.cargoTableView selectRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] animated:NO scrollPosition:UITableViewScrollPositionTop];
    
    [centerView addObserver:self forKeyPath:@"frame" options:NSKeyValueObservingOptionNew context:nil];
    
    self.pathVisible= YES;
    
    // TODO: From CykelPlanen
//    if ( self.appDelegate.mapOverlays == nil ) {
//        self.appDelegate.mapOverlays = [[SMMapOverlays alloc] initWithMapView:self.mpView];
//    }
//    [self.appDelegate.mapOverlays useMapView:self.mpView];
//
//    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onStationsFetched:) name:NOTIFICATION_STATIONS_FETCHED object:nil];
}

-(void)onStationsFetched:(NSNotification*)notification{}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [[UIApplication sharedApplication] setStatusBarHidden:NO];
    [[UIApplication sharedApplication] setStatusBarStyle: UIStatusBarStyleBlackTranslucent];
    
    // TODO: From CykelPlanen
//    if([[SMUser user] route]){
//        self.route= [[SMUser user] route];
//        self.startLocation= [self.route getStartLocation];
//        self.endLocation= [self.route getEndLocation];
//    }
//    
//    if([[SMUser user] tripRoute]){
//        self.brokenRoute= [[SMUser user] tripRoute];
//    }
    
    if (self.startLocation && self.endLocation) {
        [self start:self.startLocation.coordinate end:self.endLocation.coordinate withJSON:self.jsonRoot];
    }
    [self.mpView addObserver:self forKeyPath:@"userTrackingMode" options:0 context:nil];
    [self.mpView addObserver:self forKeyPath:@"zoom" options:0 context:nil];
    [self addObserver:self forKeyPath:@"currentlyRouting" options:0 context:nil];
    [swipableView addObserver:self forKeyPath:@"hidden" options:0 context:nil];
    [self.mapFade addObserver:self forKeyPath:@"frame" options:0 context:nil];
    
    [self.mpView setUserTrackingMode:RMUserTrackingModeNone];
    
    CGFloat maxSize = self.view.frame.size.height - 160.0f;
    if (self.mapFade.frame.size.height > maxSize) {
        [self.mapFade setAlpha:0.0f];
    } else {
        [self.mapFade setAlpha: 0.8f - ((self.mapFade.frame.size.height - MAX_TABLE) * 0.8f / (maxSize - MAX_TABLE))];
    }
    
    [self.mpView rotateMap:0.0];
    
    if (self.mapFade.alpha > 0.7f) {
        [arrivalBG setImage:[UIImage imageNamed:@"distance_black"]];
        [closeButton setImage:[UIImage imageNamed:@"btnCloseDark"] forState:UIControlStateNormal];
        [labelDistanceLeft setTextColor:[UIColor whiteColor]];
        [labelTimeLeft setTextColor:[UIColor whiteColor]];
    } else {
        [arrivalBG setImage:[UIImage imageNamed:@"distance_white"]];
        [closeButton setImage:[UIImage imageNamed:@"btnClose"] forState:UIControlStateNormal];
        [labelDistanceLeft setTextColor:[UIColor darkGrayColor]];
        [labelTimeLeft setTextColor:[UIColor darkGrayColor]];
    }
    
    [centerView addObserver:self forKeyPath:@"frame" options:NSKeyValueObservingOptionNew context:nil];
    
    CGRect rect= self.mapFade.frame;
    rect.size.height= 0;
    self.mapFade.frame= rect;
    
    // markers visibility
    [self removeAllMarkers];
    [self toggleMarkers];
    
    // TODO: From CykelPlanen
//    [self.appDelegate.mapOverlays useMapView:self.mpView];
//    [self.appDelegate.mapOverlays toggleMarkers];
    [self.mpView setZoom:self.mpView.zoom+0.0001];
    [self mapViewRegionDidChange:self.mpView];
    
    double delayInSeconds = 1.0;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        [self.mpView setZoom:self.mpView.zoom+0.0001];
    });
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [tblDirections reloadData];
    if (self.currentlyRouting) {
        [UIApplication sharedApplication].idleTimerDisabled = YES;
    } else {
        [UIApplication sharedApplication].idleTimerDisabled = NO;
    }

    // TODO: From CykelPlanen
//    if ( self.appDelegate.mapOverlays.pathVisible )
//        [self.cargoTableView selectRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] animated:NO scrollPosition:UITableViewScrollPositionTop];
//    if ( self.appDelegate.mapOverlays.serviceMarkersVisible )
//        [self.cargoTableView selectRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:0] animated:NO scrollPosition:UITableViewScrollPositionTop];
//    if ( self.appDelegate.mapOverlays.stationMarkersVisible )
//        [self.cargoTableView selectRowAtIndexPath:[NSIndexPath indexPathForRow:2 inSection:0] animated:NO scrollPosition:UITableViewScrollPositionTop];
//    if ( self.appDelegate.mapOverlays.metroMarkersVisible )
//        [self.cargoTableView selectRowAtIndexPath:[NSIndexPath indexPathForRow:3 inSection:0] animated:NO scrollPosition:UITableViewScrollPositionTop];
//    if ( self.appDelegate.mapOverlays.localTrainMarkersVisible )
//        [self.cargoTableView selectRowAtIndexPath:[NSIndexPath indexPathForRow:4 inSection:0] animated:NO scrollPosition:UITableViewScrollPositionTop];
}


- (void)viewWillDisappear:(BOOL)animated {
    [centerView removeObserver:self forKeyPath:@"frame"];
    [UIApplication sharedApplication].idleTimerDisabled = NO;
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self removeObserver:self forKeyPath:@"currentlyRouting" context:nil];
    [swipableView removeObserver:self forKeyPath:@"hidden" context:nil];
    [self.mpView removeObserver:self forKeyPath:@"userTrackingMode" context:nil];
    [self.mpView removeObserver:self forKeyPath:@"zoom" context:nil];
    [self.mapFade removeObserver:self forKeyPath:@"frame"];
    [super viewWillDisappear:animated];
}

- (void)dealloc {
    [centerView removeObserver:self forKeyPath:@"frame"];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark - station markers

- (void)loadMarkers {
    self.stationMarkers = [[NSMutableArray alloc] init];
    
        for(int i=0; i<[SMTransportation instance].allStations.count; i++){
            
            SMStationInfo* stationLocation= [SMTransportation instance].allStations[i];
            CLLocationCoordinate2D coord = CLLocationCoordinate2DMake(stationLocation.latitude, stationLocation.longitude);
            
            NSString* imageName = [SMStationInfo imageNameForType:stationLocation.type];
            NSString* title = @"station";

            NSString* annotationTitle = stationLocation.name;

            NSString* alternateTitle = @"alternate title";
            
            SMAnnotation *annotation = [SMAnnotation annotationWithMapView:self.mpView coordinate:coord andTitle:title];
            annotation.annotationType = @"marker";
            annotation.annotationIcon = [UIImage imageNamed:imageName];
            annotation.anchorPoint = CGPointMake(0.5, 1.0);
            NSMutableArray * arr = [[self.source componentsSeparatedByString:@","] mutableCopy];
            annotation.title = annotationTitle;
            
            if ([annotation.title isEqualToString:@""] && alternateTitle) {
                annotation.title = alternateTitle;
            }
            
            annotation.userInfo= @{keyZIndex: [NSNumber numberWithInt:MAP_LEVEL_STATIONS]};
            
            annotation.subtitle = [[arr componentsJoinedByString:@","] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
            
            [self.stationMarkers addObject:annotation];

        }
    
}

-(void)removeAllMarkers{
    [self.mpView removeAnnotations:self.metroMarkers];
    [self.mpView removeAnnotations:self.serviceMarkers];
    [self.mpView removeAnnotations:self.stationMarkers];
    [self hideRouteAnnotation];
    
}

-(void)toggleMarkers{
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

        if ( self.pathVisible ) {
            [self showRouteAnnotation];
        } else {
            [self hideRouteAnnotation];
        }

}

- (void)toggleMarkers:(NSString*)markerType state:(BOOL)state{
    if ( [markerType isEqualToString:@"metro"] ) {
        self.metroMarkersVisible = state;
       
    } else if ( [markerType isEqualToString:@"service"] ) {
        self.serviceMarkersVisible = state;
       
    } else if ( [markerType isEqualToString:@"station"] ) {
        self.stationMarkersVisible = state;
       
    }else if([markerType isEqualToString:@"path"]){
        self.pathVisible= state;
    
    }
    
    [self toggleMarkers];
}

#pragma mark - custom methods

#define LATITUDE_PADDING 0.25f
#define LONGITUDE_PADDING 0.10f

- (void)setupMapSize:(BOOL)heading {
    CGRect frame = mapContainer.frame;
    if (overviewShown) {
        frame.size.height = routeOverview.frame.origin.y + 1.0f;
    } else if ((heading == NO) || self.pulling) {
        frame.size.height = (self.view.frame.size.height - frame.origin.y);
    } else {
        if (currentDirectionsState == directionsMini) {
            frame.size.height = (self.view.frame.size.height - frame.origin.y) * 1.36f;
        } else {
            frame.size.height = (self.view.frame.size.height - frame.origin.y - 102.0f) * 1.36f;
        }
    }
    [mapContainer setFrame:frame];
    
    frame = buttonTrackUser.frame;
    frame.origin.y = instructionsView.frame.origin.y - 65.0f;
    [buttonTrackUser setFrame:frame];
    
}

- (void)showRouteOverview {
    oldTrackingMode = RMUserTrackingModeNone;
    [self setDirectionsState:directionsHidden];
    [self.mpView rotateMap:0];
    for (RMAnnotation *annotation in self.mpView.annotations) {
        if ([annotation.annotationType isEqualToString:@"path"]) {
            [self.mpView removeAnnotation:annotation];
        }
    }
    [routeOverview setHidden:NO];
    [UIView animateWithDuration:0.4f delay:0.0f options:UIViewAnimationOptionBeginFromCurrentState animations:^{
        routeOverview.alpha = 1.0f;
    } completion:^(BOOL finished) {
        
    }];
    overviewShown = YES;
    self.currentlyRouting = NO;
    
    /**
     * hide this if time should not be shown
     */
    [progressView setHidden:YES];
    [labelDistanceLeft setText:formatDistance(self.route.estimatedRouteDistance)];
    [labelTimeLeft setText:expectedArrivalTime(self.route.estimatedTimeForRoute)];
    /**
     * end hide
     */
    
    [self setDirectionsState:directionsNormal];
    // Display new path
    NSDictionary * coordinates = [self addRouteAnnotation:self.route];
    [self.mpView setRoutingDelegate:self];
    [tblDirections reloadData];
    
    [self reloadSwipableView];
    
    [routeOverview setFrame:instructionsView.frame];
    
    [overviewTimeDistance setText:[NSString stringWithFormat:@"%@, %0.f min, via %@", formatDistance(self.route.estimatedRouteDistance), ceilf(self.route.estimatedTimeForRoute / 60.0f), self.route.longestStreet]];
    
    NSArray * a = [self.destination componentsSeparatedByString:@","];
    NSString* streetName= [a objectAtIndex:0];
    overviewDestination.lineBreakMode= UILineBreakModeCharacterWrap;
    overviewDestinationBottom.lineBreakMode= UILineBreakModeTailTruncation;
    
    
    if(streetName){
        NSArray* splittedString= [self splitString:streetName];
        
        [overviewDestination setText:[splittedString objectAtIndex:0]];
        
        if(splittedString.count>1){
            [overviewDestinationBottom setText:[splittedString objectAtIndex:1]];
        }
    }else{
        overviewDestination.text= @"";
        overviewDestinationBottom.text= @"";
    }
    
    self.automaticallyAdjustsScrollViewInsets = NO;
    
    [self zoomOut:coordinates];
    
    //[self performSelector:@selector(zoomOut:) withObject:coordinates afterDelay:1.0f];
    
    if (![SMAnalytics trackEventWithCategory:@"Route" withAction:@"Overview" withLabel:self.destination withValue:0]) {
        debugLog(@"error in trackEvent");
    }
    
    CGRect fr = self.mapFade.frame;
    fr.size.height = 0.0f;
    self.mapFade.frame = fr;
    
    [self.mpView setUserTrackingMode:RMUserTrackingModeNone];
//    [self.mpView setShowsUserLocation:YES];


}

- (void)zoomOut:(NSDictionary*)coordinates {
    CLLocationCoordinate2D ne = ((CLLocation*)[coordinates objectForKey:@"neCoordinate"]).coordinate;
    CLLocationCoordinate2D sw = ((CLLocation*)[coordinates objectForKey:@"swCoordinate"]).coordinate;
    
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
    
    
    [self.mpView setCenterCoordinate:CLLocationCoordinate2DMake((ne.latitude+sw.latitude) / 2.0, (ne.longitude+sw.longitude) / 2.0)];
    [self.mpView zoomWithLatitudeLongitudeBoundsSouthWest:sw northEast:ne animated:YES];
}

-(NSArray*)splitString:(NSString*)str{
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
    int clipIndex= [self fitString:newStr intoLabel:overviewDestination size:overviewDestination.frame.size];
    int index= (splitWordIndex==0)?clipIndex : newWord.length-(newStr.length-clipIndex);
    
    BOOL noSplit= NO;
    if([self isStringSplittable:newWord atIndex:index]){
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

-(BOOL)isStringSplittable:(NSString*)str atIndex:(int)index{
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
-(BOOL)string:(NSString*)str fitsLabelWidth:(UILabel*)lbl{
    return [str sizeWithFont:lbl.font].width <= lbl.frame.size.width;
}

-(NSString*)splitString:(NSString*)str lastCharacterIndex:(int)index{
    NSMutableString* newStr= [NSMutableString stringWithString:str];
    
    if (index<0)
        return nil;
    
    for(int i=index; i>0; i--){
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
    UIFont *font           = label.font;

    CGSize sizeForString= [string sizeWithFont:font];
    if (sizeForString.width >= size.width-1) // sizeWithFont rounding
    {
        NSString *adjustedString;
        
        for (NSUInteger i = 1; i < [string length]; i++)
        {
            adjustedString = [[string substringToIndex:i] stringByAppendingFormat:@"-"];
            CGSize sizeWithFont= [adjustedString sizeWithFont:font];
            if (sizeWithFont.width >= size.width-1)
                return i - 1;
        }
    }
    
    return [string length];
}

- (IBAction)onBreakRoute:(id)sender {

    if ([SMLocationManager instance].hasValidLocation == NO) {
        UIAlertView * av = [[UIAlertView alloc] initWithTitle:nil message:translateString(@"error_no_gps_location") delegate:nil cancelButtonTitle:translateString(@"OK") otherButtonTitles:nil];
        [av show];
        return;
    }else{
        if(self.currentlyRouting){
            // get current location
            CLLocation* currentLocation= [[SMLocationManager instance] lastValidLocation];
            // get new route ( currentPosition -> destination )
            tempRoute= [[SMRoute alloc] initWithRouteStart:currentLocation.coordinate andEnd:[fullRoute getEndLocation].coordinate andDelegate:self];
            // create a trip route
            tempTripRoute= [[SMTripRoute alloc] initWithRoute:tempRoute];
        }else{
            [self performSegueWithIdentifier:@"breakRoute" sender:self];            
        }

    }

}

- (IBAction)startRouting:(id)sender {
    if ([SMLocationManager instance].hasValidLocation == NO) {
        UIAlertView * av = [[UIAlertView alloc] initWithTitle:nil message:translateString(@"error_no_gps_location") delegate:nil cancelButtonTitle:translateString(@"OK") otherButtonTitles:nil];
        [av show];
        return;
    }else{
        [self startRouting];
    }
}

- (void)addMarkers:(NSArray*)markers {
    for (int i=0; i<[markers count]; i++) {
        NSDictionary* marker = [markers objectAtIndex:i];
        
        double latitude = [(NSNumber*)[marker objectForKey:@"latitude"] doubleValue];
        double longitude = [(NSNumber*)[marker objectForKey:@"longitude"] doubleValue];
        CLLocationCoordinate2D coord = CLLocationCoordinate2DMake(latitude, longitude);
        
        NSString* title = [marker objectForKey:@"title"];
        NSString* image = [marker objectForKey:@"imageName"];
        NSString* annotation = [marker objectForKey:@"annotation"];
        NSString* alternateTitle = [marker objectForKey:@"alternateTitle"];
        
        [self addMarkerToMapView:self.mpView withCoordinate:coord title:title imageName:image annotationTitle:annotation alternateTitle:alternateTitle];
    }
}

-(void)startRouting{
    
    [self setupMapSize:YES];
    overviewShown = NO;
    
    fullRoute= self.route;
    fullRoute.delegate= nil;
    NSAssert(self.brokenRoute.brokenRoutes.count>0, @"Invalid routes.");
    self.route= [self.brokenRoute.brokenRoutes objectAtIndex:0];
    
    self.route.delegate= self;
    
    [UIView animateWithDuration:0.4f animations:^{
        [routeOverview setAlpha:0.0f];
    } completion:^(BOOL finished) {
        [routeOverview setHidden:YES];
    }];
    
    self.currentlyRouting = YES;
    [self resetZoom];
    [self.mpView setCenterCoordinate:CLLocationCoordinate2DMake(self.route.locationStart.latitude,self.route.locationStart.longitude)];
    [labelDistanceLeft setText:formatDistance(self.route.estimatedRouteDistance)];
    [labelTimeLeft setText:expectedArrivalTime(self.route.estimatedTimeForRoute)];

    [self.mpView setUserTrackingMode:RMUserTrackingModeFollowWithHeading];
    [self.mpView rotateMap:self.route.lastCorrectedHeading];

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
    [self.mpView setUserTrackingMode:RMUserTrackingModeNone];
    self.route.delegate = nil;
    self.route = nil;
    self.mpView.delegate = nil;
    SMRequestOSRM * r = [[SMRequestOSRM alloc] initWithDelegate:self];
    [r setAuxParam:@"startRoute"];
    [r setOsrmServer:self.osrmServer];
    [r getRouteFrom:self.startLocation.coordinate to:self.endLocation.coordinate via:nil];
    CGRect fr = self.mapFade.frame;
    fr.size.height = 0.0f;
    self.mapFade.frame = fr;
}

- (void) start:(CLLocationCoordinate2D)from end:(CLLocationCoordinate2D)to  withJSON:(id)jsonRoot{
    
    if (self.mpView.delegate == nil) {
        self.mpView.delegate = self;
    }
    
    for (RMAnnotation *annotation in self.mpView.annotations) {
        [self.mpView removeAnnotation:annotation];
    }
    if(!self.route){
        // TODO: From CykelPlanen
//        if([SMUser user].route){
//            self.route= [[SMUser user] route];
//        } else {
            self.route = [[SMRoute alloc] initWithRouteStart:from andEnd:to andDelegate:self andJSON:jsonRoot];
            self.route.osrmServer = self.osrmServer;
//        }
    }
    if(!self.brokenRoute) {
        self.brokenRoute= [[SMTripRoute alloc] initWithRoute:self.route];
    }

    self.route = [[SMRoute alloc] initWithRouteStart:from andEnd:to andDelegate:self andJSON:jsonRoot];
    self.route.osrmServer = self.osrmServer;
    if (!self.route) {
        return;
    }
    
    // station markers
    for(int i=0; i<self.brokenRoute.brokenRoutes.count; i++){
        SMRoute* rt= [self.brokenRoute.brokenRoutes objectAtIndex:i];
        NSArray* locations;
        if(i==0 && i!=self.brokenRoute.brokenRoutes.count-1){
            // first route, display only destination
            locations= [NSArray arrayWithObject:[rt getEndLocation]];
        }else if(i!=0 && i==self.brokenRoute.brokenRoutes.count-1){
            // last route, display only source
            locations= [NSArray arrayWithObject:[rt getStartLocation]];
        }else if(i!=0 && i!=self.brokenRoute.brokenRoutes.count-1){
            locations= [NSArray arrayWithObjects:[rt getStartLocation], [rt getEndLocation], nil];
        }
        
        if(locations){
            for(CLLocation* loc in locations){
                [self addMarkerToMapView:self.mpView withCoordinate:CLLocationCoordinate2DMake(loc.coordinate.latitude, loc.coordinate.longitude) title:@"S" imageName:@"metro_icon" annotationTitle:nil alternateTitle:nil];
            }
        }
    }

    SMAnnotation *startMarkerAnnotation = [SMAnnotation annotationWithMapView:self.mpView coordinate:from andTitle:@"A"]; /// START
    startMarkerAnnotation.annotationType = @"marker";
    startMarkerAnnotation.annotationIcon = [UIImage imageNamed:@"markerStart"];
    startMarkerAnnotation.anchorPoint = CGPointMake(0.5, 1.0);
    NSMutableArray * arr = [[self.source componentsSeparatedByString:@","] mutableCopy];
    startMarkerAnnotation.title = [[arr objectAtIndex:0] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if ([startMarkerAnnotation.title isEqualToString:@""]) {
        startMarkerAnnotation.title = translateString(@"marker_start");
    }
    [arr removeObjectAtIndex:0];
    startMarkerAnnotation.subtitle = [[arr componentsJoinedByString:@","] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    [self.mpView addAnnotation:startMarkerAnnotation];

    SMAnnotation *endMarkerAnnotation = [SMAnnotation annotationWithMapView:self.mpView coordinate:to andTitle:@"B"];
    endMarkerAnnotation.annotationType = @"marker";
    endMarkerAnnotation.annotationIcon = [UIImage imageNamed:@"markerFinish"];
    endMarkerAnnotation.anchorPoint = CGPointMake(0.5, 1.0);
    arr = [[self.destination componentsSeparatedByString:@","] mutableCopy];
    endMarkerAnnotation.title = [[arr objectAtIndex:0] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    [arr removeObjectAtIndex:0];
    endMarkerAnnotation.subtitle = [[arr componentsJoinedByString:@","] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    [self.mpView addAnnotation:endMarkerAnnotation]; /// END
    
    // TODO: From CykelPlanen
//    // start marker (A)
//    NSMutableArray * arr = [[self.source componentsSeparatedByString:@","] mutableCopy];
//    NSString* startTitle = [[arr objectAtIndex:0] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
//    [arr removeObjectAtIndex:0];
//    [self addMarkerToMapView:self.mpView withCoordinate:from title:@"A" imageName:@"a_pin" annotationTitle:startTitle alternateTitle:translateString(@"marker_start")];
//    
//    // end marker (B)
//    arr = [[self.destination componentsSeparatedByString:@","] mutableCopy];
//    NSString* endTitle = [[arr objectAtIndex:0] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
//    [arr removeObjectAtIndex:0];
//    [self addMarkerToMapView:self.mpView withCoordinate:to title:@"B" imageName:@"b_pin" annotationTitle:endTitle alternateTitle:nil];
    

    [self.mpView setCenterCoordinate:CLLocationCoordinate2DMake(from.latitude,from.longitude)];

    [self showRouteOverview];
}

-(void)addMarkerToMapView:(RMMapView *)mapView withCoordinate:(CLLocationCoordinate2D)coord title:(NSString*)title imageName:(NSString*)imageName annotationTitle:(NSString*)annotationTitle alternateTitle:(NSString*)alternateTitle{
    SMAnnotation *annotation = [SMAnnotation annotationWithMapView:mapView coordinate:coord andTitle:title];
    annotation.annotationType = @"marker";
    annotation.annotationIcon = [UIImage imageNamed:imageName];
    annotation.anchorPoint = CGPointMake(0.5, 1.0);
    NSMutableArray * arr = [[self.source componentsSeparatedByString:@","] mutableCopy];
    annotation.title = annotationTitle;

    if ([annotation.title isEqualToString:@""] && alternateTitle) {
        annotation.title = alternateTitle;
    }

    annotation.subtitle = [[arr componentsJoinedByString:@","] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    [self.mpView addAnnotation:annotation];
}

- (void) renderMinimizedDirectionsViewFromInstruction {
    if (self.route.turnInstructions.count > 0) {
        SMTurnInstruction *nextTurn = [self.route.turnInstructions objectAtIndex:0];
        [labelDistanceToNextTurn setText:formatDistance(nextTurn.lengthInMeters)];
        [imgNextTurnDirection setImage:[nextTurn largeDirectionIcon]];
    } else {
        [minimizedInstructionsView setHidden:YES];
    }
}

- (NSDictionary*) addRouteAnnotation:(SMRoute *)r {
    RMAnnotation *calculatedPathAnnotation = [RMAnnotation annotationWithMapView:self.mpView coordinate:[r getStartLocation].coordinate andTitle:nil];
    calculatedPathAnnotation.annotationType = @"path";
    calculatedPathAnnotation.userInfo = @{
                                         @"linePoints" : [NSArray arrayWithArray:r.waypoints],
                                         @"lineColor" : PATH_COLOR,
                                         @"fillColor" : [UIColor clearColor],
                                         @"lineWidth" : [NSNumber numberWithFloat:10.0f],
                                         };
    [calculatedPathAnnotation setBoundingBoxFromLocations:[NSArray arrayWithArray:r.waypoints]];
    [self.mpView addAnnotation:calculatedPathAnnotation];
    return @{
             @"neCoordinate" : calculatedPathAnnotation.neCoordinate,
             @"swCoordinate" : calculatedPathAnnotation.swCoordinate
             };
}

-(void)showRouteAnnotation{

    for(SMRoute* rt in self.brokenRoute.brokenRoutes){
        if(rt.routeType==SMRouteTypeNormal)
        [self addRouteAnnotation:rt];
    }
}

-(void)hideRouteAnnotation{

    for(RMAnnotation* annotation in self.mpView.annotations){
        if([annotation.annotationType isEqual:@"path"]){
            [self.mpView removeAnnotation:annotation];
        }
    }
}

- (void)resetZoom {
    [self.mpView setZoom:DEFAULT_MAP_ZOOM];
    [self.mpView zoomByFactor:1 near:[self.mpView coordinateToPixel:[SMLocationManager instance].lastValidLocation.coordinate] animated:YES];
}

- (void)zoomToLocation:(CLLocation*)loc temporary:(BOOL)isTemp {
    [self.mpView setUserTrackingMode:RMUserTrackingModeNone];
//    [self.mpView setZoom:DEFAULT_TURN_ZOOM];
//    [self.mpView zoomByFactor:1 near:[self.mpView coordinateToPixel:loc.coordinate] animated:YES];
    [self.mpView setCenterCoordinate:loc.coordinate];
    
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

- (void)saveRoute:(SMTripRoute*)pRoute {
    NSMutableArray* routesArr= [NSMutableArray new];
    BOOL shouldSaveRoute= NO;
    for(SMRoute* iRoute in pRoute.brokenRoutes){
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
    
//    if ([self.appDelegate.appSettings objectForKey:@"auth_token"]) {
//        SMSearchHistory * sh = [SMSearchHistory instance];
//        [sh addFinishedRouteToServer:@{
//         @"startDate" : [[self.route.visitedLocations objectAtIndex:0] objectForKey:@"date"],
//         @"endDate" : [[self.route.visitedLocations lastObject] objectForKey:@"date"],
//         @"visitedLocations" : [dt objectForKey:@"polyline"],
//         @"fromName" : self.source,
//         @"toName" : self.destination,
//         @"fromLocation" : self.startLocation,
//         @"toLocation" : self.endLocation
//         }];
//    }
}

#pragma mark - mapView delegate

- (void)checkCallouts {
    for (SMAnnotation * annotation in self.mpView.annotations) {
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
        for (id v in self.mpView.subviews) {
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
        for (id v in self.mpView.subviews) {
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
   
    if (self.currentlyRouting && self.route && userLocation) { /// START
        [self updateData:userLocation];

        [tblDirections reloadData];
        [self renderMinimizedDirectionsViewFromInstruction];

    } /// END
    
    // TODO: From CykelPlanen
//    if ([fullRoute getEndLocation] && [self location:userLocation.location matchesLocation:[fullRoute getEndLocation] distance:LOCATION_END_DISTANCE]){ // check if we reached the end of the route
//        // we reached end
//        [self reachedEndOfRoute];
//        return;
//    }
//    
//    if (self.currentlyRouting && self.route && userLocation) {
//        [self.route visitLocation:userLocation.location];
//        
//        [self setDirectionsState:currentDirectionsState];
//        
//        [self reloadFirstSwipableView];
//        
//        [labelDistanceLeft setText:formatDistance(self.route.distanceLeft)];
//        
//        CGFloat percent = 0;
//        @try {
//            if ((self.route.distanceLeft + self.route.tripDistance) > 0) {
//                percent = self.route.tripDistance / (self.route.distanceLeft + self.route.tripDistance);
//            }
//        }
//        @catch (NSException *exception) {
//            percent = 0;
//        }
//        
//        CGFloat time = self.route.distanceLeft * self.route.estimatedTimeForRoute / self.route.estimatedRouteDistance;
//        [labelTimeLeft setText:expectedArrivalTime(time)];
//        
//        [tblDirections reloadData];
//        [self renderMinimizedDirectionsViewFromInstruction];
//    }else if(nextRoute && userLocation){ // next route exists and userlocation is valid
//        if([self location:[nextRoute getStartLocation] matchesLocation:userLocation.location distance:LOCATION_STATION_DISTANCE_ON_BUS] ){ // check if we reached the beginning of the next route
//            NSLog(@"Next route");
//            self.route= nextRoute;
//            self.route.delegate= self;
//        }
//    }
}

-(BOOL)location:(CLLocation*)loc1 matchesLocation:(CLLocation*)loc2 distance:(double)pDistance{
    return [loc1 distanceFromLocation:loc2] < pDistance;
}

-(BOOL)location:(CLLocation*)loc1 matchesLocation:(CLLocation*)loc2{
    return [self location:loc1 matchesLocation:loc2 distance:LOCATION_DEFAULT_DISTANCE];
}

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

-(void)didStartBreakingRoute:(SMRoute *)route{

}

-(void)didFinishBreakingRoute:(SMRoute *)route{
    
}

-(void)didFailBreakingRoute:(SMRoute *)route{
    
}

-(void)didCalculateRouteDistances:(SMTripRoute*)route{
    
}

- (void)routeNotFound {
    self.currentlyRouting = NO;
    
    [labelDistanceLeft setText:@""];
    [labelTimeLeft setText:@""];
    
    [self setDirectionsState:directionsHidden];
    
    UIAlertView * av = [[UIAlertView alloc] initWithTitle:translateString(@"Error") message:translateString(@"error_route_not_found") delegate:nil cancelButtonTitle:translateString(@"OK") otherButtonTitles:nil];
    [av show];
}

- (void)startRoute:(SMRoute *)route {
    if (route == tempRoute){
        [self performSegueWithIdentifier:@"breakRoute" sender:self];
        return;
    }
    if (overviewShown) {
        return;
    }
    currentDirectionsState = directionsNormal;
    [routeOverview setHidden:YES];
    
    // Display new path
    [self addRouteAnnotation:self.route]; /// START, END
    // TODO: From CykelPlanen
//    for (SMRoute *route in self.brokenRoute.brokenRoutes){
//        [self addRouteAnnotation:self.route];
//        break;
//    }
    
    [self.mpView setRoutingDelegate:self];
    
    
    [tblDirections reloadData];
    
    [self setDirectionsState:directionsNormal];
    
    self.currentlyRouting = YES;
    
    [self reloadSwipableView];
    
    [self.mpView setCenterCoordinate:CLLocationCoordinate2DMake(self.route.locationStart.latitude,self.route.locationStart.longitude)];
    
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
    int index= [self.brokenRoute.brokenRoutes indexOfObject:self.route];
    if(index!=self.brokenRoute.brokenRoutes.count-1){ // if current route isn't the last route
        nextRoute= [self.brokenRoute.brokenRoutes objectAtIndex:index+1]; // we set the nextRoute
        self.route.delegate= nil; // remove the delegate from the old route
        self.route= nil;
        
        return;
    }else{
        [self reachedEndOfRoute];
    }

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
    [self.mpView setRoutingDelegate:nil];
    
    /**
     * hide the route
     */
    for (RMAnnotation *annotation in self.mpView.annotations) {
        if ([annotation.annotationType isEqualToString:@"path"]) {
            [self.mpView removeAnnotation:annotation];
        }
    }
    /**
     * show actual route travelled
     */
    //        [self showRouteTravelled];
    
    
    if (![SMAnalytics trackEventWithCategory:@"Route" withAction:@"Finished" withLabel:self.destination withValue:0]) {
        debugLog(@"error in trackEvent");
    }
    
    [self.mpView setUserTrackingMode:RMUserTrackingModeFollow];
    
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
    for (RMAnnotation *annotation in self.mpView.annotations) {
        if ([annotation.annotationType isEqualToString:@"path"]) {
            [self.mpView removeAnnotation:annotation];
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
    
    RMAnnotation *calculatedPathAnnotation = [RMAnnotation annotationWithMapView:self.mpView coordinate:loc.coordinate andTitle:nil];
    calculatedPathAnnotation.annotationType = @"path";
    calculatedPathAnnotation.userInfo = @{
                                          @"linePoints" : [NSArray arrayWithArray:arr],
                                          @"lineColor" : PATH_COLOR,
                                          @"fillColor" : [UIColor clearColor],
                                          @"lineWidth" : [NSNumber numberWithFloat:10.0f],
                                          };
    [calculatedPathAnnotation setBoundingBoxFromLocations:[NSArray arrayWithArray:arr]];
    [self.mpView addAnnotation:calculatedPathAnnotation];
}

- (void) updateRoute {
    // Remove previous path and display new one
    [noConnectionView setAlpha:0.0f];
    for (RMAnnotation *annotation in self.mpView.annotations) {
        if ([annotation.annotationType isEqualToString:@"path"]) {
            [self.mpView removeAnnotation:annotation];
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

- (IBAction)hideStopView:(id)sender {
    [UIView animateWithDuration:0.4f animations:^{
        [stopView setAlpha:0.0f];
    }];
}

- (IBAction)goBack:(id)sender {
    self.currentlyRouting = NO;
    
    [self.mpView setDelegate:nil];
    [self.mpView setRoutingDelegate:nil];
    [self.mpView setUserTrackingMode:RMUserTrackingModeNone];
    self.mpView = nil;

    [[NSFileManager defaultManager] removeItemAtPath:[[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent: @"lastRoute.plist"] error:nil];
    
    [self saveRoute];
    
    [self.navigationController popViewControllerAnimated:YES];
}

-(IBAction)buttonPressed:(id)sender {
    [UIView animateWithDuration:0.4f animations:^{
        [stopView setAlpha:1.0f];
    } completion:^(BOOL finished) {
    }];
}

- (void)trackingOn {
    debugLog(@"trackingOn() btn state = 0x%0x, prev btn state = 0x%0x", buttonTrackUser.gpsTrackState, buttonTrackUser.prevGpsTrackState);
    if (buttonTrackUser.gpsTrackState == SMGPSTrackButtonStateNotFollowing) {
        if (self.currentlyRouting == NO) {
            [self.mpView setUserTrackingMode:RMUserTrackingModeFollow];
        } else if (buttonTrackUser.prevGpsTrackState == SMGPSTrackButtonStateFollowing) {
            [self.mpView setUserTrackingMode:RMUserTrackingModeFollow];
        } else {
            [self.mpView setUserTrackingMode:RMUserTrackingModeFollowWithHeading];
        }
    } else if (buttonTrackUser.gpsTrackState == SMGPSTrackButtonStateFollowing && self.currentlyRouting) {
        [self.mpView setUserTrackingMode:RMUserTrackingModeFollowWithHeading];
    } else {
        // next state is follow
        [self.mpView setUserTrackingMode:RMUserTrackingModeFollow];
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
    [self.mpView setCenterCoordinate:center animated:NO];

    [self trackingOn];

}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if (([segue.identifier isEqualToString:@"reportError"]) ){
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
        [destViewController setRouteDirections:arr];
        [destViewController setDestination:self.destination];
        [destViewController setSource:self.source];
        [destViewController setDestinationLoc:self.endLocation];
        [destViewController setSourceLoc:self.startLocation];
    }else if([segue.identifier isEqualToString:@"breakRoute"]){
        SMBreakRouteViewController* brVC= segue.destinationViewController;
        brVC.sourceName= self.source;
        brVC.destinationName= self.destination;
        
        [SMGeocoder reverseGeocode:self.startLocation.coordinate completionHandler:^(NSDictionary *response, NSError *error) {
            NSString* address = [response objectForKey:@"title"];
            if ( [address isEqualToString:self.source] ) {
                brVC.sourceAddress = [response objectForKey:@"subtitle"];
            } else {
                brVC.sourceAddress = address;
            }

            [brVC.tableView reloadData];
        }];
        
        [SMGeocoder reverseGeocode:self.endLocation.coordinate completionHandler:^(NSDictionary *response, NSError *error) {
            NSString* address = [response objectForKey:@"title"];
            if ( [address isEqualToString:self.destination] ) {
                brVC.destinationAddress = [response objectForKey:@"subtitle"];
            } else {
                brVC.destinationAddress = address;
            }
            
           [brVC.tableView reloadData];
        }];
        
        if(self.currentlyRouting){
            brVC.tripRoute= tempTripRoute;
            brVC.fullRoute= [brVC.tripRoute.brokenRoutes objectAtIndex:0];
        }else{
            brVC.tripRoute= self.brokenRoute;
        }
    }
}

#pragma mark - UITableViewDataSource methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (tableView == self.cargoTableView) {
        return self.cargoItems.count;
    } else {
        return self.route.turnInstructions.count;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (tableView==self.cargoTableView) {
        SMRouteTypeSelectCell* cell= [tableView dequeueReusableCellWithIdentifier:@"cargoCell"];
        NSDictionary *cargoItem= [self.cargoItems objectAtIndex:indexPath.row];
        [cell setupCellWithData:cargoItem];
        return cell;
    } else {
        int i = [indexPath row];
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
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if(tableView==self.cargoTableView){
        return [SMRouteTypeSelectCell getHeight];
    }else{
        SMTurnInstruction *turn = (SMTurnInstruction *)[self.route.turnInstructions objectAtIndex:indexPath.row];
        if (indexPath.row == 0) {
            return [SMDirectionTopCell getHeightForDescription:[turn descriptionString] andWayname:turn.shortDescriptionString];
        } else {
            return [SMDirectionCell getHeightForDescription:[turn descriptionString] andWayname:turn.shortDescriptionString];
        }
    }
}

#pragma mark - UITableViewDelegate methods

- (void)resetZoomTurn {
    if (buttonTrackUser.gpsTrackState == SMGPSTrackButtonStateNotFollowing)
        [self trackUser:nil];
}

- (void)slideBackToMap {
    [UIView animateWithDuration:0.2f delay:0.0f options:UIViewAnimationOptionBeginFromCurrentState animations:^{
        CGRect frame = centerView.frame;
        frame.origin.x = centerView.startPos;
        [centerView setFrame:frame];
    } completion:^(BOOL finished) {
    }];
}

// TODO: From CykelPlanen
//- (void)overlaysMenuItemSelected:(int)row selected:(BOOL)pSelected{
//    if (row == 0){
//        [self.appDelegate.mapOverlays toggleMarkers:@"path" state:pSelected];
//    } else if ( row == 1 ) {
//        [self.appDelegate.mapOverlays toggleMarkers:@"service" state:pSelected];
//    } else if ( row == 2 ) {
//        [self.appDelegate.mapOverlays toggleMarkers:@"station" state:pSelected];
//    } else if ( row == 3 ) {
//        [self.appDelegate.mapOverlays toggleMarkers:@"metro" state:pSelected];
//    } else if ( row == 4 ) {
//        [self.appDelegate.mapOverlays toggleMarkers:@"local-trains" state:pSelected];
//    }
//}

- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (tableView == self.cargoTableView){
        [self overlaysMenuItemSelected:indexPath.row selected:NO];
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (tableView == self.cargoTableView){
        NSDictionary* currentRow = [self.cargoItems objectAtIndex:indexPath.row]; /// START
        self.osrmServer = currentRow[@"server"];
        [self newRouteType]; /// END
        // TODO: From CykelPlanen
//        [self overlaysMenuItemSelected:indexPath.row selected:YES];
    } else {
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
    }
}

#pragma mark - alert view delegate

- (void)alertView:(UIAlertView *)alertView willDismissWithButtonIndex:(NSInteger)buttonIndex {
    switch (buttonIndex) {
        case 2:
            [self performSegueWithIdentifier:@"reportError" sender:nil];
            break;
        case 1: {
            [self goBack:nil];
        }
            break;
        default:
            break;
    }
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
            CGRect frame = tblDirections.frame;
            frame.size.height = instructionsView.frame.size.height - tblDirections.frame.origin.y;
            [tblDirections setFrame:frame];
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
                    tblHeight = [SMDirectionTopCell getHeightForDescription:[[self.route.turnInstructions objectAtIndex:0] descriptionString] andWayname:[[self.route.turnInstructions objectAtIndex:0] wayName]];                    
                }
            }
            newY = maxY - tblHeight;
            [self repositionInstructionsView:newY + 1];
            lastDirectionsPos = newY + 1;
            [swipableView setHidden:NO];
            [swipableView setFrame:tblDirections.frame];
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


- (void)resizeMap {
//    CGRect frame = self.mpView.frame;
//    frame.size.height = instructionsView.frame.origin.y - frame.origin.y + 5.0f;
//    [self.mpView setFrame:frame];
    CGRect frame = self.mapFade.frame;
    frame.size.height = instructionsView.frame.origin.y - frame.origin.y + 5.0f;
    [self.mapFade setFrame:frame];
}

- (void)repositionInstructionsView:(CGFloat)newY {
    CGRect frame = instructionsView.frame;
    frame.size.height += frame.origin.y - newY;
    frame.origin.y = newY;
    [instructionsView setFrame:frame];
    
    [self resizeMap];
}

- (void)repositionSwipableView:(CGFloat)newY {
    CGRect frame = swipableView.frame;
    frame.size.height += frame.origin.y - newY;
    frame.origin.y = newY;
    [swipableView setFrame:frame];
}

- (void)setNewDirections:(CGFloat)newY {
    switch (currentDirectionsState) {
        case directionsFullscreen:
            if (newY > lastDirectionsPos + 20.0f) {
                [self setDirectionsState:directionsNormal];
                self.cargoHandleImageView.hidden = NO;
                buttonTrackUser.hidden = NO;
            } else {
                [self setDirectionsState:directionsFullscreen];
                self.cargoHandleImageView.hidden = YES;
                buttonTrackUser.hidden = YES;
            }
            break;
        case directionsNormal:
            if (newY > lastDirectionsPos + 20.0f) {
                [self setDirectionsState:directionsMini];
                self.cargoHandleImageView.hidden = NO;
                buttonTrackUser.hidden = NO;
            } else if (newY < lastDirectionsPos - 20.0f) {
                [self setDirectionsState:directionsFullscreen];
                self.cargoHandleImageView.hidden = YES;
                buttonTrackUser.hidden = YES;
            } else {
                [self setDirectionsState:directionsNormal];
                self.cargoHandleImageView.hidden = NO;
                buttonTrackUser.hidden = NO;
            }
            break;
        case directionsMini:
            if (newY < lastDirectionsPos - 20.0f) {
                [self setDirectionsState:directionsNormal];
                self.cargoHandleImageView.hidden = NO;
                buttonTrackUser.hidden = NO;
            } else {
                [self setDirectionsState:directionsMini];
                self.cargoHandleImageView.hidden = NO;
                buttonTrackUser.hidden = NO;
            }
            break;
        case directionsHidden:
            self.cargoHandleImageView.hidden = NO;
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
        [self.mpView setUserTrackingMode:oldTrackingMode];
    } else if (sender.state == UIGestureRecognizerStateChanged) {
        self.pulling = YES;
        [swipableView setHidden:YES];
        float newY = MAX([sender locationInView:self.view].y - touchOffset, self.mpView.frame.origin.y);
        [self repositionInstructionsView:newY];
    } else if (sender.state == UIGestureRecognizerStateBegan) {
        self.pulling = YES;
        oldTrackingMode = self.mpView.userTrackingMode;
        [self.mpView setUserTrackingMode:RMUserTrackingModeNone];
        touchOffset = [sender locationInView:instructionsView].y;
        [swipableView setHidden:YES];
        [self.cargoHandleImageView setHidden:YES];
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
    [swipableView setFrame:tblDirections.frame];
    SMTurnInstruction * instr = nil;
    NSInteger start = MAX(0, floor(swipableView.contentOffset.x / self.view.frame.size.width));
    @synchronized(self.instructionsForScrollview) {
        if ([self.instructionsForScrollview count] > start || start > 0) {
            instr = [self.instructionsForScrollview objectAtIndex:start];
        }
        self.instructionsForScrollview = [NSArray arrayWithArray:self.route.turnInstructions]; // START, END
        // TODO: From CykelPlanen
//        NSMutableArray* arr= [NSMutableArray new];
//        for(SMRoute* route in self.brokenRoute.brokenRoutes){
//            [arr addObjectsFromArray:route.turnInstructions];
//        }
//        self.instructionsForScrollview = [NSArray arrayWithArray:arr];
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
                    [cell setFrame:CGRectMake(i*swipableView.frame.size.width, 0, swipableView.frame.size.width, [SMSwipableView getHeight])];
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
    } else if (object == self.mpView && [keyPath isEqualToString:@"zoom"]) {
        NSLog(@"Zoom: %f", self.mpView.zoom);
    } else if (object == self.mpView && [keyPath isEqualToString:@"userTrackingMode"]) {
        if (self.mpView.userTrackingMode == RMUserTrackingModeFollow) {
            [buttonTrackUser newGpsTrackState:SMGPSTrackButtonStateFollowing];
            [self setupMapSize:NO];
        } else if (self.mpView.userTrackingMode == RMUserTrackingModeFollowWithHeading) {
            [buttonTrackUser newGpsTrackState:SMGPSTrackButtonStateFollowingWithHeading];
            [self setupMapSize:NO]; // set to YES to center
        } else if (self.mpView.userTrackingMode == RMUserTrackingModeNone) {
            [buttonTrackUser newGpsTrackState:SMGPSTrackButtonStateNotFollowing];
            [self setupMapSize:NO];
        }
    } else if (object == self.mapFade && [keyPath isEqualToString:@"frame"]) {
        CGFloat maxSize = self.view.frame.size.height - 160.0f;
        if (self.mapFade.frame.size.height > maxSize) {
            [self.mapFade setAlpha:0.0f];
            [self toggleBreakRouteButton];
            
        } else {
            [self.mapFade setAlpha: 0.8f - ((self.mapFade.frame.size.height - MAX_TABLE) * 0.8f / (maxSize - MAX_TABLE))];

            [self toggleBreakRouteButton];

        }
        
        if (self.mapFade.alpha > 0.7f) {
            [arrivalBG setImage:[UIImage imageNamed:@"distance_black"]];
            [closeButton setImage:[UIImage imageNamed:@"btnCloseDark"] forState:UIControlStateNormal];
            [labelDistanceLeft setTextColor:[UIColor whiteColor]];
            [labelTimeLeft setTextColor:[UIColor whiteColor]];
        } else {
            [arrivalBG setImage:[UIImage imageNamed:@"distance_white"]];
            [closeButton setImage:[UIImage imageNamed:@"btnClose"] forState:UIControlStateNormal];
            [labelDistanceLeft setTextColor:[UIColor darkGrayColor]];
            [labelTimeLeft setTextColor:[UIColor darkGrayColor]];
        }
        
        debugLog(@"size: %f maxSize: %f alpha: %f", self.mapFade.frame.size.height, maxSize, self.mapFade.alpha);
    } else if (object == centerView && [keyPath isEqualToString:@"frame"]) {
        if (centerView.frame.origin.x > 0.0f) {
            if (blockingView.alpha == 0.0f) {
                oldTrackingMode = self.mpView.userTrackingMode;
                [self.mpView setUserTrackingMode:RMUserTrackingModeNone];
                [blockingView setAlpha:1.0f];
                for (id v in self.mpView.subviews) {
                    if ([v isKindOfClass:[SMCalloutView class]]) {
                        [v removeFromSuperview];
                    }
                }
            }
        } else {
            [self.mpView setUserTrackingMode:oldTrackingMode];
            [blockingView setAlpha:0.0f];
        }
    }
}

#pragma mark - routing delegate

- (double)getCorrectedHeading {
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
            UIAlertView * av = [[UIAlertView alloc] initWithTitle:nil message:translateString(@"error_route_not_found") delegate:nil cancelButtonTitle:translateString(@"OK") otherButtonTitles:nil];
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

-(void)toggleBreakRouteButton{
    breakRouteButton.userInteractionEnabled= YES;
    [breakRouteButton setImage:[UIImage imageNamed:@"break_route"] forState:UIControlStateNormal];
}

-(BOOL)breakRouteButtonEnabled{
    return !self.currentlyRouting;
}

-(void)setDestination:(NSString *)pDestination{
    _destination= pDestination;
}

#pragma mark - statusbar style

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

@end
