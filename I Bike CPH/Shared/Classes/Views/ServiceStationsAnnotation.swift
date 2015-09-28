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
        super.init(mapView: mapView.mapView, coordinate: coordinate, andTitle: "")
        annotationIcon = UIImage(named: "serviceStationAnnotation")
        anchorPoint = CGPoint(x: 0.5, y: 0.5)
    }
}
