//
//  NSDate.swift
//  I Bike CPH
//
//  Created by Tobias Due Munk on 17/03/15.
//  Copyright (c) 2015 I Bike CPH. All rights reserved.
//

import UIKit

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
    
    enum Day {
        case Yesterday
        case Today
        case Tomorrow
        case Other(Int)
    }
    
    func relativeDay(#fromDate : NSDate) -> Int {
        let calendar = NSCalendar.currentCalendar()
        let unitFlags: NSCalendarUnit = .DayCalendarUnit
        let components = calendar.components(unitFlags, fromDate: fromDate, toDate: self, options: .allZeros)
        let days = components.day
        return days
    }
    
    func relativeDay() -> Day {
        let days = relativeDay(fromDate: NSDate())
        switch days {
            case -1: return .Yesterday
            case 0: return .Today
            case 1: return .Tomorrow
            default: return .Other(days)
        }
    }
    
    func laterOrEqualDay(thanDate date: NSDate) -> Bool {
        return relativeDay(fromDate: date) >= 0
    }
    
    class func nextWeekday(weekday: Int, fromDate: NSDate = NSDate()) -> NSDate? {
        let calendar = NSCalendar.currentCalendar()
        let unitFlags: NSCalendarUnit = .MonthCalendarUnit | .YearCalendarUnit | .WeekdayCalendarUnit | .DayCalendarUnit | .HourCalendarUnit | .MinuteCalendarUnit | .SecondCalendarUnit
        let components = calendar.components(unitFlags, fromDate: fromDate)
        
        // Early on correct weekday, return fromDate
        if components.weekday == weekday && fromDate.timeIntervalSinceNow < 0 {
            return fromDate
        }
        // Go one week forward subtracting weekday offset
        let daysToNextWeekday = 7 + weekday - components.weekday
        return calendar.dateByAddingUnit(.DayCalendarUnit, value: daysToNextWeekday, toDate: fromDate, options: nil)
    }
    
    func withComponents(year: Int? = nil, month: Int? = nil, weekday: Int? = nil, day: Int? = nil, hour: Int? = nil, minute: Int? = nil, second: Int? = nil ) -> NSDate? {
        let calendar = NSCalendar.currentCalendar()
        let unitFlags: NSCalendarUnit = .YearCalendarUnit | .MonthCalendarUnit | .WeekdayCalendarUnit | .DayCalendarUnit | .HourCalendarUnit | .MinuteCalendarUnit | .SecondCalendarUnit
        let components = calendar.components(unitFlags, fromDate: self)
        if let year = year {
            components.year = year
        }
        if let month = month {
            components.month = month
        }
        if let weekday = weekday {
            components.weekday = weekday
        }
        if let day = day {
            components.day = day
        }
        if let hour = hour {
            components.hour = hour
        }
        if let minute = minute {
            components.minute = minute
        }
        if let second = second {
            components.second = second
        }
        return calendar.dateFromComponents(components)
    }
}
