//
//  Macro.swift
//  I Bike CPH
//
//  Created by Tobias Due Munk on 06/02/15.
//  Copyright (c) 2015 I Bike CPH. All rights reserved.
//

import Foundation
import CoreLocation

let macro = Macro()
@objc protocol MacroProtocol {

    var isCykelPlanen: Bool {get}
    var isIBikeCph: Bool {get}
    var initialMapCoordinate: CLLocationCoordinate2D {get}
    var initialMapZoom: Double {get}
}

