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
    
    @IBOutlet weak var mapView2: TrackMapView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        mapView.tileSource = SMiBikeCPHMapTileSource()
        mapView.maxZoom = Float(DEFAULT_MAP_ZOOM)
        
        mapView.showsUserLocation = true
        
        updateUI()
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
        
        var pathAnnotation = RMAnnotation()
        pathAnnotation.mapView = mapView
        if let firstLocation = track.locations.firstObject() as? TrackLocation {
            if let lastLocation = track.locations.lastObject() as? TrackLocation {
                pathAnnotation.coordinate = firstLocation.coordinate()
                
                let waypoints = [firstLocation.location(), lastLocation.location()]
                pathAnnotation.annotationType = "path"
                pathAnnotation.userInfo = [
                    "linePoints" : waypoints,
                    "lineColor" : Styler.tintColor(),
                    "fillColor" : UIColor.clearColor(),
                    "lineWidth" : 10.0,
                ]
                
                pathAnnotation.setBoundingBoxFromLocations(waypoints)
                mapView.addAnnotation(pathAnnotation)
                
                let ne = firstLocation.coordinate()
                let sw = lastLocation.coordinate()
                mapView.centerCoordinate = CLLocationCoordinate2DMake((ne.latitude+sw.latitude) / 2.0, (ne.longitude+sw.longitude) / 2.0)
                mapView.zoomWithLatitudeLongitudeBoundsSouthWest(pathAnnotation.swCoordinate.coordinate, northEast:pathAnnotation.neCoordinate.coordinate, animated: false)
                
                mapView.userTrackingMode = RMUserTrackingModeNone;
            }
        }
        
        // MapKit
        mapView2.track = track
       

//    RMAnnotation *calculatedPathAnnotation = [RMAnnotation annotationWithMapView:self.mapView coordinate:[route getStartLocation].coordinate andTitle:nil];
//    calculatedPathAnnotation.annotationType = @"path";
//    calculatedPathAnnotation.userInfo = @{
//    @"linePoints" : [NSArray arrayWithArray:route.waypoints],
//    @"lineColor" : color,
//    @"fillColor" : [UIColor clearColor],
//    @"lineWidth" : [NSNumber numberWithFloat:10.0f],
//    };
//    [calculatedPathAnnotation setBoundingBoxFromLocations:[NSArray arrayWithArray:route.waypoints]];
//    [self.mapView addAnnotation:calculatedPathAnnotation];
//    return @{
//    neCoordinate : calculatedPathAnnotation.neCoordinate,
//    swCoordinate : calculatedPathAnnotation.swCoordinate
//    };
    }
    
}
