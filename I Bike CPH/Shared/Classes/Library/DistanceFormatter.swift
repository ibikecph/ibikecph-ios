//
//  DistanceFormatter.swift
//  I Bike CPH
//
//  Created by Tobias Due Munk on 04/06/15.
//  Copyright (c) 2015 I Bike CPH. All rights reserved.
//

import UIKit

class DistanceFormatter: NSNumberFormatter {
   
    private lazy var numberFormatter: NSNumberFormatter = {
        let formatter = NSNumberFormatter()
        formatter.maximumFractionDigits = 1
        formatter.minimumFractionDigits = 1
        formatter.alwaysShowsDecimalSeparator = true
        formatter.minimumIntegerDigits = 1 // "0.0" instead of ".0"
        return formatter
    }()
    
    func string(#meters: Double) -> String {
        return (numberFormatter.stringFromNumber(meters / 1000) ?? "0") + " " + "unit_km".localized
    }
}
