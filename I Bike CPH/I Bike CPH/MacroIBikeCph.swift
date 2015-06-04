//
//  MacroIBikeCph.swift
//  I Bike CPH
//
//  Created by Tobias Due Munk on 06/02/15.
//  Copyright (c) 2015 I Bike CPH. All rights reserved.
//

import Foundation

@objc class Macro: MacroProtocol {
    
    var isCykelPlanen = false
    var isIBikeCph = true
    var initialMapCoordinate = CLLocationCoordinate2DMake(55.688, 12.559)
    var initialMapZoom: Double = 10
}