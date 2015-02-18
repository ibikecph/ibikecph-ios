//
//  TrackingPromptViewController.swift
//  I Bike CPH
//
//  Created by Tobias Due Munk on 17/02/15.
//  Copyright (c) 2015 I Bike CPH. All rights reserved.
//

import UIKit

class TrackingPromptViewController: SMTranslatedViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = SMTranslation.decodeString("tracking")
    }
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return .LightContent
    }
    
    @IBAction func cancelButtonTapped(sender: UIBarButtonItem) {
        dismiss()
    }
    @IBAction func EnableTrackingButtonTapped(sender: UIButton) {
        settings.tracking.on = true
        dismiss()
    }
}
