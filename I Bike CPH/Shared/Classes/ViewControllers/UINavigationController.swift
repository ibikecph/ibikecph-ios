//
//  UINavigationController.swift
//  I Bike CPH
//
//  Created by Tobias Due Munk on 03/12/14.
//  Copyright (c) 2014 I Bike CPH. All rights reserved.
//

import UIKit

extension UINavigationController {

    open override var childViewControllerForStatusBarStyle : UIViewController? {
        return self.topViewController
    }
    
    open override var childViewControllerForStatusBarHidden : UIViewController? {
        return self.topViewController
    }

}

extension UIViewController {
    
    func dismiss() {
        // Check if view controller is on a navigation stack
        if let navigation = parent as? UINavigationController {
            // Check if view controller isn't the top vc in the stack
            if let vc: UIViewController = navigation.viewControllers.first, vc != self {
                navigation.popViewController(animated: true)
                return
            }
        }
        // Default
        self.dismiss(animated: true, completion: nil)
    }
}
