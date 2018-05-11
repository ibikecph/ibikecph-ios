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
    @IBOutlet weak var calorieLabel: UILabel!
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var sinceLabel: UILabel!
    @IBOutlet weak var tableView: UITableView!
    
    fileprivate let enableTrackingToolbarView = EnableTrackingToolbarView()
    fileprivate var tracks: [[Track]]?
    fileprivate var selectedTrack: Track?
    fileprivate var swipeEditing: Bool = false
    fileprivate var observerTokens = [AnyObject]()
    fileprivate var pendingEnableTracking = false
    fileprivate static let toAddTrackTokenSegue = "trackingToAddTrackToken"
    fileprivate static let toLoginSegue = "trackingToLogin"
    
    lazy var numberFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.maximumFractionDigits = 0
        formatter.minimumFractionDigits = 0
        return formatter
    }()
    
    lazy var decimalFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.maximumFractionDigits = 1
        formatter.minimumFractionDigits = 1
        formatter.minimumIntegerDigits = 1 // "0.0" instead of ".0"
        return formatter
    }()
    
    lazy var sinceFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .none
        return formatter
    }()
    
    lazy var headerDateFormatter: RelativeDateFormatter = {
        let formatter = RelativeDateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .none
        return formatter
    }()
    
    deinit {
        unobserve()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Title
        title = "tracking".localized
        
        // Delegates
        enableTrackingToolbarView.delegate = self
        
        // Setup notifications
        observerTokens.append(NotificationCenter.observe(processedBigNoticationKey) { [weak self] notification in
            self?.updateUI()
            if self != nil {
                // Request update of tracks
                TracksHandler.geocode()
            }
        })
        observerTokens.append(NotificationCenter.observe(processedGeocodingNoticationKey) { [weak self] notification in
            self?.updateUI()
        })
        observerTokens.append(NotificationCenter.observe(settingsUpdatedNotification) { [weak self] notification in
            self?.updateUI()
        })
        
        // Initial load of UI
        self.updateUI()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // Leave view controller if user hasn't enabled tracking and has no tracking data.
        // This will happen when user disable tracking in tracking settings and returns to this view controller.
        if !Settings.sharedInstance.tracking.on && !BikeStatistics.hasTrackedBikeData() {
            dismiss()
        }
        
        // Request new data
        TracksHandler.setNeedsProcessData(true)
        
        // Check if tracking should be enabled
        if pendingEnableTracking && UserHelper.checkEnableTracking() == .allowed {
            Settings.sharedInstance.tracking.on = true
            if let indexPaths = tableView.indexPathsForVisibleRows {
                tableView.beginUpdates()
                tableView.reloadRows(at: indexPaths, with: .fade)
                tableView.endUpdates()
            }
        } else if pendingEnableTracking && UserHelper.checkEnableTracking() == .lacksTrackToken {
            performSegue(withIdentifier: TrackingViewController.toAddTrackTokenSegue, sender: self)
        } else {
            pendingEnableTracking = false
        }
    }
    
    override var preferredStatusBarStyle : UIStatusBarStyle {
        return .lightContent
    }
    
    fileprivate func unobserve() {
        for observerToken in observerTokens {
            NotificationCenter.unobserve(observerToken)
        }
        NotificationCenter.unobserve(self)
    }
    
    func updateUI() {
        
        // Re-enable button
        if Settings.sharedInstance.tracking.on {
            removeToolbar()
        } else {
            add(toolbarView: enableTrackingToolbarView)
        }
        
        // Stats
        let totalDistance = BikeStatistics.totalDistance() / 1000
        distanceLabel.text = numberFormatter.string(from: NSNumber(totalDistance))
        
        let totalTime = BikeStatistics.totalDuration() / 3600
        timeLabel.text = numberFormatter.string(from: NSNumber(totalTime))
        
        let averageSpeed = BikeStatistics.averageSpeed() / 1000 * 3600
        speedLabel.text = decimalFormatter.string(from: NSNumber(averageSpeed))
        
        if let startDate = BikeStatistics.firstTrackStartDate() {
            sinceLabel.text = "Since".localized + " " + sinceFormatter.string(from: startDate as Date)
            let totalDays = Date().relativeDay(startDate) + 1
            let averageDayDistance = BikeStatistics.totalDistance() / Double(totalDays)
            let averageDayCalories = BikeStatistics.kiloCaloriesPerBikedDistance(averageDayDistance)
            calorieLabel.text = numberFormatter.string(from: averageDayCalories)
        } else {
            sinceLabel.text = "–"
            calorieLabel.text = "-"
        }
        
        if swipeEditing {
            return
        }
        
        // Tracks
        updateTracks()
        tableView.reloadData()
    }
    
    func updateTracks() {
        var updatedTracks = [[Track]]()
        if BikeStatistics.firstTrackStartDate() != nil {
            let allTracks = BikeStatistics.tracks().sortedResults(usingKeyPath: "startTimestamp", ascending: false)
            var currentDate: Date = BikeStatistics.lastTrackEndDate() as! Date ?? Date()
            var section = 0
            for track in allTracks {
                if let
                    track = track as? Track,
                    let date = track.startDate()
                {
                    let sameDay = date.relativeDay(currentDate) == 0
                    if !sameDay {
                        currentDate = date
                        section += 1
                    }
                    while updatedTracks.count <= section {
                        updatedTracks.append([Track]())
                    }
                    updatedTracks[section].append(track)
                }
            }
        }
        tracks = updatedTracks
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if
            segue.identifier == "trackingToDetail",
            let track = selectedTrack,
            let trackDetailViewController = segue.destination as? TrackDetailViewController
        {
            trackDetailViewController.track = track
        }
    }
}


private let cellID = "TrackCell"

extension TrackingViewController: UITableViewDataSource {
    
    func tracks(inSection section: Int) -> [Track]? {
        if let tracks = tracks, section < tracks.count {
            return tracks[section]
        }
        return nil
    }
    
    func track(_ indexPath: IndexPath?) -> Track? {
        if let
            indexPath = indexPath,
            let tracks = tracks(inSection: indexPath.section), indexPath.row < tracks.count
        {
            return tracks[indexPath.row]
        }
        return nil
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return tracks?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let tracks = tracks(inSection: section) {
            return Int(tracks.count)
        }
        return 0
    }
    
    // Section header title
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if let aDateInSection = tracks(inSection: section)?.first?.startDate() {
            return headerDateFormatter.string(from: aDateInSection)
        }
        return nil
    }
    
    // Cell
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.cellWithIdentifier(cellID, forIndexPath: indexPath) as TrackTableViewCell
        cell.updateToTrack(track(indexPath))
        return cell
    }
    
    // Delete track
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete,
            let track = track(indexPath), !track.isInvalidated
        {
            let deleteLocalClosure: () -> () = {
                Async.main {
                    tableView.beginUpdates()
                    tableView.deleteRows(at: [indexPath], with: .left)
                    track.deleteFromRealmWithRelationships()
                    self.updateTracks()
                    tableView.endUpdates()
                }
            }
            if track.serverId == "" {
                deleteLocalClosure()
            } else {
                // Delete from server
                TracksClient.sharedInstance.delete(track) { result in
                    switch result {
                        case .success(_): fallthrough
                        case .notFound:
                            deleteLocalClosure() // Delete if deleted on server or not found
                        case .notAuthorized:
                            Async.main {
                                tableView.setEditing(false, animated: true)
                            }
                        case .other(let result):
                            Async.main {
                                tableView.setEditing(false, animated: true)
                            }
                            switch result {
                                case .failed(let error):
                                    print(error.localizedDescription)
                                default:
                                    print("Other upload error \(result)")
                            }
                    }
                }
            }
        } else {
            updateUI()
        }
    }
    func tableView(_ tableView: UITableView, willBeginEditingRowAt indexPath: IndexPath) {
        swipeEditing = true
    }
    func tableView(_ tableView: UITableView, didEndEditingRowAt indexPath: IndexPath?) {
        swipeEditing = false
    }
}


extension TrackingViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let track = track(indexPath), !track.isInvalidated {
            selectedTrack = track
            performSegue(withIdentifier: "trackingToDetail", sender: self)
        } else {
            updateUI()
        }
    }
}


extension TrackingViewController: EnableTrackingToolbarDelegate {
    
    func didSelectEnableTracking() {
        switch UserHelper.checkEnableTracking() {
        case .notLoggedIn:
            let alertController = PSTAlertController(title: "", message: "log_in_to_track_prompt".localized, preferredStyle: .alert)
            alertController?.addCancelAction(handler: nil)
            let loginAction = PSTAlertAction(title: "log_in".localized) { [weak self] action in
                self?.pendingEnableTracking = true
                self?.performSegue(withIdentifier: TrackingViewController.toLoginSegue, sender: self)
            }
            alertController?.addAction(loginAction)
            alertController?.showWithSender(self, controller: self, animated: true, completion: nil)
        case .allowed:
            Settings.sharedInstance.tracking.on = true
        case .lacksTrackToken:
            // User is logged in but doesn't have a trackToken
            pendingEnableTracking = true
            performSegue(withIdentifier: TrackingViewController.toAddTrackTokenSegue, sender: self)
            return
        }
    }
}
