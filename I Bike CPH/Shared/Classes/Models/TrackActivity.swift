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
    
    func sameActivityTypeAs(activity: TrackActivity) -> Bool {
        let stationary = self.stationary == activity.stationary
        let walking = self.walking == activity.walking
        let cycling = self.cycling == activity.cycling
        let running = self.running == activity.running
        let automotive = self.automotive == activity.automotive
        return stationary && walking && cycling && running && automotive
    }
    
    func moving() -> Bool {
        let movingType = walking || cycling || running || automotive
        return !stationary && movingType
    }
    
    func empty() -> Bool {
        let hasContent = unknown || stationary || walking || cycling || running || automotive
        return !hasContent
    }
}
