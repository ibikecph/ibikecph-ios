//
//  RouteTypeHandler.swift
//  I Bike CPH
//
//  Created by Tobias Due Munk on 08/01/15.
//  Copyright (c) 2015 I Bike CPH. All rights reserved.
//

import UIKit

@objc class RouteTypeHandler: NSObject {
    
    var currentType: RouteType = .Regular
}

@objc protocol RouteTypeHandlerDelegate {
    
    @objc func routeTypeHandler() {
    
    }
}
