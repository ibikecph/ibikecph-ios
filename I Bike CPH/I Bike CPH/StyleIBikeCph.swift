//
//  StyleIBikeCph.swift
//  I Bike CPH
//
//  Created by Tobias Due Munk on 30/11/14.
//  Copyright (c) 2014 I Bike CPH. All rights reserved.
//

import UIKit

extension UIColor {
    
    class func red() -> UIColor {
        return UIColor(red: 255/255, green: 13/255, blue: 0/255, alpha: 1)
//        return UIColor(red: 208/255, green: 2/255, blue: 27/255, alpha: 1) // Color from Android version
//        return UIColor(red:0.93, green:0.18, blue:0.14, alpha:1) // Color from logo
    }
    class func blue() -> UIColor {
        return UIColor(red: 0/255, green: 174/255, blue: 255/255, alpha: 1)
    }
}

@objc class Styler: NSObject, StyleProtocol {
    
    @objc class func backgroundColor() -> UIColor {
        return .whiteColor()
    }
    
    @objc class func tintColor() -> UIColor {
        return .red()
    }
    
    @objc class func foregroundColor() -> UIColor {
        return .darkGrayColor()
    }

    @objc class func foregroundSecondaryColor() -> UIColor {
        return .lightGrayColor()
    }
    
    @objc class func navigationBarTintColor() -> UIColor {
        return .red()
    }
    
    @objc class func navigationBarContentTintColor() -> UIColor {
        return .whiteColor()
    }
    
    @objc class func logo() -> UIImage? {
        return UIImage(named: "Logo")
    }
}