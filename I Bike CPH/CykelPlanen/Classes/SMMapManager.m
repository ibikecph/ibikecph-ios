//
//  SMMapManager.m
//  I Bike CPH
//
//  Created by Nikola Markovic on 7/25/13.
//  Copyright (c) 2013 City of Copenhagen. All rights reserved.
//

#import "SMMapManager.h"

#import "SMAnnotation.h"

@implementation SMMapManager

+(SMMapManager*)instance{
    static SMMapManager* INSTANCE;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        INSTANCE= [SMMapManager new];
    });
    
    return INSTANCE;
}



-(void)addMarkerToMapView:(RMMapView*)mapView withCoordinate:(CLLocationCoordinate2D)coord title:(NSString*)title imageName:(NSString*)imageName
          annotationTitle:(NSString*)annotationTitle alternateTitle:(NSString*)alternateTitle{
    SMAnnotation *annotation = [SMAnnotation annotationWithMapView:mapView coordinate:coord andTitle:title];
    annotation.annotationType = @"marker";
    annotation.annotationIcon = [UIImage imageNamed:imageName];
    annotation.anchorPoint = CGPointMake(0.5, 1.0);
//    NSMutableArray * arr = [[self.source componentsSeparatedByString:@","] mutableCopy];
    annotation.title = annotationTitle;
    
    if ([annotation.title isEqualToString:@""] && alternateTitle) {
        annotation.title = alternateTitle;
    }
    
//    annotation.subtitle = [[arr componentsJoinedByString:@","] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    [mapView addAnnotation:annotation];
}

@end
