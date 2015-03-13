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
    let valueDividerForDescription = 1
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
        let currentDaystreak = 3 // TODO: Use real value
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






//protocol NotificationProtocol {
//    var description: String { get }
//}
//
//protocol NotificationMilestoneProtocol: Comparable {
////    var latestPresentedMilestone: <T: where NotificationMilestoneProtocol> { get set }
//}
//
//
//let latestPresentedTotalDistanceMilestoneKey = "latestPresentedTotalDistanceMilestoneKey"
//class TotalDistanceNotification {
//    enum Milestone: NotificationMilestoneProtocol, SequenceType {
//        case First
//        case Second
//        case Third
//        case Fourth
//        case Fifth
//        case Sixth
//        case Seventh
//        case Consecutive(Double)
//
//        func distance() -> Double {
//            switch self {
//                case .First: return 10000
//                case .Second: return 50000
//                case .Third: return 100000
//                case .Fourth: return 250000
//                case .Fifth: return 500000
//                case .Sixth: return 750000
//                case .Seventh: return 1000000
//                case .Consecutive(let distance): return distance
//            }
//        }
//
//        func generate() -> GeneratorOf<Milestone> {
//            var i = 0
//            return GeneratorOf<Milestone> {
//                switch i {
//                    case 0: return .First
//                    case 1: return .Second
//                    case 2: return .Third
//                    case 3: return .Fourth
//                    case 4: return .Fifth
//                    case 5: return .Sixth
//                    case 6: return .Seventh
//                    case let _i:
//                        let step = _i - 6
//                        let distance = TotalDistanceNotification.firstConsecutiveDistance() + Double(step) * TotalDistanceNotification.consecutiveDistanceStep()
//                        return .Consecutive(distance)
//                }
//            }
//        }
//    }
//
//    /// Last milestone presented to the user
//    class func latestPresentedMilestone() -> Double? {
//        return Defaults[latestPresentedTotalDistanceMilestoneKey].double
//    }
//    class func setLatestPresentedMilestone(distance: Double) {
//        Defaults[latestPresentedTotalDistanceMilestoneKey] = distance
//    }
//
//    class func consecutiveDistanceStep() -> Double {
//        return Milestone.Seventh.distance()
//    }
//
//    class func firstConsecutiveDistance() -> Double {
//        return Milestone.Seventh.distance() + consecutiveDistanceStep()
//    }
//
//    class func lowestConsecutiveMilestone() -> Milestone {
//        return .Consecutive(firstConsecutiveDistance())
//    }
//
//    class func milestoneForDistance(distance: Double) -> Milestone? {
//        switch distance {
//            case Milestone.First.distance() ..< Milestone.Second.distance():
//                return .First
//            case Milestone.Second.distance() ..< Milestone.Third.distance():
//                return .Second
//            case Milestone.Third.distance() ..< Milestone.Fourth.distance():
//                return .Third
//            case Milestone.Fourth.distance() ..< Milestone.Fifth.distance():
//                return .Fourth
//            case Milestone.Fifth.distance() ..< Milestone.Sixth.distance():
//                return .Fifth
//            case Milestone.Sixth.distance() ..< Milestone.Seventh.distance():
//                return .Sixth
//            case Milestone.Seventh.distance() ..< lowestConsecutiveMilestone().distance():
//                return .Seventh
//            default:
//                if distance >= lowestConsecutiveMilestone().distance() {
//                    return Milestone.Consecutive(distance)
//                }
//                return nil
//        }
//    }
//
//
//
//    class func nextMilestone(fromMilestone: Milestone) -> Milestone {
////        while let d = fromMilestone.generate().next() {
////
////        }
////        switch fromMilestone {
////            case .First: return .Second
////            case .Second: return .Third
////            case .Third: return .Fourth
////            case .Fourth: return .Fifth
////            case .Fourth: return .Fifth
////        }
//        return .First
//    }
//
//    class func nextMilestoneToPresentToUser(fromMilestone: Milestone) -> Milestone {
//        if let latestPresentedMilestone = latestPresentedMilestone() {
////            return milestoneFor
//        }
//        return .First
//    }
//
//
//    /**
//    Description like "Alright! You have cycled your first 10 km."
//
//    :param: distance in meters [m]
//    */
//    private func description(forMilestone milestone: Milestone, distance: Double) -> String {
//        let descriptionKey: String = {
//            switch milestone {
//                case .First: return "milestone_1_description"
//                case .Second: return "milestone_2_description"
//                case .Third: return "milestone_3_description"
//                case .Fourth: return "milestone_4_description"
//                case .Fifth: return "milestone_5_description"
//                case .Sixth: return "milestone_6_description"
//                case .Seventh: return "milestone_7_description"
//                case .Consecutive: return "milestone_7_description"
//            }
//        }()
//        return String(format: descriptionKey.localized, distance)
//    }
//
//    class func shouldPresent(forDistance distance: Double) -> Bool {
//        if let latestPresentedMilestone = latestPresentedMilestone() {
//
//        }
//        return false
//    }
//}
//
//func ==(lhs: TotalDistanceNotification.Milestone, rhs: TotalDistanceNotification.Milestone) -> Bool {
//    return lhs.distance() == rhs.distance()
//}
//func <(lhs: TotalDistanceNotification.Milestone, rhs: TotalDistanceNotification.Milestone) -> Bool {
//    return lhs.distance() < rhs.distance()
//}
