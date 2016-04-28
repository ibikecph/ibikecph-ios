//
//  HourMinuteFormatter.swift
//  I Bike CPH
//
//  Created by Tobias Due Munk on 08/05/15.
//  Copyright (c) 2015 I Bike CPH. All rights reserved.
//

import UIKit

class HourMinuteFormatter {
   
    private let calendar = NSCalendar.currentCalendar()
    private let unitFlags: NSCalendarUnit = .CalendarUnitHour | .CalendarUnitMinute
    
    private func hoursAndMinutes(seconds: NSTimeInterval) -> (hour: Int, minutes: Int) {
        let rounded = round(seconds/60)*60 // Round to minutes
        let components = calendar.components(unitFlags, fromDate: NSDate(), toDate: NSDate(timeIntervalSinceNow: rounded), options: nil)
        let hours = components.hour
        let minutes = components.minute
        return (hours, minutes)
    }
    
    func string(seconds: NSTimeInterval) -> String {
        let (hours, minutes) = hoursAndMinutes(seconds: seconds)
        let description = String(format: "hour_minute_format".localized, hours, minutes)
        return description
    }
}
