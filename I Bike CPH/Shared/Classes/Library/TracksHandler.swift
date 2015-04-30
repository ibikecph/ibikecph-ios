//
//  TracksHandler.swift
//  I Bike CPH
//
//  Created by Tobias Due Munk on 20/02/15.
//  Copyright (c) 2015 I Bike CPH. All rights reserved.
//

import UIKit
import CoreMotion

let tracksHandler = TracksHandler()
let processedSmallNoticationKey = "processedSmallNoticationKey"
let processedBigNoticationKey = "processedBigNoticationKey"

class TracksHandler {
    
    private var processing: Bool = false

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
        let queue = NSOperationQueue.mainQueue()
        queue.maxConcurrentOperationCount = 1
        return queue
    }()
    
    class func setNeedsProcessData(force: Bool = false) {
        if force {
            tracksHandler.cleanUpBig()
            return
        }
        if NSDate().timeIntervalSinceDate(tracksHandler.lastProcessedBig) > 60*60*1 { // Do big stuff every hour
            tracksHandler.cleanUpBig()
            tracksHandler.lastProcessedBig = NSDate()
            return
        }
        if NSDate().timeIntervalSinceDate(tracksHandler.lastProcessedSmall) > 60*5 { // Do small stuff every 5 min
            tracksHandler.cleanUpSmall()
            tracksHandler.lastProcessedSmall = NSDate()
            return
        }
        Async.main(after: 10) {
            self.setNeedsProcessData()
        }
    }
    
    private func cleanUpSmall() {
        if tracksHandler.processing {
            println("Already processing")
            Async.main(after: 10) { // Check again after 10 seconds
                self.cleanUpSmall()
            }
            return
        }
        tracksHandler.processing = true
        
        println("Start processing small")
        let fromDate = lastProcessedSmall.dateByAddingTimeInterval(-60*15) // Go 15 minutes back
        let operations = [
            MergeCloseSameActivityTracksOperation(fromDate: fromDate, seconds: 60),
            RecalculateTracksOperation(fromDate: fromDate)
        ]
        operations.last?.completionBlock = {
            println("Done processing small")
            tracksHandler.processing = false
            NotificationCenter.post(processedSmallNoticationKey, object: self)
        }
        TracksOperation.addDependencies(operations)
        operationQueue.addOperations(operations, waitUntilFinished: false)
    }
    
    private func cleanUpBig() {
        if tracksHandler.processing {
            println("Already processing")
            Async.main(after: 10) { // Check again after 10 seconds
                self.cleanUpBig()
            }
            return
        }
        tracksHandler.processing = true
        
        println("Start processing big")
        let fromDate = lastProcessedBig.dateByAddingTimeInterval(-60*15) // Go 15 minutes back
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
            RecalculateTracksOperation(fromDate: fromDate),
            RemoveUnownedDataOperation(fromDate: fromDate)
        ]
        
        operations.last?.completionBlock = {
            println("Done processing big")
            tracksHandler.processing = false
            NotificationCenter.post(processedBigNoticationKey, object: self)
        }
        TracksOperation.addDependencies(operations)
        operationQueue.addOperations(operations, waitUntilFinished: false)
    }
}


class TracksOperation: NSOperation {
    
    private let fromDate: NSDate?
    init(fromDate: NSDate? = nil) {
        self.fromDate = fromDate
        super.init()
    }
    
    private func tracks() -> RLMResults {
        let tracks = Track.allObjects()
        if let fromDate = fromDate {
            let timestamp = fromDate.timeIntervalSince1970
            return tracks.objectsWhere("endTimestamp >= %lf", timestamp)
        }
        return tracks
    }
    
    private func tracksSorted() -> RLMResults {
        return tracks().sortedResultsUsingProperty("startTimestamp", ascending: true)
    }
    
    private func tracksSortedAsTracks() -> [Track] {
        return tracksSorted().toArray(Track.self)
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
        println("Recalculating tracks")
        RLMRealm.beginWriteTransaction()
        for track in tracks()  {
            if let track = track as? Track {
                track.recalculate(inWriteTransaction: false)
            }
        }
        RLMRealm.commitWriteTransaction()
    }
}


class RemoveEmptyTracksOperation: TracksOperation {
    
    override func main() {
        println("Remove empty tracks")
        RLMRealm.beginWriteTransaction()
        for track in tracks() {
            if let track = track as? Track where track.locations.count == 0 {
                track.deleteFromRealm(inWriteTransaction: false)
            }
        }
        RLMRealm.commitWriteTransaction()
    }
}


class RemoveUnownedDataOperation: TracksOperation {
    
    override func main() {
        println("Clear unowned data")
        RLMRealm.beginWriteTransaction()
        // Mark locations
        let locations = tracks()
        for location in locations {
            if let location = location as? TrackLocation {
                location.owned = false
            }
        }
        for track in tracks() {
            if let track = track as? Track {
                let _locations = track.locations
                for _location in _locations {
                    if let _location = _location as? TrackLocation {
                        _location.owned = true
                    }
                }
            }
        }
        // Mark activities
        let activities = TrackActivity.allObjects()
        for activity in activities {
            if let activity = activity as? TrackLocation {
                activity.owned = false
            }
        }
        for track in Track.allObjects() {
            if let track = track as? Track {
                track.activity.owned = true
            }
        }
        
        let unownedLocations = TrackLocation.objectsWhere("owned == FALSE").toArray()
        println("Deleting \(unownedLocations.count) unowned locations")
        RLMRealm.defaultRealm().deleteObjects(unownedLocations)
        let unownedActivities = TrackActivity.objectsWhere("owned == FALSE").toArray()
        println("Deleting \(unownedActivities.count) unowned activities")
        RLMRealm.defaultRealm().deleteObjects(unownedActivities)
        RLMRealm.commitWriteTransaction()
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
        println("Infer bike from speed from other activity")
        for track in Track.allObjects().toArray(Track.self) {
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
            track.activity.cycling = true
            track.realm.commitWriteTransaction()
            println("Infered biking \(track.startDate)")
        }
    }
}

class ClearLeftOversOperation: TracksOperation {
    
    override func main() {
        println("Clear left overs")
        for track in tracksSortedAsTracks() {
            track.recalculate()
            
            let formatter = NSDateFormatter()
            formatter.dateStyle = .ShortStyle
            formatter.timeStyle = .MediumStyle
            
            // Empty
            if track.locations.count <= 1 {
                println("Deleted no (to 1) locations: \(track.startDate)")
                track.deleteFromRealm()
                continue
            }
            // Not moving activity
            let moving = track.activity.moving()
            if !moving {
                println("Deleted not moving activity: \(track.startDate)")
                track.deleteFromRealm()
                continue
            }
            // Very slow
            let verySlow = track.slow(speedLimit: 2, minLength: 0.020)
            if verySlow {
                println("Deleted slow: \(track.startDate)")
                track.deleteFromRealm()
                continue
            }
            // Somewhat slow + low accuracy
            let someWhatSlow = track.slow(speedLimit: 5, minLength: 0.020)
            let lowAccuracy = track.lowAccuracy(minAccuracy: 50)
            if someWhatSlow && lowAccuracy {
                println("Deleted low accuracy: \(track.startDate)")
                track.deleteFromRealm()
                continue
            }
            // Somewhat slow + long distance
            let someWhatSlowLongDistance = track.slow(speedLimit: 5, minLength: 0.200)
            if someWhatSlowLongDistance {
                println("Deleted someWhatSlowLongDistance: \(track.startDate)")
                track.deleteFromRealm()
                continue
            }
            // Very fast
            let veryFast = track.speeding(speedLimit: 50, minLength: 0.200)
            if veryFast {
                println("Deleted fast: \(track.startDate) - \(track.endDate)")
                track.deleteFromRealm()
                continue
            }
            // Odd flight distance (for stationary device with fluctuating data)
            if let flightWithOneMedianStopDistance = track.flightWithOneMedianStopDistance() {
                let shortFlight = track.flightDistance() < 50
                let flightLengthRatio = track.length / flightWithOneMedianStopDistance
                let flightSuspicious = 10 < flightLengthRatio
                //                println("PP \(shortFlight) \(flightSuspicious) \(track.flightDistance()) \(flightLengthRatio) \(track.duration) \(track.locations.count) \(formatter.stringFromDate(track.startDate!))")
                if flightSuspicious {
                    println("Deleted short flight distance: \(track.startDate)")
                    track.deleteFromRealm()
                    continue
                }
            }
            // No length
            let noLength = track.length == 0
            if noLength {
                println("Deleted no length: \(track.startDate)")
                track.deleteFromRealm()
                continue
            }
            // No duration
            let noDuration = track.duration == 0
            if noDuration {
                println("Deleted no duration: \(track.startDate)")
                track.deleteFromRealm()
                continue
            }
        }
    }
}


class PruneSlowEndsOperation: TracksOperation {
    
    override func main() {
        println("Prune slow ends")
        for track in tracks() {
            if let track = track as? Track {
                let cycling = track.activity.cycling
                if !cycling {
                    continue
                }
                let speeds = track.smoothSpeeds()
                
                let speedLimit: Double = 7 * 1000 / 3600 // 10 km/h
                for speed in speeds {
                    if speed > speedLimit {
                        break
                    }
                    if let firstLocation = track.locations.firstObject() as? TrackLocation {
                        firstLocation.deleteFromRealm()
                    }
                }
                for speed in speeds.reverse() {
                    if speed > speedLimit {
                        break
                    }
                    if let lastLocation = track.locations.lastObject() as? TrackLocation {
                        lastLocation.deleteFromRealm()
                    }
                }
                track.recalculate()
            }
        }
    }
}


class MergeTracksOperation: TracksOperation {
    
    private func mergeTrack(track1: Track, toTrack track2: Track, forceBike: Bool = false, forceActivity: TrackActivity? = nil) -> Track {
        // Merge locations
        track1.realm.beginWriteTransaction()
        for location in track2.locations {
            track1.locations.addObject(location)
        }
        // Combine
        track1.end = track2.end
        if forceBike {
            track1.activity.cycling = true
            track1.activity.automotive = false
            track1.activity.walking = false
            track1.activity.running = false
            track1.activity.confidence = 0
        } else if let forceActivity = forceActivity {
            let startDate = track1.activity.startDate
            track1.activity = forceActivity;
            track1.activity.startDate = startDate
        }
        // Clean up
        track1.recalculate(inWriteTransaction: false)
        track2.deleteFromRealm(inWriteTransaction: false)
        
        track1.realm.commitWriteTransaction()
        
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
            track1EndDate = track1.endDate,
            track2StartDate = track2.startDate
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
        println("Merge close to same activity")
        var tracks = tracksSorted()
        
        var count = UInt(0)
        while count + 1 < tracks.count {
            if let track = tracks[count] as? Track, nextTrack = tracks[count+1] as? Track {
                let close = closeTracks(track: track, toTrack: nextTrack, closerThanSeconds: seconds)
                let sameType = track.activity.sameActivityTypeAs(nextTrack.activity)
                let merge = close && sameType
                if merge {
                    println("Close tracks: \(track.endDate) to \(nextTrack.startDate)")
                    let mergedTrack = mergeTrack(track, toTrack: nextTrack)
                    tracks = tracksSorted()
                } else {
                    count++
                }
                //                println(" \(count) / \(tracks.count)")
            }
        }
    }
}


class MergeCloseToUnknownActivityTracksOperation: MergeTimeTracksOperation {
    
    override func main() {
        println("Merge close to unknown activity tracks")
        var tracks = tracksSorted()
            
        var count = UInt(0)
        while count + 1 < tracks.count {
            if let track = tracks[count] as? Track, nextTrack = tracks[count+1] as? Track {
                let close = closeTracks(track: track, toTrack: nextTrack, closerThanSeconds: seconds)
                let unknown = track.activity.unknown || track.activity.completelyUnknown()
                let unknownNext = nextTrack.activity.unknown || nextTrack.activity.completelyUnknown()
                let eitherIsUnknown = unknown || unknownNext
                let merge = close && eitherIsUnknown
                if merge {
                    let forceActivity = unknownNext ? track.activity : nextTrack.activity
                    let mergedTrack = mergeTrack(track, toTrack: nextTrack, forceActivity: forceActivity)
                    tracks = tracksSorted()
                    println("Close to empty activity: \(mergedTrack.startDate)")
                } else {
                    count++
                }
                //                println(" \(count) / \(tracks.count)")
            }
        }
    }
}


class MergeTracksBetweenBikeTracksOperation: MergeTimeTracksOperation {
    
    override func main() {
        println("Merge track between bike tracks")
        var tracks = tracksSortedAsTracks()
        
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
                println("\(formatter.stringFromDate(track.endDate!)) | \(formatter.stringFromDate(_nextTrack.startDate!))")
                nextTrack = _nextTrack
                nextCount++
            }
            if let nextTrack = nextTrack where nextCount > count {
                // Merge tracks between bike tracks
                println("MERGEEEEE")
                let tracksToMerge = Array(tracks[count...nextCount])
                
                for track in tracksToMerge {
                    println("\(formatter.stringFromDate(track.startDate!)) -> \(formatter.stringFromDate(track.endDate!))")
                }
                mergeTracks(tracksToMerge)
                tracks = tracksSortedAsTracks()
            } else {
                count++
            }
        }
    }
}

class MergeBikeCloseWithMoveTracksOperation: MergeTimeTracksOperation {
    
    override func main() {
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
    }
}



