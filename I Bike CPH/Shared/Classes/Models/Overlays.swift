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
            case .CycleSuperHighways: return SMTranslation.decodeString("cycle_super_highways")
            case .BikeServiceStations: return SMTranslation.decodeString("service_stations")
            case .STrainStations: return SMTranslation.decodeString("s_train_stations")
            case .MetroStations: return SMTranslation.decodeString("metro_stations")
            case .LocalTrainStation: return SMTranslation.decodeString("local_trains_stations")
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
