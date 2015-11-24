//
//  Style.swift
//  I Bike CPH
//
//  Created by Tobias Due Munk on 30/11/14.
//  Copyright (c) 2014 I Bike CPH. All rights reserved.
//

import Foundation
import UIKit

@objc protocol StyleProtocol {
    
    static func setupAppearance()
    
    static func backgroundColor() -> UIColor
    static func tintColor() -> UIColor
    static func foregroundColor() -> UIColor
    static func foregroundSecondaryColor() -> UIColor
    static func navigationBarTintColor() -> UIColor
    static func navigationBarContentTintColor() -> UIColor

    static func logo() -> UIImage?
}

extension Styler {
    
    class func setupAppearance() {
        UINavigationBar.appearance().barTintColor = Styler.navigationBarTintColor()
        UINavigationBar.appearance().tintColor = Styler.navigationBarContentTintColor()
        UINavigationBar.appearance().titleTextAttributes = [NSForegroundColorAttributeName: Styler.navigationBarContentTintColor()]
        UIToolbar.appearance().barTintColor = Styler.navigationBarTintColor()
        UIToolbar.appearance().tintColor = Styler.navigationBarContentTintColor()
        UISwitch.appearance().tintColor = Styler.tintColor()
    }
}

class LogoImageView: UIImageView {
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    func setup() {
        image = Styler.logo()
    }
    
    override func prepareForInterfaceBuilder() {
        super.prepareForInterfaceBuilder()
        setup()
    }
}
