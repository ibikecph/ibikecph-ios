//
//  MainMapViewController.swift
//  I Bike CPH
//
//  Created by Tobias Due Munk on 04/06/15.
//  Copyright (c) 2015 I Bike CPH. All rights reserved.
//

import UIKit

class MainMapViewController: MapViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Follow user if possible
        mapView.mapView.userTrackingMode = .Follow
    }

    @IBAction func openMenu(sender: AnyObject) {
        NotificationCenter.post("openMenu")
    }
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return .LightContent
    }
}


