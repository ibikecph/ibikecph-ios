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
    :returns: True if any bike tracks exists
    */
    class func hasTrackedBikeData() -> Bool {
        return tracks().count > 0
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
        if let timestampDayStart = date.beginningOfDay()?.timeIntervalSince1970, timestampDayEnd = date.endOfDay()?.timeIntervalSince1970 {
            // Start time or end time should be within day
            return tracks().objectsWhere("startTimestamp BETWEEN %@ OR endTimestamp BETWEEN %@", [timestampDayStart, timestampDayEnd], [timestampDayEnd, timestampDayEnd])
        }
        return nil
    }
    
    /**
    Start date of first bike track

    :returns: The start date of the first bike track
    */
    class func firstTrackStartDate() -> NSDate? {
        let sortedTracks = tracks().sortedResultsUsingProperty("startTimestamp", ascending: true)
        let firstTrack = sortedTracks.firstObject() as? Track
        let startDate = firstTrack?.startDate()
        return startDate
    }
    
    /**
    End date of latest bike track
    
    :returns: The end date of the latest bike track
    */
    class func lastTrackEndDate() -> NSDate? {
        let startDate = (tracks().sortedResultsUsingProperty("startTimestamp", ascending: true).lastObject() as? Track)?.endDate()
        return startDate
    }
    
    private class func tracksThisWeek() -> RLMResults? {
        let now = NSDate()
        if let
            endOfToday = now.endOfDay(),
            nextSunday = now.nextWeekday(1, fromDate: endOfToday),
            thisMonday = NSCalendar.currentCalendar().dateByAddingUnit(.WeekOfYearCalendarUnit, value: -1, toDate: nextSunday, options: nil)
        {
            return tracks().objectsWhere("endTimestamp BETWEEN %@", [thisMonday.timeIntervalSince1970, nextSunday.timeIntervalSince1970])
        }
        return nil
    }
    
    /**
    Duration of bike tracks this week
    
    :returns: Total duration in seconds [s]
    */
    class func durationThisWeek() -> Double {
        return tracksThisWeek()?.sumOfProperty("duration")?.doubleValue ?? 0
    }
    
    /**
    Distance of bike tracks this week
    
    :returns: Total distance in meters [m]
    */
    class func distanceThisWeek() -> Double {
        return tracksThisWeek()?.sumOfProperty("length")?.doubleValue ?? 0
    }
}
