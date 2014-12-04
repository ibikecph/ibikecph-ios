//
//  SMViewController.h
//  I Bike CPH
//
//  Created by Ivan Pavlovic on 22/01/2013.
//  Copyright (c) 2013 City of Copenhagen. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "SMEnterRouteController.h"
#import "SMEvents.h"

#import "RMMapView.h"
#import "SMAnnotation.h"
#import "SMNearbyPlaces.h"
#import "SMRequestOSRM.h"

#import "SMGPSTrackButton.h"
#import "SMSearchController.h"

#import "FlickableView.h"

/**
 * View controller for main app use. Has map, menu button, search button, location/tracking button.
 */
@interface SMMainViewController : SMTranslatedViewController <RMMapViewDelegate, UIScrollViewDelegate, UITableViewDelegate, UITableViewDataSource, EnterRouteDelegate, UIGestureRecognizerDelegate, SMAnnotationActionDelegate, SMNearbyPlacesDelegate, SMRequestOSRMDelegate, SMSearchDelegate, ViewTapDelegate>

@property (nonatomic, strong) SMAnnotation* endMarkerAnnotation;

@end
