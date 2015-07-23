//
//  SMMapOverlays.h
//  I Bike CPH
//
//  Created by Igor Jerković on 7/29/13.
//  Copyright (c) 2013 City of Copenhagen. All rights reserved.
//

#import <Foundation/Foundation.h>
@class MapView;

/**
 * Map overlays. Handle markers/annotations for metro, service, station, and local train.
 */
@interface SMMapOverlays : NSObject

- (SMMapOverlays*)initWithMapView:(MapView*)mapView;
- (void)useMapView:(MapView*)mapView;
- (void)updateOverlays;

@end
