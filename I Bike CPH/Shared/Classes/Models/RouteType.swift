//
//  RouteType.swift
//  I Bike CPH
//
//  Created by Tobias Due Munk on 08/01/15.
//  Copyright (c) 2015 I Bike CPH. All rights reserved.
//

import Foundation

enum RouteType {
    case disabled
    case fast
    case cargo
    case green
    case broken
    
    var localizedDescription: String {
        switch self {
            case .disabled: return ""
            case .fast: return "bike_type_1".localized
            case .cargo: return "bike_type_2".localized
            case .green: return "bike_type_3".localized
            case .broken: return "bike_type_4".localized
        }
    }

    var server: String {
        get {
            let settings = SMRouteSettings.sharedInstance()
            switch self {
            case .disabled: return ""
            case .fast: return settings!.osrm_server
            case .cargo: return settings!.osrm_server_cargo
            case .green: return settings!.osrm_server_green
            case .broken: return settings!.broken_journey_server
            }
        }
    }

    static func validTypes() -> [RouteType] {
        if macro.isCykelPlanen {
            return [.fast, .green, .broken]
        }
        if macro.isIBikeCph {
            return [.fast, .cargo, .green]
        }
        return []
    }
    
    var estimatedAverageSpeed: CGFloat {
        get {
            var kmPerHour: CGFloat
            switch self {
                case .disabled: kmPerHour = 0
                case .fast: kmPerHour = 15
                case .cargo: kmPerHour = 10
                case .green: kmPerHour = 15
                case .broken: kmPerHour = 15
            }
            // return in m/s
            return kmPerHour / 3.6
        }
    }
    
    static func estimatedAverageSpeedForOSRMServer(_ osrmServer: String) -> CGFloat {
        switch osrmServer {
            case RouteType.disabled.server: return RouteType.disabled.estimatedAverageSpeed
            case RouteType.fast.server: return RouteType.fast.estimatedAverageSpeed
            case RouteType.cargo.server: return RouteType.cargo.estimatedAverageSpeed
            case RouteType.green.server: return RouteType.green.estimatedAverageSpeed
            case RouteType.broken.server: return RouteType.broken.estimatedAverageSpeed
            default: return 15
        }
    }
}
