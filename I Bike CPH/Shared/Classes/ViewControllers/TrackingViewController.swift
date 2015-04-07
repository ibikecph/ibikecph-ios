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
    private var tracks: [RLMResults]?
    private var selectedTrack: Track?
    private var swipeEditing: Bool = false
    
    lazy var numberFormatter: NSNumberFormatter = {
        let formatter = NSNumberFormatter()
        formatter.maximumFractionDigits = 1
        formatter.minimumFractionDigits = 1
        formatter.minimumIntegerDigits = 1 // "0.0" instead of ".0"
        return formatter
    }()
    
    lazy var sinceFormatter: NSDateFormatter = {
        let formatter = NSDateFormatter()
        formatter.dateStyle = .LongStyle
        formatter.timeStyle = .NoStyle
        return formatter
    }()
    
    lazy var headerDateFormatter: RelativeDateFormatter = {
        let formatter = RelativeDateFormatter()
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
            sinceLabel.text = "Since".localized + " " + sinceFormatter.stringFromDate(startDate)
        } else {
            sinceLabel.text = "–"
        }
        
        updateTracks()
        if !swipeEditing {
            tableView.reloadData()
        }
        
        if let tracks = tracks {
            for tracksInSection in tracks {
                for track in tracksInSection {
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
    }
    
    func updateTracks() {
        var date = NSDate()
        var updatedTracks: [RLMResults]? = nil
        if let oldestDate = BikeStatistics.firstTrackDate() {
            while date.laterOrEqualDay(thanDate: oldestDate) {
                if let tracksForDate = BikeStatistics.tracksForDayOfDate(date) {
                    if let tracks = tracksForDate.sortedResultsUsingProperty("startTimestamp", ascending: false) {
                        if updatedTracks == nil {
                            updatedTracks = [tracks]
                        } else {
                            updatedTracks?.append(tracks)
                        }
                    }
                }
                date = date.dateByAddingTimeInterval(-60*60*24) // Go one day back
            }
        }
        tracks = updatedTracks
    }
}


private let cellID = "TrackCell"

extension TrackingViewController: UITableViewDataSource {
    
    func tracks(inSection section: Int) -> RLMResults? {
        return tracks?[section]
    }
    
    func track(indexPath: NSIndexPath?) -> Track? {
        if let indexPath = indexPath {
            return tracks(inSection: indexPath.section)?[UInt(indexPath.row)] as? Track
        }
        return nil
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return tracks?.count ?? 0
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let tracks = tracks(inSection: section) {
            return Int(tracks.count)
        }
        return 0
    }
    
    // Section header title
    func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if let aDateInSection = (tracks(inSection: section)?.firstObject() as? Track)?.startDate {
            return headerDateFormatter.stringFromDate(aDateInSection)
        }
        return nil
    }
    
    // Cell
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(cellID) as TrackTableViewCell
        cell.updateToTrack(track(indexPath))
        return cell
    }
    
    // Delete track
    func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            track(indexPath)?.deleteFromRealm()
        }
    }
    func tableView(tableView: UITableView, willBeginEditingRowAtIndexPath indexPath: NSIndexPath) {
        swipeEditing = true
    }
    func tableView(tableView: UITableView, didEndEditingRowAtIndexPath indexPath: NSIndexPath) {
        swipeEditing = false
        updateUI()
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
