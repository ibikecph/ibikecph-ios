//
//  UINavigationController.swift
//  I Bike CPH
//
//  Created by Tobias Due Munk on 03/12/14.
//  Copyright (c) 2014 I Bike CPH. All rights reserved.
//

import UIKit

extension UINavigationController {

    public override func childViewControllerForStatusBarStyle() -> UIViewController? {
        return self.topViewController
    }
    
    public override func childViewControllerForStatusBarHidden() -> UIViewController? {
        return self.topViewController
    }

}

extension UIViewController {
    
    func dismiss() {
        if let navigation = parentViewController as? UINavigationController { // Check if view controller is on a navigation stack
            if navigation.viewControllers.first as UIViewController != self { // Check if view controller isn't the top vc in the stack
                navigation.popViewControllerAnimated(true)
                return
            }
        }
        // Default
        dismissViewControllerAnimated(true, completion: nil)
    }
}
