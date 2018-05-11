//
//  Statistics.swift
//  I Bike CPH
//
//  Created by Tobias Due Munk on 09/03/15.
//  Copyright (c) 2015 I Bike CPH. All rights reserved.
//

import UIKit
// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}

// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func > <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l > r
  default:
    return rhs < lhs
  }
}


class BikeStatistics {
   
    /**
    :returns: All bike tracks as an RLMResults
    */
    class func tracks() -> RLMResults<RLMObject> {
        return Track.objectsWhere("activity.cycling == TRUE AND startTimestamp != 0")
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
        return tracks().sum(ofProperty: "length").doubleValue ?? 0
    }
    
    /**
    Total duration of bike tracks
    
    :returns: Total duration in seconds [s]
    */
    class func totalDuration() -> Double {
        return tracks().sum(ofProperty: "duration").doubleValue ?? 0
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
        return tracks().average(ofProperty: "length")?.doubleValue ?? 0
    }
    
    /**
    Current day streak of bike tracks
    
    :returns: Day streak in days
    */
    class func currentDayStreak() -> Int {
        var date = Date()
        var streak = 0
        while tracksForDayOfDate(date)?.count > 0 {
            streak += 1
            date = date.addingTimeInterval(-60*60*24)
        }
        return streak
    }
    
    
    class func tracksForDayOfDate(_ date: Date) -> RLMResults<RLMObject>? {
        if let timestampDayStart = date.beginningOfDay()?.timeIntervalSince1970, let timestampDayEnd = date.endOfDay()?.timeIntervalSince1970 {
            // Start time or end time should be within day
            return tracks().objectsWhere("startTimestamp BETWEEN %@ OR endTimestamp BETWEEN %@", [timestampDayStart, timestampDayEnd], [timestampDayEnd, timestampDayEnd])
        }
        return nil
    }
    
    /**
    Start date of first bike track

    :returns: The start date of the first bike track
    */
    class func firstTrackStartDate() -> Date? {
        let sortedTracks = tracks().sortedResults(usingKeyPath: "startTimestamp", ascending: true)
        let firstTrack = sortedTracks.firstObject() as? Track
        let startDate = firstTrack?.startDate()
        return startDate
    }
    
    /**
    End date of latest bike track
    
    :returns: The end date of the latest bike track
    */
    class func lastTrackEndDate() -> Date? {
        let startDate = (tracks().sortedResults(usingKeyPath: "startTimestamp", ascending: true).lastObject() as? Track)?.endDate()
        return startDate
    }
    
    fileprivate class func tracksThisWeek() -> RLMResults<RLMObject>? {
        let now = Date()
        if let
            endOfToday = now.endOfDay(),
            let nextSunday = now.nextWeekday(1, fromDate: endOfToday),
            let thisMonday = (Calendar.current as NSCalendar).date(byAdding: .weekOfYear, value: -1, to: nextSunday, options: NSCalendar.Options(rawValue: 0))
        {
            return tracks().objectsWhere("endTimestamp BETWEEN %@", [thisMonday.timeIntervalSince1970, nextSunday.timeIntervalSince1970])
        }
        return nil
    }
    
    /**
    Duration of bike tracks this date
    
    :returns: Total duration in seconds [s]
    */
    class func durationThisDate(_ date: Date = Date()) -> Double {
        return tracksForDayOfDate(date)?.sum(ofProperty: "duration").doubleValue ?? 0
    }
    
    /**
    Distance of bike tracks this date
    
    :returns: Total distance in meters [m]
    */
    class func distanceThisDate(_ date: Date = Date()) -> Double {
        return tracksForDayOfDate(date)?.sum(ofProperty: "length").doubleValue ?? 0
    }
    
    /**
    Duration of bike tracks this week
    
    :returns: Total duration in seconds [s]
    */
    class func durationThisWeek() -> Double {
        return tracksThisWeek()?.sum(ofProperty: "duration").doubleValue ?? 0
    }
    
    /**
    Distance of bike tracks this week
    
    :returns: Total distance in meters [m]
    */
    class func distanceThisWeek() -> Double {
        return tracksThisWeek()?.sum(ofProperty: "length").doubleValue ?? 0
    }
    
    /**
    Calories for distance biked
    
    :param: distance Distance in meters [m]
    :returns: Calories [kcal]
    */
    class func kiloCaloriesPerBikedDistance(_ distance: Double) -> Double {
        let km = distance / 1000
        let calPerKm: Double = 11
        return calPerKm * km
    }
}
