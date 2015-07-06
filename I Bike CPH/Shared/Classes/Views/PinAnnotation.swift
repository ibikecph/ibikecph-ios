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
    
    enum Type {
        case Regular, Start, End
    }
    
    var type: Type {
        didSet {
            updateIconToType()
        }
    }
    
    init(mapView: MapView, coordinate: CLLocationCoordinate2D, type: Type = .Regular, title: String? = nil) {
        // Subclass properties
        self.type = type
        // Init
        super.init(mapView: mapView.mapView, coordinate: coordinate, andTitle: title ?? "")
        // Super class properties
        annotationType = "marker"
        // Update icon, since didSet isn't called on property the `type`
        updateIconToType()
    }
    
    func updateIconToType() {
        let imageName: String = {
            switch self.type {
                case .Regular: return "markerFinish"
                case .Start: return "markerStart"
                case .End: return "markerFinish"
            }
        }()
        annotationIcon = UIImage(named: imageName)
        // Fix at bottom center
        anchorPoint = CGPoint(x: 0.5, y: 1)
    }
}
