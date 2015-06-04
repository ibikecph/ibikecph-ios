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

//    @IBOutlet weak var mapView: MapView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
//        mapView.tileSource = SMiBikeCPHMapTileSource()
//        mapView.maxZoom = Float(MAX_MAP_ZOOM)
//        
//        mapView.showsUserLocation = true
        
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
        
//        if mapView == nil {
//            return
//        }
//        
//        var coordinates = [CLLocationCoordinate2D]()
//        for location in track.locations {
//            let location = location as! TrackLocation
//            coordinates.append(location.coordinate())
//        }
//        let pathAnnotation = mapView.addPath(coordinates)
//        
////        let speedLimit: Double = 3
////        var slowStartIndex = 0
////        for speed in track.smoothSpeeds() {
////            if speed > speedLimit {
////                break
////            }
////            slowStartIndex++
////        }
////        let slowStartCoordinates = Array(coordinates[0...slowStartIndex])
////        mapView.addPath(slowStartCoordinates, lineColor: .redColor())
////        
////        var slowEndIndex = coordinates.count - 1
////        for speed in track.smoothSpeeds().reverse() {
////            if speed > speedLimit {
////                break
////            }
////            slowEndIndex--
////        }
////        let slowEndCoordinates = Array(coordinates[slowEndIndex...(coordinates.count-1)])
////        mapView.addPath(slowEndCoordinates, lineColor: .greenColor())
//        
//        mapView.userTrackingMode = RMUserTrackingModeNone;
//        
//        Async.main {
//            
//            // Padding
//            var ne = pathAnnotation.neCoordinate.coordinate
//            var sw = pathAnnotation.swCoordinate.coordinate
//            
//            let latitudeDiff = abs(ne.latitude - sw.latitude)
//            let longitudeDiff = abs(ne.longitude - sw.longitude)
//            
//            let padding = 0.2
//            ne.latitude += latitudeDiff * padding;
//            ne.longitude += longitudeDiff * padding;
//            
//            sw.latitude -= latitudeDiff * padding;
//            sw.longitude -= longitudeDiff * padding;
//            
//            // Zoom
//            self.mapView.zoomWithLatitudeLongitudeBoundsSouthWest(sw, northEast: ne, animated: false)
//        }
    }
}

//extension RMMapView {
//    
//    func addPath(coordinates: [CLLocationCoordinate2D], lineColor: UIColor = Styler.tintColor()) -> RMAnnotation {
//    
//        var shape = RMShape(view: self)
//        var pathAnnotation = RMAnnotation()
//        pathAnnotation.mapView = self
//        if let firstCoordinate = coordinates.first {
//            pathAnnotation.coordinate = firstCoordinate
//        }
//        shape.lineColor = lineColor
//        shape.lineWidth = 4.0
//        
//        var waypoints: [CLLocation] = [CLLocation]()
//        for coordinate in coordinates {
//            shape.addLineToCoordinate(coordinate)
//            let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
//            waypoints.append(location)
//        }
//        
//        pathAnnotation.layer = shape
//        
//        pathAnnotation.setBoundingBoxFromLocations(waypoints)
//        self.addAnnotation(pathAnnotation)
//        
//        return pathAnnotation
//    }
//}
