//
//  TrackDetailViewController.swift
//  I Bike CPH
//
//  Created by Tobias Due Munk on 23/02/15.
//  Copyright (c) 2015 I Bike CPH. All rights reserved.
//

import UIKit
import Async


class TrackDetailViewController: SMTranslatedViewController {

    @IBOutlet weak var mapView: MapView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Make map passive
        mapView.showsUserLocation = false
        mapView.userTrackingMode = .none
        
        updateUI()
    }
    
    override var preferredStatusBarStyle : UIStatusBarStyle {
        return .lightContent
    }
    
    var track: Track? {
        didSet {
            updateUI()
        }
    }
    
    func updateUI() {
        
        if let track = track {
            zoomToTrack(track)
        } else {
            // Clean up
            if mapView == nil {
                return
            }
            mapView.removeAllAnnotations()
        }
    }
    
    func zoomToTrack(_ track: Track) {
        
        if mapView == nil {
            return
        }

        let trackLocations = RLMResultsHelper.toArray(results: track.locationsSorted() as! RLMResults<AnyObject>, ofType: TrackLocation.self)
        let coordinates = trackLocations.map { return $0.coordinate() }
        // Draw route
        let pathAnnotation = mapView.addPath(coordinates)
        
        // Pins
//        if let startCoordinate = coordinates.first {
//            let startPin = PinAnnotation(mapView: mapView, coordinate: startCoordinate, type: .Start)
//            mapView.addAnnotation(startPin)
//        }
//        if let endCoordinate = coordinates.last {
//            let endPin = PinAnnotation(mapView: mapView, coordinate: endCoordinate, type: .End)
//            mapView.addAnnotation(endPin)
//        }
        
        // Set zoom asynchronous, else MapBox view doesn't render
        Async.main {
            self.mapView.zoomToAnnotation(pathAnnotation, animated: false)
        }
    }
}






