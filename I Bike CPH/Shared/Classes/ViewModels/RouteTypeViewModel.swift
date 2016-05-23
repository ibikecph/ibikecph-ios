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
        let iconWidth: CGFloat = 25
        let iconColor = UIColor.grayColor()
        switch self.type {
            case .Disabled: return nil
            case .Fast: return poFastRouteImage(width: iconWidth, color: iconColor)?.imageWithRenderingMode(.AlwaysTemplate)
            case .Cargo: return poCargoRouteImage(width: iconWidth, color: iconColor)?.imageWithRenderingMode(.AlwaysTemplate)
            case .Green: return poGreenRouteImage(width: iconWidth, color: iconColor)?.imageWithRenderingMode(.AlwaysTemplate)
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
