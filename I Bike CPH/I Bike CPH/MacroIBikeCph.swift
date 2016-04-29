//
//  MacroIBikeCph.swift
//  I Bike CPH
//
//  Created by Tobias Due Munk on 06/02/15.
//  Copyright (c) 2015 I Bike CPH. All rights reserved.
//

import Foundation

class Macro: NSObject, MacroProtocol {
    @objc var isCykelPlanen = false
    @objc var isIBikeCph = true
    @objc var initialMapCoordinate = CLLocationCoordinate2DMake(55.688, 12.559)
    @objc var initialMapZoom: Double = 11
}