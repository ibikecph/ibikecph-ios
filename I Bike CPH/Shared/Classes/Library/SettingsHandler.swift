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

extension DefaultsKeys {
    // Voice Settings
    static let voiceOn = DefaultsKey<Bool>("voiceOn")
   
    // Tracking Settings
    static let trackingOn = DefaultsKey<Bool>("trackingOn")
    static let milestoneNotificationsOn = DefaultsKey<Bool>("milestoneNotifications")
    static let weeklyStatusNotificationsOn = DefaultsKey<Bool>("weeklyStatusNotifications")
    
    // Turnstile Settings
    static let turnstileDidSeeActivateTracking = DefaultsKey<Bool>("turnstileDidSeeActivateTrackingKey")
    static let turnstileDidSeeGreenestRouteIntroduction = DefaultsKey<Bool>("turnstileDidSeeGreenestRouteIntroductionKey")
    
    // Overlays Settings
    static let showBikeServiceStationsOverlay = DefaultsKey<Bool>("overlayBikeServiceStationsKey")
    static let showCycleSuperHighwaysOverlay = DefaultsKey<Bool>("overlayCycleSuperHighways")
    static let showHarborRingOverlay = DefaultsKey<Bool>("overlayHarborRingKey")
    static let showGreenPathsOverlay = DefaultsKey<Bool>("overlayGreenPathsKey")
}

class Settings: NSObject {
    static let sharedInstance = Settings()
    
    let voice = VoiceSettings()
    let tracking = TrackingSettings()
    let overlays = OverlaysSettings()
    let turnstile = TurnstileSettings()
    
    func clear() {
        if let bundleID = NSBundle.mainBundle().bundleIdentifier {
            Defaults.removePersistentDomainForName(bundleID)
        }
    }
}

class VoiceSettings {
    var on: Bool {
        get { return Defaults[.voiceOn] ?? false }
        set {
            Defaults[.voiceOn] = newValue
            NotificationCenter.post(settingsUpdatedNotification, object: self)
        }
    }
}

class TrackingSettings {
    var on: Bool {
        get { return Defaults[.trackingOn] ?? false }
        set {
            Defaults[.trackingOn] = newValue
            NotificationCenter.post(settingsUpdatedNotification, object: self)
        }
    }
    var milestoneNotifications: Bool {
        get { return Defaults[.milestoneNotificationsOn] ?? true }
        set {
            Defaults[.milestoneNotificationsOn] = newValue
            NotificationCenter.post(settingsUpdatedNotification, object: self)
        }
    }
    var weeklyStatusNotifications: Bool {
        get { return Defaults[.weeklyStatusNotificationsOn] ?? true }
        set {
            Defaults[.weeklyStatusNotificationsOn] = newValue
            NotificationCenter.post(settingsUpdatedNotification, object: self)
        }
    }
}

class TurnstileSettings {
    var didSeeActivateTracking: Bool {
        get { return Defaults[.turnstileDidSeeActivateTracking] ?? false }
        set {
            Defaults[.turnstileDidSeeActivateTracking] = newValue
            NotificationCenter.post(settingsUpdatedNotification, object: self)
        }
    }
    
    var didSeeGreenestRouteIntroduction: Bool {
        get { return Defaults[.turnstileDidSeeGreenestRouteIntroduction] ?? false }
        set {
            Defaults[.turnstileDidSeeGreenestRouteIntroduction] = newValue
            NotificationCenter.post(settingsUpdatedNotification, object: self)
        }
    }
}

class OverlaysSettings: NSObject {
    var showBikeServiceStations: Bool {
        get { return Defaults[.showBikeServiceStationsOverlay] ?? false }
        set {
            Defaults[.showBikeServiceStationsOverlay] = newValue
            NotificationCenter.post(settingsUpdatedNotification, object: self)
        }
    }
    var showCycleSuperHighways: Bool {
        get {
            return false // Disable until routes are updated
//            return Defaults[.showCycleSuperHighwaysOverlay] ?? false
        }
        set {
            Defaults[.showCycleSuperHighwaysOverlay] = newValue
            NotificationCenter.post(settingsUpdatedNotification, object: self)
        }
    }
    var showHarborRing: Bool {
        get { return Defaults[.showHarborRingOverlay] ?? false }
        set {
            Defaults[.showHarborRingOverlay] = newValue
            NotificationCenter.post(settingsUpdatedNotification, object: self)
        }
    }
    var showGreenPaths: Bool {
        get { return Defaults[.showGreenPathsOverlay] ?? false }
        set {
            Defaults[.showGreenPathsOverlay] = newValue
            NotificationCenter.post(settingsUpdatedNotification, object: self)
        }
    }
}