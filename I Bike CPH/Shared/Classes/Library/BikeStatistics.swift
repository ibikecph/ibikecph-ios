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
    
    
    private class func tracksForDayOfDate(date: NSDate) -> RLMResults? {
        if let timestampDayStart = date.beginningOfDay()?.timeIntervalSince1970 {
            if let timestampDayEnd = date.endOfDay()?.timeIntervalSince1970 {
                // Start time or end time should be within day
                return tracks().objectsWhere("startTimestamp BETWEEN %@ OR endTimestamp BETWEEN %@", [timestampDayStart, timestampDayEnd], [timestampDayEnd, timestampDayEnd])
            }
        }
        return nil
    }
}

extension NSDate {
    
    func beginningOfDay() -> NSDate? {
        let calendar = NSCalendar.currentCalendar()
        let unitFlags: NSCalendarUnit = .MonthCalendarUnit | .YearCalendarUnit | .DayCalendarUnit | .HourCalendarUnit | .MinuteCalendarUnit | .SecondCalendarUnit
        let components = calendar.components(unitFlags, fromDate: self)
        components.hour = 0
        components.minute = 0
        components.second = 0
        return calendar.dateFromComponents(components)
    }
    
    func endOfDay() -> NSDate? {
        let calendar = NSCalendar.currentCalendar()
        let unitFlags: NSCalendarUnit = .MonthCalendarUnit | .YearCalendarUnit | .DayCalendarUnit | .HourCalendarUnit | .MinuteCalendarUnit | .SecondCalendarUnit
        let components = calendar.components(unitFlags, fromDate: self)
        components.hour = 23
        components.minute = 59
        components.second = 59
        return calendar.dateFromComponents(components)
    }
}
