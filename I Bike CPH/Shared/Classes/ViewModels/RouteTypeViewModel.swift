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
        switch self.type {
            case .Disabled: return nil
            case .Fast: return UIImage(named:"Fast")
            case .Cargo: return UIImage(named:"Cargo")
            case .Green: return UIImage(named:"Green")
            case .Broken: return UIImage(named:"BrokenRoute")
        }
    }
    let type: RouteType
    var selected: Bool {
        get {
            return (type == .Disabled) ? false : type == RouteTypeHandler.instance.type
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
