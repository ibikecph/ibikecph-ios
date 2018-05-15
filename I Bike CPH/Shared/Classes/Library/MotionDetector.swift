//
//  MotionDetector.swift
//  I Bike CPH
//
//  Created by Tobias Due Munk on 16/02/15.
//  Copyright (c) 2015 I Bike CPH. All rights reserved.
//

import Foundation
import CoreMotion

class MotionDetector {
    
    var motionActivityManager: CMMotionActivityManager?
    
    init() {
        
    }
    
    func isAvailable() -> Bool {
        return CMMotionActivityManager.isActivityAvailable()
    }
    
    func start(_ handler: @escaping (_ activity: CMMotionActivity) -> ()) {
        if !isAvailable() {
            return
        }
        print("Start activity updates")
        let manager = CMMotionActivityManager()
        manager.startActivityUpdates(to: OperationQueue.main) { act in
            guard let activity = act else {
               return
            }
            guard Settings.sharedInstance.tracking.on else {
                return // Received activity even though it should have been stopped
            }
            print("stationary: \(activity.stationary), bike: \(activity.cycling),  walk: \(activity.walking), run: \(activity.running), automotive: \(activity.automotive), unknown: \(activity.unknown), confidence: \(activity.confidence.rawValue), start: \(activity.startDate), ")
            handler(activity)
        }
        self.motionActivityManager = manager
    }
    
    func stop() {
        print("Stop activity updates")
        if let motionActivityManager = motionActivityManager {
            motionActivityManager.stopActivityUpdates()
        }
        motionActivityManager = nil
    }
}
