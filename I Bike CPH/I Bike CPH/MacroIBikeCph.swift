//
//  MacroIBikeCph.swift
//  I Bike CPH
//
//  Created by Tobias Due Munk on 06/02/15.
//  Copyright (c) 2015 I Bike CPH. All rights reserved.
//

import Foundation

@objc class Macro: MacroProtocol {

    class func isCykelPlanen() -> Bool {
        return false
    }
    class func isIBikeCph() -> Bool {
        return true
    }
}