//
//  CaloriesFormatter.swift
//  I Bike CPH
//
//  Created by Tobias Due Munk on 31/07/15.
//  Copyright (c) 2015 I Bike CPH. All rights reserved.
//

import Foundation

class CaloriesFormatter: NumberFormatter {
    
    fileprivate lazy var numberFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.maximumFractionDigits = 0
        return formatter
    }()
    
    func string(_ kiloCalories: Double) -> String {
        return (numberFormatter.string(from: NSNumber(value: kiloCalories)) ?? "0") + " " + "unit_kcal".localized
    }
}
