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

class NonTrackingHandler: NSObject {
    
    var isCurrentlyRouting: Bool = false

    private var observerTokens = [AnyObject]()
    
    override init() {
        super.init()
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
}

// MARK: - ObjC compatibility

extension NonTrackingHandler {
    
    class func sharedInstance() -> NonTrackingHandler {
        return nonTrackingHandler
    }
}
