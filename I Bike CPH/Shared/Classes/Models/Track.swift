//
//  Track.swift
//  I Bike CPH
//
//  Created by Tobias Due Munk on 16/02/15.
//  Copyright (c) 2015 I Bike CPH. All rights reserved.
//

import CoreLocation
import SwiftyJSON

class Track: RLMObject {
    dynamic var activity: TrackActivity = TrackActivity()
    dynamic var locations = RLMArray<RLMObject>(objectClassName: TrackLocation.className())
    dynamic var start = ""
    dynamic var end = ""
    dynamic var length: Double = 0
    dynamic var duration: Double = 0
    dynamic var hasBeenGeocoded: Bool = false
    // Calculated from first and last location object
    dynamic var startTimestamp: Double = 0
    dynamic var endTimestamp: Double = 0
    dynamic var serverId: String = ""
}


extension Track {
	
    func startDate() -> Date? {
        return (locationsSorted().firstObject() as? TrackLocation)?.date() as! Date
    }
	
    func endDate() -> Date? {
        return (locationsSorted().lastObject() as? TrackLocation)?.date() as! Date
    }
	
    func recalculate() {
        let realm = RLMRealm.default()
        let transact = !realm.inWriteTransaction
        if transact {
            realm.beginWriteTransaction()
        }
        if isInvalidated {
            if transact {
                realm.cancelWriteTransaction()
            }
            return
        }
        recalculateTimestamps()
        recalculateDuration()
        recalculateLength()
        if transact {
            do {
                try realm.commitWriteTransaction()
            } catch {
                print("Could not commit Realm write transaction!")
            }
        }
    }
    
    func deleteFromRealmWithRelationships(_ realm: RLMRealm = .default(), keepLocations: Bool = false, keepActivity: Bool = false) {
        let transact = !realm.inWriteTransaction
        if transact {
            realm.beginWriteTransaction()
        }
        if !keepLocations {
            realm.deleteObjects(locations)
        }
        if !keepActivity,
            let activityRealm = activity.realm, activityRealm == realm {
            realm.delete(activity)
        }
        deleteFromRealm()
        if transact {
            do {
                try realm.commitWriteTransaction()
            } catch {
                print("Could not commit Realm write transaction!")
            }
        }
    }
    
    fileprivate func recalculateTimestamps() {
        // Use first TrackLocation timestamp. Fallback to activity
        startTimestamp = (locationsSorted().firstObject() as? TrackLocation)?.timestamp ?? activity.startDate.timeIntervalSince1970 ?? 0
        endTimestamp = (locationsSorted().lastObject() as? TrackLocation)?.timestamp ?? activity.startDate.timeIntervalSince1970 ?? 0
    }
    
    fileprivate func recalculateLength() {
        var newLength: Double = 0
        let locations = locationsSorted()
        for (index, location) in locations.enumerated() {
            if index + 1 >= Int(locations.count) {
                continue
            }
            if let nextLocation = locations[UInt(index+1)] as? TrackLocation {
                if let location = location as? TrackLocation {
                    newLength += location.location().distance(from: nextLocation.location())
                }
            }
        }
        length = newLength
    }
    
    fileprivate func recalculateDuration() {
        if let newDuration = endDate()?.timeIntervalSince(startDate() ?? endDate()!) {
            duration = newDuration
        } else {
            duration = 0
        }
    }
    
    func speeding(_ speedLimit: Double, minLength: Double = 0.050) -> Bool {
        let duration = self.duration / 3600
        if duration <= 0 {
            return false
        }
        let length = self.length / 1000
        if length < minLength {
            return false
        }
        let speed = length/duration
        if speed < speedLimit {
            return false
        }
        return true
    }
    
    func slow(_ speedLimit: Double, minLength: Double = 0.05) -> Bool {
        let duration = self.duration / 3600
        if duration <= 0 {
            return false
        }
        let length = self.length / 1000
        if length < minLength {
            return false
        }
        let speed = length/duration
        if speed > speedLimit {
            return false
        }
        return true
    }
    
    func lowAccuracy(_ minAccuracy: Double = 100) -> Bool {
        let locations = locationsSorted().objects(with: NSPredicate(value: true))
        let horizontal = locations.average(ofProperty: "horizontalAccuracy")?.doubleValue ?? 0
        let vertical = locations.average(ofProperty: "verticalAccuracy")?.doubleValue ?? 0
        return min(horizontal, vertical) > minAccuracy
    }
    
    func flightDistance() -> Double? {
        if self.locations.count <= 1 {
            return nil
        }
        let locations = locationsSorted()
        if let
            firstLocation = locations.firstObject() as? TrackLocation,
            let lastLocation = locations.lastObject() as? TrackLocation
        {
            return firstLocation.location().distance(from: lastLocation.location())
        }
        return nil
    }
    
    func flightWithOneMedianStopDistance() -> Double? {
        if self.locations.count <= 2 {
            return nil
        }
        let locations = locationsSorted()
        if let firstLocation = locations.firstObject() as? TrackLocation {
            let centerIndex = UInt(floor(Double(locations.count)/2))
            if let centerLocation = locations[centerIndex] as? TrackLocation {
                if let lastLocation = locations.lastObject() as? TrackLocation {
                    let distance1 = firstLocation.location().distance(from: centerLocation.location())
                    let distance2 = centerLocation.location().distance(from: lastLocation.location())
                    return distance1 + distance2
                }
            }
        }
        return nil
    }
    
    func speeds() -> [Double] {
        var speeds = [Double]()
        let locations = locationsSorted()
        for (index, location) in locations.enumerated() {
            if index + 1 >= Int(locations.count) {
                continue
            }
            if let nextLocation = locations[UInt(index+1)] as? TrackLocation {
                if let location = location as? TrackLocation {
                    let length = location.location().distance(from: nextLocation.location())
                    let duration = nextLocation.date().timeIntervalSince(location.date())
                    let speed = length / duration
                    speeds.append(speed)
                }
            }
        }
        return speeds
    }
    
    func smoothSpeeds() -> [Double] {
        var smoothSpeed: Double = length / duration // Begin at average speed
        let lowpass = 0.01
        var smoothSpeeds = [Double]()
        for speed in speeds() {
            // Ignore extreme jumps in speed
            if speed > 20*smoothSpeed {
                // Do nothing
            } else {
                smoothSpeed = lowpass * speed + (1 - lowpass) * smoothSpeed
            }
            smoothSpeeds.append(smoothSpeed)
        }
        return smoothSpeeds
    }
    
    /**
    Smoothed top speed of track
    
    :returns: Top speed in meters per second [m/s]
    */
    func topSpeed() -> Double {
        let speeds = smoothSpeeds()
        return speeds.count > 0 ? speeds.max() ?? 0 : 0
    }
    
    func geocode(_ synchronous: Bool = false, completion:((Bool) -> ())? = nil) {
        if let startLocation = locations.firstObject() as? TrackLocation {
            let coordinate = startLocation.coordinate()
            SMGeocoder.reverseGeocode(coordinate, synchronous: synchronous) { (item: KortforItem?, error: Error?) in
                if let realm = self.realm {
                    let transact = !realm.inWriteTransaction
                    if transact {
                        realm.beginWriteTransaction()
                    }
                    if self.isInvalidated {
                        if transact {
                            realm.cancelWriteTransaction()
                        }
                        completion?(false)
                        return
                    }
                    var succeeded = false
                    if let item = item {
                        self.start = item.street
                        succeeded = true
                    }
                    if transact {
                        do {
                            try realm.commitWriteTransaction()
                        } catch {
                            print("Could not commit Realm write transaction!")
                        }
                    }
                    if !succeeded {
                        return // Only proceed if "start" was set
                    }
                    if let endLocation = self.locations.lastObject() as? TrackLocation {
                        let coordinate = endLocation.coordinate()
                        SMGeocoder.reverseGeocode(coordinate, synchronous: synchronous) { (item: KortforItem?, error: Error?) in
                            let transact = !realm.inWriteTransaction
                            if transact {
                                realm.beginWriteTransaction()
                            }
                            if self.isInvalidated {
                                if transact {
                                    realm.cancelWriteTransaction()
                                }
                                completion?(false)
                                return
                            }
                            if let item = item {
                                self.end = item.street
                                self.hasBeenGeocoded = true
                                completion?(true)
                            } else {
                                completion?(false)
                            }
                            if transact {
                                do {
                                    try realm.commitWriteTransaction()
                                } catch {
                                    print("Could not commit Realm write transaction!")
                                }
                            }
                        }
                    }
                }
                }
        }
    }
    
    func jsonForServerUpload() -> JSON? {
        let locations = locationsSorted()
        if let firstLocation = locations.firstObject() as? TrackLocation {
            if let trackToken = UserHelper.trackToken() {
                let startTimestamp = firstLocation.timestamp.roundTo(1)
                var serializedLocations = [AnyObject]()
        
                for location in locations {
                    if let location = location as? TrackLocation {
                        let serializedLocation = [
                            "seconds_passed": Int((location.timestamp - startTimestamp).roundTo(1)),
                            "latitude": location.latitude.roundTo(1000000),
                            "longitude": location.longitude.roundTo(1000000)
                            ] as [String : Any]
                        serializedLocations.append(serializedLocation as AnyObject)
                    }
                }
                
                let json: JSON = [
                    "track": [
                        "signature": trackToken,
                        "timestamp": startTimestamp,
                        "from_name": start,
                        "to_name": end,
                        "coord_count": serializedLocations.count,
                        "coordinates": serializedLocations,
                    ]
                ]
                return json
            }
        }
        return nil
    }

    func locationsSorted() -> RLMResults<RLMObject> {
        return locations.sortedResults(usingKeyPath: "timestamp", ascending: true)
    }
}


extension Double {
    
    func roundTo(_ to: Int) -> Double {
        let to = Double(to)
        return (self * to).rounded() / to
    }
}
