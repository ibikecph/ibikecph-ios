//
//  MenuNavigationViewController.swift
//  I Bike CPH
//
//  Created by Tobias Due Munk on 21/05/15.
//  Copyright (c) 2015 I Bike CPH. All rights reserved.
//

import UIKit

class NavigationWithSideMenuViewController: UINavigationController {

    var sideMenu: ENSideMenu?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let menuNavigationViewController = storyboard?.instantiateViewControllerWithIdentifier("MenuNavigationViewController") as? UIViewController {
            sideMenu = ENSideMenu(sourceViewController: self, menuViewController: menuNavigationViewController, menuPosition:.Left)
        }
        
        NotificationCenter.observe("openMenu") { [unowned self] notification in
            self.sideMenu?.showSideMenu()
        }
        NotificationCenter.observe("closeMenu") { [unowned self] notification in
            self.sideMenu?.hideSideMenu()
        }
    }
}