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
   
    class func cleanUpTracks() {
        removeEmptyTracks()
        mergeCloseTracks(seconds: 60*5)
        inferBikingFromHighSpeedWalking(speedLimit: 10, minLength: 0.05)
        mergeBikeCloseWithMoveTracks(seconds: 60*3)
        clearLeftOvers()
        recalculateTracks()
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
            if track.locations.count == 0 {
                track.deleteFromRealm()
                continue
            }
            let verySlow = trackIsSlow(track, speedLimit: 1, minLength: 0.020)
            let move = moving(track)
            if !move && verySlow {
                println("Deleted slow: \(track.activity.startDate)")
                track.deleteFromRealm()
                continue
            }
            let someWhatSlow = trackIsSlow(track, speedLimit: 5, minLength: 0.020)
            let lowAccuracy = trackHasLowAccuracy(track, minAccuracy: 50)
            if someWhatSlow && lowAccuracy {
                println("Deleted low accuracy: \(track.activity.startDate)")
                track.deleteFromRealm()
                continue
            }
        }
    }
    
    private class func inferBikingFromHighSpeedWalking(#speedLimit: Double, minLength: Double) {
        for track in Track.allObjects().toArray(Track.self) {
            if !track.activity.walking {
                continue
            }
            if !trackIsSpeeding(track, speedLimit: speedLimit, minLength: minLength) {
                continue
            }
            track.realm.beginWriteTransaction()
            track.activity.walking = false
            track.activity.cycling = true
            track.realm.commitWriteTransaction()
            println("Infered biking \(track.activity.startDate)")
        }
    }
    
    private class func trackIsSpeeding(track: Track, speedLimit: Double, minLength: Double = 0.050) -> Bool {
        let duration = track.duration / 3600
        if duration <= 0 {
            return false
        }
        let length = track.length / 1000
        if length < minLength {
            return false
        }
        let speed = length/duration
        if speed < speedLimit {
            return false
        }
        return true
    }
    
    private class func trackIsSlow(track: Track, speedLimit: Double, minLength: Double = 0.05) -> Bool {
        let duration = track.duration / 3600
        if duration <= 0 {
            return false
        }
        let length = track.length / 1000
        if length < minLength {
            return false
        }
        let speed = length/duration
        if speed > speedLimit {
            return false
        }
        return true
    }
    
    private class func trackHasLowAccuracy(track: Track, minAccuracy: Double = 100) -> Bool {
        let t1 = track.locations
        let t2 = track.locations.objectsWithPredicate(nil)
        let t3 = track.locations.objectsWithPredicate(nil).averageOfProperty("horizontalAccuracy")
        let horizontal = track.locations.objectsWithPredicate(nil).averageOfProperty("horizontalAccuracy").doubleValue
        let vertical = track.locations.objectsWithPredicate(nil).averageOfProperty("verticalAccuracy").doubleValue
        if min(horizontal, vertical) < minAccuracy {
            return false
        }
        return true
    }
    
    private class func tracksSorted() -> [Track] {
        return Track.allObjects().sortedResultsUsingProperty("startTimestamp", ascending: true).toArray(Track.self)
    }
    
    private class func mergeCloseTracks(#seconds: NSTimeInterval) {
        var tracks = tracksSorted()
        
        var count = 0
        while count < tracks.count - 1 {
            let track = tracks[count]
            let nextTrack = tracks[count+1]
            let close = closeTracks(track: track, toTrack: nextTrack, closerThanSeconds: seconds)
            let sameType = sameActivityTracks(track: track, toTrack: nextTrack)
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
            let move = moving(track) || trackIsSpeeding(track, speedLimit: 10, minLength: 0.1)
            let moveNext = moving(track) || trackIsSpeeding(track, speedLimit: 10, minLength: 0.1)
            let bikeCloseAndMoving = (cycling && moveNext) || (cyclingNext && move)
            let merge = close && bikeCloseAndMoving
            if merge {
                let mergedTrack = mergeTrack(track, toTrack: nextTrack, forceBike: true)
                tracks = tracksSorted()
                print("Bike close w. move:\(mergedTrack.activity.startDate)")
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
    
    private class func sameActivityTracks(track track1: Track, toTrack track2: Track) -> Bool {
        let stationary = track1.activity.stationary == track2.activity.stationary
        let walking = track1.activity.walking == track2.activity.walking
        let cycling = track1.activity.cycling == track2.activity.cycling
        let running = track1.activity.running == track2.activity.running
        let automotive = track1.activity.automotive == track2.activity.automotive
        return stationary && walking && cycling && running && automotive
    }
    
    private class func moving(track: Track) -> Bool {
        let stationary = track.activity.stationary
        let walking = track.activity.walking
        let cycling = track.activity.cycling
        let running = track.activity.running
        let automotive = track.activity.automotive
        let movingType = walking && cycling && running && automotive
        return !stationary && movingType
    }
    
    private class func mergeTrack(track1: Track, toTrack track2: Track, forceBike: Bool = false) -> Track {
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
