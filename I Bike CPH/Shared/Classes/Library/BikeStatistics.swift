//
//  Statistics.swift
//  I Bike CPH
//
//  Created by Tobias Due Munk on 09/03/15.
//  Copyright (c) 2015 I Bike CPH. All rights reserved.
//

import UIKit

class BikeStatistics {
   
    /**
    :returns: All bike tracks as an RLMResults
    */
    class func tracks() -> RLMResults {
        return Track.objectsWhere("activity.cycling == TRUE")
    }
    
    /**
    Total distance of bike tracks
    
    :returns: Total distance in meters [m]
     */
    class func totalDistance() -> Double {
        return (tracks().sumOfProperty("length")?.doubleValue ?? 0)
    }
    
    /**
    Total duration of bike tracks
    
    :returns: Total duration in seconds [s]
    */
    class func totalDuration() -> Double {
        return (tracks().sumOfProperty("duration")?.doubleValue ?? 0)
    }
    
    /**
    Average speed of bike tracks
    
    :returns: Average speed in meter pr. second [m/s]
    */
    class func averageSpeed() -> Double {
        let duration = totalDuration()
        return duration == 0 ? 0 : totalDistance() / duration
    }
    
    /**
    Average distance of bike tracks
    
    :returns: Average track distance in meters [m]
    */
    class func averageTrackDistance() -> Double {
        return tracks().averageOfProperty("length")?.doubleValue ?? 0
    }
    
    /**
    Current day streak of bike tracks
    
    :returns: Day streak in days
    */
    class func currentDayStreak() -> Int {
        var date = NSDate()
        var streak = 0
        while tracksForDayOfDate(date)?.count > 0 {
            streak++
            date = date.dateByAddingTimeInterval(-60*60*24)
        }
        return streak
    }
    
    
    class func tracksForDayOfDate(date: NSDate) -> RLMResults? {
        if let timestampDayStart = date.beginningOfDay()?.timeIntervalSince1970 {
            if let timestampDayEnd = date.endOfDay()?.timeIntervalSince1970 {
                // Start time or end time should be within day
                return tracks().objectsWhere("startTimestamp BETWEEN %@ OR endTimestamp BETWEEN %@", [timestampDayStart, timestampDayEnd], [timestampDayEnd, timestampDayEnd])
            }
        }
        return nil
    }
    
    
    /**
    First day that has bike track

    :returns: The date of the first bike track
    */
    class func firstTrackDate() -> NSDate? {
        let startDate = (tracks().sortedResultsUsingProperty("startTimestamp", ascending: true).firstObject() as? Track)?.startDate
        return startDate
    }
}
