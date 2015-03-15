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
    @IBOutlet weak var sinceLabel: UILabel!
    
    private var token: RLMNotificationToken?
    
    lazy var numberFormatter: NSNumberFormatter = {
        let formatter = NSNumberFormatter()
        formatter.maximumFractionDigits = 1
        formatter.minimumFractionDigits = 1
        formatter.minimumIntegerDigits = 1 // "0.0" instead of ".0"
        return formatter
    }()
    
    lazy var dateFormatter: NSDateFormatter = {
        let formatter = NSDateFormatter()
        formatter.dateStyle = .LongStyle
        formatter.timeStyle = .NoStyle
        return formatter
    }()
    
    deinit {
        RLMRealm.removeNotification(token)
    }
    
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
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        if !settings.tracking.on && !TracksHandler.hasTrackedBikeData() {
            dismiss()
        }
    }
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return .LightContent
    }
    
    func updateUI() {
        
        let tracks = Track.objectsWhere("activity.cycling == TRUE")
        
        let totalDistance = BikeStatistics.totalDistance() / 1000
        distanceLabel.text = numberFormatter.stringFromNumber(totalDistance)
        
        let totalTime = BikeStatistics.totalDuration() / 3600
        timeLabel.text = numberFormatter.stringFromNumber(totalTime)
        
        let averageSpeed = BikeStatistics.averageSpeed() / 1000 * 3600
        speedLabel.text = numberFormatter.stringFromNumber(averageSpeed)
        
        let averageTripDistance = BikeStatistics.averageTrackDistance() / 1000
        tripLabel.text = numberFormatter.stringFromNumber(averageTripDistance)
        
        if let startDate = (tracks.sortedResultsUsingProperty("startTimestamp", ascending: false).firstObject() as? Track)?.startDate {
            sinceLabel.text = "Since".localized + " " + dateFormatter.stringFromDate(startDate)
        } else {
            sinceLabel.text = "–"
        }        
    }
}
