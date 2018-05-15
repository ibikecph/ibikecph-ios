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
    @IBOutlet weak var readAloudButton: ReadAloudButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Delegate
        mapView.trackingDelegate = self
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        OverlaysManager.sharedInstance.mapView = mapView
        mapView.loadInitialRegionIfNecessary()
    }
    
    @IBAction func compassButtonTapped(_ sender: AnyObject) {
        switch mapView.userTrackingMode {
            case .none: mapView.userTrackingMode = .follow // None -> Follow
            case .follow: mapView.userTrackingMode = .followWithHeading // Follow -> Heading
            case .followWithHeading: mapView.userTrackingMode = .follow // Heading -> Follow
        }
    }
    
    func removePin(_ pin: PinAnnotation) {
        mapView.removeAnnotation(pin)
    }

    func addPin(_ coordinate: CLLocationCoordinate2D) -> PinAnnotation {
        let pin = PinAnnotation(mapView: mapView, coordinate: coordinate)
        mapView.addAnnotation(pin)
        return pin
    }
}


extension MapViewController: MapViewTrackingDelegate {
    func didChangeUserTrackingMode(_ mode: MapView.UserTrackingMode) {
        compassButton?.userTrackingMode = mode
    }
}
