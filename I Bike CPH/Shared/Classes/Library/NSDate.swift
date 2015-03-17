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
    
    func relativeDay() -> Day {
        let calendar = NSCalendar.currentCalendar()
        let unitFlags: NSCalendarUnit = .DayCalendarUnit
        let components = calendar.components(unitFlags, fromDate: NSDate(), toDate: self, options: .allZeros)
        let days = components.day
        switch days {
            case -1: return .Yesterday
            case 0: return .Today
            case 1: return .Tomorrow
            default: return .Other(days)
        }
    }
}
