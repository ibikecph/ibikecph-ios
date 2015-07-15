//
//  TracksHandler.swift
//  I Bike CPH
//
//  Created by Tobias Due Munk on 20/02/15.
//  Copyright (c) 2015 I Bike CPH. All rights reserved.
//

import UIKit
import CoreMotion
import CoreLocation

let processedSmallNoticationKey = "processedSmallNoticationKey"
let processedBigNoticationKey = "processedBigNoticationKey"
let processedGeocodingNoticationKey = "processedGeocodingNoticationKey"

class TracksHandler {
    static let instance = TracksHandler()

    private var processing: Bool = false {
        didSet {
            println("Processing \(processing)")
            UIApplication.sharedApplication().networkActivityIndicatorVisible = processing
        }
    }

    private let lastProcessedSmallKey = "lastProcessedSmallKey"
    var lastProcessedSmall: NSDate {
        get { return Defaults[lastProcessedSmallKey].date ?? NSDate(timeIntervalSince1970: 0) }
        set { Defaults[lastProcessedSmallKey] = newValue }
    }
    private let lastProcessedBigKey = "lastProcessedBigKey"
    var lastProcessedBig: NSDate {
        get { return Defaults[lastProcessedBigKey].date ?? NSDate(timeIntervalSince1970: 0) }
        set { Defaults[lastProcessedBigKey] = newValue }
    }
    
    private lazy var operationQueue: NSOperationQueue = {
        let queue = NSOperationQueue() // Create background queue
        queue.maxConcurrentOperationCount = 1
        return queue
    }()
    
    class func setNeedsProcessData(userInitiated: Bool = false) {
        if compressingRealm {
            Async.main(after: 10) {
                self.setNeedsProcessData()
            }
            return
        }
        let timeIntervalSinceBig = NSDate().timeIntervalSinceDate(instance.lastProcessedBig)
        let timeIntervalSinceSmall = NSDate().timeIntervalSinceDate(instance.lastProcessedSmall)
        if
            userInitiated &&
            timeIntervalSinceBig > 60*1 // Allow userInitiated every 1 min
        {
            instance.cleanUpBig(asap: true)
            instance.lastProcessedBig = NSDate()
            return
        }
        if timeIntervalSinceBig > 60*60*1 { // Do big stuff every hour
            instance.cleanUpBig(asap: false)
            instance.lastProcessedBig = NSDate()
            return
        }
        if timeIntervalSinceSmall > 60*5 { // Do small stuff every 5 min
            instance.cleanUpSmall()
            instance.lastProcessedSmall = NSDate()
            return
        }
        Async.main(after: 10) {
            self.setNeedsProcessData()
        }
    }
    
    private func cleanUpSmall() {
        if TracksHandler.instance.processing {
            println("Already processing")
            return
        }
        TracksHandler.instance.processing = true
        
        println("Start processing small")
        let fromDate = lastProcessedSmall.dateByAddingTimeInterval(-60*15) // Go 15 minutes back
        let operations = [
            MergeCloseSameActivityTracksOperation(fromDate: fromDate, seconds: 60),
            RecalculateTracksOperation(fromDate: fromDate)
        ]
        for operation in operations {
            operation.queuePriority = .Low
            operation.qualityOfService = .Background
        }
        operations.last?.completionBlock = {
            println("Done processing small")
            TracksHandler.instance.processing = false
            NotificationCenter.post(processedSmallNoticationKey, object: self)
        }
        TracksOperation.addDependencies(operations)
        operationQueue.addOperations(operations, waitUntilFinished: false)
    }
    
    private func cleanUpBig(#asap: Bool) {
        if TracksHandler.instance.processing {
            println("Already processing")
            Async.main(after: 60*1) { // Check again after 1 minute
                self.cleanUpBig(asap: asap)
            }
            return
        }
        TracksHandler.instance.processing = true
        
        println("Start processing big")
        let fromDate = lastProcessedBig.dateByAddingTimeInterval(-60*60*24) // Go 24 hours back
        let operations = [
            RemoveEmptyTracksOperation(fromDate: fromDate),
            MergeCloseToUnknownActivityTracksOperation(fromDate: fromDate, seconds: 30),
            InferBikingFromSpeedOperation(fromDate: fromDate, activity: { $0.walking }, minSpeedLimit: 7, minLength: 0.050),
            InferBikingFromSpeedOperation(fromDate: fromDate, activity: { $0.automotive }, minSpeedLimit: 10, maxSpeedLimit: 20, minLength: 0.200),
            MergeCloseSameActivityTracksOperation(fromDate: fromDate, seconds: 60),
            MergeTracksBetweenBikeTracksOperation(fromDate: fromDate, seconds: 60*5),
            MergeBikeCloseWithMoveTracksOperation(fromDate: fromDate, seconds: 60),
            MergeTracksBetweenBikeTracksOperation(fromDate: fromDate, seconds: 60*5), // again
            ClearLeftOversOperation(fromDate: fromDate),
            PruneSlowEndsOperation(fromDate: fromDate),
            PruneSimilarLocationOperation(fromDate: fromDate),
            PruneCurlyEndsOperation(fromDate: fromDate),
            RecalculateTracksOperation(fromDate: fromDate),
            RemoveUnownedDataOperation(fromDate: fromDate),
            RemoveEmptyTracksOperation(), // Rinse and repeat
        ]
        for operation in operations {
            operation.queuePriority = .Low
            operation.qualityOfService = asap ? .UserInitiated : .Background
        }
        operations.last?.completionBlock = {
            println("Done processing big")
            Async.main {
                TracksHandler.instance.processing = false
                NotificationCenter.post(processedBigNoticationKey, object: self)
            }
        }
        TracksOperation.addDependencies(operations)
        operationQueue.addOperations(operations, waitUntilFinished: false)
    }
    
    class func geocode() {
        if TracksHandler.instance.processing {
            println("Already processing")
            Async.main(after: 10) { // Check again after 10 seconds
                self.geocode()
            }
            return
        }
        TracksHandler.instance.processing = true
        
        println("Start geocoding")
        let operations = [
            GeocodeBikeTracksOperation() // Don't use from date since background operation might not have geocoded)
        ]
        for operation in operations {
            operation.queuePriority = .High
            operation.qualityOfService = .UserInitiated
        }
        operations.last?.completionBlock = {
            println("Done geocoding")
            Async.main {
                TracksHandler.instance.processing = false
                NotificationCenter.post(processedGeocodingNoticationKey, object: self)
            }
        }
        TracksOperation.addDependencies(operations)
        TracksHandler.instance.operationQueue.addOperations(operations, waitUntilFinished: false)
    }
}


class TracksOperation: NSOperation {
    
    private let fromDate: NSDate?
    private var realm: RLMRealm = RLMRealm.defaultRealm()
    override var asynchronous: Bool {
        return true
    }

    init(fromDate: NSDate? = nil ) {
        self.fromDate = fromDate
        super.init()
    }
    
    override func main() {
        realm = RLMRealm.defaultRealm()
    }
    
    private func tracks(useFromDate: Bool = true) -> RLMResults {
        let tracks = Track.allObjectsInRealm(realm)
        if useFromDate, let fromDate = fromDate {
            let timestamp = fromDate.timeIntervalSince1970
            return tracks.objectsWhere("endTimestamp >= %lf", timestamp)
        }
        return tracks
    }
    
    private func tracksSorted() -> RLMResults {
        return tracks().sortedResultsUsingProperty("startTimestamp", ascending: true)
    }
    
    /// Add dependency to previous operation in array
    class func addDependencies(operations: [TracksOperation]) {
        for (index, operation) in enumerate(operations) {
            if index + 1 >= operations.count {
                continue
            }
            let nextOperation = operations[index+1]
            nextOperation.addDependency(operation)
        }
    }
}


class RecalculateTracksOperation: TracksOperation {
    
    override func main() {
        super.main()
        println("Recalculating tracks")
//        realm.beginWriteTransaction()
        for track in tracks()  {
            if let track = track as? Track {
                track.recalculate()
            }
        }
//        realm.commitWriteTransaction()
        println("Recalculating tracks DONE")
    }
}


class RemoveEmptyTracksOperation: TracksOperation {
    
    override func main() {
        super.main()
        println("Remove empty tracks")
        let tracksResults = tracks()
        var count = UInt(0)
        while count < tracksResults.count {
            if let track = tracksResults[count] as? Track {
                if track.locations.count == 0 {
                    track.deleteFromRealmWithRelationships(realm: realm)
                    continue
                }
                if let act = track.activity as? TrackActivity {
                } else {
                    // Couldn't resolve activity
                    println("No activity? Deleting track")
                    track.deleteFromRealmWithRelationships(realm: realm)
                    continue
                }
            }
            count++
        }
        println("Remove empty tracks DONE")
    }
}


class RemoveUnownedDataOperation: TracksOperation {
    
    private func locations(useFromDate: Bool = true) -> RLMResults {
        let locations = TrackLocation.allObjectsInRealm(realm)
        if useFromDate, let fromDate = fromDate {
            let timestamp = fromDate.timeIntervalSince1970
            return locations.objectsWhere("timestamp >= %lf", timestamp)
        }
        return locations
    }
    private func activities(useFromDate: Bool = true) -> RLMResults {
        let activities = TrackActivity.allObjectsInRealm(realm)
        if useFromDate, let fromDate = fromDate {
            return activities.objectsWhere("startDate >= %@", fromDate)
        }
        return activities
    }
    
    override func main() {
        super.main()
        println("Clear unowned data")
        realm.beginWriteTransaction()
        
        let someTracks = tracks()
        let someLocations = locations()
        let someActivities = activities()
        
        // Mark locations unowned
        for location in someLocations {
            if let location = location as? TrackLocation {
                location.owned = false
            }
        }
        // Mark activities unowned
        for activity in someActivities {
            if let activity = activity as? TrackActivity {
                activity.owned = false
            }
        }
        // Mark locations and activities owned
        for track in someTracks {
            if let track = track as? Track {
                let locations = track.locations
                for location in locations {
                    if let location = location as? TrackLocation {
                        location.owned = true
                    }
                }
                track.activity.owned = true
            }
        }
        realm.commitWriteTransaction()
        
        // Delete unowned data
        let unownedLocations = someLocations.objectsWhere("owned == FALSE")
        println("Deleting \(unownedLocations.count) unowned locations")
        deleteObjectsInParts(unownedLocations)
        let unownedActivities = someActivities.objectsWhere("owned == FALSE")
        println("Deleting \(unownedActivities.count) unowned activities")
        deleteObjectsInParts(unownedActivities)
        
        println("Clear unowned data DONE")
    }
}

func deleteObjectsInParts(results: RLMResults) {
    let realm = results.realm
    let max = 1000
    let count = Int(results.count)
    if count > max {
        let array = results.toArray(RLMObject.self)
        let parts = Int(floor(Double(count) / Double(max)))
        for i in 0..<parts {
            let date = NSDate()
            realm.beginWriteTransaction()
            let slicedArray = Array(array[i*max..<((i+1)*max)])
            realm.deleteObjects(slicedArray)
            realm.commitWriteTransaction()
            println("\(results.count) \(NSDate().timeIntervalSinceDate(date))")
        }
    }
    while results.count > 0 {
        let date = NSDate()
        realm.beginWriteTransaction()
        if Int(results.count) > max {
            let array = results.toArray(RLMObject.self)
            let slicedArray = Array(array[0..<max])
            realm.deleteObjects(slicedArray)
        } else {
            (results.firstObject() as? RLMObject)?.deleteFromRealm()
        }
        realm.commitWriteTransaction()
        println("\(results.count) \(NSDate().timeIntervalSinceDate(date))")
    }
}


class InferBikingFromSpeedOperation: TracksOperation {

    private let activity: (TrackActivity) -> Bool
    private let minSpeedLimit: Double?
    private let maxSpeedLimit: Double?
    private let minLength: Double
    init(fromDate: NSDate? = nil, activity: (TrackActivity) -> Bool, minSpeedLimit: Double? = nil, maxSpeedLimit: Double? = nil, minLength: Double) {
        self.activity = activity
        self.minSpeedLimit = minSpeedLimit
        self.maxSpeedLimit = maxSpeedLimit
        self.minLength = minLength
        super.init(fromDate: fromDate)
    }
    
    override func main() {
        super.main()
        println("Infer bike from speed from other activity")
        for track in tracks() {
            if let track = track as? Track {
                if !activity(track.activity) {
                    continue
                }
                if let minSpeedLimit = minSpeedLimit {
                    if !track.speeding(speedLimit: minSpeedLimit, minLength: minLength) {
                        continue
                    }
                }
                if let maxSpeedLimit = maxSpeedLimit {
                    if !track.slow(speedLimit: maxSpeedLimit, minLength: minLength) {
                        continue
                    }
                }
                track.realm.beginWriteTransaction()
                track.activity.automotive = false
                track.activity.running = false
                track.activity.walking = false
                track.activity.cycling = true // Force cycling
                track.activity.stationary = false // Force non-stationary
                track.realm.commitWriteTransaction()
                println("Infered biking \(track.startDate())")
            }
        }
        println("Infer bike from speed from other activity DONE")
    }
}

class ClearLeftOversOperation: TracksOperation {
    
    override func main() {
        super.main()
        println("Clear left overs")
//        realm.beginWriteTransaction()
        for track in tracksSorted() {
            if let track = track as? Track {
                track.recalculate()
                
                let formatter = NSDateFormatter()
                formatter.dateStyle = .ShortStyle
                formatter.timeStyle = .MediumStyle
                
                // Empty
                if track.locations.count <= 1 {
                    println("Deleted no (to 1) locations: \(track.startDate())")
                    track.deleteFromRealmWithRelationships()
                    continue
                }
                // Not moving activity
                if track.activity.realm != nil {
                    let moving = track.activity.moving()
                    if !moving {
                        println("Deleted not moving activity: \(track.startDate())")
                        track.deleteFromRealmWithRelationships()
                        continue
                    }
                }
                // Very slow
                let verySlow = track.slow(speedLimit: 2, minLength: 0.020)
                if verySlow {
                    println("Deleted slow: \(track.startDate())")
                    track.deleteFromRealmWithRelationships()
                    continue
                }
                // Somewhat slow + low accuracy
                let someWhatSlow = track.slow(speedLimit: 5, minLength: 0.020)
                let lowAccuracy = track.lowAccuracy(minAccuracy: 50)
                if someWhatSlow && lowAccuracy {
                    println("Deleted low accuracy: \(track.startDate())")
                    track.deleteFromRealmWithRelationships()
                    continue
                }
                
                // Delete inacurate locations
                let inaccurateLocations = track.locations.objectsWhere("horizontalAccuracy > 200 OR verticalAccuracy > 200")
                for inaccurateLocation in inaccurateLocations {
                    println("Deleted inacurate location in track: \(track.startDate())")
                    inaccurateLocation.deleteFromRealm()
                }
                
                // Somewhat slow + long distance
                let someWhatSlowLongDistance = track.slow(speedLimit: 5, minLength: 0.200)
                if someWhatSlowLongDistance {
                    println("Deleted someWhatSlowLongDistance: \(track.startDate())")
                    track.deleteFromRealmWithRelationships()
                    continue
                }
                // Very fast
                let veryFast = track.speeding(speedLimit: 50, minLength: 0.200)
                if veryFast {
                    println("Deleted fast: \(track.startDate) - \(track.endDate())")
                    track.deleteFromRealmWithRelationships()
                    continue
                }
                // Odd flight distance (for stationary device with fluctuating data)
                if let flightWithOneMedianStopDistance = track.flightWithOneMedianStopDistance() {
                    let shortFlight = track.flightDistance() < 50
                    let flightLengthRatio = track.length / flightWithOneMedianStopDistance
                    let flightSuspicious = 10 < flightLengthRatio
                    //                println("PP \(shortFlight) \(flightSuspicious) \(track.flightDistance()) \(flightLengthRatio) \(track.duration) \(track.locations.count) \(formatter.stringFromDate(track.startDate!))")
                    if flightSuspicious {
                        println("Deleted short flight distance: \(track.startDate())")
                        track.deleteFromRealmWithRelationships()
                        continue
                    }
                }
                // No length
                let noLength = track.length == 0
                if noLength {
                    println("Deleted no length: \(track.startDate())")
                    track.deleteFromRealmWithRelationships()
                    continue
                }
                // No duration
                let noDuration = track.duration == 0
                if noDuration {
                    println("Deleted no duration: \(track.startDate())")
                    track.deleteFromRealmWithRelationships()
                    continue
                }
            }
        }
//        realm.commitWriteTransaction()
        println("Clear left overs DONE")
    }
}

class PruneSimilarLocationOperation: TracksOperation {
    
    private func pruneSimilarLocation(track: Track) -> Bool {
        var changed = false
        
        // All 
        var index: UInt = 0
        while 3 <= track.locations.count && index <= track.locations.count - 3  {
            let indexCenter = index + 1
            let indexLast = index + 2
            if let
                first = track.locations[index] as? TrackLocation,
                center = track.locations[indexCenter] as? TrackLocation,
                last = track.locations[indexLast] as? TrackLocation
            {
                if
                    first.coordinate().latitude == center.coordinate().latitude &&
                    first.coordinate().longitude == center.coordinate().longitude &&
                    first.coordinate().latitude == last.coordinate().latitude &&
                    first.coordinate().longitude == last.coordinate().longitude
                {
                    track.locations.removeObjectAtIndex(indexCenter)
                    center.deleteFromRealm()
                    changed = true
                } else {
                    index++
                }
            }
        }
        
        return changed
    }
    
    override func main() {
        super.main()
        println("Prune similar locations ends")
        let transact = !realm.inWriteTransaction
        if transact {
            realm.beginWriteTransaction()
        }
        for track in tracks().objectsWhere("activity.cycling == TRUE") {
            if let track = track as? Track where !track.invalidated {
                let t = pruneSimilarLocation(track)
            }
        }
        if transact {
            realm.commitWriteTransaction()
        }
        println("Prune similar locations DONE")
    }
}


class PruneCurlyEndsOperation: TracksOperation {
    
    private func difference(coordinates: [CLLocationCoordinate2D]) -> [Double] {
        
        let rotations: [Double] = {
            var rotations = [Double]()
            for (index, coordinate) in enumerate(coordinates) {
                let nextIndex = index + 1
                if nextIndex < Int(coordinates.count) {
                    let nextCoordinate = coordinates[nextIndex]
                    let newRotation = coordinate.degreesFromCoordinate(nextCoordinate)
                    rotations.append(newRotation)
                }
            }
            return rotations
        }()
        if rotations.count == 0 {
            return [Double]()
        }
        let firstToLast = coordinates.first!.degreesFromCoordinate(coordinates.last!)
        
        let diffClosure: Double -> Double = { rotation in
            var diff = rotation - firstToLast
            while diff > 180 { diff -= 360 }
            while diff < -180 { diff += 360 }
            return diff
        }
        let diff = rotations.map(diffClosure)
        return diff
    }
    
    private func pruneCurl(track: Track, extendSeconds: NSTimeInterval = 30) -> Bool {
        var changed = false
        
        let varianceLimit: Double = 2000
        
        if let firstLocation = track.locations.firstObject() as? TrackLocation {
            // Go 60 seconds from start
            var firstLocations = track.locations.objectsWhere("timestamp <= %lf", firstLocation.timestamp + extendSeconds)
            
            let firstCoordinates = firstLocations.toArray(TrackLocation).map { $0.coordinate() }
        
            let degreeDifferencesStart = difference(firstCoordinates)
            let variancesFromStart: [Double] = {
                var vars = [Double]()
                for i in 0..<degreeDifferencesStart.count {
                    let part = Array(degreeDifferencesStart[0...i])
                    vars.append(self.variance(part))
                }
                return vars
            }()
            let removeToIndex: UInt? = {
                // Find first coordinate with high deviation
                for (index, diff) in enumerate(variancesFromStart) {
                    if diff > varianceLimit { return UInt(index) }
                }
                return nil
            }()
            if let removeToIndex = removeToIndex {
                removeLocations(inRange: 0...removeToIndex, fromTrack: track)
                changed = true
            }
        }
        
        if let lastLocation = track.locations.lastObject() as? TrackLocation {
            // Go back 60 seconds from end
            var lastLocations = track.locations.objectsWhere("timestamp >= %lf", lastLocation.timestamp - extendSeconds)
            let t = path(lastLocations.toArray(TrackLocation).map { $0.location() })
            var lastCoordinates = lastLocations.toArray(TrackLocation).map { $0.coordinate() }
            let degreeDifferencesLast = difference(lastCoordinates)
            let variancesToEnd: [Double] = {
                var vars = [Double]()
                let count = degreeDifferencesLast.count
                for i in 0..<count {
                    let part = Array(degreeDifferencesLast[i..<count])
                    vars.append(self.variance(part))
                }
                return vars
            }()
            let removeFromIndex: UInt? = {
                for (index, diff) in enumerate(variancesToEnd.reverse()) {
                    if diff > varianceLimit {
                        return track.locations.count - UInt(index) - 1 // Subtract from count since enumerating over reverse
                    }
                }
                return nil
            }()
            if let removeFromIndex = removeFromIndex where removeFromIndex > 0 {
                removeLocations(inRange: removeFromIndex..<track.locations.count, fromTrack: track)
                changed = true
            }
        }
        return changed
    }
    
    func variance(array: [Double]) -> Double {
        let count = Double(array.count)
        let sum = array.reduce(0, combine: +)
        let mean = sum / count
        let diffSqr =  array.map { pow($0 - mean, 2) }
        let variance = diffSqr.reduce(0, combine: +) / count
        return variance
    }
    
    func removeLocations(inRange range: Range<UInt>, fromTrack track: Track) {
        // Delete from high index to low to not mess up order while deleting
        let indeces = range.startIndex < range.endIndex ? reverse(range) : [UInt](range)
        for i in indeces {
            if let location = track.locations[i] as? TrackLocation {
                track.locations.removeObjectAtIndex(i)
                location.deleteFromRealm()
            }
        }
    }
    
    override func main() {
        super.main()
        println("Prune curly ends")
        let transact = !realm.inWriteTransaction
        if transact {
            realm.beginWriteTransaction()
        }
        for track in tracks().objectsWhere("activity.cycling == TRUE") {
            if let track = track as? Track where !track.invalidated {
                while pruneCurl(track) {} // Keep pruning untill nothing changes
            }
        }
        if transact {
            realm.commitWriteTransaction()
        }
        println("Prune slow ends DONE")
    }
}


class PruneSlowEndsOperation: TracksOperation {
    
    override func main() {
        super.main()
        println("Prune slow ends")
        let transact = !realm.inWriteTransaction
        if transact {
            realm.beginWriteTransaction()
        }
        for track in tracks().objectsWhere("activity.cycling == TRUE") {
            if let track = track as? Track where !track.invalidated {
                let cycling = track.activity.cycling
                if !cycling {
                    continue
                }
                let speeds = track.smoothSpeeds()
                
                let speedLimit: Double = 7 * 1000 / 3600 // 7 km/h
                for speed in speeds {
                    if speed > speedLimit {
                        break
                    }
                    if let firstLocation = track.locations.firstObject() as? TrackLocation {
                        track.locations.removeObjectAtIndex(0)
                        firstLocation.deleteFromRealm()
                    }
                }
                for speed in speeds.reverse() {
                    if speed > speedLimit {
                        break
                    }
                    if let lastLocation = track.locations.lastObject() as? TrackLocation {
                        track.locations.removeLastObject()
                        lastLocation.deleteFromRealm()
                    }
                }
            }
        }
        if transact {
            realm.commitWriteTransaction()
        }
        println("Prune slow ends DONE")
    }
}

class MergeTracksOperation: TracksOperation {
    
    private func mergeTrack(track1: Track, toTrack track2: Track, forceBike: Bool = false, useFirstTrackActivity: Bool = true) -> Track {
        realm.beginWriteTransaction()
        if track1.invalidated || track2.invalidated {
            println("Couldn't merge tracks since one is invalid")
            realm.cancelWriteTransaction()
            return track1
        }
        // Merge locations
        for location in track2.locations {
            track1.locations.addObject(location)
        }
        // Combine activity
        track1.end = track2.end
        if !useFirstTrackActivity {
            let startDate = track1.activity.startDate // Take date from 1st activity
            track1.activity.deleteFromRealm() // Delete 1st activity
            track1.activity = track2.activity // Use 2nd activity
            track1.activity.startDate = startDate // Update date
        }
        if forceBike {
            track1.activity.cycling = true
            track1.activity.automotive = false
            track1.activity.walking = false
            track1.activity.running = false
            track1.activity.confidence = 0
        }
        // Use 2nd track end name
        track1.end = track2.end
        track1.hasBeenGeocoded = track2.hasBeenGeocoded // If 2nd hasn't been geocoded, reflect in 1st
        // Clean up
        track1.recalculate()
        if useFirstTrackActivity {
            track2.activity.deleteFromRealm()
        }
        track2.deleteFromRealmWithRelationships(realm: realm, keepLocations: true, keepActivity: true) // Keep relationships, since they have been transferred to another track or deleted manually
        realm.commitWriteTransaction()
        
        return track1
    }
    
    private func mergeTracks(tracks: [Track]) -> Track? {
        var tracks = tracks
        while tracks.count > 1 {
            let track1 = tracks[0]
            let track2 = tracks[1]
            mergeTrack(track1, toTrack: track2)
            tracks.removeAtIndex(1)
        }
        return tracks.first
    }
    
    private func closeTracks(track track1: Track, toTrack track2: Track, closerThanSeconds seconds: NSTimeInterval) -> Bool {
        if let
            track1EndDate = track1.endDate(),
            track2StartDate = track2.startDate()
        {
            let timeIntervalBetweenTracks = track2StartDate.timeIntervalSinceDate(track1EndDate)
            if timeIntervalBetweenTracks < seconds {
                return true
            }
        }
        return false
    }
}


class MergeTimeTracksOperation: MergeTracksOperation {
    
    private let seconds: NSTimeInterval
    init(fromDate: NSDate? = nil, seconds: NSTimeInterval) {
        self.seconds = seconds
        super.init(fromDate: fromDate)
    }
}


class MergeCloseSameActivityTracksOperation : MergeTimeTracksOperation {
    
    override func main() {
        super.main()
        println("Merge close to same activity")
        var tracks = tracksSorted()
        
        var count = UInt(0)
        while count + 1 < tracks.count {
            if let track = tracks[count] as? Track, nextTrack = tracks[count+1] as? Track {
                let close = closeTracks(track: track, toTrack: nextTrack, closerThanSeconds: seconds)
                let sameType = track.activity.sameActivityTypeAs(nextTrack.activity)
                let merge = close && sameType
                if merge {
                    println("Close tracks: \(track.endDate()) to \(nextTrack.startDate())")
                    let mergedTrack = mergeTrack(track, toTrack: nextTrack)
                    tracks = tracksSorted()
                } else {
                    count++
                }
                //                println(" \(count) / \(tracks.count)")
            }
        }
        println("Merge close to same activity DONE")
    }
}


class MergeCloseToUnknownActivityTracksOperation: MergeTimeTracksOperation {
    
    override func main() {
        super.main()
        println("Merge close to unknown activity tracks")
        var tracks = tracksSorted()
            
        var count = UInt(0)
        while count + 1 < tracks.count {
            if let
                track = tracks[count] as? Track,
                nextTrack = tracks[count+1] as? Track,
                trackActivity = track.activity as? TrackActivity,
                nextTrackActivity = nextTrack.activity as? TrackActivity
            {
                let close = closeTracks(track: track, toTrack: nextTrack, closerThanSeconds: seconds)
                let unknown = trackActivity.unknown || trackActivity.completelyUnknown()
                let unknownNext = nextTrackActivity.unknown || nextTrackActivity.completelyUnknown()
                let eitherIsUnknown = unknown || unknownNext
                let merge = close && eitherIsUnknown
                if merge {
                    let mergedTrack = mergeTrack(track, toTrack: nextTrack, useFirstTrackActivity: unknownNext)
                    tracks = tracksSorted()
                    println("Close to empty activity: \(mergedTrack.startDate())")
                } else {
                    count++
                }
                //                println(" \(count) / \(tracks.count)")
            }
        }
        println("Merge close to unknown activity tracks DONE")
    }
}


class MergeTracksBetweenBikeTracksOperation: MergeTimeTracksOperation {
    
    override func main() {
        super.main()
        println("Merge track between bike tracks")
        var tracks = tracksSorted().toArray(Track.self)
        
        let formatter = NSDateFormatter()
        formatter.dateStyle = .ShortStyle
        formatter.timeStyle = .MediumStyle
        
        var count = 0
        while count + 2 < tracks.count {
            let track = tracks[count]
            if !track.activity.cycling { // Is not biking
                count++
                continue
            }
            // Find next bike track within time interval
            var nextCount = count
            var nextTrack: Track?
            while nextCount < tracks.count - 3 {
                let _nextTrack = tracks[nextCount+1]
                if !_nextTrack.activity.cycling {
                    break
                }
                if !closeTracks(track: track, toTrack: _nextTrack, closerThanSeconds: seconds) {
                    break
                }
                println("\(formatter.stringFromDate(track.endDate()!)) | \(formatter.stringFromDate(_nextTrack.startDate()!))")
                nextTrack = _nextTrack
                nextCount++
            }
            if let nextTrack = nextTrack where nextCount > count {
                // Merge tracks between bike tracks
                println("MERGEEEEE")
                let tracksToMerge = Array(tracks[count...nextCount])
                
                for track in tracksToMerge {
                    println("\(formatter.stringFromDate(track.startDate()!)) -> \(formatter.stringFromDate(track.endDate()!))")
                }
                mergeTracks(tracksToMerge)
                tracks = tracksSorted().toArray(Track.self)
            } else {
                count++
            }
        }
        println("Merge track between bike tracks DONE")
    }
}

class MergeBikeCloseWithMoveTracksOperation: MergeTimeTracksOperation {
    
    override func main() {
        super.main()
        println("Merge bike close with non-stationary tracks")
        var tracks = tracksSorted()
    
        var count = UInt(0)
        while count + 1 < tracks.count {
            if let track = tracks[count] as? Track, nextTrack = tracks[count+1] as? Track {
                let close = closeTracks(track: track, toTrack: nextTrack, closerThanSeconds: seconds)
                let cycling = track.activity.cycling
                let cyclingNext = nextTrack.activity.cycling
                let move = track.activity.moving() || track.speeding(speedLimit: 10, minLength: 0.1)
                let moveNext = nextTrack.activity.moving() || nextTrack.speeding(speedLimit: 10, minLength: 0.1)
                let bikeCloseAndMoving = (cycling && moveNext) || (cyclingNext && move)
                let merge = close && bikeCloseAndMoving
                if merge {
                    let mergedTrack = mergeTrack(track, toTrack: nextTrack, forceBike: true)
                    tracks = tracksSorted()
                    println("Bike close w. move: \(mergedTrack.startDate)")
                } else {
                    count++
                }
                //                println(" \(count) / \(tracks.count)")
            }
        }
        println("Merge bike close with non-stationary tracks DONE")
    }
}


class GeocodeBikeTracksOperation: TracksOperation {
    
    override func main() {
        super.main()
        
        // Only perform this if the app is in the foreground
        if UIApplication.sharedApplication().applicationState != .Active {
            return
        }
        
        println("Geocode bike tracks")
        
        var bikeTracks = tracks().objectsWhere("activity.cycling == TRUE")
        for track in bikeTracks {
            if let track = track as? Track where !track.hasBeenGeocoded {
                // Geocode synchronously to make sure writes are happening on same thread
                track.geocode(synchronous: true)
            }
        }
        println("Geocode bike tracks DONE")
    }
}







