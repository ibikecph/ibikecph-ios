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
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        sideMenu?.menuViewController.beginAppearanceTransition(true, animated: animated)
        mainViewController?.beginAppearanceTransition(true, animated: animated)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if sideMenu != nil {
            return
        }
        
        if let mainViewController = storyboard?.instantiateViewController(withIdentifier: "MainNavigationViewController") {
            self.mainViewController = mainViewController
            
            addChildViewController(mainViewController)
            view.addSubview(mainViewController.view)
            mainViewController.didMove(toParentViewController: self)
            
            let mainView = mainViewController.view
            mainView?.translatesAutoresizingMaskIntoConstraints = false
            view.addConstraint(NSLayoutConstraint(item: mainView!, attribute: .left, relatedBy: .equal, toItem: view, attribute: .left, multiplier: 1, constant: 0))
            view.addConstraint(NSLayoutConstraint(item: mainView!, attribute: .right, relatedBy: .equal, toItem: view, attribute: .right, multiplier: 1, constant: 0))
            view.addConstraint(NSLayoutConstraint(item: mainView!, attribute: .bottom, relatedBy: .equal, toItem: view, attribute: .bottom, multiplier: 1, constant: 0))
            view.addConstraint(NSLayoutConstraint(item: mainView!, attribute: .top, relatedBy: .equal, toItem: view, attribute: .top, multiplier: 1, constant: 0))
        }

        if let menuNavigationViewController = storyboard?.instantiateViewController(withIdentifier: "MenuNavigationViewController") {
            menuNavigationViewController.beginAppearanceTransition(true, animated: false)
            sideMenu = ENSideMenu(sourceViewController: self, menuViewController: menuNavigationViewController, menuPosition: .left)
            sideMenu?.delegate = self
            menuNavigationViewController.endAppearanceTransition()
            
            _ = NotificationCenter.observe("openMenu") { [weak self] notification in
                self?.sideMenu?.showSideMenu()
            }
            _ = NotificationCenter.observe("closeMenu") { [weak self] notification in
                self?.sideMenu?.hideSideMenu()
            }
        }
        
        setNeedsStatusBarAppearanceUpdate()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillAppear(animated)
        sideMenu?.menuViewController.beginAppearanceTransition(false, animated: animated)
        mainViewController?.beginAppearanceTransition(false, animated: animated)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidAppear(animated)
        sideMenu?.menuViewController.endAppearanceTransition()
        mainViewController?.endAppearanceTransition()
    }
    
    override var childViewControllerForStatusBarStyle : UIViewController? {
        if let isMenuOpen = sideMenu?.isMenuOpen, isMenuOpen == true {
            return sideMenu?.menuViewController
        }
        return mainViewController
    }
    
    override var preferredStatusBarStyle : UIStatusBarStyle {
        return .lightContent
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
