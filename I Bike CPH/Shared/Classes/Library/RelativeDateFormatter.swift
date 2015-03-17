//
//  RelativeDateFormatter.swift
//  I Bike CPH
//
//  Created by Tobias Due Munk on 17/03/15.
//  Copyright (c) 2015 I Bike CPH. All rights reserved.
//

import UIKit

/**
Relative dates like 'yesterday', '

*/
class RelativeDateFormatter: NSDateFormatter {
   
    /**

    Default to add days like "Monday, " before i.e. "Jan 2, 2001"
    */
    lazy var beforeFallback: NSDateFormatter? = {
        let formatter = NSDateFormatter()
        formatter.dateFormat = "EEEE, "
        return formatter
    }()
    
    override func stringFromDate(date: NSDate) -> String {
        switch date.relativeDay() {
            case .Yesterday: return "yesterday".localized.capitalizedString
            case .Today: return "today".localized.capitalizedString
            case .Tomorrow: return "tomorrow".localized.capitalizedString
            default:
                let fallback = super.stringFromDate(date)
                if let beforeFallback = beforeFallback {
                    return beforeFallback.stringFromDate(date) + fallback
                }
                return fallback
        }
    }
}
