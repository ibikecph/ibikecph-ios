//
//  TrackDetailViewController.swift
//  I Bike CPH
//
//  Created by Tobias Due Munk on 23/02/15.
//  Copyright (c) 2015 I Bike CPH. All rights reserved.
//

import UIKit
import MapKit

class TrackDetailViewController: SMTranslatedViewController {

    @IBOutlet weak var mapView: RMMapView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        mapView.tileSource = SMiBikeCPHMapTileSource()
        mapView.maxZoom = Float(MAX_MAP_ZOOM)
        
        mapView.showsUserLocation = true
        
        updateUI()
    }
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return .LightContent
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
            // TODO: clean up
        }
    }
    
    func zoomToTrack(track: Track) {
        
        if mapView == nil {
            return
        }
        
        var shape = RMShape(view: mapView)
        var pathAnnotation = RMAnnotation()
        pathAnnotation.mapView = mapView
        if let firstLocation = track.locations.firstObject() as? TrackLocation {
            pathAnnotation.coordinate = firstLocation.coordinate()
        }
        shape.lineColor = Styler.tintColor()
        shape.lineWidth = 5.0
        
        var waypoints: [CLLocation] = [CLLocation]()
        for location in track.locations {
            let location = location as TrackLocation
            waypoints.append(location.location())
            shape.addLineToCoordinate(location.coordinate())
        }
        
        pathAnnotation.layer = shape
        
        pathAnnotation.setBoundingBoxFromLocations(waypoints)
        mapView.addAnnotation(pathAnnotation)
        
        mapView.zoomWithLatitudeLongitudeBoundsSouthWest(pathAnnotation.swCoordinate.coordinate, northEast:pathAnnotation.neCoordinate.coordinate, animated: false)
        
        mapView.userTrackingMode = RMUserTrackingModeNone;
    }

}
