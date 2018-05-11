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
import SwiftyUserDefaults

let processedSmallNoticationKey = "processedSmallNoticationKey"
let processedBigNoticationKey = "processedBigNoticationKey"
let processedGeocodingNoticationKey = "processedGeocodingNoticationKey"

class TracksHandler {
    static let sharedInstance = TracksHandler()

    fileprivate var processingStartDate: Date = Date()
    fileprivate var processing: Bool = false {
        didSet {
            UIApplication.shared.isNetworkActivityIndicatorVisible = processing
            if processing {
                processingStartDate = Date()
                print("Processing start \(processingStartDate)")
            } else {
                print("Processing ended \(-processingStartDate.timeIntervalSinceNow))s")
            }
        }
    }
    fileprivate var pendingUserInitiatedProcess = false
    fileprivate var pendingGeocode = false

    fileprivate let lastProcessedSmallKey = "lastProcessedSmallKey"
    var lastProcessedSmall: Date {
        get { return Defaults[lastProcessedSmallKey].date ?? Date(timeIntervalSince1970: 0) }
        set { Defaults[lastProcessedSmallKey] = newValue }
    }
    fileprivate let lastProcessedBigKey = "lastProcessedBigKey"
    var lastProcessedBig: Date {
        get { return Defaults[lastProcessedBigKey].date ?? Date(timeIntervalSince1970: 0) }
        set { Defaults[lastProcessedBigKey] = newValue }
    }
    
    fileprivate lazy var operationQueue: OperationQueue = {
        let queue = OperationQueue() // Create background queue
        queue.maxConcurrentOperationCount = 1
        return queue
    }()
    
    fileprivate var observerTokens = [AnyObject]()
    
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
    
    fileprivate func unobserve() {
        for observerToken in observerTokens {
            NotificationCenter.unobserve(observerToken)
        }
        NotificationCenter.unobserve(self)
    }
    
    class func setNeedsProcessData(_ userInitiated: Bool = false) {
        if compressingRealm {
            if userInitiated {
                TracksHandler.sharedInstance.pendingUserInitiatedProcess = true
            }
            return
        }
        let timeIntervalSinceBig = Date().timeIntervalSince(sharedInstance.lastProcessedBig)
        let timeIntervalSinceSmall = Date().timeIntervalSince(sharedInstance.lastProcessedSmall)
        if
            userInitiated &&
            timeIntervalSinceBig > 60*1 // Allow userInitiated every 1 min
        {
            sharedInstance.cleanUpBig(true)
            sharedInstance.lastProcessedBig = Date()
            return
        }
        if timeIntervalSinceBig > 60*60*2 { // Do big stuff every other hour
            sharedInstance.cleanUpBig(false)
            sharedInstance.lastProcessedBig = Date()
            return
        }
        if timeIntervalSinceSmall > 60*30 { // Do small stuff every 30 min
            sharedInstance.cleanUpSmall()
            sharedInstance.lastProcessedSmall = Date()
            return
        }
    }
    
    fileprivate func cleanUpSmall() {
        if TracksHandler.sharedInstance.processing {
            print("Already processing")
            return
        }
        TracksHandler.sharedInstance.processing = true
        
        print("Start processing small")
        let fromDate = lastProcessedSmall.addingTimeInterval(-60*15) // Go 15 minutes back
        let operations = [
            MergeCloseSameActivityTracksOperation(fromDate: fromDate, seconds: 60),
            RecalculateTracksOperation(fromDate: fromDate)
        ]
        for operation in operations {
            operation.queuePriority = .low
            operation.qualityOfService = .background
        }
        operations.last?.completionBlock = {
            print("Done processing small")
            TracksHandler.sharedInstance.processing = false
            NotificationCenter.post(processedSmallNoticationKey, object: self)
        }
        TracksOperation.addDependencies(operations)
        operationQueue.addOperations(operations, waitUntilFinished: false)
    }
    
    fileprivate func cleanUpBig(_ asap: Bool) {
        if TracksHandler.sharedInstance.processing {
            print("Already processing")
            pendingUserInitiatedProcess = true
            return
        }
        TracksHandler.sharedInstance.processing = true
        
        print("Start processing big")
        let fromDate = lastProcessedBig.addingTimeInterval(-60*60*24) // Go 24 hours back
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
            operation.queuePriority = .low
            operation.qualityOfService = asap ? .userInitiated : .background
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
            operation.queuePriority = .high
            operation.qualityOfService = .userInitiated
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


class TracksOperation: Operation {
    
    fileprivate let fromDate: Date?
    fileprivate var realm: RLMRealm = RLMRealm.default()
    override var isAsynchronous: Bool {
        return true
    }
    
    fileprivate var startDate: Date = Date()

    init(fromDate: Date? = nil) {
        self.fromDate = fromDate
        super.init()
    }
    
    override func main() {
        startDate = Date()
        realm = RLMRealm.default()
    }
    
    fileprivate func tracks(_ useFromDate: Bool = true) -> RLMResults<RLMObject> {
        let tracks = Track.allObjects(in: realm)
        
        //TODO: disabled temporarily
        /*if useFromDate, let fromDate = fromDate {
            let timestamp = fromDate.timeIntervalSince1970
            return tracks.objectsWhere("endTimestamp >= %lf", timestamp)
        }*/
        
        return tracks as! RLMResults<RLMObject>
    }
    
    fileprivate func tracksSorted() -> RLMResults<AnyObject> {
        return tracks().sortedResults(usingKeyPath: "startTimestamp", ascending: true) as! RLMResults<AnyObject>
    }
    
    /// Add dependency to previous operation in array
    class func addDependencies(_ operations: [TracksOperation]) {
        for (index, operation) in operations.enumerated() {
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
    
    fileprivate func locations() -> RLMResults<RLMObject> {
        let locations = TrackLocation.allObjects(in: realm)
        
        // Disabled temporarily (TODO)
        /*if let fromDate = fromDate {
            let timestamp = fromDate.timeIntervalSince1970
            return locations.objectsWhere("timestamp >= %lf", timestamp)
        }*/
        
        return locations as! RLMResults<RLMObject>
    }
    
    fileprivate func activities() -> RLMResults<RLMObject> {
        let activities = TrackActivity.allObjects(in: realm)
        
        // Disabled temporarily (TODO)
        /*if let fromDate = fromDate {
            return activities.objectsWhere("startDate >= %@", fromDate)
        }*/
        
        return activities as! RLMResults<RLMObject>
    }
    
    override func main() {
        super.main()
        
        // Only perform this if the app is in the foreground
        if UIApplication.shared.applicationState != .active {
            return
        }
        
        print("Clear unowned data")
        realm.beginWriteTransaction()
        
        let someTracks = tracks()
        let someLocations = locations()
        let someActivities = activities()
        
        // Mark locations and activities owned
        let uuid = UUID().uuidString
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

func deleteObjectsInParts(_ results: RLMResults<RLMObject>) {
    let realm = results.realm
    let max = 1000
    let count = Int(results.count)
    if count > max {
        let array = RLMResultsHelper.toArray(results: results as! RLMResults<Any>, ofType: RLMObject.self)
        let parts = Int(floor(Double(count) / Double(max)))
        for i in 0..<parts {
            let date = Date()
            realm.beginWriteTransaction()
            let slicedArray = Array(array[i*max..<((i+1)*max)])
            realm.deleteObjects(slicedArray)
            do {
                try realm.commitWriteTransaction()
            } catch {
                print("Could not commit Realm write transaction!")
            }
            print("\(results.count) \(Date().timeIntervalSince(date)) .a")
        }
    }
    if results.count > 0 {
        let date = Date()
        realm.beginWriteTransaction()
        
        var resultsArray = RLMResultsHelper.toArray(results: results as! RLMResults<AnyObject>, ofType: RLMObject.self)
        realm.deleteObjects(resultsArray)
        do {
            try realm.commitWriteTransaction()
        } catch {
            print("Could not commit Realm write transaction!")
        }
        print("\(results.count) \(Date().timeIntervalSince(date)) .b")
    }
}


class InferBikingFromSpeedOperation: TracksOperation {

    fileprivate let activity: (TrackActivity) -> Bool
    fileprivate let minSpeedLimit: Double?
    fileprivate let maxSpeedLimit: Double?
    fileprivate let minLength: Double
    init(fromDate: Date? = nil, activity: @escaping (TrackActivity) -> Bool, minSpeedLimit: Double? = nil, maxSpeedLimit: Double? = nil, minLength: Double) {
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
                
                let formatter = DateFormatter()
                formatter.dateStyle = .short
                formatter.timeStyle = .medium
                
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
                // Temporarily disabled (TODO)
                /*let inaccurateLocations = track.locations.objectsWhere("horizontalAccuracy > 200 OR verticalAccuracy > 200")
                for inaccurateLocation in inaccurateLocations {
                    print("Deleted inacurate location in track: \(track.startDate())")
                    inaccurateLocation.deleteFromRealm()
                }*/
                
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
    
    fileprivate func pruneSimilarLocation(_ track: Track) -> Bool {
        var changed = false
        
        // All 
        var index: UInt = 0
        let locations = track.locationsSorted()
        while 3 <= locations.count && index <= locations.count - 3  {
            let indexCenter = index + 1
            let indexLast = index + 2
            if let
                first = locations[index] as? TrackLocation,
                let center = locations[indexCenter] as? TrackLocation,
                let last = locations[indexLast] as? TrackLocation
            {
                let squeezedBetweenSimilar = first.coordinate().latitude == center.coordinate().latitude &&
                    first.coordinate().longitude == center.coordinate().longitude &&
                    first.coordinate().latitude == last.coordinate().latitude &&
                    first.coordinate().longitude == last.coordinate().longitude

                let deleteCenter = squeezedBetweenSimilar &&
                    first.coordinate().latitude == center.coordinate().latitude &&
                    first.coordinate().longitude == center.coordinate().longitude &&
                    abs(first.timestamp - center.timestamp) < 2 // Less than two seconds between

                if deleteCenter {
                    // Find locations of object in unsorted array
                    let i = track.locations.indexOfObject(center)
                    // Delete from locations array on track
                    track.locations.removeObject(at: i)
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
    
    fileprivate func difference(_ coordinates: [CLLocationCoordinate2D]) -> [Double] {
        
        let rotations: [Double] = {
            var rotations = [Double]()
            for (index, coordinate) in coordinates.enumerated() {
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
        
        let diffClosure: (Double) -> Double = { rotation in
            var diff = rotation - firstToLast
            while diff > 180 { diff -= 360 }
            while diff < -180 { diff += 360 }
            return diff
        }
        let diff = rotations.map(diffClosure)
        return diff
    }
    
    fileprivate func pruneCurl(_ track: Track, extendSeconds: TimeInterval = 30) -> Bool {
        // Temporarily disabled (TODO)
        /*var changed = false
        
        let varianceLimit: Double = 2000

        let locations = track.locationsSorted()
        if let firstLocation = locations.firstObject() as? TrackLocation {
            // Go 60 seconds from start
            let firstLocations = locations.objectsWhere("timestamp <= %lf", firstLocation.timestamp + extendSeconds)
            
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
                for (index, diff) in variancesFromStart.enumerated() {
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
            let lastLocations = locations.objectsWhere("timestamp >= %lf", args: [lastLocation.timestamp - extendSeconds])
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
                for (index, diff) in variancesToEnd.reversed().enumerated() {
                    if diff > varianceLimit {
                        return locations.count - UInt(index) - 1 // Subtract from count since enumerating over reverse
                    }
                }
                return nil
            }()
            if let removeFromIndex = removeFromIndex, removeFromIndex > 0 {
                removeLocations(inRange: removeFromIndex..<locations.count, fromTrack: track)
                changed = true
            }
        }
        
        return changed*/
        
        return false; // Temporary
    }
    
    func variance(_ array: [Double]) -> Double {
        let count = Double(array.count)
        let sum = array.reduce(0, +)
        let mean = sum / count
        let diffSqr =  array.map { pow($0 - mean, 2) }
        let variance = diffSqr.reduce(0, +) / count
        return variance
    }
    
    func removeLocations(inRange range: Range<UInt>, fromTrack track: Track) {
        // Delete from high index to low to not mess up order while deleting
        let indeces = range.lowerBound < range.upperBound ? range.reversed() : [UInt](range)
        for i in indeces {
            let locations = track.locationsSorted()
            if let location = locations[i] as? TrackLocation {
                let _i = track.locations.indexOfObject(location)
                track.locations.removeObject(at: _i)
                location.deleteFromRealm()
            }
        }
    }
    
    fileprivate func path(_ locations: [CLLocation]) -> UIBezierPath {
        let coordinates = locations.map { $0.coordinate }
        let allPoints = coordinates.map { CGPoint(x: $0.latitude, y: $0.longitude) }
        let points = allPoints //Array(allPoints[0..<20])
        let count = CGFloat(points.count)
        let meanPoint = points.reduce(CGPoint.zero) { mean, new in
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
                path.move(to: point)
            } else {
                path.addLine(to: point)
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
        
        let tracksArray = tracks()
        for track in tracksArray {
            if let track = track as? Track {
                if (!track.activity.cycling || !track.isInvalidated) {
                    continue
                }
                
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
                        let _i = track.locations.index(of: firstLocation)
                        track.locations.removeObject(at: _i)
                        firstLocation.deleteFromRealm()
                    }
                }
                for speed in speeds.reversed() {
                    if speed > speedLimit {
                        break
                    }
                    if let lastLocation = track.locationsSorted().lastObject() as? TrackLocation {
                        let _i = track.locations.index(lastLocation)
                        track.locations.removeObject(at: _i)
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
    
    fileprivate func mergeTrack(_ track1: Track, toTrack track2: Track, forceBike: Bool = false, useFirstTrackActivity: Bool = true) -> Track {
        realm.beginWriteTransaction()
        if track1.isInvalidated || track2.isInvalidated {
            print("Couldn't merge tracks since one is invalid")
            realm.cancelWriteTransaction()
            return track1
        }
        // Merge locations
        for location in track2.locations {
            track1.locations.add(location)
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
    
    fileprivate func mergeTracks(_ tracks: [Track]) -> Track? {
        var tracks = tracks
        while tracks.count > 1 {
            let track1 = tracks[0]
            let track2 = tracks[1]
            mergeTrack(track1, toTrack: track2)
            tracks.remove(at: 1)
        }
        return tracks.first
    }
    
    fileprivate func closeTracks(track track1: Track, toTrack track2: Track, closerThanSeconds seconds: TimeInterval) -> Bool {
        if let
            track1EndDate = track1.endDate(),
            let track2StartDate = track2.startDate()
        {
            let timeIntervalBetweenTracks = track2StartDate.timeIntervalSince(track1EndDate as Date)
            if timeIntervalBetweenTracks < seconds {
                return true
            }
        }
        return false
    }
}


class MergeTimeTracksOperation: MergeTracksOperation {
    
    fileprivate let seconds: TimeInterval
    init(fromDate: Date? = nil, seconds: TimeInterval) {
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
            if let track = tracks[count] as? Track, let nextTrack = tracks[count+1] as? Track {
                let close = closeTracks(track: track, toTrack: nextTrack, closerThanSeconds: seconds)
                let sameType = track.activity.sameActivityTypeAs(nextTrack.activity)
                let merge = close && sameType
                if merge {
                    print("Close tracks: \(track.endDate()) to \(nextTrack.startDate())")
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
                   let nextTrack = tracks[count+1] as? Track
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
        var tracks = RLMResultsHelper.toArray(results: tracksSorted(), ofType: Track.self)
        
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .medium
        
        var count = 0
        while count + 2 < tracks.count {
            let track = tracks[count]
            if !track.activity.cycling { // Is not biking
                count += 1
                continue
            }
            // Find latest bike track within time interval
            var nextCount = count
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
                print("\(formatter.string(from: track.endDate()!)) | \(formatter.string(from: _nextTrack.startDate()!))")
                nextCount += 1 // Keep searching
            }
            if nextCount > count {
                // Merge tracks between bike tracks
                let tracksToMerge = Array(tracks[count...nextCount])
                
                for track in tracksToMerge {
                    print("\(formatter.string(from: track.startDate()!)) -> \(formatter.string(from: track.endDate()!))")
                }
                mergeTracks(tracksToMerge)
                tracks = RLMResultsHelper.toArray(results: tracksSorted(), ofType: Track.self)
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
            if let track = tracks[count] as? Track, let nextTrack = tracks[count+1] as? Track {
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
        if UIApplication.shared.applicationState != .active {
            return
        }
        
        print("Geocode bike tracks")
        
        let bikeTracks = tracks()
        for track in bikeTracks {
            if let track = track as? Track, !track.hasBeenGeocoded {
                if track.activity.cycling {
                    // Geocode synchronously to make sure writes are happening on same thread
                    track.geocode(true)
                }
            }
        }
        print("Geocode bike tracks DONE \(-startDate.timeIntervalSinceNow)")
    }
}


class UploadBikeTracksOperation: TracksOperation {
    
    override func main() {
        super.main()
        
        // Temporarily disabled (TODO)
        /*
        // Only perform this if the app is in the foreground
        if UIApplication.shared.applicationState != .active {
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
        let dummyTrackId = UUID().uuidString
        for track in Track.allObjects() {
            if let track = track as? Track {
                if track.serverId.lengthOfBytes(using: String.Encoding.utf8) == dummyTrackId.lengthOfBytes(using: String.Encoding.utf8) {
                    do {
                        try track.realm?.transaction {
                            track.serverId = ""
                        }
                    } catch let error as NSError {
                        print("Realm transaction failed: \(error.description)")
                    }
                }
            }
        }
        
        let timestamp = Date(timeIntervalSinceNow: -60*60*1).timeIntervalSince1970 // Only upload tracks older than an hour
        let bikeTracks = tracks()
        for bikeTrack in bikeTracks {
            if let track = bikeTrack as? Track {
                if !(track.endTimestamp <= timestamp && track.serverId == "" && track.activity.cycling) {
                    continue
                }
                
                let temporaryTrackId = UUID().uuidString
                do {
                    try track.realm?.transaction {
                        track.serverId = temporaryTrackId
                    }
                } catch let error as NSError {
                    print("Realm transaction failed: \(error.description)")
                }
                TracksClient.sharedInstance.upload(track) { result in
                    if let track = Track.allObjects().objectsWhere("serverId == %@", temporaryTrackId).firstObject() as? Track {
                        switch result {
                            case .success(let trackServerId):
                                do {
                                    try track.realm?.transaction {
                                        track.serverId = trackServerId
                                        print("Track stored on server: " + trackServerId)
                                    }
                                } catch let error as NSError {
                                    print("Realm transaction failed: \(error.description)")
                                }
                            case .other(let result):
                                switch result {
                                    case .failed(let error):
                                        print(error.localizedDescription)
                                        do {
                                            try track.realm?.transaction {
                                                track.serverId = ""
                                            }
                                        } catch let error as NSError {
                                            print("Realm transaction failed: \(error.description)")
                                        }
                                    default:
                                        print("Other upload error \(result)")
                                        do {
                                            try track.realm?.transaction {
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
        */
    }
}
