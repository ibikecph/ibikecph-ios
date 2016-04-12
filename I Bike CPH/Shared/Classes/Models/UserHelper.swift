//
//  UserHelper.swift
//  I Bike CPH
//
//  Created by Tobias Due Munk on 12/01/15.
//  Copyright (c) 2015 I Bike CPH. All rights reserved.
//

import Foundation

@objc class UserHelper {
    
    enum EnableTrackingOptions {
        case Allowed, LacksTrackToken, NotLoggedIn
    }
    
    class func authToken() -> String? {
        return AppHelper.delegate()?.appSettings["auth_token"] as? String
    }
    
    class func id() -> String? {
        let id: AnyObject? = AppHelper.delegate()?.appSettings["id"]
        if let id: AnyObject = id {
            return "\(id)"
        }
        return nil
    }
    
    class func email() -> String? {
        return AppHelper.delegate()?.appSettings["email"] as? String ?? AppHelper.delegate()?.appSettings["username"] as? String // Fallback to "username" previous version of the app
    }
    
    class func loggedIn() -> Bool {
        return authToken() != nil
    }
    
    class func isFacebook() -> Bool {
        if let loginType = AppHelper.delegate()?.appSettings["loginType"] as? String {
            return loginType == "FB"
        }
        return false
    }
    
    class func logout() {
        Settings.sharedInstance.tracking.on = false // Turn off tracking when logging out
        AppHelper.delegate()?.clearSettings()
        SMFavoritesUtil.saveFavorites(nil)
    }
    
    class func trackToken() -> String? {
        return AppHelper.delegate()?.appSettings["signature"] as? String
    }
    
    class func checkEnableTracking() -> EnableTrackingOptions {
        let isLoggedIn = UserHelper.loggedIn()
        let isFacebook = UserHelper.isFacebook()
        let hasTrackToken = UserHelper.trackToken() != nil
        
        if !isLoggedIn {
            return .NotLoggedIn
        }
        if hasTrackToken {
            return .Allowed
        }
        return .LacksTrackToken
    }
}
