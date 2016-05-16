//
//  SettingsHandler.swift
//  I Bike CPH
//
//  Created by Tobias Due Munk on 26/01/15.
//  Copyright (c) 2015 I Bike CPH. All rights reserved.
//

import UIKit
import SwiftyUserDefaults

let settingsUpdatedNotification = "settingsUpdatedNotification"

class Settings: NSObject {
    static let sharedInstance = Settings()
    
    let voice = VoiceSettings()
    let tracking = TrackingSettings()
    let overlays = OverlaysSettings()
    let onboarding = OnboardingSettings()
    
    func clear() {
        if let bundleID = NSBundle.mainBundle().bundleIdentifier {
            Defaults.removePersistentDomainForName(bundleID)
        }
    }
}

class VoiceSettings {
    private let onKey = "voiceOn"
    var on: Bool {
        get { return Defaults[onKey].bool ?? false }
        set {
            Defaults[onKey] = newValue
            NotificationCenter.post(settingsUpdatedNotification, object: self)
        }
    }
}

class TrackingSettings {
    private let onKey = "trackingOn"
    var on: Bool {
        get { return Defaults[onKey].bool ?? false }
        set {
            Defaults[onKey] = newValue
            NotificationCenter.post(settingsUpdatedNotification, object: self)
        }
    }
    private let milestoneNotificationsKey = "milestoneNotifications"
    var milestoneNotifications: Bool {
        get { return Defaults[milestoneNotificationsKey].bool ?? true }
        set {
            Defaults[milestoneNotificationsKey] = newValue
            NotificationCenter.post(settingsUpdatedNotification, object: self)
        }
    }
    private let weeklyStatusNotificationsKey = "weeklyStatusNotifications"
    var weeklyStatusNotifications: Bool {
        get { return Defaults[weeklyStatusNotificationsKey].bool ?? true }
        set {
            Defaults[weeklyStatusNotificationsKey] = newValue
            NotificationCenter.post(settingsUpdatedNotification, object: self)
        }
    }
}

class OnboardingSettings {
    private let onboardingDidSeeActivateTrackingKey = "onboardingDidSeeActivateTrackingKey"
    var didSeeActivateTracking: Bool {
        get { return Defaults[onboardingDidSeeActivateTrackingKey].bool ?? false }
        set {
            Defaults[onboardingDidSeeActivateTrackingKey] = newValue
            NotificationCenter.post(settingsUpdatedNotification, object: self)
        }
    }
}

class OverlaysSettings: NSObject {
    private let bikeServiceStationsKey = "overlayBikeServiceStationsKey"
    var showBikeServiceStations: Bool {
        get { return Defaults[bikeServiceStationsKey].bool ?? false }
        set {
            Defaults[bikeServiceStationsKey] = newValue
            NotificationCenter.post(settingsUpdatedNotification, object: self)
        }
    }
    private let cycleSuperHighwaysKey = "overlayCycleSuperHighways"
    var showCycleSuperHighways: Bool {
        get {
            return false // Disable until routes are updated
//            return Defaults[cycleSuperHighwaysKey].bool ?? false
        }
        set {
            Defaults[cycleSuperHighwaysKey] = newValue
            NotificationCenter.post(settingsUpdatedNotification, object: self)
        }
    }
    private let harborRingKey = "overlayHarborRingKey"
    var showHarborRing: Bool {
        get { return Defaults[harborRingKey].bool ?? false }
        set {
            Defaults[harborRingKey] = newValue
            NotificationCenter.post(settingsUpdatedNotification, object: self)
        }
    }
    private let greenPathsKey = "overlayGreenPathsKey"
    var showGreenPaths: Bool {
        get { return Defaults[greenPathsKey].bool ?? false }
        set {
            Defaults[greenPathsKey] = newValue
            NotificationCenter.post(settingsUpdatedNotification, object: self)
        }
    }
}