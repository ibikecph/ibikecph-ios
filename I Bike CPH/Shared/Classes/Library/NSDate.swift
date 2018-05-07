//
//  NSDate.swift
//  I Bike CPH
//
//  Created by Tobias Due Munk on 17/03/15.
//  Copyright (c) 2015 I Bike CPH. All rights reserved.
//

import UIKit

public extension Date {
    
    func beginningOfDay() -> Date? {
        let calendar = Calendar.current
        let unitFlags: NSCalendar.Unit = [.hour, .year, .day, .hour, .minute, .second]
        var components = (calendar as NSCalendar).components(unitFlags, from: self)
        components.hour = 0
        components.minute = 0
        components.second = 0
        return calendar.date(from: components)
    }
    
    func endOfDay() -> Date? {
        let calendar = Calendar.current
        let unitFlags: NSCalendar.Unit = [.month, .year, .day, .hour, .minute, .second]
        var components = (calendar as NSCalendar).components(unitFlags, from: self)
        components.hour = 23
        components.minute = 59
        components.second = 59
        return calendar.date(from: components)
    }
    
    enum Day {
        case yesterday
        case today
        case tomorrow
        case other(Int)
    }
    
    func relativeDay(_ fromDate : Date) -> Int {
        let calendar = Calendar.current
        let unitFlags: NSCalendar.Unit = .day
        let fromDate = fromDate.withComponents(hour: 12, minute: 0, second: 0)!
        let toDate = self.withComponents(hour: 12, minute: 0, second: 0)!
        let components = (calendar as NSCalendar).components(unitFlags, from: fromDate, to: toDate, options: NSCalendar.Options(rawValue: 0))
        let days = components.day
        return days!
    }
    
    func relativeDay() -> Day {
        let days = relativeDay(Date())
        switch days {
            case -1: return .yesterday
            case 0: return .today
            case 1: return .tomorrow
            default: return .other(days)
        }
    }
    
    func laterOrEqualDay(thanDate date: Date) -> Bool {
        return relativeDay(date) >= 0
    }
    
    func nextWeekday(_ weekday: Int, fromDate: Date = Date()) -> Date? {
        let calendar = Calendar.current
        let unitFlags: NSCalendar.Unit = [.month, .year, .weekday, .day, .hour, .minute, .second]
        let components = (calendar as NSCalendar).components(unitFlags, from: fromDate)
        
        // Early on correct weekday, return fromDate
        if components.weekday == weekday && self.timeIntervalSince(fromDate) < 0 {
            return fromDate
        }
        // Go one week forward subtracting weekday offset
        let daysToNextWeekday = 7 + weekday - components.weekday!
        return (calendar as NSCalendar).date(byAdding: .day, value: daysToNextWeekday, to: fromDate, options: NSCalendar.Options(rawValue: 0))
    }
    
    func withComponents(_ year: Int? = nil, month: Int? = nil, weekday: Int? = nil, day: Int? = nil, hour: Int? = nil, minute: Int? = nil, second: Int? = nil ) -> Date? {
        let calendar = Calendar.current
        let unitFlags: NSCalendar.Unit = [.year, .month, .weekday, .day, .hour, .minute, .second]
        var components = (calendar as NSCalendar).components(unitFlags, from: self)
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
        return calendar.date(from: components)
    }
}
