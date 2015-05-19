//
//  RouteTypeViewModel.swift
//  I Bike CPH
//
//  Created by Tobias Due Munk on 11/05/15.
//  Copyright (c) 2015 I Bike CPH. All rights reserved.
//

import UIKit

struct RouteTypeViewModel {
    var title: String {
        return self.type.localizedDescription
    }
    var iconImage: UIImage? {
        let name: String = {
            switch self.type {
            case .Regular: return "regularBike"
            case .Cargo: return "cargoBike"
            }
        }()
        return UIImage(named: name)
    }
    let type: RouteType
    var selected: Bool {
        get {
            return type == routeTypeHandler.type
        }
        set {
            if newValue {
                routeTypeHandler.type = type
            }
        }
    }
    
    init(type: RouteType) {
        self.type = type
    }
}
