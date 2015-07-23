//
//  SplashViewController.swift
//  I Bike CPH
//
//  Created by Tobias Due Munk on 22/07/15.
//  Copyright (c) 2015 I Bike CPH. All rights reserved.
//

import UIKit

class SplashViewController: SMTranslatedViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        appDelegate.loadSettings()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        if !UserHelper.loggedIn() {
            // If user isn't logged in, keep them on the splash screen
            return
        }
        // User is logged in, go to main screen
        goToMain()
    }
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return .LightContent
    }
    
    func goToMain() {
        performSegueWithIdentifier("splashToMain", sender: self)
    }
}
