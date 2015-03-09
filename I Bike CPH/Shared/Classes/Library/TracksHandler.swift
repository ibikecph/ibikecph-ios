//
//  TracksHandler.swift
//  I Bike CPH
//
//  Created by Tobias Due Munk on 20/02/15.
//  Copyright (c) 2015 I Bike CPH. All rights reserved.
//

import UIKit
import CoreMotion

class TracksHandler {
    
    class func hasTrackedBikeData() -> Bool {
        let hasBikeTracks = Track.objectsWhere("activity.cycling == TRUE").count > 0
        return hasBikeTracks
    }
   
    class func cleanUpTracks() {
        Async.background() {
            TracksHandler.removeEmptyTracks()
        }.background() {
            TracksHandler.mergeCloseToEmptyActivityTracks(seconds: 30)
        }.background() {
            TracksHandler.inferBikingFromSpeed(activity: { $0.walking }, minSpeedLimit: 10, minLength: 0.05)
        }.background() {
            TracksHandler.mergeTrackBetweenBike(seconds: 60*5)
        }.background() {
            TracksHandler.mergeCloseSameActivityTracks(seconds: 60)
        }.background() {
            TracksHandler.inferBikingFromSpeed(activity: { $0.automotive }, minSpeedLimit: 10, maxSpeedLimit: 20, minLength: 0.200)
        }.background() {
            TracksHandler.mergeBikeCloseWithMoveTracks(seconds: 60)
        }.background() {
            TracksHandler.clearLeftOvers()
        }.background() {
            TracksHandler.recalculateTracks()
        }
    }
    
    private class func recalculateTracks() {
        for track in Track.allObjects().toArray(Track.self) {
            track.recalculate()
        }
    }
    
    private class func removeEmptyTracks() {
        for track in Track.allObjects().toArray(Track.self) {
            if track.locations.count == 0 {
                track.deleteFromRealm()
            }
        }
    }
    
    private class func clearLeftOvers() {
        for track in Track.allObjects().toArray(Track.self) {
            // Empty activity
            if track.activity.empty() {
                println("Delete empty activity: \(track.activity.startDate)")
                track.deleteFromRealm()
                continue
            }
            // Empty
            if track.locations.count == 0 {
                track.deleteFromRealm()
                continue
            }
            // Very slow
            let verySlow = track.slow(speedLimit: 1, minLength: 0.020)
            let move = track.activity.moving()
            if !move && verySlow {
                println("Deleted slow: \(track.activity.startDate)")
                track.deleteFromRealm()
                continue
            }
            // Somewhat slow + low accuracy
            let someWhatSlow = track.slow(speedLimit: 5, minLength: 0.020)
            let lowAccuracy = track.lowAccuracy(minAccuracy: 50)
            if someWhatSlow && lowAccuracy {
                println("Deleted low accuracy: \(track.activity.startDate)")
                track.deleteFromRealm()
                continue
            }
            // Low flight distance
            let shortFlight = track.flightDistance() < 50
            let flightLengthRatio = track.flightDistance() / track.length
            let flightSuspicuous = 0.1 < flightLengthRatio && flightLengthRatio < 10
            println("\(shortFlight) \(flightSuspicuous) \(track.duration) \(track.locations.count)")
            if shortFlight && flightSuspicuous  && track.duration > 60 && track.locations.count > 5 {
                println("Deleted short flight distance: \(track.activity.startDate)")
                track.deleteFromRealm()
                continue
            }
        }
    }
    
    private class func mergeTrackBetweenBike(#seconds: NSTimeInterval) {
        var tracks = tracksSorted()
        
        var count = 0
        while count < tracks.count - 2 {
            let track1 = tracks[count]
            let track2 = tracks[count+1]
            let track3 = tracks[count+2]
            let close = closeTracks(track: track1, toTrack: track3, closerThanSeconds: seconds)
            let betweenBikes = track1.activity.cycling && track3.activity.cycling
            let merge = close && betweenBikes
            if merge {
                let mergedTrack12 = mergeTrack(track1, toTrack: track2)
                let mergedTrack123 = mergeTrack(mergedTrack12, toTrack: track3)
                tracks = tracksSorted()
                print("Between bike tracks: \(mergedTrack123.activity.startDate)")
            } else {
                count++
            }
            println(" \(count) / \(tracks.count)")
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
            println("Infered biking \(track.activity.startDate)")
        }
    }
    
    private class func tracksSorted() -> [Track] {
        return Track.allObjects().sortedResultsUsingProperty("startTimestamp", ascending: true).toArray(Track.self)
    }
    
    private class func mergeCloseSameActivityTracks(#seconds: NSTimeInterval) {
        var tracks = tracksSorted()
        
        var count = 0
        while count < tracks.count - 1 {
            let track = tracks[count]
            let nextTrack = tracks[count+1]
            let close = closeTracks(track: track, toTrack: nextTrack, closerThanSeconds: seconds)
            let sameType = track.activity.sameActivityTypeAs(nextTrack.activity)
            let merge = close && sameType
            if merge {
                let mergedTrack = mergeTrack(track, toTrack: nextTrack)
                tracks = tracksSorted()
                print("Close tracks: \(mergedTrack.activity.startDate)")
            } else {
                count++
            }
            println(" \(count) / \(tracks.count)")
        }
    }
    
    private class func mergeBikeCloseWithMoveTracks(#seconds: NSTimeInterval) {
        var tracks = tracksSorted()
        
        var count = 0
        while count < tracks.count - 1 {
            let track = tracks[count]
            let nextTrack = tracks[count+1]
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
                print("Bike close w. move: \(mergedTrack.activity.startDate)")
            } else {
                count++
            }
            println(" \(count) / \(tracks.count)")
        }
    }
    
    private class func mergeCloseToEmptyActivityTracks(#seconds: NSTimeInterval) {
        var tracks = tracksSorted()
        
        var count = 0
        while count < tracks.count - 1 {
            let track = tracks[count]
            let nextTrack = tracks[count+1]
            let close = closeTracks(track: track, toTrack: nextTrack, closerThanSeconds: seconds)
            let empty = track.activity.empty()
            let emptyNext = nextTrack.activity.empty()
            let eitherIsEmpty = empty || emptyNext
            let merge = close && eitherIsEmpty
            if merge {
                let forceActivity = emptyNext ? track.activity : nextTrack.activity
                let mergedTrack = mergeTrack(track, toTrack: nextTrack, forceActivity: forceActivity)
                tracks = tracksSorted()
                print("Close to empty: \(mergedTrack.activity.startDate)")
            } else {
                count++
            }
            println(" \(count) / \(tracks.count)")
        }
    }
    
    private class func closeTracks(track track1: Track, toTrack track2: Track, closerThanSeconds seconds: NSTimeInterval) -> Bool {
        if let track1EndDate = track1.endDate {
            if let track2StartDate = track2.startDate {
                let timeIntervalBetweenTracks = track2StartDate.timeIntervalSinceDate(track1EndDate)
                if timeIntervalBetweenTracks < seconds {
                    return true
                }
            }
        }
        return false
    }
    
    private class func mergeTrack(track1: Track, toTrack track2: Track, forceBike: Bool = false, forceActivity: TrackActivity? = nil) -> Track {
        let mergedTrack = Track()
        mergedTrack.addToRealm()
        // Merge locations
        mergedTrack.realm.beginWriteTransaction()
        for location in track1.locations {
            mergedTrack.locations.addObject(location)
        }
        for location in track2.locations {
            mergedTrack.locations.addObject(location)
        }
        mergedTrack.realm.commitWriteTransaction()
        mergedTrack.recalculate()
        // Combine
        mergedTrack.realm.beginWriteTransaction()
        mergedTrack.start = track1.start
        mergedTrack.end = track2.end
        if forceBike {
            var activity = TrackActivity()
            activity.addToRealm(inWriteTransaction: false)
            activity.startDate = track1.activity.startDate
            activity.cycling = true
            mergedTrack.activity = activity
        } else if let forceActivity = forceActivity {
            mergedTrack.activity = forceActivity;
            mergedTrack.activity.startDate = track1.activity.startDate
        } else {
            mergedTrack.activity = track1.activity
        }
        mergedTrack.realm.commitWriteTransaction()
        // Clean up
        track1.deleteFromRealm()
        track2.deleteFromRealm()
        
        return mergedTrack
    }
}
