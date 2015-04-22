//
//  Overlays.swift
//  I Bike CPH
//
//  Created by Tobias Due Munk on 08/01/15.
//  Copyright (c) 2015 I Bike CPH. All rights reserved.
//

import Foundation

enum OverlayType {
    case CycleSuperHighways
    case BikeServiceStations
    case STrainStations
    case MetroStations
    case LocalTrainStation
    
    var localizedDescription: String {
        switch self {
            case .CycleSuperHighways: return "cycle_super_highways".localized
            case .BikeServiceStations: return "service_stations".localized
            case .STrainStations: return "s_train_stations".localized
            case .MetroStations: return "metro_stations".localized
            case .LocalTrainStation: return "local_trains_stations".localized
        }
    }
    var key: String {
        switch self {
            case .CycleSuperHighways: return "path"
            case .BikeServiceStations: return "service"
            case .STrainStations: return "station"
            case .MetroStations: return "metro"
            case .LocalTrainStation: return "local-trains"
        }
    }
}
