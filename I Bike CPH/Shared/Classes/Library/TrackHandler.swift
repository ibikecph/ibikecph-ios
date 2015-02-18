//
//  TrackHandler.swift
//  I Bike CPH
//
//  Created by Tobias Due Munk on 16/02/15.
//  Copyright (c) 2015 I Bike CPH. All rights reserved.
//

import Foundation
import CoreLocation

let trackHandler = TrackHandler()

@objc class TrackHandler {

    private var currentTrack: Track?
    let bikeDetector = BikeDetector()
    
    init() {
        setupMotionTracking()
        setupBackgroundHandling()
        setupLocationObserver()
    }
    
    func trackingAvailable() -> Bool {
        return bikeDetector.isAvailable()
    }
    
    func setupMotionTracking() {
        if !settings.tracking.on {
            return
        }
        if !bikeDetector.isAvailable() {
            return
        }
        bikeDetector.start { [unowned self] isBiking in
            // Run tracking when biking
            if isBiking {
                self.startTracking()
            } else {
                self.stopTracking()
            }
        }
    }
    
    func setupBackgroundHandling() {
        NSNotificationCenter.defaultCenter().addObserverForName(UIApplicationDidEnterBackgroundNotification, object: nil, queue: nil) { notification in
            if settings.tracking.on {
                return
            }
            // TODO: Check if app is routing
            let currentlyRouting = false // WARNING: FIXME: get actual value
            if settings.voice.on && currentlyRouting {
                return
            }
            // Stop location manager
            SMLocationManager.instance().stop()
        }
        NSNotificationCenter.defaultCenter().addObserverForName(UIApplicationWillEnterForegroundNotification, object: nil, queue: nil) { notification in
            SMLocationManager.instance().start()
        }
    }
    
    func setupLocationObserver() {
        NSNotificationCenter.defaultCenter().addObserverForName("refreshPosition", object: nil, queue: nil) { notification in
            for location in notification.userInfo?["locations"] as [CLLocation] {
                self.add(location)
            }
        }
    }
    
    func startTracking() {
        println("Start tracking")
        
        // Start location manager
        SMLocationManager.instance().start()
        
        // Initialize track
        currentTrack = Track()
        currentTrack!.addToRealm()
    }
    
    func stopTracking() {
        println("Stop tracking")
        
        // Stop location manager
        // TODO: Check that other functionality doesn't depend on it, else only idle down (to allow bike detection in background)
        SMLocationManager.instance().idle()
        
        // Stop track
        currentTrack?.recalculateLength()
        currentTrack = nil
    }
    
    func add(location: CLLocation) {
        if let currentTrack = currentTrack {
            let location = TrackLocation.build(location)
            currentTrack.locations.add(location)
            currentTrack.recalculateLength()
            println("Tracked location: \(location.location())")
        }
    }
}


// MARK: - ObjC compatibility

extension TrackHandler {
    
    class func sharedInstance() -> TrackHandler {
        return trackHandler
    }
}
