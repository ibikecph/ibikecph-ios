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

class TrackingHandler: NSObject {
    var isCurrentlyRouting: Bool = false
    
    fileprivate var currentTrack: Track?
    
    fileprivate let thread: Thread = {
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
                    do {
                        try RLMRealm.default().transaction() { [weak self] in
                            if let track = self?.currentTrack, !track.isInvalidated {
                                print("Tracking: Add new activity")
                                let newActivity = TrackActivity.build(activity)
                                track.activity.deleteFromRealm() // Delete current
                                track.activity = newActivity
                            }
                        }
                    } catch let error as NSError {
                       print("Realm transaction failed: \(error.description)")
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
    fileprivate var observerTokens = [AnyObject]()
    
    override init() {
        super.init()
        setup()
        check()
    }
    
    deinit {
        unobserve()
    }
    
    fileprivate func unobserve() {
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
                do {
                    try RLMRealm.default().transaction() { [weak self] in
                        if let currentTrack = self?.currentTrack, !currentTrack.isInvalidated && currentTrack.activity.realm != nil && currentTrack.activity.sameActivityTypeAs(cmMotionActivity: activity) {
                            print("Tracking: New confidence for activity")
                            // Activity just updated it's confidence
                            currentTrack.activity.confidence = activity.confidence.rawValue
                            return
                        }
                        Async.main {
                            print("Tracking: Set new activity")
                            self?.currentActivity = activity
                        }
                    }
                } catch let error as NSError {
                   print("Realm transaction failed: \(error.description)")
                }
            }
        }
    }
    
    func setupBackgroundHandling() {
        observerTokens.append(NotificationCenter.observe(NSNotification.Name.UIApplicationDidEnterBackground) { notification in
            if Settings.sharedInstance.tracking.on {
                return
            }
            // TODO: Revisit functionality of isCurrentlyRouting
            if Settings.sharedInstance.readAloud.on && self.isCurrentlyRouting {
                return
            }
            // Stop location manager
            SMLocationManager.sharedInstance().stopUpdating()
        })
        observerTokens.append(NotificationCenter.observe(NSNotification.Name.UIApplicationWillEnterForeground) { notification in
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
        print("Start tracking")
        
        // Start location manager
        SMLocationManager.sharedInstance().startUpdating()
        
        // Initialize track
        thread.enqueue() { [weak self] in
            do {
                try RLMRealm.default().transaction() { [weak self] in
                    print("Tracking: New track")
                    self?.currentTrack = Track()
                    self?.currentTrack!.addToRealm()
                }
            } catch let error as NSError {
               print("Realm transaction failed: \(error.description)")
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
            do {
                try RLMRealm.default().transaction() { [weak self] in
                    if let currentTrack = self?.currentTrack, !currentTrack.isInvalidated {
                        currentTrack.recalculate()
                    }
                }
                print("Tracking: End track")
                self?.currentTrack = nil
                
                TracksHandler.setNeedsProcessData()
            } catch let error as NSError {
               print("Realm transaction failed: \(error.description)")
            }
        }
    }
    
    func add(_ locations: [CLLocation]) {
        if currentTrack == nil {
            return
        }
        thread.enqueue() { [weak self] in
            do {
                try RLMRealm.default().transaction() { [weak self] in
                    if let currentTrack = self?.currentTrack, !currentTrack.isInvalidated {
                        for location in locations {
                            let location = TrackLocation.build(location)
                            currentTrack.locations.add(location)
                        }
                    }
                }
            } catch {
                print("Realm transaction failed!")
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
