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
    @IBOutlet weak var tableView: UITableView!
    
    private var token: RLMNotificationToken?
    private var tracks: RLMResults?
    private var selectedTrack: Track?
    
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
        
        let totalDistance = BikeStatistics.totalDistance() / 1000
        distanceLabel.text = numberFormatter.stringFromNumber(totalDistance)
        
        let totalTime = BikeStatistics.totalDuration() / 3600
        timeLabel.text = numberFormatter.stringFromNumber(totalTime)
        
        let averageSpeed = BikeStatistics.averageSpeed() / 1000 * 3600
        speedLabel.text = numberFormatter.stringFromNumber(averageSpeed)
        
        let averageTripDistance = BikeStatistics.averageTrackDistance() / 1000
        tripLabel.text = numberFormatter.stringFromNumber(averageTripDistance)
        
        if let startDate = BikeStatistics.firstTrackDate() {
            sinceLabel.text = "Since".localized + " " + dateFormatter.stringFromDate(startDate)
        } else {
            sinceLabel.text = "–"
        }
        
        updateTracks()
        tableView.reloadData()
        
        if let tracks = tracks {
            for track in tracks {
                let track = track as Track
                if track.start == "" {
                    if let startLocation = track.locations.firstObject() as? TrackLocation {
                        let coordinate = startLocation.coordinate()
                        SMGeocoder.reverseGeocode(coordinate) { (item: KortforItem?, error: NSError?) in
                            if track.invalidated {
                                return
                            }
                            track.realm.beginWriteTransaction()
                            if let item = item { println("\(item.street) \(track.start)")
                                track.start = item.street
                            }
                            track.realm.commitWriteTransaction()
                        }
                    }
                }
                if track.end == "" {
                    if let endLocation = track.locations.lastObject() as? TrackLocation {
                        let coordinate = endLocation.coordinate()
                        SMGeocoder.reverseGeocode(coordinate) { (item: KortforItem?, error: NSError?) in
                            if track.invalidated {
                                return
                            }
                            track.realm.beginWriteTransaction()
                            if let item = item {
                                track.end = item.street
                            }
                            track.realm.commitWriteTransaction()
                        }
                    }
                }
            }
        }
    }
    
    func updateTracks() {
        tracks = Track.objectsWhere("activity.cycling == TRUE").sortedResultsUsingProperty("startTimestamp", ascending: false)
    }
}


private let cellID = "TrackCell"

extension TrackingViewController: UITableViewDataSource {
    
    func track(indexPath: NSIndexPath?) -> Track? {
        if let indexPath = indexPath {
            return tracks?[UInt(indexPath.row)] as? Track
        }
        return nil
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return Int(tracks?.count ?? 0)
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(cellID) as TrackTableViewCell
        cell.updateToTrack(track(indexPath))
        return cell
    }
}

extension TrackingViewController: UITableViewDelegate {
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if let track = track(indexPath) {
            selectedTrack = track
            performSegueWithIdentifier("trackingToDetail", sender: self)
        }
    }
}

extension TrackingViewController {
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "trackingToDetail" {
            if let track = selectedTrack {
                let trackDetailViewController = segue.destinationViewController as TrackDetailViewController
                trackDetailViewController.track = track
            }
        }
    }
}
