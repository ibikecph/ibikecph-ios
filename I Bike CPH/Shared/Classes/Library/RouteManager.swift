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
    func didGetResultForRoute(result: RouteManager.Result)
}

class RouteManager: NSObject {
    
    var delegate: RouteManagerDelegate?
    
    enum Result {
        case Success(json: JSON, osrmServer: String)
        case ErrorOfType(Type)
        case Error(NSError)
        
        enum Type {
            case MissingCoordinates
            case RouteNotFound
            case ServerNotReachable
            case WrongJsonFormat
        }
    }
    
    
    func findRoute(from: SearchListItem, to: SearchListItem, server osrmServer: String) {
        
        if let
            fromCoordinate = from.location?.coordinate,
            toCoordinate = to.location?.coordinate
        {
            let requestOSRM = SMRequestOSRM(delegate: self)
            requestOSRM.auxParam = "startRoute"
            requestOSRM.osrmServer = osrmServer
            requestOSRM.getRouteFrom(fromCoordinate, to: toCoordinate, via: nil)
            return
        }
        delegate?.didGetResultForRoute(.ErrorOfType(.MissingCoordinates))
    }
}


extension RouteManager: SMRequestOSRMDelegate {
    
    func request(req: SMRequestOSRM!, failedWithError error: NSError!) {
        delegate?.didGetResultForRoute(.Error(error))
    }
    
    func request(req: SMRequestOSRM!, finishedWithResult res: AnyObject!) {
        
        let isBrokenJourney = SMRouteSettings.sharedInstance().broken_journey_server == req.osrmServer
        
        let json = JSON(data: req.responseData)
        // TODO: Get this status code thing sorted
        if let status = json["status"].int where (status != 200 && status != 0) {
            delegate?.didGetResultForRoute(.ErrorOfType(.RouteNotFound))
            return
        }
        if let errorString = json["error"].string {
            let error = NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: errorString])
            delegate?.didGetResultForRoute(.Error(error))
            return
        }
        delegate?.didGetResultForRoute(.Success(json: json, osrmServer: req.osrmServer))
    }
    
    func serverNotReachable() {
        delegate?.didGetResultForRoute(.ErrorOfType(.ServerNotReachable))
    }
}
