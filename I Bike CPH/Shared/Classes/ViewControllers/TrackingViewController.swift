//
//  TrackingViewController.swift
//  I Bike CPH
//
//  Created by Tobias Due Munk on 17/02/15.
//  Copyright (c) 2015 I Bike CPH. All rights reserved.
//

import UIKit

class TrackingViewController: SMTranslatedViewController {

    @IBOutlet weak var value1Label: UILabel!
    
    private var token: RLMNotificationToken?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = SMTranslation.decodeString("tracking")
        
        token = RLMRealm.addNotificationBlock() { [unowned self] note, realm in
            self.view.setNeedsLayout()
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        self.updateUI()
    }
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return .LightContent
    }
    
    func updateUI() {
        
        let tracks = Track.allObjects()
        let length = round(tracks.sumOfProperty("length").doubleValue)
        value1Label.text = "\(length) m"
    }
}
