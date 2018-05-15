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
    
    fileprivate var pendingEnableTrackingFromTrackToken = false
    fileprivate var pendingEnableTrackingFromLogin = false
    fileprivate let toAddTrackTokenControllerSegue = "trackingPromptToAddTrackToken"
    fileprivate static let toLoginSegue = "trackingPromptToLogin"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "tracking".localized
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
       
        // Hide navigationbar when appeared
        navigationController?.setNavigationBarHidden(true, animated: true)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // Check if tracking should be enabled
        if (pendingEnableTrackingFromTrackToken || pendingEnableTrackingFromLogin) && UserHelper.checkEnableTracking() == .allowed {
            Settings.sharedInstance.tracking.on = true
            pendingEnableTrackingFromLogin = false
            pendingEnableTrackingFromTrackToken = false
            dismiss()
        } else if pendingEnableTrackingFromLogin && UserHelper.checkEnableTracking() == .lacksTrackToken {
            pendingEnableTrackingFromLogin = false
            pendingEnableTrackingFromTrackToken = true
            performSegue(withIdentifier: toAddTrackTokenControllerSegue, sender: self)
        } else {
            pendingEnableTrackingFromLogin = false
            pendingEnableTrackingFromTrackToken = false
        }
    }
    
    override var preferredStatusBarStyle : UIStatusBarStyle {
        return .lightContent
    }
    
    @IBAction func cancelButtonTapped(_ sender: UIButton) {
        dismiss()
    }
    
    @IBAction func EnableTrackingButtonTapped(_ sender: UIButton) {
        switch UserHelper.checkEnableTracking() {
        case .notLoggedIn:
            let alertController = PSTAlertController(title: "", message: "log_in_to_track_prompt".localized, preferredStyle: .alert)
            alertController?.addCancelAction(handler: nil)
            let loginAction = PSTAlertAction(title: "log_in".localized) { [weak self] action in
                self?.pendingEnableTrackingFromLogin = true
                self?.performSegue(withIdentifier: TrackingPromptViewController.toLoginSegue, sender: self)
            }
            alertController?.addAction(loginAction)
            alertController?.showWithSender(self, controller: self, animated: true, completion: nil)
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
}
