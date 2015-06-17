//
//  PinAnnotation.swift
//  I Bike CPH
//
//  Created by Tobias Due Munk on 08/06/15.
//  Copyright (c) 2015 I Bike CPH. All rights reserved.
//

import UIKit

class Annotation: RMAnnotation {
    
}


class PinAnnotation: Annotation {
    
    init(mapView: MapView, coordinate: CLLocationCoordinate2D, title: String? = nil) {
        super.init(mapView: mapView.mapView, coordinate: coordinate, andTitle: title ?? "")
        
        self.annotationType = "marker"
        self.annotationIcon = UIImage(named: "markerFinish")
    }
}
