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

class TracksHandler {
    
    class func hasTrackedBikeData() -> Bool {
        let hasBikeTracks = Track.objectsWhere("activity.cycling == TRUE").count > 0
        return hasBikeTracks
    }
    
    private var processing: Bool = false {
        didSet {
            processingHandler?(processing)
        }
    }
    var processingHandler: ((Bool) -> ())?

    var lastProcessedSmall: NSDate = NSDate()
    var lastProcessedBig: NSDate = NSDate()
    
    class func setNeedsProcessData(force: Bool = false) {
        if force {
            self.cleanUpSmall()
            self.cleanUpBig()
            return
        }
        if NSDate().timeIntervalSinceDate(tracksHandler.lastProcessedSmall) > 10 {
            tracksHandler.lastProcessedSmall = NSDate()
            self.cleanUpSmall()
        }
        if NSDate().timeIntervalSinceDate(tracksHandler.lastProcessedBig) > 60 {
            tracksHandler.lastProcessedBig = NSDate()
            self.cleanUpBig()
            return
        }
        Async.main(after: 6) {
            self.setNeedsProcessData()
        }
    }
    
    private class func cleanUpSmall() {
        if tracksHandler.processing {
            println("Already processing")
            Async.main(after: 10) { // Check again after 10 seconds
                self.cleanUpSmall()
            }
            return
        }
        tracksHandler.processing = true
        
        println("Start processing small")
        Async.main() { println("Remove empty tracks")
            TracksHandler.removeEmptyTracks()
        }.main() { println("Merge close to same activity")
            TracksHandler.mergeCloseSameActivityTracks(seconds: 60)
        }.main {
            println("Done processing small")
            tracksHandler.processing = false
        }
    }
    
    private class func cleanUpBig() {
        if tracksHandler.processing {
            println("Already processing")
            Async.main(after: 10) { // Check again after 10 seconds
                self.cleanUpBig()
            }
            return
        }
        tracksHandler.processing = true
        
        println("Start processing big")
        Async.background() { println("Remove empty tracks")
            TracksHandler.removeEmptyTracks()
        }.background() { println("Merge close to unknown activity tracks")
            TracksHandler.mergeCloseToUnknownActivityTracks(seconds: 30)
        }.background() { println("Infer bike from speed from walking")
            TracksHandler.inferBikingFromSpeed(activity: { $0.walking }, minSpeedLimit: 7, minLength: 0.050)
        }.background() { println("Infer bike from speed from automotive")
            TracksHandler.inferBikingFromSpeed(activity: { $0.automotive }, minSpeedLimit: 10, maxSpeedLimit: 20, minLength: 0.200)
        }.background() { println("Merge close to same activity")
            TracksHandler.mergeCloseSameActivityTracks(seconds: 60)
        }.background() { println("Merge track between bike tracks")
            TracksHandler.mergeTracksBetweenBike(seconds: 60*5)
        }.background() { println("Merge bike close with non-stationary tracks")
            TracksHandler.mergeBikeCloseWithMoveTracks(seconds: 60)
        }.background() { println("Merge track between bike tracks – again")
            TracksHandler.mergeTracksBetweenBike(seconds: 60*5)
        }.background() { println("Clear left overs")
            TracksHandler.clearLeftOvers()
        }.background() { println("Prune slow ends")
            TracksHandler.pruneSlowEnds()
        }.background() { println("Recalculate")
            TracksHandler.recalculateTracks()
        }.main() {
            println("Done processing big")
            tracksHandler.processing = false
        }
    }
    
    private class func recalculateTracks() {
        for track in Track.allObjects() {
            if let track = track as? Track {
                track.recalculate()
            }
        }
    }
    
    private class func removeEmptyTracks() {
        let tracks = Track.allObjects()
        RLMRealm.beginWriteTransaction()
        for track in tracks {
            if let track = track as? Track where track.locations.count == 0 {
                track.deleteFromRealm(inWriteTransaction: false)
            }
        }
        RLMRealm.commitWriteTransaction()
    }
    
    private class func clearLeftOvers() {
        for track in Track.allObjects().toArray(Track.self) {
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
    
    private class func pruneSlowEnds() {
        for track in Track.allObjects() {
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
    
    private class func mergeTracksBetweenBike(#seconds: NSTimeInterval) {
        var tracks = tracksSorted()
        
        let formatter = NSDateFormatter()
        formatter.dateStyle = .ShortStyle
        formatter.timeStyle = .MediumStyle
        
        var count = 0
        while count < tracks.count - 2 {
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
                tracks = tracksSorted()
            } else {
                count++
            }
        }
    }
    
    private class func inferBikingFromSpeed(#activity: (TrackActivity) -> Bool, minSpeedLimit: Double? = nil, maxSpeedLimit: Double? = nil, minLength: Double) {
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
    
    private class func tracksSorted_() -> RLMResults {
        return Track.allObjects().sortedResultsUsingProperty("startTimestamp", ascending: true)
    }
    
    private class func tracksSorted() -> [Track] {
        return Track.allObjects().sortedResultsUsingProperty("startTimestamp", ascending: true).toArray(Track.self)
    }
    
    private class func mergeCloseSameActivityTracks(#seconds: NSTimeInterval) {
        var tracks = tracksSorted_()
        
        var count = UInt(0)
        while count < tracks.count - 1 {
            if let track = tracks[count] as? Track, nextTrack = tracks[count+1] as? Track {
                let close = closeTracks(track: track, toTrack: nextTrack, closerThanSeconds: seconds)
                let sameType = track.activity.sameActivityTypeAs(nextTrack.activity)
                let merge = close && sameType
                if merge {
                    println("Close tracks: \(track.endDate) to \(nextTrack.startDate)")
                    let mergedTrack = mergeTrack(track, toTrack: nextTrack)
                    tracks = tracksSorted_()
                } else {
                    count++
                }
//                println(" \(count) / \(tracks.count)")
            }
        }
    }
    
    private class func mergeBikeCloseWithMoveTracks(#seconds: NSTimeInterval) {
        var tracks = tracksSorted_()
        
        var count = UInt(0)
        while count < tracks.count - 1 {
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
                    tracks = tracksSorted_()
                    println("Bike close w. move: \(mergedTrack.startDate)")
                } else {
                    count++
                }
//                println(" \(count) / \(tracks.count)")
            }
        }
    }
    
    private class func mergeCloseToUnknownActivityTracks(#seconds: NSTimeInterval) {
        var tracks = tracksSorted_()
        
        var count = UInt(0)
        while count < tracks.count - 1 {
            if let track = tracks[count] as? Track, nextTrack = tracks[count+1] as? Track {
                let close = closeTracks(track: track, toTrack: nextTrack, closerThanSeconds: seconds)
                let unknown = track.activity.unknown || track.activity.completelyUnknown()
                let unkownNext = nextTrack.activity.unknown || nextTrack.activity.completelyUnknown()
                let eitherIsUnkown = unknown || unkownNext
                let merge = close && eitherIsUnkown
                if merge {
                    let forceActivity = unkownNext ? track.activity : nextTrack.activity
                    let mergedTrack = mergeTrack(track, toTrack: nextTrack, forceActivity: forceActivity)
                    tracks = tracksSorted_()
                    println("Close to empty activity: \(mergedTrack.startDate)")
                } else {
                    count++
                }
//                println(" \(count) / \(tracks.count)")
            }
        }
    }
    
    private class func closeTracks(track track1: Track, toTrack track2: Track, closerThanSeconds seconds: NSTimeInterval) -> Bool {
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
    
    private class func mergeTrack(track1: Track, toTrack track2: Track, forceBike: Bool = false, forceActivity: TrackActivity? = nil) -> Track {
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
    
    private class func mergeTracks(tracks: [Track]) -> Track? {
        var tracks = tracks
        while tracks.count > 1 {
            let track1 = tracks[0]
            let track2 = tracks[1]
            mergeTrack(track1, toTrack: track2)
            tracks.removeAtIndex(1)
        }
        return tracks.first
    }
}
