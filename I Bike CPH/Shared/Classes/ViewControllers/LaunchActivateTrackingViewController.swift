//
//  LaunchActivateTrackingViewController.swift
//  I Bike CPH
//
//  Created by Tobias Due Munk on 07/08/15.
//  Copyright (c) 2015 I Bike CPH. All rights reserved.
//

import UIKit

class LaunchActivateTrackingViewController: SMTranslatedViewController {
    
    private let toLoginNavigationControllerSegue = "activateTrackingToLogin"
    @IBOutlet weak var activateButton: UIButton!

    @IBAction func didTapActivateButton(sender: AnyObject) {
        if UserHelper.loggedIn() {
            Settings.instance.tracking.on = true
            dismiss()
        } else {
            performSegueWithIdentifier(toLoginNavigationControllerSegue, sender: self)
        }
    }
    
    @IBAction func didTapCancelButton(sender: AnyObject) {
        dismiss()
    }
    
    @IBAction func didTapReadMore(sender: AnyObject) {
        if let url = NSURL(string: "") {
            UIApplication.sharedApplication().openURL(url)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        updateActivateButton()
        // Register visit to this view
        Settings.instance.onboarding.didSeeActivateTracking = true
        // Hide navigationbar initially
        navigationController?.setNavigationBarHidden(true, animated: false)
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        updateActivateButton()
        // Hide navigationbar when appeared
        navigationController?.setNavigationBarHidden(true, animated: true)
    }
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return .LightContent
    }
    
    private func updateActivateButton() {
        let activateButtonTitle = (UserHelper.loggedIn() ? "enable" : "log_in").localized
        activateButton.setTitle(activateButtonTitle, forState: .Normal)
    }
}
