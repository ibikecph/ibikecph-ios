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
    static let sharedInstance = TracksHandler()

    private var processingStartDate: NSDate = NSDate()
    private var processing: Bool = false {
        didSet {
            UIApplication.sharedApplication().networkActivityIndicatorVisible = processing
            if processing {
                processingStartDate = NSDate()
                print("Processing start \(processingStartDate)")
            } else {
                print("Processing ended \(-processingStartDate.timeIntervalSinceNow))s")
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
                TracksHandler.setNeedsProcessData(true)
            }
        })
        observerTokens.append(NotificationCenter.observe(processedGeocodingNoticationKey) { [weak self] notification in
            if self?.pendingUserInitiatedProcess ?? false {
                TracksHandler.setNeedsProcessData(true)
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
                TracksHandler.sharedInstance.pendingUserInitiatedProcess = true
            }
            return
        }
        let timeIntervalSinceBig = NSDate().timeIntervalSinceDate(sharedInstance.lastProcessedBig)
        let timeIntervalSinceSmall = NSDate().timeIntervalSinceDate(sharedInstance.lastProcessedSmall)
        if
            userInitiated &&
            timeIntervalSinceBig > 60*1 // Allow userInitiated every 1 min
        {
            sharedInstance.cleanUpBig(true)
            sharedInstance.lastProcessedBig = NSDate()
            return
        }
        if timeIntervalSinceBig > 60*60*2 { // Do big stuff every other hour
            sharedInstance.cleanUpBig(false)
            sharedInstance.lastProcessedBig = NSDate()
            return
        }
        if timeIntervalSinceSmall > 60*30 { // Do small stuff every 30 min
            sharedInstance.cleanUpSmall()
            sharedInstance.lastProcessedSmall = NSDate()
            return
        }
    }
    
    private func cleanUpSmall() {
        if TracksHandler.sharedInstance.processing {
            print("Already processing")
            return
        }
        TracksHandler.sharedInstance.processing = true
        
        print("Start processing small")
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
            print("Done processing small")
            TracksHandler.sharedInstance.processing = false
            NotificationCenter.post(processedSmallNoticationKey, object: self)
        }
        TracksOperation.addDependencies(operations)
        operationQueue.addOperations(operations, waitUntilFinished: false)
    }
    
    private func cleanUpBig(asap: Bool) {
        if TracksHandler.sharedInstance.processing {
            print("Already processing")
            pendingUserInitiatedProcess = true
            return
        }
        TracksHandler.sharedInstance.processing = true
        
        print("Start processing big")
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
            PruneSimilarLocationOperation(fromDate: fromDate),
            PruneSlowEndsOperation(fromDate: fromDate),
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
            print("Done processing big")
            Async.main {
                TracksHandler.sharedInstance.pendingUserInitiatedProcess = false
                TracksHandler.sharedInstance.processing = false
                NotificationCenter.post(processedBigNoticationKey, object: self)
            }
        }
        TracksOperation.addDependencies(operations)
        operationQueue.addOperations(operations, waitUntilFinished: false)
    }
    
    class func geocode() {
        if TracksHandler.sharedInstance.processing {
            print("Already processing")
            TracksHandler.sharedInstance.pendingGeocode = true
            return
        }
        TracksHandler.sharedInstance.processing = true
        
        print("Start geocoding")
        let operations = [
            GeocodeBikeTracksOperation() // Don't use from date since background operation might not have geocoded)
        ]
        for operation in operations {
            operation.queuePriority = .High
            operation.qualityOfService = .UserInitiated
        }
        operations.last?.completionBlock = {
            print("Done geocoding")
            Async.main {
                TracksHandler.sharedInstance.pendingGeocode = false
                TracksHandler.sharedInstance.processing = false
                NotificationCenter.post(processedGeocodingNoticationKey, object: self)
            }
        }
        TracksOperation.addDependencies(operations)
        TracksHandler.sharedInstance.operationQueue.addOperations(operations, waitUntilFinished: false)
    }
    
    class func upload() {
        if TracksHandler.sharedInstance.processing {
            print("Already processing")
            return
        }
        TracksHandler.sharedInstance.processing = true
        
        print("Start uploading")
        let operations = [
            UploadBikeTracksOperation()
        ]
        operations.last?.completionBlock = {
            print("Done uploading")
            Async.main {
                TracksHandler.sharedInstance.processing = false
            }
        }
        TracksOperation.addDependencies(operations)
        TracksHandler.sharedInstance.operationQueue.addOperations(operations, waitUntilFinished: false)
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
        for (index, operation) in operations.enumerate() {
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
        print("Recalculating tracks")
        for track in tracks()  {
            if let track = track as? Track {
                track.recalculate()
            }
        }
        print("Recalculating tracks DONE \(-startDate.timeIntervalSinceNow)")
    }
}


class RemoveEmptyTracksOperation: TracksOperation {
    
    override func main() {
        super.main()
        print("Remove empty tracks")
        let tracksResults = tracks()
        var count = UInt(0)
        while count < tracksResults.count {
            if let track = tracksResults[count] as? Track {
                if track.locations.count == 0 {
                    track.deleteFromRealmWithRelationships(realm)
                    continue
                }
// TODO: Remove the uncommented?
//                if let act = track.activity as? TrackActivity {
//                } else {
//                    // Couldn't resolve activity
//                    print("No activity? Deleting track")
//                    track.deleteFromRealmWithRelationships(realm: realm)
//                    continue
//                }
            }
            count += 1
        }
        print("Remove empty tracks DONE \(-startDate.timeIntervalSinceNow)")
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
        
        print("Clear unowned data")
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
        do {
            try realm.commitWriteTransaction()
        } catch {
            print("Could not commit Realm write transaction!")
        }
        
        // Delete unowned data
        let unownedLocations = someLocations.objectsWhere("owned != %@", uuid)
        print("Deleting \(unownedLocations.count) unowned locations")
        deleteObjectsInParts(unownedLocations)
        let unownedActivities = someActivities.objectsWhere("owned != %@", uuid)
        print("Deleting \(unownedActivities.count) unowned activities")
        deleteObjectsInParts(unownedActivities)
        
        print("Clear unowned data DONE \(-startDate.timeIntervalSinceNow)")
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
            do {
                try realm.commitWriteTransaction()
            } catch {
                print("Could not commit Realm write transaction!")
            }
            print("\(results.count) \(NSDate().timeIntervalSinceDate(date)) .a")
        }
    }
    if results.count > 0 {
        let date = NSDate()
        realm.beginWriteTransaction()
        realm.deleteObjects(results.toArray(RLMObject.self))
        do {
            try realm.commitWriteTransaction()
        } catch {
            print("Could not commit Realm write transaction!")
        }
        print("\(results.count) \(NSDate().timeIntervalSinceDate(date)) .b")
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
        print("Infer bike from speed from other activity")
        for track in tracks() {
            if let track = track as? Track {
                if !activity(track.activity) {
                    continue
                }
                if let minSpeedLimit = minSpeedLimit {
                    if !track.speeding(minSpeedLimit, minLength: minLength) {
                        continue
                    }
                }
                if let maxSpeedLimit = maxSpeedLimit {
                    if !track.slow(maxSpeedLimit, minLength: minLength) {
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
                    do {
                        try realm.commitWriteTransaction()
                    } catch {
                        print("Could not commit Realm write transaction!")
                    }
                    print("Infered biking \(track.startDate())")
                }
            }
        }
        print("Infer bike from speed from other activity DONE \(-startDate.timeIntervalSinceNow)")
    }
}

class ClearLeftOversOperation: TracksOperation {
    
    override func main() {
        super.main()
        print("Clear left overs")
//        realm.beginWriteTransaction()
        for track in tracksSorted() {
            if let track = track as? Track {
                track.recalculate()
                
                let formatter = NSDateFormatter()
                formatter.dateStyle = .ShortStyle
                formatter.timeStyle = .MediumStyle
                
                // Empty
                if track.locations.count <= 1 {
                    print("Deleted no (to 1) locations: \(track.startDate())")
                    track.deleteFromRealmWithRelationships()
                    continue
                }
                // Not moving activity
                if track.activity.realm != nil {
                    let moving = track.activity.moving()
                    if !moving {
                        print("Deleted not moving activity: \(track.startDate())")
                        track.deleteFromRealmWithRelationships()
                        continue
                    }
                }
                // Very slow
                let verySlow = track.slow(2, minLength: 0.020)
                if verySlow {
                    print("Deleted slow: \(track.startDate())")
                    track.deleteFromRealmWithRelationships()
                    continue
                }
                // Somewhat slow + low accuracy
                let someWhatSlow = track.slow(5, minLength: 0.020)
                let lowAccuracy = track.lowAccuracy(50)
                if someWhatSlow && lowAccuracy {
                    print("Deleted low accuracy: \(track.startDate())")
                    track.deleteFromRealmWithRelationships()
                    continue
                }
                
                // Delete inacurate locations
                let inaccurateLocations = track.locations.objectsWhere("horizontalAccuracy > 200 OR verticalAccuracy > 200")
                for inaccurateLocation in inaccurateLocations {
                    print("Deleted inacurate location in track: \(track.startDate())")
                    inaccurateLocation.deleteFromRealm()
                }
                
                // Somewhat slow + long distance
                let someWhatSlowLongDistance = track.slow(5, minLength: 0.200)
                if someWhatSlowLongDistance {
                    print("Deleted someWhatSlowLongDistance: \(track.startDate())")
                    track.deleteFromRealmWithRelationships()
                    continue
                }
                // Very fast
                let veryFast = track.speeding(50, minLength: 0.200)
                if veryFast {
                    print("Deleted fast: \(track.startDate) - \(track.endDate())")
                    track.deleteFromRealmWithRelationships()
                    continue
                }
                // Odd flight distance (for stationary device with fluctuating data)
                if let flightWithOneMedianStopDistance = track.flightWithOneMedianStopDistance() {
                    let flightLengthRatio = track.length / flightWithOneMedianStopDistance
                    let flightSuspicious = 10 < flightLengthRatio
                    //                print("PP \(shortFlight) \(flightSuspicious) \(track.flightDistance()) \(flightLengthRatio) \(track.duration) \(track.locations.count) \(formatter.stringFromDate(track.startDate!))")
                    if flightSuspicious {
                        print("Deleted short flight distance: \(track.startDate())")
                        track.deleteFromRealmWithRelationships()
                        continue
                    }
                }
                
                // Very short distance, 50m
//                let noLength = track.length < 50
//                if noLength {
//                    print("Deleted short length: \(track.startDate())")
//                    track.deleteFromRealmWithRelationships()
//                    continue
//                }
                // Very low duration, 30 seconds
                let noDuration = track.duration == 0
                if noDuration {
                    print("Deleted no duration: \(track.startDate())")
                    track.deleteFromRealmWithRelationships()
                    continue
                }
            }
        }
//        realm.commitWriteTransaction()
        print("Clear left overs DONE \(-startDate.timeIntervalSinceNow)")
    }
}

class PruneSimilarLocationOperation: TracksOperation {
    
    private func pruneSimilarLocation(track: Track) -> Bool {
        var changed = false
        
        // All 
        var index: UInt = 0
        let locations = track.locationsSorted()
        while 3 <= locations.count && index <= locations.count - 3  {
            let indexCenter = index + 1
            let indexLast = index + 2
            if let
                first = locations[index] as? TrackLocation,
                center = locations[indexCenter] as? TrackLocation,
                last = locations[indexLast] as? TrackLocation
            {
                let squeezedBetweenSimilar = first.coordinate().latitude == center.coordinate().latitude &&
                    first.coordinate().longitude == center.coordinate().longitude &&
                    first.coordinate().latitude == last.coordinate().latitude &&
                    first.coordinate().longitude == last.coordinate().longitude

                var deleteCenter = squeezedBetweenSimilar &&
                    first.coordinate().latitude == center.coordinate().latitude &&
                    first.coordinate().longitude == center.coordinate().longitude &&
                    abs(first.timestamp - center.timestamp) < 2 // Less than two seconds between

                if deleteCenter {
                    // Find locations of object in unsorted array
                    let i = track.locations.indexOfObject(center)
                    // Delete from locations array on track
                    track.locations.removeObjectAtIndex(i)
                    // Delete from realm
                    center.deleteFromRealm()
                    changed = true
                } else {
                    index += 1
                }
            }
        }
        
        return changed
    }
    
    override func main() {
        super.main()
        print("Prune similar locations ends")
        let transact = !realm.inWriteTransaction
        if transact {
            realm.beginWriteTransaction()
        }
//        for track in tracks().objectsWhere("activity.cycling == TRUE") {
//            if let track = track as? Track where !track.invalidated {
//                let t = pruneSimilarLocation(track)
//            }
//        }
        if transact {
            do {
                try realm.commitWriteTransaction()
            } catch {
                print("Could not commit Realm write transaction!")
            }
        }
        print("Prune similar locations DONE \(-startDate.timeIntervalSinceNow)")
    }
}


class PruneCurlyEndsOperation: TracksOperation {
    
    private func difference(coordinates: [CLLocationCoordinate2D]) -> [Double] {
        
        let rotations: [Double] = {
            var rotations = [Double]()
            for (index, coordinate) in coordinates.enumerate() {
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

        let locations = track.locationsSorted()
        if let firstLocation = locations.firstObject() as? TrackLocation {
            // Go 60 seconds from start
            var firstLocations = locations.objectsWhere("timestamp <= %lf", firstLocation.timestamp + extendSeconds)
            
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
                for (index, diff) in variancesFromStart.enumerate() {
                    if diff > varianceLimit { return UInt(index) }
                }
                return nil
            }()
            if let removeToIndex = removeToIndex {
                removeLocations(inRange: 0...removeToIndex, fromTrack: track)
                changed = true
            }
        }
        
        if let lastLocation = locations.lastObject() as? TrackLocation {
            // Go back 60 seconds from end
            let lastLocations = locations.objectsWhere("timestamp >= %lf", lastLocation.timestamp - extendSeconds)
            let lastCoordinates = lastLocations.toArray(TrackLocation).map { $0.coordinate() }
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
                for (index, diff) in variancesToEnd.reverse().enumerate() {
                    if diff > varianceLimit {
                        return locations.count - UInt(index) - 1 // Subtract from count since enumerating over reverse
                    }
                }
                return nil
            }()
            if let removeFromIndex = removeFromIndex where removeFromIndex > 0 {
                removeLocations(inRange: removeFromIndex..<locations.count, fromTrack: track)
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
        let indeces = range.startIndex < range.endIndex ? range.reverse() : [UInt](range)
        for i in indeces {
            let locations = track.locationsSorted()
            if let location = locations[i] as? TrackLocation {
                let _i = track.locations.indexOfObject(location)
                track.locations.removeObjectAtIndex(_i)
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
        print("Prune curly ends")
        let transact = !realm.inWriteTransaction
        if transact {
            realm.beginWriteTransaction()
        }
//        for track in tracks().objectsWhere("activity.cycling == TRUE") {
//            if let track = track as? Track where !track.invalidated {
//                while pruneCurl(track) { } // Keep pruning untill nothing changes
//                let d = 0
//            }
//        }
        if transact {
            do {
                try realm.commitWriteTransaction()
            } catch {
                print("Could not commit Realm write transaction!")
            }
        }
        print("Prune culry ends DONE \(-startDate.timeIntervalSinceNow)")
    }
}


class PruneSlowEndsOperation: TracksOperation {
    
    override func main() {
        super.main()
        print("Prune slow ends")
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
                    if let firstLocation = track.locationsSorted().firstObject() as? TrackLocation {
                        let _i = track.locations.indexOfObject(firstLocation)
                        track.locations.removeObjectAtIndex(_i)
                        firstLocation.deleteFromRealm()
                    }
                }
                for speed in speeds.reverse() {
                    if speed > speedLimit {
                        break
                    }
                    if let lastLocation = track.locationsSorted().lastObject() as? TrackLocation {
                        let _i = track.locations.indexOfObject(lastLocation)
                        track.locations.removeObjectAtIndex(_i)
                        lastLocation.deleteFromRealm()
                    }
                }
            }
        }
        if transact {
            do {
                try realm.commitWriteTransaction()
            } catch {
                print("Could not commit Realm write transaction!")
            }
        }
        print("Prune slow ends DONE \(-startDate.timeIntervalSinceNow)")
    }
}

class MergeTracksOperation: TracksOperation {
    
    private func mergeTrack(track1: Track, toTrack track2: Track, forceBike: Bool = false, useFirstTrackActivity: Bool = true) -> Track {
        realm.beginWriteTransaction()
        if track1.invalidated || track2.invalidated {
            print("Couldn't merge tracks since one is invalid")
            realm.cancelWriteTransaction()
            return track1
        }
        // Merge locations
        for location in track2.locations {
            track1.locations.addObject(location)
        }
        // Combine activity
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
        track2.deleteFromRealmWithRelationships(realm, keepLocations: true, keepActivity: true) // Keep relationships, since they have been transferred to another track or deleted manually
        do {
            try realm.commitWriteTransaction()
        } catch {
            print("Could not commit Realm write transaction!")
        }
        
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
        print("Merge close to same activity")
        var tracks = tracksSorted()
        
        var count = UInt(0)
        while count + 1 < tracks.count {
            if let track = tracks[count] as? Track, nextTrack = tracks[count+1] as? Track {
                let close = closeTracks(track: track, toTrack: nextTrack, closerThanSeconds: seconds)
                let sameType = track.activity.sameActivityTypeAs(nextTrack.activity)
                let merge = close && sameType
                if merge {
                    print("Close tracks: \(track.endDate()) to \(nextTrack.startDate())")
                    let mergedTrack = mergeTrack(track, toTrack: nextTrack)
                    tracks = tracksSorted()
                } else {
                    count += 1
                }
                //                print(" \(count) / \(tracks.count)")
            }
        }
        print("Merge close to same activity DONE \(-startDate.timeIntervalSinceNow)")
    }
}


class MergeCloseToUnknownActivityTracksOperation: MergeTimeTracksOperation {
    
    override func main() {
        super.main()
        print("Merge close to unknown activity tracks")
        var tracks = tracksSorted()
            
        var count = UInt(0)
        while count + 1 < tracks.count {
            if let track = tracks[count] as? Track,
                   nextTrack = tracks[count+1] as? Track
            {
                let close = closeTracks(track: track, toTrack: nextTrack, closerThanSeconds: seconds)
                let unknown = track.activity.unknown || track.activity.completelyUnknown()
                let unknownNext = nextTrack.activity.unknown || nextTrack.activity.completelyUnknown()
                let eitherIsUnknown = unknown || unknownNext
                let merge = close && eitherIsUnknown
                if merge {
                    let mergedTrack = mergeTrack(track, toTrack: nextTrack, useFirstTrackActivity: unknownNext)
                    tracks = tracksSorted()
                    print("Close to empty activity: \(mergedTrack.startDate())")
                } else {
                    count += 1
                }
                //                print(" \(count) / \(tracks.count)")
            }
        }
        print("Merge close to unknown activity tracks DONE \(-startDate.timeIntervalSinceNow)")
    }
}


class MergeTracksBetweenBikeTracksOperation: MergeTimeTracksOperation {
    
    override func main() {
        super.main()
        print("Merge track between bike tracks")
        var tracks = tracksSorted().toArray(Track.self)
        
        let formatter = NSDateFormatter()
        formatter.dateStyle = .ShortStyle
        formatter.timeStyle = .MediumStyle
        
        var count = 0
        while count + 2 < tracks.count {
            let track = tracks[count]
            if !track.activity.cycling { // Is not biking
                count += 1
                continue
            }
            // Find latest bike track within time interval
            var nextCount = count
            var nextTrack: Track?
            while nextCount < tracks.count - 3 {
                let _nextTrack = tracks[nextCount+1]
                if !_nextTrack.activity.cycling {
                    nextCount += 1 // Skip and keep searching
                    continue
                }
                if !closeTracks(track: track, toTrack: _nextTrack, closerThanSeconds: seconds) {
                    break // Outside limit, stop search
                }
                // Found a bike track
                print("\(formatter.stringFromDate(track.endDate()!)) | \(formatter.stringFromDate(_nextTrack.startDate()!))")
                nextTrack = _nextTrack
                nextCount += 1 // Keep searching
            }
            if let nextTrack = nextTrack where nextCount > count {
                // Merge tracks between bike tracks
                print("MERGEEEEE")
                let tracksToMerge = Array(tracks[count...nextCount])
                
                for track in tracksToMerge {
                    print("\(formatter.stringFromDate(track.startDate()!)) -> \(formatter.stringFromDate(track.endDate()!))")
                }
                mergeTracks(tracksToMerge)
                tracks = tracksSorted().toArray(Track.self)
            } else {
                count += 1
            }
        }
        print("Merge track between bike tracks DONE \(-startDate.timeIntervalSinceNow)")
    }
}

class MergeBikeCloseWithMoveTracksOperation: MergeTimeTracksOperation {
    
    override func main() {
        super.main()
        print("Merge bike close with non-stationary tracks")
        var tracks = tracksSorted()
    
        var count = UInt(0)
        while count + 1 < tracks.count {
            if let track = tracks[count] as? Track, nextTrack = tracks[count+1] as? Track {
                let close = closeTracks(track: track, toTrack: nextTrack, closerThanSeconds: seconds)
                let cycling = track.activity.cycling
                let cyclingNext = nextTrack.activity.cycling
                let move = track.activity.moving() || track.speeding(10, minLength: 0.1)
                let moveNext = nextTrack.activity.moving() || nextTrack.speeding(10, minLength: 0.1)
                let bikeCloseAndMoving = (cycling && moveNext) || (cyclingNext && move)
                let merge = close && bikeCloseAndMoving
                if merge {
                    let mergedTrack = mergeTrack(track, toTrack: nextTrack, forceBike: true)
                    tracks = tracksSorted()
                    print("Bike close w. move: \(mergedTrack.startDate)")
                } else {
                    count += 1
                }
                //                print(" \(count) / \(tracks.count)")
            }
        }
        print("Merge bike close with non-stationary tracks DONE \(-startDate.timeIntervalSinceNow)")
    }
}


class GeocodeBikeTracksOperation: TracksOperation {
    
    override func main() {
        super.main()
        
        // Only perform this if the app is in the foreground
        if UIApplication.sharedApplication().applicationState != .Active {
            return
        }
        
        print("Geocode bike tracks")
        
        var bikeTracks = tracks().objectsWhere("activity.cycling == TRUE")
        for track in bikeTracks {
            if let track = track as? Track where !track.hasBeenGeocoded {
                // Geocode synchronously to make sure writes are happening on same thread
                track.geocode(true)
            }
        }
        print("Geocode bike tracks DONE \(-startDate.timeIntervalSinceNow)")
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
        if !Settings.sharedInstance.tracking.on {
            return
        }
        
        print("Upload bike tracks")
        
        // Reset server ids 
        let dummyTrackId = NSUUID().UUIDString
        for track in Track.allObjects() {
            if let track = track as? Track {
                if track.serverId.lengthOfBytesUsingEncoding(NSUTF8StringEncoding) == dummyTrackId.lengthOfBytesUsingEncoding(NSUTF8StringEncoding) {
                    do {
                        try track.realm?.transactionWithBlock {
                            track.serverId = ""
                        }
                    } catch let error as NSError {
                        print("Realm transaction failed: \(error.description)")
                    }
                }
            }
        }
        
        let timestamp = NSDate(timeIntervalSinceNow: -60*60*1).timeIntervalSince1970 // Only upload tracks older than an hour
        var bikeTracks = tracks().objectsWhere("endTimestamp <= %lf AND serverId == '' AND activity.cycling == TRUE", timestamp)
        for track in bikeTracks {
            if let track = track as? Track {
                let temporaryTrackId = NSUUID().UUIDString
                do {
                    try track.realm?.transactionWithBlock {
                        track.serverId = temporaryTrackId
                    }
                } catch let error as NSError {
                    print("Realm transaction failed: \(error.description)")
                }
                TracksClient.sharedInstance.upload(track) { result in
                    if let track = Track.allObjects().objectsWhere("serverId == %@", temporaryTrackId).firstObject() as? Track {
                        switch result {
                            case .Success(let trackServerId):
                                do {
                                    try track.realm?.transactionWithBlock {
                                        track.serverId = trackServerId
                                        print("Track stored on server: " + trackServerId)
                                    }
                                } catch let error as NSError {
                                    print("Realm transaction failed: \(error.description)")
                                }
                            case .Other(let result):
                                switch result {
                                    case .Failed(let error):
                                        print(error.localizedDescription)
                                        do {
                                            try track.realm?.transactionWithBlock {
                                                track.serverId = ""
                                            }
                                        } catch let error as NSError {
                                            print("Realm transaction failed: \(error.description)")
                                        }
                                    default:
                                        print("Other upload error \(result)")
                                        do {
                                            try track.realm?.transactionWithBlock {
                                                track.serverId = ""
                                            }
                                        } catch let error as NSError {
                                            print("Realm transaction failed: \(error.description)")
                                        }
                                }
                        }
                    } else {
                        print("Upload error: Couldn't find track with temporary server id \(temporaryTrackId)")
                    }
                }
            }
        }
        print("Upload bike tracks DONE \(-startDate.timeIntervalSinceNow)")
    }
}
