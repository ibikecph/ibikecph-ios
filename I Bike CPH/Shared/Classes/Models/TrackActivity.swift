//
//  TrackActivity.swift
//  I Bike CPH
//
//  Created by Tobias Due Munk on 20/02/15.
//  Copyright (c) 2015 I Bike CPH. All rights reserved.
//

import CoreMotion

class TrackActivity: RLMObject {
    dynamic var unknown = false
    dynamic var stationary = false
    dynamic var walking = false
    dynamic var running = false
    dynamic var automotive = false
    dynamic var cycling = false
    dynamic var startDate = NSDate()
    
    class func build(activity: CMMotionActivity) -> TrackActivity {
        var newActivity = TrackActivity()
        newActivity.unknown = activity.unknown
        newActivity.stationary = activity.stationary
        newActivity.walking = activity.walking
        newActivity.running = activity.running
        newActivity.automotive = activity.automotive
        newActivity.cycling = activity.cycling
        newActivity.startDate = activity.startDate
        return newActivity
    }
}
