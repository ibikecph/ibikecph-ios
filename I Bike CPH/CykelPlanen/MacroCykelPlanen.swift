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
    var initialMapCoordinate = CLLocationCoordinate2DMake(55.740, 12.424)
    var initialMapZoom: Double = 9.8
}
