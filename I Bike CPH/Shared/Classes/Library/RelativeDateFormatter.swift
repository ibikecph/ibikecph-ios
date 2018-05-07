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
class RelativeDateFormatter: DateFormatter {
   
    /**

    Default to add days like "Monday, " before i.e. "Jan 2, 2001"
    */
    lazy var beforeFallback: DateFormatter? = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, "
        return formatter
    }()
    
    override func string(from date: Date) -> String {
        switch date.relativeDay() {
            case .yesterday: return "Yesterday".localized
            case .today: return "Today".localized
            case .tomorrow: return "Tomorrow".localized
            default:
                let fallback = super.string(from: date)
                if let beforeFallback = beforeFallback {
                    return beforeFallback.string(from: date) + fallback
                }
                return fallback
        }
    }
}
