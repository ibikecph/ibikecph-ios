//
//  RouteManager.swift
//  I Bike CPH
//
//  Created by Tobias Due Munk on 19/06/15.
//  Copyright (c) 2015 I Bike CPH. All rights reserved.
//

import UIKit
import SwiftyJSON

struct Route {
    
}

protocol RouteManagerDelegate {
    func didGetResultForRoute(_ result: RouteManager.Result)
}

class RouteManager: NSObject {
    
    var delegate: RouteManagerDelegate?
    
    enum Result {
        case success(json: JSON, osrmServer: String)
        case errorOfType(ErrorType)
        case error(NSError)
        
        enum ErrorType {
            case missingCoordinates
            case routeNotFound
            case serverNotReachable
            case wrongJsonFormat
        }
    }
    
    
    func findRoute(_ from: SearchListItem, to: SearchListItem, server osrmServer: String) -> SMRequestOSRM? {
        
        if let
            fromCoordinate = from.location?.coordinate,
            let toCoordinate = to.location?.coordinate
        {
            let requestOSRM = SMRequestOSRM(delegate: self)
            requestOSRM?.auxParam = "startRoute"
            requestOSRM?.osrmServer = osrmServer
            requestOSRM?.getRouteFrom(fromCoordinate, to: toCoordinate, via: nil)
            return requestOSRM
        }
        delegate?.didGetResultForRoute(.errorOfType(.missingCoordinates))
        return nil
    }
}


extension RouteManager: SMRequestOSRMDelegate {
    
    func request(_ req: SMRequestOSRM!, failedWithError error: NSError!) {
        delegate?.didGetResultForRoute(.error(error))
    }
    
    func request(_ req: SMRequestOSRM!, finishedWithResult res: AnyObject!) {
        
        let json = JSON(data: req.responseData)
        // TODO: Get this status code thing sorted
        if let status = json["status"].int, (status != 200 && status != 0) {
            delegate?.didGetResultForRoute(.errorOfType(.routeNotFound))
            return
        }
        if let errorString = json["error"].string {
            let error = NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: errorString])
            delegate?.didGetResultForRoute(.error(error))
            return
        }
        delegate?.didGetResultForRoute(.success(json: json, osrmServer: req.osrmServer))
    }
    
    func serverNotReachable() {
        delegate?.didGetResultForRoute(.errorOfType(.serverNotReachable))
    }
}
