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
    case HarborRing
    case GreenPaths
    
    var localizedDescription: String {
        switch self {
            case .CycleSuperHighways: return "cycle_super_highways".localized
            case .BikeServiceStations: return "service_stations".localized
            case .HarborRing: return "harbor_ring".localized
            case .GreenPaths: return "green_paths".localized
        }
    }
    
    var menuIcon: UIImage? {
        let name: String = {
            switch self {
                case .CycleSuperHighways: return "SuperCycleHighway"
                case .BikeServiceStations: return "serviceStation"
                case .HarborRing: return "serviceStation"
                case .GreenPaths: return "serviceStation"
            }
        }()
        return UIImage(named: name)
    }
}
