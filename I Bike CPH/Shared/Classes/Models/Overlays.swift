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
    
    var localizedDescription: String {
        switch self {
            case .CycleSuperHighways: return "cycle_super_highways".localized
            case .BikeServiceStations: return "service_stations".localized
        }
    }
}
