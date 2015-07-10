//
//  ServiceStationsAnnotation.swift
//  I Bike CPH
//
//  Created by Tobias Due Munk on 10/07/15.
//  Copyright (c) 2015 I Bike CPH. All rights reserved.
//

import Foundation


class ServiceStationsAnnotation: Annotation {
    
    init(mapView: MapView, coordinate: CLLocationCoordinate2D) {
        // Init
        super.init(mapView: mapView.mapView, coordinate: coordinate, andTitle: "")
        // Super class properties
        annotationType = "marker"
        // Icon
        annotationIcon = UIImage(named: "serviceStation")
    }
}
