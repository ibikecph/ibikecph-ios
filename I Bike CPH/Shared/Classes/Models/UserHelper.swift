//
//  UserHelper.swift
//  I Bike CPH
//
//  Created by Tobias Due Munk on 12/01/15.
//  Copyright (c) 2015 I Bike CPH. All rights reserved.
//

import Foundation

@objc class UserHelper {
    
    class func loggedIn() -> Bool {
        return AppHelper.delegate()?.appSettings["auth_token"] != nil
    }
    
    class func isFacebook() -> Bool {
        if let loginType = AppHelper.delegate()?.appSettings["loginType"] as? String {
            return loginType == "FB"
        }
        return false
    }
    
    class func logout() {
        Settings.instance.tracking.on = false // Turn off tracking when logging out
        AppHelper.delegate()?.clearSettings()
    }
    
    class func trackToken() -> String? {
        return AppHelper.delegate()?.appSettings["signature"] as? String
    }
}
