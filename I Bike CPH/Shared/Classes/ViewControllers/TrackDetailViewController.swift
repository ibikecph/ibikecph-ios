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

        let trackLocations = track.locations.toArray(TrackLocation.self)
        var coordinates = trackLocations.map { return $0.coordinate() }
        // Draw route
        let pathAnnotation = mapView.addPath(coordinates)
        
        
//        let firstCoordinates = Array(coordinates[0..<min(10, coordinates.count)])
//        let rotations: [Double] = {
//            var rotations = [Double]()
//            for (index, coordinate) in enumerate(firstCoordinates) {
//                let nextIndex = index + 1
//                if nextIndex < Int(firstCoordinates.count) {
//                    let nextCoordinate = firstCoordinates[nextIndex]
//                    let newRotation = coordinate.degreesFromCoordinate(nextCoordinate)
//                    rotations.append(newRotation)
//                }
//            }
//            return rotations
//        }()
//        let median = rotations.sorted { $0 < $1 } [rotations.count/2]
//        
//        let diffClosure: Double -> Double = { rotation in
//            var diff = rotation - median
//            while diff > 180 { diff -= 360 }
//            while diff < -180 { diff += 360 }
//            return diff
//        }
//        let diffToMedian = rotations.map(diffClosure)
//        let removeToIndex: Int? = {
//            for (index, diff) in enumerate(diffToMedian.reverse()) {
//                if abs(diff) > 90 {
//                    return rotations.count - index // Subtract from count since enumerating over reverse
//                }
//            }
//            return nil
//        }()
//        
//        if let removeToIndex = removeToIndex {
//            let jumpyStartCoordinates = Array(coordinates[0..<removeToIndex])
//            mapView.addPath(jumpyStartCoordinates, lineColor: .greenColor(), lineWidth: 8)
//        }

        
        
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






