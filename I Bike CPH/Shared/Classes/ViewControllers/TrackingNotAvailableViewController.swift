//
//  TrackingNotAvailableViewController.swift
//  I Bike CPH
//
//  Created by Tobias Due Munk on 23/02/15.
//  Copyright (c) 2015 I Bike CPH. All rights reserved.
//

import UIKit

class TrackingNotAvailableViewController: SMTranslatedViewController {
    
    override var preferredStatusBarStyle : UIStatusBarStyle {
        return .lightContent
    }
    
    @IBAction func cancelButtonTapped(_ sender: UIBarButtonItem) {
        dismiss()
    }
}
