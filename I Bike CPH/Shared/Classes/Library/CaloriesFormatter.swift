//
//  CaloriesFormatter.swift
//  I Bike CPH
//
//  Created by Tobias Due Munk on 31/07/15.
//  Copyright (c) 2015 I Bike CPH. All rights reserved.
//

import Foundation

class CaloriesFormatter: NSNumberFormatter {
    
    private lazy var numberFormatter: NSNumberFormatter = {
        let formatter = NSNumberFormatter()
        formatter.maximumFractionDigits = 0
        return formatter
    }()
    
    func string(kiloCalories: Double) -> String {
        return (numberFormatter.stringFromNumber(kiloCalories) ?? "0") + " " + "unit_kcal".localized
    }
}