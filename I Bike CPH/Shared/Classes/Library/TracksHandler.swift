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

    private var processingStartDate: NSDate = NSDate()
    private var processing: Bool = false {
        didSet {
            UIApplication.sharedApplication().networkActivityIndicatorVisible = processing
            if processing {
                processingStartDate = NSDate()
                println("Processing start \(processingStartDate)")
            } else {
                println("Processing ended \(-processingStartDate.timeIntervalSinceNow))s")
            }
        }
    }
    private var pendingUserInitiatedProcess = false
    private var pendingGeocode = false

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
    
    private var observerTokens = [AnyObject]()
    
    init() {
        observerTokens.append(NotificationCenter.observe(processedBigNoticationKey) { [weak self] notification in
            if self?.pendingGeocode ?? false {
                TracksHandler.geocode()
            }
        })
        observerTokens.append(NotificationCenter.observe(processedSmallNoticationKey) { [weak self] notification in
            if self?.pendingUserInitiatedProcess ?? false {
                TracksHandler.setNeedsProcessData(userInitiated: true)
            }
        })
        observerTokens.append(NotificationCenter.observe(processedGeocodingNoticationKey) { [weak self] notification in
            if self?.pendingUserInitiatedProcess ?? false {
                TracksHandler.setNeedsProcessData(userInitiated: true)
            }
        })
    }
    
    deinit {
        unobserve()
    }
    
    private func unobserve() {
        for observerToken in observerTokens {
            NotificationCenter.unobserve(observerToken)
        }
        NotificationCenter.unobserve(self)
    }
    
    class func setNeedsProcessData(userInitiated: Bool = false) {
        if compressingRealm {
            if userInitiated {
                TracksHandler.instance.pendingUserInitiatedProcess = true
            }
            return
        }
        let timeIntervalSinceBig = NSDate().timeIntervalSinceDate(instance.lastProcessedBig)
        let timeIntervalSinceSmall = NSDate().timeIntervalSinceDate(instance.lastProcessedSmall)
        if
            userInitiated &&
            timeIntervalSinceBig > 0 //60*1 // Allow userInitiated every 1 min
        {
            instance.cleanUpBig(asap: true)
            instance.lastProcessedBig = NSDate()
            return
        }
        if timeIntervalSinceBig > 60*60*2 { // Do big stuff every other hour
            instance.cleanUpBig(asap: false)
            instance.lastProcessedBig = NSDate()
            return
        }
        if timeIntervalSinceSmall > 60*30 { // Do small stuff every 30 min
            instance.cleanUpSmall()
            instance.lastProcessedSmall = NSDate()
            return
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
            pendingUserInitiatedProcess = true
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
            UploadBikeTracksOperation()
        ]
        for operation in operations {
            operation.queuePriority = .Low
            operation.qualityOfService = asap ? .UserInitiated : .Background
        }
        operations.last?.completionBlock = {
            println("Done processing big")
            Async.main {
                TracksHandler.instance.pendingUserInitiatedProcess = false
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
            TracksHandler.instance.pendingGeocode = true
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
                TracksHandler.instance.pendingGeocode = false
                TracksHandler.instance.processing = false
                NotificationCenter.post(processedGeocodingNoticationKey, object: self)
            }
        }
        TracksOperation.addDependencies(operations)
        TracksHandler.instance.operationQueue.addOperations(operations, waitUntilFinished: false)
    }
    
    class func upload() {
        if TracksHandler.instance.processing {
            println("Already processing")
            return
        }
        TracksHandler.instance.processing = true
        
        println("Start uploading")
        let operations = [
            UploadBikeTracksOperation()
        ]
        operations.last?.completionBlock = {
            println("Done uploading")
            Async.main {
                TracksHandler.instance.processing = false
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
    
    private var startDate: NSDate = NSDate()

    init(fromDate: NSDate? = nil) {
        self.fromDate = fromDate
        super.init()
    }
    
    override func main() {
        startDate = NSDate()
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
        println("Recalculating tracks DONE \(-startDate.timeIntervalSinceNow)")
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
        println("Remove empty tracks DONE \(-startDate.timeIntervalSinceNow)")
    }
}


class RemoveUnownedDataOperation: TracksOperation {
    
    private func locations() -> RLMResults {
        let locations = TrackLocation.allObjectsInRealm(realm)
        if let fromDate = fromDate {
            let timestamp = fromDate.timeIntervalSince1970
            return locations.objectsWhere("timestamp >= %lf", timestamp)
        }
        return locations
    }
    private func activities() -> RLMResults {
        let activities = TrackActivity.allObjectsInRealm(realm)
        if let fromDate = fromDate {
            return activities.objectsWhere("startDate >= %@", fromDate)
        }
        return activities
    }
    
    override func main() {
        super.main()
        
        // Only perform this if the app is in the foreground
        if UIApplication.sharedApplication().applicationState != .Active {
            return
        }
        
        println("Clear unowned data")
        realm.beginWriteTransaction()
        
        let someTracks = tracks()
        let someLocations = locations()
        let someActivities = activities()
        
        // Mark locations and activities owned
        let uuid = NSUUID().UUIDString
        for track in someTracks {
            if let track = track as? Track {
                let locations = track.locations
                for location in locations {
                    if let location = location as? TrackLocation {
                        location.owned = uuid
                    }
                }
                track.activity.owned = uuid
            }
        }
        realm.commitWriteTransaction()
        
        // Delete unowned data
        let unownedLocations = someLocations.objectsWhere("owned != %@", uuid)
        println("Deleting \(unownedLocations.count) unowned locations")
        deleteObjectsInParts(unownedLocations)
        let unownedActivities = someActivities.objectsWhere("owned != %@", uuid)
        println("Deleting \(unownedActivities.count) unowned activities")
        deleteObjectsInParts(unownedActivities)
        
        println("Clear unowned data DONE \(-startDate.timeIntervalSinceNow)")
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
            println("\(results.count) \(NSDate().timeIntervalSinceDate(date)) .a")
        }
    }
    if results.count > 0 {
        let date = NSDate()
        realm.beginWriteTransaction()
        realm.deleteObjects(results.toArray(RLMObject.self))
        realm.commitWriteTransaction()
        println("\(results.count) \(NSDate().timeIntervalSinceDate(date)) .b")
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
                if let realm = track.realm {
                    realm.beginWriteTransaction()
                    track.activity.automotive = false
                    track.activity.running = false
                    track.activity.walking = false
                    track.activity.cycling = true // Force cycling
                    track.activity.stationary = false // Force non-stationary
                    realm.commitWriteTransaction()
                    println("Infered biking \(track.startDate())")
                }
            }
        }
        println("Infer bike from speed from other activity DONE \(-startDate.timeIntervalSinceNow)")
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
                
                // Very short distance, 50m
                let noLength = track.length < 50
                if noLength {
                    println("Deleted short length: \(track.startDate())")
                    track.deleteFromRealmWithRelationships()
                    continue
                }
                // Very low duration, 30 seconds
                let noDuration = track.duration < 30
                if noDuration {
                    println("Deleted short duration: \(track.startDate())")
                    track.deleteFromRealmWithRelationships()
                    continue
                }
            }
        }
//        realm.commitWriteTransaction()
        println("Clear left overs DONE \(-startDate.timeIntervalSinceNow)")
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
        println("Prune similar locations DONE \(-startDate.timeIntervalSinceNow)")
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
    
    private func path(locations: [CLLocation]) -> UIBezierPath {
        let coordinates = locations.map { $0.coordinate }
        let allPoints = coordinates.map { CGPoint(x: $0.latitude, y: $0.longitude) }
        let points = allPoints //Array(allPoints[0..<20])
        let count = CGFloat(points.count)
        let meanPoint = points.reduce(CGPointZero) { mean, new in
            return CGPoint(x: mean.x + new.x/count, y: mean.y + new.y/count)
        }
        let minPoint = points.reduce(CGPoint(x: 1000, y: 1000)) { value, new in
            return CGPoint(x: min(value.x, new.x), y: min(value.y, new.y))
        }
        let maxPoint = points.reduce(CGPoint(x: -1000, y: -1000)) { value, new in
            return CGPoint(x: max(value.x, new.x), y: max(value.y, new.y))
        }
        let diff: CGFloat = {
            var p = max(maxPoint.x-minPoint.x, maxPoint.y-minPoint.y)
            p = p == 0 ? 1 : p
            return p
        }()
        let normalizedPoints = points.map { CGPoint(x: ($0.x - meanPoint.x) / diff * 700, y: ($0.y - meanPoint.y) / diff * 700) }
        let path = UIBezierPath()
        for point in normalizedPoints {
            if point == normalizedPoints.first {
                path.moveToPoint(point)
            } else {
                path.addLineToPoint(point)
            }
        }
        return path
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
//                let a1 = path(track.locations.toArray(TrackLocation).map { $0.location() })
                while pruneCurl(track) { } // Keep pruning untill nothing changes
//                let b1 = path(track.locations.toArray(TrackLocation).map { $0.location() })
                let d = 0
            }
        }
        if transact {
            realm.commitWriteTransaction()
        }
        println("Prune culry ends DONE \(-startDate.timeIntervalSinceNow)")
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
        println("Prune slow ends DONE \(-startDate.timeIntervalSinceNow)")
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
        println("Merge close to same activity DONE \(-startDate.timeIntervalSinceNow)")
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
        println("Merge close to unknown activity tracks DONE \(-startDate.timeIntervalSinceNow)")
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
        println("Merge track between bike tracks DONE \(-startDate.timeIntervalSinceNow)")
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
        println("Merge bike close with non-stationary tracks DONE \(-startDate.timeIntervalSinceNow)")
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
        println("Geocode bike tracks DONE \(-startDate.timeIntervalSinceNow)")
    }
}


class UploadBikeTracksOperation: TracksOperation {
    
    override func main() {
        super.main()
        
        // Only perform this if the app is in the foreground
        if UIApplication.sharedApplication().applicationState != .Active {
            return
        }
        // Logged in user with valid track token
        if !UserHelper.loggedIn() || UserHelper.trackToken() == nil {
            return
        }
        // Tracking currently enabled
        if !Settings.instance.tracking.on {
            return
        }
        
        println("Upload bike tracks")
        
        // Reset server ids 
        let dummyTrackId = NSUUID().UUIDString
        for track in Track.allObjects() {
            if let track = track as? Track {
                if track.serverId.lengthOfBytesUsingEncoding(NSUTF8StringEncoding) == dummyTrackId.lengthOfBytesUsingEncoding(NSUTF8StringEncoding) {
                    track.realm?.transactionWithBlock {
                        track.serverId = ""
                    }
                }
            }
        }
        
        let timestamp = NSDate(timeIntervalSinceNow: -60*60*1).timeIntervalSince1970 // Only upload tracks older than an hour
        var bikeTracks = tracks().objectsWhere("endTimestamp <= %lf AND serverId == '' AND activity.cycling == TRUE", timestamp)
        for track in bikeTracks {
            if let track = track as? Track {
                let temporaryTrackId = NSUUID().UUIDString
                track.realm?.transactionWithBlock {
                    track.serverId = temporaryTrackId
                }
                TracksClient.instance.upload(track) { result in
                    if let track = Track.allObjects().objectsWhere("serverId == %@", temporaryTrackId).firstObject() as? Track {
                        switch result {
                            case .Success(let trackServerId):
                                track.realm?.transactionWithBlock {
                                    track.serverId = trackServerId
                                    println("Track stored on server: " + trackServerId)
                                }
                            case .Other(let result):
                                switch result {
                                    case .Failed(let error):
                                        println(error.localizedDescription)
                                        track.realm?.transactionWithBlock {
                                            track.serverId = ""
                                        }
                                    default:
                                        println("Other upload error \(result)")
                                        track.realm?.transactionWithBlock {
                                            track.serverId = ""
                                        }
                                }
                        }
                    } else {
                        println("Upload error: Couldn't find track with temporary server id \(temporaryTrackId)")
                    }
                }
            }
        }
        println("Upload bike tracks DONE \(-startDate.timeIntervalSinceNow)")
    }
}
