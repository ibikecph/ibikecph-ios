//
//  StyleIBikeCph.swift
//  I Bike CPH
//
//  Created by Tobias Due Munk on 30/11/14.
//  Copyright (c) 2014 I Bike CPH. All rights reserved.
//

import UIKit

extension UIColor {
    
    class func red() {
        return UIColor(red: 255/255, green: 13/255, blue: 0/255, alpha: 1)
    }
    class func blue() {
        return UIColor(red: 0/255, green: 174/255, blue: 255/255, alpha: 1)
    }
}

@objc class Styler: StyleProtocol {
    
    class func backgroundColor() -> UIColor {
        return .whiteColor()
    }
    
    class func tintColor() -> UIColor {
        return .red()
    }
    
    class func foregroundColor() -> UIColor {
        return .darkGrayColor()
    }
    
    class func navigationBarTintColor() -> UIColor {
        return .red()
    }
    
    class func navigationBarContentTintColor() -> UIColor {
        return .whiteColor()
    }
    
    class func logo() -> UIImage? {
        return UIImage(named: "Logo")
    }
}