//
//  MacroCykelPlanen.swift
//  I Bike CPH
//
//  Created by Tobias Due Munk on 06/02/15.
//  Copyright (c) 2015 I Bike CPH. All rights reserved.
//

import Foundation

@objc class Macro: MacroProtocol {
    
    var isCykelPlanen = true
    var isIBikeCph = false
    var initialMapCoordinate = CLLocationCoordinate2DMake(55.678, 12.482)
    var initialMapZoom: Double = 9
}
