//
//  MainMapViewController.swift
//  I Bike CPH
//
//  Created by Tobias Due Munk on 04/06/15.
//  Copyright (c) 2015 I Bike CPH. All rights reserved.
//

import UIKit

class MainMapViewController: MapViewController {

    var trackingToolbarView = TrackingToolbarView()
    
    let mainToTrackingSegue = "mainToTracking"
    
    deinit {
        NotificationCenter.unobserve(self)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Follow user if possible
        mapView.mapView.userTrackingMode = .Follow
        
        // Toolbar delegate
        trackingToolbarView.delegate = self
        
        // Tracking changes
        updateTrackingToolbarView()
        NotificationCenter.observe(processedBigNoticationKey) { notification in
            self.updateTrackingToolbarView()
        }
        NotificationCenter.observe(settingsUpdatedNotification) { notification in
            self.updateTrackingToolbarView()
        }
    }

    @IBAction func openMenu(sender: AnyObject) {
        NotificationCenter.post("openMenu")
    }
    
    func updateTrackingToolbarView() {
        let trackingOn = settings.tracking.on
        let hasBikeTracks = BikeStatistics.hasTrackedBikeData()
        let showTrackingView = trackingOn || hasBikeTracks
        if showTrackingView {
            trackingToolbarView.distance = BikeStatistics.distanceThisDate()
            trackingToolbarView.duration = BikeStatistics.durationThisDate()
            add(toolbarView: trackingToolbarView)
        } else {
            removeToolbar()
        }
    }
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return .LightContent
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if
            segue.identifier == mainToTrackingSegue,
            let navigationController = segue.destinationViewController as? UINavigationController
        {
            let backButton = UIBarButtonItem(barButtonSystemItem: .Done, target: self, action: "dismissViewController")
            navigationController.viewControllers.first?.navigationItem.leftBarButtonItem = backButton
        }
    }
    
    func dismissViewController() {
         dismissViewControllerAnimated(true, completion: nil)
    }
}

extension MainMapViewController: TrackingToolbarDelegate {
    
    func didSelectOpenTracking() {
        performSegueWithIdentifier(mainToTrackingSegue, sender: self)
    }
}


