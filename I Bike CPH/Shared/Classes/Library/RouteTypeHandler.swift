//
//  RouteTypeHandler.swift
//  I Bike CPH
//
//  Created by Tobias Due Munk on 08/01/15.
//  Copyright (c) 2015 I Bike CPH. All rights reserved.
//

import UIKit

let routeTypeHandler = RouteTypeHandler()

@objc class RouteTypeHandler: NSObject {
    
    var type: RouteType = .Regular {
        didSet {
            delegate?.routeTypeHandlerChanged(type)
            delegateObjc?.routeTypeHandlerChanged(server)
        }
    }
    @objc var server: String {
        get {
            let settings = SMRouteSettings.sharedInstance()
            switch type {
                case .Regular: return settings.osrm_server
                case .Cargo: return settings.osrm_server_cargo
            }
        }
    }

    var delegate: RouteTypeHandlerDelegate?
    var delegateObjc: RouteTypeHandlerDelegateObjc?
    
    class func sharedInstance() -> RouteTypeHandler {
        return routeTypeHandler
    }
    
    @objc func setTypeRegular() {
        type = .Regular
    }
    @objc func setTypeCargo() {
        type = .Cargo
    }
}

protocol RouteTypeHandlerDelegate {
    
    func routeTypeHandlerChanged(toType: RouteType)
}

@objc protocol RouteTypeHandlerDelegateObjc {
    
    func routeTypeHandlerChanged(toServer: String)
}
