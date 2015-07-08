//
//  RouteManager.swift
//  I Bike CPH
//
//  Created by Tobias Due Munk on 19/06/15.
//  Copyright (c) 2015 I Bike CPH. All rights reserved.
//

import UIKit

struct Route {
    
}

protocol RouteManagerDelegate {
    func didGetResultForRoute(result: RouteManager.Result)
}

class RouteManager: NSObject {
    
    var delegate: RouteManagerDelegate?
    
    enum Result {
        case Success(json: [String : AnyObject], osrmServer: String)
        case ErrorOfType(Type)
        case Error(NSError)
        
        enum Type {
            case MissingCoordinates
            case RouteNotFound
            case ServerNotReachable
            case WrongJsonFormat
        }
    }
    
    
    func findRoute(from: SearchListItem, to: SearchListItem) {
        
        if let
            fromCoordinate = from.location?.coordinate,
            toCoordinate = to.location?.coordinate
        {
            let requestOSRM = SMRequestOSRM(delegate: self)
            requestOSRM.auxParam = "startRoute"
            requestOSRM.osrmServer = RouteTypeHandler.instance.server
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
        
        let json = JSON(data: req.responseData)
        if let status = json["status"].int where status != 0 {
            delegate?.didGetResultForRoute(.ErrorOfType(.RouteNotFound))
            return
        }
        
        if
            json.type == .Dictionary,
            let jsonDictionary = json.object as? [String : AnyObject]
        {
            delegate?.didGetResultForRoute(.Success(json: jsonDictionary, osrmServer: req.osrmServer))
            return
        }
        delegate?.didGetResultForRoute(.ErrorOfType(.WrongJsonFormat))
    }
    
    func serverNotReachable() {
        delegate?.didGetResultForRoute(.ErrorOfType(.ServerNotReachable))
    }
}