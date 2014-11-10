//
//  SMMapManager.h
//  I Bike CPH
//
//  Created by Nikola Markovic on 7/25/13.
//  Copyright (c) 2013 City of Copenhagen. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RMMapView.h"
@interface SMMapManager : NSObject

+(SMMapManager*)instance;

-(void)addMarkerToMapView:(RMMapView*)mapView withCoordinate:(CLLocationCoordinate2D)coord title:(NSString*)title imageName:(NSString*)imageName
          annotationTitle:(NSString*)annotationTitle alternateTitle:(NSString*)alternateTitle;
@end
