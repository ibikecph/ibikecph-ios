//
//  Notifications.swift
//  I Bike CPH
//
//  Created by Tobias Due Munk on 13/04/15.
//  Copyright (c) 2015 I Bike CPH. All rights reserved.
//

import UIKit


@objc class Notifications {
    
    class func register() {
        let settings = UIUserNotificationSettings(forTypes: .Sound | .Alert | .Badge, categories: nil)
        UIApplication.sharedApplication().registerUserNotificationSettings(settings)
    }
    
    class func localNotification(description: String, fireDate: NSDate? = NSDate()) -> UILocalNotification  {
        let notification = UILocalNotification()
        notification.fireDate = fireDate
        notification.alertBody = description
        notification.applicationIconBadgeNumber = 0
        UIApplication.sharedApplication().scheduleLocalNotification(notification)
        return notification
    }
}
