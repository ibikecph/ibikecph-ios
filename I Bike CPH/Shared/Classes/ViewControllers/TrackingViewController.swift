//
//  TrackingViewController.swift
//  I Bike CPH
//
//  Created by Tobias Due Munk on 17/02/15.
//  Copyright (c) 2015 I Bike CPH. All rights reserved.
//

import UIKit

class TrackingViewController: SMTranslatedViewController {

    @IBOutlet weak var distanceLabel: UILabel!
    @IBOutlet weak var speedLabel: UILabel!
    @IBOutlet weak var tripLabel: UILabel!
    @IBOutlet weak var timeLabel: UILabel!
    
    private var token: RLMNotificationToken?
    
    lazy var formatter: NSNumberFormatter = {
        let formatter = NSNumberFormatter()
        formatter.maximumFractionDigits = 1
        formatter.minimumFractionDigits = 1
        formatter.minimumIntegerDigits = 1 // "0.0" instead of ".0"
        return formatter
    }()
    
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
        
        let totalDistance = tracks.sumOfProperty("length").doubleValue / 1000
        distanceLabel.text = formatter.stringFromNumber(totalDistance)!
        
        let totalTime = tracks.sumOfProperty("duration").doubleValue / 3600
        timeLabel.text = formatter.stringFromNumber(totalTime)!
        
        let averageSpeed = totalDistance / totalTime
        speedLabel.text = formatter.stringFromNumber(averageSpeed)!
        
        let averageTripDistance = tracks.averageOfProperty("length").doubleValue
        tripLabel.text = formatter.stringFromNumber(averageTripDistance)!
    }
}
