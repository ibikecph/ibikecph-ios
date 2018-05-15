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
    
    enum PinAnnotationType {
        case regular, start, end, metro, sTrain, bus, ferry, train, walk, bike
    }
    static func typeForRouteType(_ routeType: SMRouteType) -> PinAnnotationType? {
        switch routeType {
        case .bike: return .bike
        case .walk: return .walk
        case .sTrain: return .sTrain
        case .metro: return .metro
        case .ferry: return .ferry
        case .bus: return .bus
        case .train: return .train
        }
    }

    var type: PinAnnotationType {
        didSet {
            updateIconToType()
        }
    }
    
    init(mapView: MapView, coordinate: CLLocationCoordinate2D, type: PinAnnotationType = .regular, title: String? = nil) {
        // Subclass properties
        self.type = type
        // Init
        super.init(mapView: mapView.mapView, coordinate: coordinate, andTitle: title ?? "")
        // Update icon, since didSet isn't called on property the `type`
        updateIconToType()
    }
    
    func updateIconToType() {
        let imageName: String = {
            switch self.type {
                case .regular: return "marker"
                case .start: return "markerStart"
                case .end: return "markerFinish"
                case .metro: return "pin_metro"
                case .sTrain: return "pin_strain"
                case .bus: return "pin_bus"
                case .ferry: return "pin_ferry"
                case .train: return "pin_train"
                case .walk: return "pin_walk"
                case .bike: return "pin_bike"
            }
        }()
        annotationIcon = UIImage(named: imageName)
        // Fix at bottom center
        anchorPoint = CGPoint(x: 0.5, y: 1)
    }
}
