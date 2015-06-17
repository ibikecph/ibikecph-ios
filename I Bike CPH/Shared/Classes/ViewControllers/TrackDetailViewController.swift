//
//  TrackDetailViewController.swift
//  I Bike CPH
//
//  Created by Tobias Due Munk on 23/02/15.
//  Copyright (c) 2015 I Bike CPH. All rights reserved.
//

import UIKit


class TrackDetailViewController: SMTranslatedViewController {

    @IBOutlet weak var mapView: MapView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Make map passive
        mapView.showsUserLocation = false
        mapView.userTrackingMode = .None
        
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

        var coordinates = [CLLocationCoordinate2D]()
        for location in track.locations {
            let location = location as! TrackLocation
            coordinates.append(location.coordinate())
        }
        let pathAnnotation = mapView.addPath(coordinates)
        
        //        let speedLimit: Double = 3
        //        var slowStartIndex = 0
        //        for speed in track.smoothSpeeds() {
        //            if speed > speedLimit {
        //                break
        //            }
        //            slowStartIndex++
        //        }
        //        let slowStartCoordinates = Array(coordinates[0...slowStartIndex])
        //        mapView.addPath(slowStartCoordinates, lineColor: .redColor())
        //
        //        var slowEndIndex = coordinates.count - 1
        //        for speed in track.smoothSpeeds().reverse() {
        //            if speed > speedLimit {
        //                break
        //            }
        //            slowEndIndex--
        //        }
        //        let slowEndCoordinates = Array(coordinates[slowEndIndex...(coordinates.count-1)])
        //        mapView.addPath(slowEndCoordinates, lineColor: .greenColor())

        // Set zoom asynchronous, else MapBox view doesn't render
        Async.main {
            self.mapView.zoomToAnnotation(pathAnnotation, animated: false)
        }
    }
}




