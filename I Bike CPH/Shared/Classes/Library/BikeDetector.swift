//
//  BikeDetector.swift
//  I Bike CPH
//
//  Created by Tobias Due Munk on 16/02/15.
//  Copyright (c) 2015 I Bike CPH. All rights reserved.
//

import Foundation
import CoreMotion

class BikeDetector {
    
    var motionActivityManager: CMMotionActivityManager?
    
    init() {
        
    }
    
    func isAvailable() -> Bool {
        return CMMotionActivityManager.isActivityAvailable()
    }
    
    func start(handler: (biking: Bool) -> ()) {
        if !isAvailable() {
            return
        }
        let manager = CMMotionActivityManager()
        manager.startActivityUpdatesToQueue(NSOperationQueue.mainQueue()) { activity in
            println("stationary: \(activity.stationary), bike: \(activity.cycling),  walk: \(activity.walking), run: \(activity.running), automotive: \(activity.automotive), unkown: \(activity.unknown), confidence: \(activity.confidence.rawValue), start: \(activity.startDate), ")
            let isBiking = activity.cycling
            handler(biking: isBiking)
        }
        self.motionActivityManager = manager
    }
    
    func stop() {
        if let motionActivityManager = motionActivityManager {
            motionActivityManager.stopActivityUpdates()
        }
        motionActivityManager = nil
    }
}