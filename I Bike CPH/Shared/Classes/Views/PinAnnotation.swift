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
        case Regular, Start, End, Metro, STrain, Bus, Ferry, Train, Walk, Bike
    }
    static func typeForRouteType(routeType: SMRouteType) -> Type? {
        switch routeType {
        case SMRouteTypeBike: return .Bike
        case SMRouteTypeWalk: return .Walk
        case SMRouteTypeSTrain: return .STrain
        case SMRouteTypeMetro: return .Metro
        case SMRouteTypeFerry: return .Ferry
        case SMRouteTypeBus: return .Bus
        case SMRouteTypeTrain: return .Train
        default: return nil
        }
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
        // Update icon, since didSet isn't called on property the `type`
        updateIconToType()
    }
    
    func updateIconToType() {
        let imageName: String = {
            switch self.type {
                case .Regular: return "marker"
                case .Start: return "markerStart"
                case .End: return "markerFinish"
                case .Metro: return "pin_metro"
                case .STrain: return "pin_strain"
                case .Bus: return "pin_bus"
                case .Ferry: return "pin_ferry"
                case .Train: return "pin_train"
                case .Walk: return "pin_walk"
                case .Bike: return "pin_bike"
            }
        }()
        annotationIcon = UIImage(named: imageName)
        // Fix at bottom center
        anchorPoint = CGPoint(x: 0.5, y: 1)
    }
}
