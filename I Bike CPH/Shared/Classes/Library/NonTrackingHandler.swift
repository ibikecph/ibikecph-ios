//
//  NonTrackingHandler.swift
//  I Bike CPH
//
//  Copyright (c) 2016 I Bike CPH. All rights reserved.
//

import Foundation
import CoreLocation
import CoreMotion

let nonTrackingHandler = NonTrackingHandler()

@objc class NonTrackingHandler {

    private var observerTokens = [AnyObject]()
    
    init() {
        setupBackgroundHandling()
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
    
    func setupBackgroundHandling() {
        observerTokens.append(NotificationCenter.observe(UIApplicationDidEnterBackgroundNotification) { notification in
            // TODO: Check if app is routing
            let currentlyRouting = false // WARNING: FIXME: get actual value
            if Settings.sharedInstance.voice.on && currentlyRouting {
                return
            }
            // Stop location manager
            SMLocationManager.sharedInstance().stopUpdating()
        })
        observerTokens.append(NotificationCenter.observe(UIApplicationWillEnterForegroundNotification) { notification in
            SMLocationManager.sharedInstance().startUpdating()
        })
    }
}

// MARK: - ObjC compatibility

extension NonTrackingHandler {
    
    class func sharedInstance() -> NonTrackingHandler {
        return nonTrackingHandler
    }
}
