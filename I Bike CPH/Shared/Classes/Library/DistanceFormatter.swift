//
//  DistanceFormatter.swift
//  I Bike CPH
//
//  Created by Tobias Due Munk on 04/06/15.
//  Copyright (c) 2015 I Bike CPH. All rights reserved.
//

import UIKit

class DistanceFormatter: NumberFormatter {
   
    fileprivate lazy var numberFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.maximumFractionDigits = 1
        formatter.minimumFractionDigits = 1
        formatter.alwaysShowsDecimalSeparator = true
        formatter.minimumIntegerDigits = 1 // "0.0" instead of ".0"
        return formatter
    }()
    
    func string(_ meters: Double) -> String {
        let mm = meters / 1000
        return (numberFormatter.string(from: NSNumber(value: mm)) ?? "0") + " " + "unit_km".localized
    }
}
