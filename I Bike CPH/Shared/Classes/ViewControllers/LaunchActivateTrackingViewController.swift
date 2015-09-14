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
    private let toAddTrackTokenControllerSegue = "activateTrackingToAddTrackToken"
    @IBOutlet weak var activateButton: UIButton!

    @IBAction func didTapActivateButton(sender: AnyObject) {
        switch UserHelper.checkEnableTracking() {
        case .NotLoggedIn:
            performSegueWithIdentifier(toLoginNavigationControllerSegue, sender: self)
        case .Allowed:
            Settings.instance.tracking.on = true
            dismiss()
        case .LacksTrackToken:
            // User is logged in but doesn't have a trackToken
            performSegueWithIdentifier(toAddTrackTokenControllerSegue, sender: self)
            return
        }
    }
    
    @IBAction func didTapCancelButton(sender: AnyObject) {
        dismiss()
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
