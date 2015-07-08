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
    
    private let thread: Thread = {
        let thread = Thread()
        thread.start()
        return thread
    }()
    
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
                thread.enqueue() { [weak self] in
                    RLMRealm.defaultRealm().transactionWithBlock() {
                        if let track = self?.currentTrack where !track.invalidated {
                            println("Tracking: Add new activity")
                            let newActivity = TrackActivity.build(activity)
                            track.activity.deleteFromRealm() // Delete current
                            track.activity = newActivity
                        }
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
        NotificationCenter.observe(settingsUpdatedNotification) { [weak self] notification in
            self?.setup()
        }
    }
    
    func setupMotionTracking() {
        if !Settings.instance.tracking.on {
            motionDetector.stop()
            return
        }
        if !motionDetector.isAvailable() {
            return
        }
        motionDetector.start { [weak self] activity in
            self!.thread.enqueue() {
                RLMRealm.defaultRealm().transactionWithBlock() {
                    if let currentTrack = self?.currentTrack where !currentTrack.invalidated && currentTrack.activity.sameActivityTypeAs(cmMotionActivity: activity) {
                        println("Tracking: New confidence for activity")
                        // Activity just updated it's confidence
                        currentTrack.activity.confidence = activity.confidence.rawValue
                        return
                    }
                    Async.main {
                        println("Tracking: Set new activity")
                        self?.currentActivity = activity
                    }
                }
            }
        }
    }
    
    func setupBackgroundHandling() {
        NSNotificationCenter.defaultCenter().addObserverForName(UIApplicationDidEnterBackgroundNotification, object: nil, queue: nil) { notification in
            if Settings.instance.tracking.on {
                return
            }
            // TODO: Check if app is routing
            let currentlyRouting = false // WARNING: FIXME: get actual value
            if Settings.instance.voice.on && currentlyRouting {
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
        if !Settings.instance.tracking.on {
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
        if !Settings.instance.tracking.on {
            return
        }
        statsNotificationHandler.checkPresentNotificationToUser()
    }
    
    func startTracking() {
        println("Start tracking")
        
        // Start location manager
        SMLocationManager.instance().start()
        
        // Initialize track
        thread.enqueue() { [weak self] in
            RLMRealm.defaultRealm().transactionWithBlock() {
                println("Tracking: New track")
                self?.currentTrack = Track()
                self?.currentTrack!.addToRealm()
            }
        }
    }
    
    func stopTracking() {
        if Settings.instance.tracking.on {
            // Idle location manager
            SMLocationManager.instance().idle()
        } else {
            // Stop location manager
            SMLocationManager.instance().stop()
        }
        
        thread.enqueue() { [weak self] in
            // Stop track
            RLMRealm.defaultRealm().transactionWithBlock() {
                if let currentTrack = self?.currentTrack where !currentTrack.invalidated {
                    currentTrack.recalculate()
                }
            }
            println("Tracking: End track")
            self?.currentTrack = nil
            
            TracksHandler.setNeedsProcessData()
        }
    }
    
    func add(location: CLLocation) {
        if currentTrack == nil {
            return
        }
        thread.enqueue() { [weak self] in
            RLMRealm.defaultRealm().transactionWithBlock() {
                if let currentTrack = self?.currentTrack where !currentTrack.invalidated {
                    println("Tracking: Add location")
                    let location = TrackLocation.build(location)
                    currentTrack.locations.addObject(location)
                    currentTrack.recalculate()
                }
                //            println("Tracked location: \(location.location())")
            }
        }
    }
}


// MARK: - ObjC compatibility

extension TrackingHandler {
    
    class func sharedInstance() -> TrackingHandler {
        return trackingHandler
    }
}
