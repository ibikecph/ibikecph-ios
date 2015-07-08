//
//  CLLocationCoordinate2D.swift
//  I Bike CPH
//
//  Created by Tobias Due Munk on 08/07/15.
//  Copyright (c) 2015 I Bike CPH. All rights reserved.
//

import CoreLocation

extension CLLocationCoordinate2D {
    
    /// The angle between -180 and 180 degrees
    func degreesFromCoordinate(coordinate: CLLocationCoordinate2D) -> CLLocationDirection {
        let deltaLatitude = latitude - coordinate.latitude
        let deltaLongitude = longitude - coordinate.longitude
        let angle = atan2(deltaLatitude, deltaLongitude) * 180 / M_PI
        return angle
    }
}
