//
//  MainWithSideMenuViewController.swift
//  I Bike CPH
//
//  Created by Tobias Due Munk on 21/05/15.
//  Copyright (c) 2015 I Bike CPH. All rights reserved.
//

import UIKit

class MainWithSideMenuViewController: UIViewController {

    var sideMenu: ENSideMenu?
    var mainViewController: UIViewController?
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        sideMenu?.menuViewController.beginAppearanceTransition(true, animated: animated)
        mainViewController?.beginAppearanceTransition(true, animated: animated)
    }

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        if sideMenu != nil {
            return
        }
        
        if let mainViewController = storyboard?.instantiateViewControllerWithIdentifier("MainNavigationViewController") {
            self.mainViewController = mainViewController
            
            addChildViewController(mainViewController)
            view.addSubview(mainViewController.view)
            mainViewController.didMoveToParentViewController(self)
            
            let mainView = mainViewController.view
            mainView.translatesAutoresizingMaskIntoConstraints = false
            view.addConstraint(NSLayoutConstraint(item: mainView, attribute: .Left, relatedBy: .Equal, toItem: view, attribute: .Left, multiplier: 1, constant: 0))
            view.addConstraint(NSLayoutConstraint(item: mainView, attribute: .Right, relatedBy: .Equal, toItem: view, attribute: .Right, multiplier: 1, constant: 0))
            view.addConstraint(NSLayoutConstraint(item: mainView, attribute: .Bottom, relatedBy: .Equal, toItem: view, attribute: .Bottom, multiplier: 1, constant: 0))
            view.addConstraint(NSLayoutConstraint(item: mainView, attribute: .Top, relatedBy: .Equal, toItem: view, attribute: .Top, multiplier: 1, constant: 0))
        }

        if let menuNavigationViewController = storyboard?.instantiateViewControllerWithIdentifier("MenuNavigationViewController") {
            menuNavigationViewController.beginAppearanceTransition(true, animated: false)
            sideMenu = ENSideMenu(sourceViewController: self, menuViewController: menuNavigationViewController, menuPosition: .Left)
            sideMenu?.delegate = self
            menuNavigationViewController.endAppearanceTransition()
            
            NotificationCenter.observe("openMenu") { [weak self] notification in
                self?.sideMenu?.showSideMenu()
            }
            NotificationCenter.observe("closeMenu") { [weak self] notification in
                self?.sideMenu?.hideSideMenu()
            }
        }
        
        setNeedsStatusBarAppearanceUpdate()
    }

    override func viewWillDisappear(animated: Bool) {
        super.viewWillAppear(animated)
        sideMenu?.menuViewController.beginAppearanceTransition(false, animated: animated)
        mainViewController?.beginAppearanceTransition(false, animated: animated)
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidAppear(animated)
        sideMenu?.menuViewController.endAppearanceTransition()
        mainViewController?.endAppearanceTransition()
    }
    
    override func childViewControllerForStatusBarStyle() -> UIViewController? {
        if let isMenuOpen = sideMenu?.isMenuOpen where isMenuOpen == true {
            return sideMenu?.menuViewController
        }
        return mainViewController
    }
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return .LightContent
    }
}

extension MainWithSideMenuViewController: ENSideMenuDelegate {
    
    func sideMenuWillOpen() {
        setNeedsStatusBarAppearanceUpdate()
    }
    
    func sideMenuWillClose() {
        setNeedsStatusBarAppearanceUpdate()
    }
}
