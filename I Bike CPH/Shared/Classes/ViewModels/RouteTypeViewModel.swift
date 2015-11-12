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
                case .Regular: return "Fast"
                case .Cargo: return "Cargo"
                case .Green: return "Green"
                case .Broken: return "BrokenRoute"
            }
        }()
        return UIImage(named: name)
    }
    let type: RouteType
    var selected: Bool {
        get {
            return type == RouteTypeHandler.instance.type
        }
        set {
            if newValue {
                RouteTypeHandler.instance.type = type
            }
        }
    }
    
    init(type: RouteType) {
        self.type = type
    }
}
