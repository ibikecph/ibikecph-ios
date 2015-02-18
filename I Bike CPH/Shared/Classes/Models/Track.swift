//
//  Track.swift
//  I Bike CPH
//
//  Created by Tobias Due Munk on 16/02/15.
//  Copyright (c) 2015 I Bike CPH. All rights reserved.
//

import CoreLocation

class Track: RLMObject {
    dynamic var locations = RLMArray(objectClassName: TrackLocation.className())
    dynamic var start = ""
    dynamic var end = ""
    dynamic var length: Double = 0
    
    func recalculateLength() {
        var newLength: Double = 0
        for (index, location) in enumerate(locations) {
            if index + 1 >= locations.count {
                continue
            }
            if let nextLocation = locations[index+1] as? TrackLocation {
                if let location = location as? TrackLocation {
                    newLength += location.location().distanceFromLocation(nextLocation.location())
                }
            }
        }
        realm.beginWriteTransaction()
        length = newLength
        realm.commitWriteTransaction()
    }
}
