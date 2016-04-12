//
//  TrackingPromptViewController.swift
//  I Bike CPH
//
//  Created by Tobias Due Munk on 17/02/15.
//  Copyright (c) 2015 I Bike CPH. All rights reserved.
//

import UIKit
import PSTAlertController

class TrackingPromptViewController: SMTranslatedViewController {
    
    private var pendingEnableTrackingFromTrackToken = false
    private var pendingEnableTrackingFromLogin = false
    private let toAddTrackTokenControllerSegue = "trackingPromptToAddTrackToken"
    private static let toLoginSegue = "trackingPromptToLogin"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "tracking".localized
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
       
        // Hide navigationbar when appeared
        navigationController?.setNavigationBarHidden(true, animated: true)
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        // Check if tracking should be enabled
        if (pendingEnableTrackingFromTrackToken || pendingEnableTrackingFromLogin) && UserHelper.checkEnableTracking() == .Allowed {
            Settings.sharedInstance.tracking.on = true
            pendingEnableTrackingFromLogin = false
            pendingEnableTrackingFromTrackToken = false
            dismiss()
        } else if pendingEnableTrackingFromLogin && UserHelper.checkEnableTracking() == .LacksTrackToken {
            pendingEnableTrackingFromLogin = false
            pendingEnableTrackingFromTrackToken = true
            performSegueWithIdentifier(toAddTrackTokenControllerSegue, sender: self)
        } else {
            pendingEnableTrackingFromLogin = false
            pendingEnableTrackingFromTrackToken = false
        }
    }
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return .LightContent
    }
    
    @IBAction func cancelButtonTapped(sender: UIButton) {
        dismiss()
    }
    
    @IBAction func EnableTrackingButtonTapped(sender: UIButton) {
        switch UserHelper.checkEnableTracking() {
        case .NotLoggedIn:
            let alertController = PSTAlertController(title: "", message: "log_in_to_track_prompt".localized, preferredStyle: .Alert)
            alertController.addCancelActionWithHandler(nil)
            let loginAction = PSTAlertAction(title: "log_in".localized) { [weak self] action in
                self?.pendingEnableTrackingFromLogin = true
                self?.performSegueWithIdentifier(TrackingPromptViewController.toLoginSegue, sender: self)
            }
            alertController.addAction(loginAction)
            alertController.showWithSender(self, controller: self, animated: true, completion: nil)
        case .Allowed:
            Settings.sharedInstance.tracking.on = true
            dismiss()
        case .LacksTrackToken:
            // User is logged in but doesn't have a trackToken
            pendingEnableTrackingFromTrackToken = true
            performSegueWithIdentifier(toAddTrackTokenControllerSegue, sender: self)
            return
        }
    }
}
