//
//  TrackingViewController.swift
//  I Bike CPH
//
//  Created by Tobias Due Munk on 17/02/15.
//  Copyright (c) 2015 I Bike CPH. All rights reserved.
//

import UIKit
import PSTAlertController

class TrackingViewController: ToolbarViewController {

    @IBOutlet weak var distanceLabel: UILabel!
    @IBOutlet weak var speedLabel: UILabel!
    @IBOutlet weak var tripLabel: UILabel!
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var sinceLabel: UILabel!
    @IBOutlet weak var tableView: UITableView!
    
    private let enableTrackingToolbarView = EnableTrackingToolbarView()
    private var tracks: [[Track]]?
    private var selectedTrack: Track?
    private var swipeEditing: Bool = false
    
    lazy var numberFormatter: NSNumberFormatter = {
        let formatter = NSNumberFormatter()
        formatter.maximumFractionDigits = 0
        formatter.minimumFractionDigits = 0
        return formatter
    }()
    
    lazy var decimalFormatter: NSNumberFormatter = {
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
        NotificationCenter.unobserve(self)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Title
        title = "tracking".localized
        
        // Delegates
        enableTrackingToolbarView.delegate = self
        
        // Setup notifications
        NotificationCenter.observe(processedBigNoticationKey) { [weak self] notification in
            self?.updateUI()
            if self != nil {
                // Request update of tracks
                TracksHandler.geocode()
            }
        }
        NotificationCenter.observe(processedGeocodingNoticationKey) { [weak self] notification in
            self?.updateUI()
        }
        NotificationCenter.observe(settingsUpdatedNotification) { [weak self] notification in
            self?.updateUI()
        }
        
        // Initial load of UI
        self.updateUI()
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        // Leave view controller if user hasn't enabled tracking and has no tracking data.
        // This will happen when user disable tracking in tracking settings and returns to this view controller.
        if !Settings.instance.tracking.on && !BikeStatistics.hasTrackedBikeData() {
            dismiss()
        }
        
        // Request new data
        TracksHandler.setNeedsProcessData(userInitiated: true)
    }
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return .LightContent
    }
    
    func updateUI() {
        
        // Re-enable button
        if Settings.instance.tracking.on {
            removeToolbar()
        } else {
            add(toolbarView: enableTrackingToolbarView)
        }
        
        // Stats
        let totalDistance = BikeStatistics.totalDistance() / 1000
        distanceLabel.text = numberFormatter.stringFromNumber(totalDistance)
        
        let totalTime = BikeStatistics.totalDuration() / 3600
        timeLabel.text = numberFormatter.stringFromNumber(totalTime)
        
        let averageSpeed = BikeStatistics.averageSpeed() / 1000 * 3600
        speedLabel.text = decimalFormatter.stringFromNumber(averageSpeed)
        
        let averageTripDistance = BikeStatistics.averageTrackDistance() / 1000
        tripLabel.text = decimalFormatter.stringFromNumber(averageTripDistance)
        
        if let startDate = BikeStatistics.firstTrackStartDate() {
            sinceLabel.text = "Since".localized + " " + sinceFormatter.stringFromDate(startDate)
        } else {
            sinceLabel.text = "–"
        }
        
        if swipeEditing {
            return
        }
        
        // Tracks
        updateTracks()
        tableView.reloadData()
    }
    
    func updateTracks() {
        var date = NSDate()
        var updatedTracks: [[Track]]? = nil
        if let oldestDate = BikeStatistics.firstTrackStartDate() {
            while date.laterOrEqualDay(thanDate: oldestDate) {
                if let tracksForDate = BikeStatistics.tracksForDayOfDate(date) {
                    if let tracks = tracksForDate.sortedResultsUsingProperty("startTimestamp", ascending: false) {
                        let tracksArray = tracks.toArray(Track.self)
                        if updatedTracks == nil {
                            updatedTracks = [tracksArray]
                        } else {
                            updatedTracks?.append(tracksArray)
                        }
                    }
                }
                date = date.dateByAddingTimeInterval(-60*60*24) // Go one day back
            }
        }
        tracks = updatedTracks
    }
    
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


private let cellID = "TrackCell"

extension TrackingViewController: UITableViewDataSource {
    
    func tracks(inSection section: Int) -> [Track]? {
        if let tracks = tracks where section < tracks.count {
            return tracks[section]
        }
        return nil
    }
    
    func track(indexPath: NSIndexPath?) -> Track? {
        if let
            indexPath = indexPath,
            tracks = tracks(inSection: indexPath.section)
            where indexPath.row < tracks.count
        {
            return tracks[indexPath.row]
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
        if let aDateInSection = tracks(inSection: section)?.first?.startDate() {
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
        if editingStyle == .Delete,
            let track = track(indexPath) where !track.invalidated
        {
            tableView.beginUpdates()
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Left)
            track.deleteFromRealmWithRelationships()
            updateTracks()
            tableView.endUpdates()
        } else {
            updateUI()
        }
    }
    func tableView(tableView: UITableView, willBeginEditingRowAtIndexPath indexPath: NSIndexPath) {
        swipeEditing = true
    }
    func tableView(tableView: UITableView, didEndEditingRowAtIndexPath indexPath: NSIndexPath) {
        swipeEditing = false
    }
}


extension TrackingViewController: UITableViewDelegate {
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if let track = track(indexPath) where !track.invalidated {
            selectedTrack = track
            performSegueWithIdentifier("trackingToDetail", sender: self)
        } else {
            updateUI()
        }
    }
}


extension TrackingViewController: EnableTrackingToolbarDelegate {
    
    func didSelectEnableTracking() {
        if !UserHelper.loggedIn() {
            let alertController = PSTAlertController(title: "", message: "log_in_to_track_prompt".localized, preferredStyle: .Alert)
            alertController.addCancelActionWithHandler(nil)
            let loginAction = PSTAlertAction(title: "log_in".localized) { [weak self] action in
                self?.performSegueWithIdentifier("trackingPromptToLogin", sender: self)
            }
            alertController.addAction(loginAction)
            alertController.showWithSender(self, controller: self, animated: true, completion: nil)
            return
        }
        Settings.instance.tracking.on = true
    }
}
