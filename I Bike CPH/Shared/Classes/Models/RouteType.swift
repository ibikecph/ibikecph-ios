//
//  RouteType.swift
//  I Bike CPH
//
//  Created by Tobias Due Munk on 08/01/15.
//  Copyright (c) 2015 I Bike CPH. All rights reserved.
//

import Foundation

enum RouteType {
    case Disabled
    case Fast
    case Cargo
    case Green
    case Broken
    
    var localizedDescription: String {
        switch self {
            case .Disabled: return ""
            case .Fast: return "bike_type_1".localized
            case .Cargo: return "bike_type_2".localized
            case .Green: return "bike_type_3".localized
            case .Broken: return "bike_type_4".localized
        }
    }

    var server: String {
        get {
            let settings = SMRouteSettings.sharedInstance()
            switch self {
            case .Disabled: return ""
            case .Fast: return settings.osrm_server
            case .Cargo: return settings.osrm_server_cargo
            case .Green: return settings.osrm_server_green
            case .Broken: return settings.broken_journey_server
            }
        }
    }

    static func validTypes() -> [RouteType] {
        if macro.isCykelPlanen {
            return [.Fast, .Green, .Broken]
        }
        if macro.isIBikeCph {
            return [.Fast, .Cargo, .Green]
        }
        return []
    }
}
