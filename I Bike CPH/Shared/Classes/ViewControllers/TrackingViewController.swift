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
    
    var lastUpdate: NSDate?
    
    deinit {
        NotificationCenter.unobserve(self)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "tracking".localized
        
        NotificationCenter.observe(processedBigNoticationKey) { notification in
            self.setNeedsUpdateUI()
        }
        self.updateUI()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        Async.main {
            self.updateUI()
        }
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        if !settings.tracking.on && !BikeStatistics.hasTrackedBikeData() {
            dismiss()
        }
        
        TracksHandler.setNeedsProcessData(force: true)
    }
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return .LightContent
    }
    
    func setNeedsUpdateUI() {
        if let lastUpdate = self.lastUpdate {
            if NSDate().timeIntervalSinceDate(lastUpdate) > 5 {
                self.lastUpdate = NSDate()
                self.view.setNeedsLayout()
                return
            }
        } else {
            self.lastUpdate = NSDate()
            self.view.setNeedsLayout()
            return
        }
        Async.main(after: 6) {
            self.setNeedsUpdateUI()
        }
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
        
        if let startDate = BikeStatistics.firstTrackStartDate() {
            sinceLabel.text = "Since".localized + " " + sinceFormatter.stringFromDate(startDate)
        } else {
            sinceLabel.text = "–"
        }
        
        if swipeEditing {
            return
        }
        
        updateTracks()
        tableView.reloadData()
        
        if let tracks = tracks {
            for tracksInSection in tracks {
                for track in tracksInSection {
                    if let let track = track as? Track {
                        if track.start == "" {
                            if let startLocation = track.locations.firstObject() as? TrackLocation {
                                let coordinate = startLocation.coordinate()
                                SMGeocoder.reverseGeocode(coordinate) { (item: KortforItem?, error: NSError?) in
                                    if track.invalidated {
                                        return
                                    }
                                    if let item = item {
                                        track.realm.beginWriteTransaction()
                                        track.start = item.street
                                        track.realm.commitWriteTransaction()
                                        self.setNeedsUpdateUI()
                                    }
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
                                    if let item = item {
                                        track.realm.beginWriteTransaction()
                                        track.end = item.street
                                        track.realm.commitWriteTransaction()
                                        self.setNeedsUpdateUI()
                                    }
                                }
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
        if let oldestDate = BikeStatistics.firstTrackStartDate() {
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
        let cell = tableView.cellWithIdentifier(cellID, forIndexPath: indexPath) as TrackTableViewCell
        cell.updateToTrack(track(indexPath))
        return cell
    }
    
    // Delete track
    func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            tableView.beginUpdates()
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Left)
            track(indexPath)?.deleteFromRealm()
            tableView.endUpdates()
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
        if
            segue.identifier == "trackingToDetail",
            let track = selectedTrack,
            trackDetailViewController = segue.destinationViewController as? TrackDetailViewController
        {
            trackDetailViewController.track = track
        }
    }
}
