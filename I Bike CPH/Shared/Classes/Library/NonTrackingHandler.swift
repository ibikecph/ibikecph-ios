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

    fileprivate var observerTokens = [AnyObject]()
    
    override init() {
        super.init()
        setupBackgroundHandling()
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
    
    func setupBackgroundHandling() {
        observerTokens.append(NotificationCenter.observe(NSNotification.Name.UIApplicationDidEnterBackground.rawValue) { notification in
            // TODO: Revisit functionality of isCurrentlyRouting
            if Settings.sharedInstance.readAloud.on && self.isCurrentlyRouting {
                return
            }
            // Stop location manager
            SMLocationManager.sharedInstance().stopUpdating()
        })
        observerTokens.append(NotificationCenter.observe(NSNotification.Name.UIApplicationWillEnterForeground.rawValue) { notification in
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
