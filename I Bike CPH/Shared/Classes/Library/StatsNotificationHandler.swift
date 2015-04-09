//
//  StatsNotificationHandler.swift
//  I Bike CPH
//
//  Created by Tobias Due Munk on 09/03/15.
//  Copyright (c) 2015 I Bike CPH. All rights reserved.
//

import UIKit


struct Milestone {
    let uniqueKey: String
    let values: [Int]
    let descriptions: [String]
    let valueDividerForDescription: Int
    
    init (uniqueKey: String, values: [Int], descriptions: [String], valueDividerForDescription: Int = 0) {
        self.uniqueKey = uniqueKey
        self.values = values
        self.descriptions = descriptions
        self.valueDividerForDescription = valueDividerForDescription
    }
    
    private var storeKey: String { return "MilestoneLatest" + uniqueKey }
    /// Last milestone presented to the user
    func latestPresentedValue() -> Int? {
        return Defaults[storeKey].int
    }
    func setLatestPresentedValue(newValue: Int) {
        Defaults[storeKey] = newValue
    }
    
    func nextMilestoneToPresentToUser() -> Int {
        if let latestPresentedValue = latestPresentedValue() {
            if let nextMilestone = values.filter({$0 > latestPresentedValue}).first {
                return nextMilestone
            } else {
                // Beyond array, add a last value as consecutive step
                return latestPresentedValue + values.last!
            }
        }
        // No value ever stored
        return values.first!
    }
    
    
    enum Response {
        case Present(description: String, milestone: Milestone)
        case False
    }

    func shouldPresent(forValue value: Int) -> Response {
        let nextMilestone = nextMilestoneToPresentToUser()
        if value >= nextMilestone {
            if let index = find(values, nextMilestone) {
                let reducedValue = nextMilestone / valueDividerForDescription
                let description = String(format: descriptions[index].localized, reducedValue)
                setLatestPresentedValue(value)
                return .Present(description: description, milestone: self)
            }
        }
        return .False
    }
}



let statsNotificationHandler = StatsNotificationHandler()

class StatsNotificationHandler {
    
    enum NotificationCategory {
        case TotalDistance
        case DayStreak
    }
   
    private var token: RLMNotificationToken?
    
    private var distanceMilestone = Milestone(
        uniqueKey: "distanceMilestone",
        values: [10000, 50000, 100000, 250000, 500000, 750000, 1000000],
        descriptions: [
            "milestone_distance_1_description",
            "milestone_distance_2_description",
            "milestone_distance_3_description",
            "milestone_distance_4_description",
            "milestone_distance_5_description",
            "milestone_distance_6_description",
            "milestone_distance_7_description"],
        valueDividerForDescription: 1000
    )
    private var daystreakMilestone = Milestone(
        uniqueKey: "daystreakMilestone",
        values: [3, 5, 10, 15, 20, 25, 30],
        descriptions: [
            "milestone_daystreak_1_description",
            "milestone_daystreak_2_description",
            "milestone_daystreak_3_description",
            "milestone_daystreak_4_description",
            "milestone_daystreak_5_description",
            "milestone_daystreak_6_description",
            "milestone_daystreak_7_description"],
        valueDividerForDescription: 1
    )

    init() {
        setupLocalNotifications()
        setupTracksObserver()
    }
    
    deinit {
        RLMRealm.removeNotification(token)
    }
    
    private func setupLocalNotifications() {
        let settings = UIUserNotificationSettings(forTypes: .Alert, categories: nil)
        UIApplication.sharedApplication().registerUserNotificationSettings(settings)
    }
    
    private func setupTracksObserver() {
        token = RLMRealm.addNotificationBlock() { [unowned self] note, realm in
            self.updateToTrackData()
        }
    }
    
    private func updateToTrackData() {
        // Distance
        let currentTotalDistance = Int(floor(BikeStatistics.totalDistance()))
        switch distanceMilestone.shouldPresent(forValue: currentTotalDistance) {
            case .Present(let description, let milestone):
                addNotificationToQueue(description, milestone: milestone)
            case .False: break // Do nothing
        }
        // Day streak
        let currentDaystreak = BikeStatistics.currentDayStreak()
        switch daystreakMilestone.shouldPresent(forValue: currentDaystreak) {
            case .Present(let description, let milestone):
                addNotificationToQueue(description, milestone: milestone)
            case .False: break // Do nothing
        }
        
        // Check if notifications should be presented to user
        checkPresentNotificationToUser()
    }
    
    private func storeKeyForMilestone(milestone: Milestone) -> String {
        return "NotificationQueue" + milestone.uniqueKey
    }
    
    private func addNotificationToQueue(description: String, milestone: Milestone) {
        Defaults[storeKeyForMilestone(milestone)] = description
    }
    
    func checkPresentNotificationToUser() {
        if !settings.tracking.milestoneNotifications {
            return
        }
        for milestone in [distanceMilestone, daystreakMilestone] {
            if let descripionToPresent = Defaults[storeKeyForMilestone(milestone)].string {
                let succeeded = tryPresentNotification(descripionToPresent)
                if succeeded {
                    Defaults[storeKeyForMilestone(milestone)] = nil
                }
            }
        }
    }
    
    private func tryPresentNotification(description: String) -> Bool {
        let fireDate = NSDate().dateByAddingTimeInterval(1)
        let notification = UILocalNotification()
        notification.fireDate = fireDate
        notification.alertBody = description
        notification.applicationIconBadgeNumber = 0
        UIApplication.sharedApplication().scheduleLocalNotification(notification)
        return true
    }
}


// MARK: - ObjC compatibility

extension StatsNotificationHandler {
    
    class func sharedInstance() -> StatsNotificationHandler {
        return statsNotificationHandler
    }
}
