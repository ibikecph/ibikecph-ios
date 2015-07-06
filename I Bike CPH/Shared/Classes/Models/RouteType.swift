//
//  RouteType.swift
//  I Bike CPH
//
//  Created by Tobias Due Munk on 08/01/15.
//  Copyright (c) 2015 I Bike CPH. All rights reserved.
//

import Foundation

enum RouteType {
    case Regular
    case Cargo
    case Green
    case BrokenWithPublicTransport
    
    var localizedDescription: String {
        switch self {
            case .Regular: return "bike_type_1".localized
            case .Cargo: return "bike_type_2".localized
            case .Green: return "bike_type_3".localized
            case .BrokenWithPublicTransport: return "bike_type_4".localized // TODO: Fix strings
        }
    }
    
    static func validTypes() -> [RouteType] {
        if Macro.instance().isCykelPlanen {
            return [.Regular, .Green] // TODO: Add .BrokenWithPublicTransport]
        }
        return [.Regular, .Green, .Cargo]
    }
}
