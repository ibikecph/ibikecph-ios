//
//  Macro.swift
//  I Bike CPH
//
//  Created by Tobias Due Munk on 06/02/15.
//  Copyright (c) 2015 I Bike CPH. All rights reserved.
//

import Foundation
import CoreLocation

@objc protocol MacroProtocol {

    var isCykelPlanen: Bool {get}
    var isIBikeCph: Bool {get}
    var initialMapCoordinate: CLLocationCoordinate2D {get}
    var initialMapZoom: Double {get}
}

// To access using Swift just use `macro`
let macro = Macro()

// To access using Objective-C use [Macro sharedInstance]
extension Macro {
    class func sharedInstance() -> Macro {
        return macro
    }
}

