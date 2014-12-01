//
//  StyleIBikeCph.swift
//  I Bike CPH
//
//  Created by Tobias Due Munk on 30/11/14.
//  Copyright (c) 2014 I Bike CPH. All rights reserved.
//

import UIKit

@objc class Styler: StyleProtocol {
    
    class func backgroundColor() -> UIColor {
        return .whiteColor()
    }
    
    class func tintColor() -> UIColor {
        return UIColor.blueColor()
    }
    
    class func logo() -> UIImage? {
        return UIImage(named: "Logo")
    }
}