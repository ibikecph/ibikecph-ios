//
//  TrackingHandler.swift
//  I Bike CPH
//
//  Created by Tobias Due Munk on 16/02/15.
//  Copyright (c) 2015 I Bike CPH. All rights reserved.
//

import Foundation
import CoreLocation
import CoreMotion

let trackingHandler = TrackingHandler()

@objc class TrackingHandler {

    private var currentTrack: Track?
    let bikeDetector = BikeDetector()
    var currentActivity: CMMotionActivity? {
        didSet {
            if let activity = currentActivity {
                if activity.stationary {
                    self.stopTracking()
                } else {
                    self.startTracking()
                }
                if let track = currentTrack {
                    let newActivity = TrackActivity.build(activity)
                    newActivity.addToRealm()
                    track.realm.beginWriteTransaction()
                    track.activity = newActivity
                    track.realm.commitWriteTransaction()
                }
            } else {
                self.stopTracking()
            }
        }
    }
    
    init() {
        setupMotionTracking()
        setupBackgroundHandling()
        setupLocationObserver()
    }
    
    func trackingAvailable() -> Bool {
        #if (arch(i386) || arch(x86_64)) && os(iOS)
            return true
        #endif
        return bikeDetector.isAvailable()
    }
    
    func setupMotionTracking() {
        if !settings.tracking.on {
            return
        }
        if !bikeDetector.isAvailable() {
            return
        }
        bikeDetector.start { [unowned self] isBiking, activity in
//            // Run tracking when biking
//            if isBiking {
//                self.startTracking()
//            } else {
//                self.stopTracking()
//            }
            self.currentActivity = activity
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
        currentTrack?.recalculate()
        currentTrack = nil
    }
    
    func add(location: CLLocation) {
        if let currentTrack = currentTrack {
            let location = TrackLocation.build(location)
            currentTrack.locations.add(location)
            currentTrack.recalculate()
            println("Tracked location: \(location.location())")
        }
    }
}


// MARK: - ObjC compatibility

extension TrackingHandler {
    
    class func sharedInstance() -> TrackingHandler {
        return trackingHandler
    }
}