//
//  MapViewController.swift
//  I Bike CPH
//
//  Created by Tobias Due Munk on 04/06/15.
//  Copyright (c) 2015 I Bike CPH. All rights reserved.
//

import UIKit

class MapViewController: ToolbarViewController {

    @IBOutlet weak var mapView: MapView!
    @IBOutlet weak var compassButton: CompassButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Delegate
        mapView.trackingDelegate = self
        
        NotificationCenter.observe(settingsUpdatedNotification) { [weak self] notification in
            self?.appDelegate.mapOverlays.updateAllOverlays()
        }
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        appDelegate.mapOverlays.mapView = mapView
//        appDelegate.mapOverlays.updateAllOverlays() // Load annotations to view
        mapView.loadInitialRegionIfNecessary()
    }
    
    @IBAction func compassButtonTapped(sender: AnyObject) {
        switch mapView.userTrackingMode {
            case .None: mapView.userTrackingMode = .Follow // None -> Follow
            case .Follow: mapView.userTrackingMode = .FollowWithHeading // Follow -> Heading
            case .FollowWithHeading: mapView.userTrackingMode = .Follow // Heading -> Follow
        }
    }
    
    func removePin(pin: PinAnnotation) {
        mapView.removeAnnotation(pin)
    }

    func addPin(coordinate: CLLocationCoordinate2D) -> PinAnnotation {
        let pin = PinAnnotation(mapView: mapView, coordinate: coordinate)
        mapView.addAnnotation(pin)
        return pin
    }
}


extension MapViewController: MapViewTrackingDelegate {
    func didChangeUserTrackingMode(mode: MapView.UserTrackingMode) {
        compassButton?.userTrackingMode = mode
    }
}
