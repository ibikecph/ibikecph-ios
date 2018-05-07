//
//  StatsNotificationHandler.swift
//  I Bike CPH
//
//  Created by Tobias Due Munk on 09/03/15.
//  Copyright (c) 2015 I Bike CPH. All rights reserved.
//

import UIKit
import SwiftyUserDefaults

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
    
    fileprivate var storeKey: String { return "MilestoneLatest" + uniqueKey }
    /// Last milestone presented to the user
    func latestPresentedValue() -> Int? {
        return Defaults[storeKey].int
    }
    func setLatestPresentedValue(_ newValue: Int) {
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
        case present(description: String, milestone: Milestone)
        case `false`
    }

    func shouldPresent(forValue value: Int) -> Response {
        let nextMilestone = nextMilestoneToPresentToUser()
        if value >= nextMilestone, let index = values.index(of: nextMilestone) {
            let reducedValue = nextMilestone / valueDividerForDescription
            let description = String(format: descriptions[index].localized, reducedValue)
            setLatestPresentedValue(value)
            return .present(description: description, milestone: self)
        }
        return .false
    }
}



let statsNotificationHandler = StatsNotificationHandler()

class StatsNotificationHandler {
    
    enum NotificationCategory {
        case totalDistance
        case dayStreak
    }
    
    fileprivate var distanceMilestone = Milestone(
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
    fileprivate var daystreakMilestone = Milestone(
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
    fileprivate var observerTokens = [AnyObject]()

    init() {
        setupLocalNotifications()
        setupTracksObserver()
        setupSettingsObserver()
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
    
    fileprivate func setupLocalNotifications() {
        Notifications.register()
    }
    
    fileprivate func setupTracksObserver() {
        observerTokens.append(NotificationCenter.observe(processedBigNoticationKey) { [weak self] notification in
            self?.updateToTrackData()
        })
    }
    
    fileprivate func setupSettingsObserver() {
        observerTokens.append(NotificationCenter.observe(settingsUpdatedNotification) { [weak self] notification in
            self?.updateToTrackData()
        })
    }
    
    fileprivate func updateToTrackData() {
        // Weekly
        let now = Date()
        if let
            correctTimeToday = now.withComponents(hour: 18, minute: 0, second: 0),
            let nextSundayAt18 = now.nextWeekday(1, fromDate: correctTimeToday)
        {
            // Cancel previously set notification
            if let existingNotification = Notifications.localNotificationScheduledAtDate(nextSundayAt18) {
                Notifications.cancelScheduledLocalNotification(existingNotification)
            }
            //  Schedule new notification, if setting is on
            if Settings.sharedInstance.tracking.weeklyStatusNotifications {
                // Update notification with latest statistics
                let durationThisWeek = round(BikeStatistics.durationThisWeek()/60)*60 // Round to minutes
                let calendar = Calendar.current
                let unitFlags: NSCalendar.Unit = [.hour, .minute]
                let components = (calendar as NSCalendar).components(unitFlags, from: Date(), to: Date(timeIntervalSinceNow: durationThisWeek), options: NSCalendar.Options(rawValue: 0))
                let description = String(format: "weekly_status_description".localized, BikeStatistics.distanceThisWeek()/1000, components.hour!, components.minute!)
                Notifications.scheduleLocalNotification(description, fireDate: nextSundayAt18)
            }
        }
        
        // Distance
        let currentTotalDistance = Int(floor(BikeStatistics.totalDistance()))
        switch distanceMilestone.shouldPresent(forValue: currentTotalDistance) {
            case .present(let description, let milestone):
                addNotificationToQueue(description, milestone: milestone)
            case .false: break // Do nothing
        }
        
        // Day streak
        let currentDaystreak = BikeStatistics.currentDayStreak()
        switch daystreakMilestone.shouldPresent(forValue: currentDaystreak) {
            case .present(let description, let milestone):
                addNotificationToQueue(description, milestone: milestone)
            case .false: break // Do nothing
        }
        
        // Check if notifications should be presented to user
        checkPresentNotificationToUser()
    }
    
    fileprivate func storeKeyForMilestone(_ milestone: Milestone) -> String {
        return "NotificationQueue" + milestone.uniqueKey
    }
    
    fileprivate func addNotificationToQueue(_ description: String, milestone: Milestone) {
        Defaults[storeKeyForMilestone(milestone)] = description
    }
    
    func checkPresentNotificationToUser() {
        // Check if milestones is even on
        if !Settings.sharedInstance.tracking.milestoneNotifications {
            return
        }
        // Check that user didn't bike within last 5 min.
        if let interval = BikeStatistics.lastTrackEndDate()?.timeIntervalSinceNow, -interval < 5*60 {
            return
        }
        // Present pending milestones
        for milestone in [distanceMilestone, daystreakMilestone] {
            if let descripionToPresent = Defaults[storeKeyForMilestone(milestone)].string {
                let succeeded = tryPresentNotification(descripionToPresent)
                if succeeded {
                    Defaults[storeKeyForMilestone(milestone)] = nil
                }
            }
        }
    }
    
    fileprivate func tryPresentNotification(_ description: String) -> Bool {
        let fireDate = Date().addingTimeInterval(1)
        Notifications.scheduleLocalNotification(description, fireDate: fireDate)
        return true
    }
}


// MARK: - ObjC compatibility

extension StatsNotificationHandler {
    
    class func sharedInstance() -> StatsNotificationHandler {
        return statsNotificationHandler
    }
}
