//
//  LaunchActivateTrackingViewController.swift
//  I Bike CPH
//
//  Created by Tobias Due Munk on 07/08/15.
//  Copyright (c) 2015 I Bike CPH. All rights reserved.
//

import UIKit

class LaunchActivateTrackingViewController: SMTranslatedViewController {
    
    fileprivate let toLoginNavigationControllerSegue = "activateTrackingToLogin"
    fileprivate let toAddTrackTokenControllerSegue = "activateTrackingToAddTrackToken"
    fileprivate var pendingEnableTrackingFromTrackToken = false
    @IBOutlet weak var activateButton: UIButton!

    @IBAction func didTapActivateButton(_ sender: AnyObject) {
        switch UserHelper.checkEnableTracking() {
        case .notLoggedIn:
            performSegue(withIdentifier: toLoginNavigationControllerSegue, sender: self)
        case .allowed:
            Settings.sharedInstance.tracking.on = true
            dismiss()
        case .lacksTrackToken:
            // User is logged in but doesn't have a trackToken
            pendingEnableTrackingFromTrackToken = true
            performSegue(withIdentifier: toAddTrackTokenControllerSegue, sender: self)
            return
        }
    }
    
    @IBAction func didTapCancelButton(_ sender: AnyObject) {
        dismiss()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        updateActivateButton()
        // Register visit to this view
        Settings.sharedInstance.turnstile.didSeeActivateTracking = true
        // Hide navigationbar initially
        navigationController?.setNavigationBarHidden(true, animated: false)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        updateActivateButton()
        // Hide navigationbar when appeared
        navigationController?.setNavigationBarHidden(true, animated: true)

        // Check if tracking should be enabled
        if pendingEnableTrackingFromTrackToken && UserHelper.checkEnableTracking() == .allowed {
            Settings.sharedInstance.tracking.on = true
            pendingEnableTrackingFromTrackToken = false
            dismiss()
        } else {
            pendingEnableTrackingFromTrackToken = false
        }
    }
    
    override var preferredStatusBarStyle : UIStatusBarStyle {
        return .lightContent
    }
    
    fileprivate func updateActivateButton() {
        let activateButtonTitle = (UserHelper.loggedIn() ? "enable" : "log_in").localized
        activateButton.setTitle(activateButtonTitle, for: UIControlState())
    }
}
