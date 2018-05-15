//
//  HourMinuteFormatter.swift
//  I Bike CPH
//
//  Created by Tobias Due Munk on 08/05/15.
//  Copyright (c) 2015 I Bike CPH. All rights reserved.
//

import UIKit

class HourMinuteFormatter {
   
    fileprivate let calendar = Calendar.current
    fileprivate let unitFlags: NSCalendar.Unit = [.hour, .minute]
    
    fileprivate func hoursAndMinutes(_ seconds: TimeInterval) -> (hour: Int, minutes: Int) {
        let rounded = round(seconds/60)*60 // Round to minutes
        let components = (calendar as NSCalendar).components(unitFlags, from: Date(), to: Date(timeIntervalSinceNow: rounded), options: NSCalendar.Options(rawValue: 0))
        let hours = components.hour
        let minutes = components.minute
        return (hours!, minutes!)
    }
    
    func string(_ seconds: TimeInterval) -> String {
        let (hours, minutes) = hoursAndMinutes(seconds)
        let description = String(format: "hour_minute_format".localized, hours, minutes)
        return description
    }
}
