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
    let motionDetector = MotionDetector()
    var currentActivity: CMMotionActivity? {
        didSet {
            if let activity = currentActivity {
                if activity.stationary {
                    self.stopTracking()
                } else {
                    self.startTracking()
                }
                // Add activity to current track
                if let track = currentTrack {
                    let transact = !track.realm.inWriteTransaction
                    if transact {
                        track.realm.beginWriteTransaction()
                    }
                    let newActivity = TrackActivity.build(activity)
                    newActivity.addToRealm()
                    track.activity = newActivity
                    if transact {
                        track.realm.commitWriteTransaction()
                    }
                }
            } else {
                self.stopTracking()
            }
        }
    }
    var trackingAvailable: Bool {
        #if (arch(i386) || arch(x86_64)) && os(iOS)
            return true
        #endif
        return motionDetector.isAvailable()
    }
    
    init() {
        setup()
    }
    
    deinit {
        NotificationCenter.unobserve(self)
    }
    
    func setup() {
        setupSettingsObserver()
        setupMotionTracking()
        setupBackgroundHandling()
        setupLocationObserver()
        setupMilestoneNotification()
    }
    
    func setupSettingsObserver() {
        NotificationCenter.observe(settingsUpdatedNotification) { [unowned self] notification in
            self.setup()
        }
    }
    
    func setupMotionTracking() {
        if !settings.tracking.on {
            motionDetector.stop()
            return
        }
        if !motionDetector.isAvailable() {
            return
        }
        motionDetector.start { [unowned self] activity in
            if let currentTrack = self.currentTrack where !currentTrack.invalidated && currentTrack.activity.sameActivityTypeAs(cmMotionActivity: activity){
                // Activity just updated it's confidence
                let transact = !currentTrack.realm.inWriteTransaction
                if transact {
                    currentTrack.realm.beginWriteTransaction()
                }
                currentTrack.activity.confidence = activity.confidence.rawValue
                if transact {
                    currentTrack.realm.commitWriteTransaction()
                }
                return
            }
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
        if !settings.tracking.on {
            self.stopTracking()
        }
        
        NSNotificationCenter.defaultCenter().addObserverForName("refreshPosition", object: nil, queue: nil) { notification in
            if let locations = notification.userInfo?["locations"] as? [CLLocation] {
                for location in locations {
                    self.add(location)
                }
            }
        }
    }
    
    func setupMilestoneNotification() {
        if !settings.tracking.on {
            return
        }
        statsNotificationHandler.checkPresentNotificationToUser()
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
        if settings.tracking.on {
            // Idle location manager
            SMLocationManager.instance().idle()
        } else {
            // Stop location manager
            SMLocationManager.instance().stop()
        }
        
        // Stop track
        if let currentTrack = currentTrack where !currentTrack.invalidated {
            currentTrack.recalculate()
        }
        currentTrack = nil
        
        TracksHandler.setNeedsProcessData()
    }
    
    func add(location: CLLocation) {
        if let currentTrack = currentTrack where !currentTrack.invalidated {
            let realm = RLMRealm.defaultRealm()
            let transact = !realm.inWriteTransaction
            if transact {
                currentTrack.realm.beginWriteTransaction()
            }
            let location = TrackLocation.build(location)
            currentTrack.locations.addObject(location)
            if transact {
                currentTrack.realm.commitWriteTransaction()
            }
            currentTrack.recalculate()
//            println("Tracked location: \(location.location())")
        }
    }
}


// MARK: - ObjC compatibility

extension TrackingHandler {
    
    class func sharedInstance() -> TrackingHandler {
        return trackingHandler
    }
}
