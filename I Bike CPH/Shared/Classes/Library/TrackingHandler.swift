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

class TrackingHandler {
    var isCurrentlyRouting: Bool = false
    
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
                    RLMRealm.defaultRealm().transactionWithBlock() { [weak self] in
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
        #else
            return motionDetector.isAvailable()
        #endif
    }
    private var observerTokens = [AnyObject]()
    
    init() {
        setup()
        check()
    }
    
    deinit {
        unobserve()
    }
    
    private func unobserve() {
        for observerToken in observerTokens {
            NotificationCenter.unobserve(observerToken)
        }
        NotificationCenter.unobserve(self)
    }
    
    func setup() {
        setupSettingsObserver()
        setupBackgroundHandling()
        setupLocationObserver()
    }
    
    func check() {
        checkMotionTracking()
        checkMilestoneNotification()
    }
    
    func setupSettingsObserver() {
        observerTokens.append(NotificationCenter.observe(settingsUpdatedNotification) { [weak self] notification in
            self?.check()
        })
    }
    
    func checkMotionTracking() {
        if !Settings.sharedInstance.tracking.on {
            motionDetector.stop()
            return
        }
        if !motionDetector.isAvailable() {
            return
        }
        motionDetector.start { [weak self] activity in
            self!.thread.enqueue() { [weak self] in
                RLMRealm.defaultRealm().transactionWithBlock() { [weak self] in
                    if let currentTrack = self?.currentTrack where !currentTrack.invalidated && currentTrack.activity.realm != nil && currentTrack.activity.sameActivityTypeAs(cmMotionActivity: activity) {
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
        observerTokens.append(NotificationCenter.observe(UIApplicationDidEnterBackgroundNotification) { notification in
            if Settings.sharedInstance.tracking.on {
                return
            }
            // TODO: Revisit functionality of isCurrentlyRouting
            if Settings.sharedInstance.voice.on && self.isCurrentlyRouting {
                return
            }
            // Stop location manager
            SMLocationManager.sharedInstance().stopUpdating()
        })
        observerTokens.append(NotificationCenter.observe(UIApplicationWillEnterForegroundNotification) { notification in
            SMLocationManager.sharedInstance().startUpdating()
        })
    }
    
    func setupLocationObserver() {
        observerTokens.append(NotificationCenter.observe("refreshPosition") { notification in
            if let locations = notification.userInfo?["locations"] as? [CLLocation] {
                self.add(locations)
            }
        })
    }
    
    func checkMilestoneNotification() {
        if !Settings.sharedInstance.tracking.on {
            return
        }
        statsNotificationHandler.checkPresentNotificationToUser()
    }
    
    func startTracking() {
        println("Start tracking")
        
        // Start location manager
        SMLocationManager.sharedInstance().startUpdating()
        
        // Initialize track
        thread.enqueue() { [weak self] in
            RLMRealm.defaultRealm().transactionWithBlock() { [weak self] in
                println("Tracking: New track")
                self?.currentTrack = Track()
                self?.currentTrack!.addToRealm()
            }
        }
    }
    
    func stopTracking() {
        if Settings.sharedInstance.tracking.on {
            // Idle location manager
            SMLocationManager.sharedInstance().idleUpdating()
        } else {
            // Stop location manager
            SMLocationManager.sharedInstance().stopUpdating()
        }
        
        thread.enqueue() { [weak self] in
            // Stop track
            RLMRealm.defaultRealm().transactionWithBlock() { [weak self] in
                if let currentTrack = self?.currentTrack where !currentTrack.invalidated {
                    currentTrack.recalculate()
                }
            }
            println("Tracking: End track")
            self?.currentTrack = nil
            
            TracksHandler.setNeedsProcessData()
        }
    }
    
    func add(locations: [CLLocation]) {
        if currentTrack == nil {
            return
        }
        thread.enqueue() { [weak self] in
            RLMRealm.defaultRealm().transactionWithBlock() { [weak self] in
                if let currentTrack = self?.currentTrack where !currentTrack.invalidated {
                    for location in locations {
                        let location = TrackLocation.build(location)
                        currentTrack.locations.addObject(location)
                    }
                }
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
