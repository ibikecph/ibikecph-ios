//
//  Notifications.swift
//  I Bike CPH
//
//  Created by Tobias Due Munk on 13/04/15.
//  Copyright (c) 2015 I Bike CPH. All rights reserved.
//

import UIKit


class Notifications {
    
    class func register() {
        let settings = UIUserNotificationSettings(forTypes: .Sound | .Alert | .Badge, categories: nil)
        UIApplication.sharedApplication().registerUserNotificationSettings(settings)
    }
    
    class func scheduleLocalNotification(description: String, fireDate: NSDate? = NSDate()) -> UILocalNotification  {
        let notification = UILocalNotification()
        notification.fireDate = fireDate
        notification.alertBody = description
        notification.applicationIconBadgeNumber = 0
        UIApplication.sharedApplication().scheduleLocalNotification(notification)
        return notification
    }
    
    class func localNotificationCancelScheduled()  {
        UIApplication.sharedApplication().cancelAllLocalNotifications()
    }
    
    class func cancelScheduledLocalNotification(localNotification: UILocalNotification)  {
        UIApplication.sharedApplication().cancelLocalNotification(localNotification)
    }
    
    class func localNotificationScheduledAtDate(date: NSDate) -> UILocalNotification? {
        if let scheduledNotifications = UIApplication.sharedApplication().scheduledLocalNotifications as? [UILocalNotification] {
            for scheduledNotification in scheduledNotifications {
                if let
                    fireDate = scheduledNotification.fireDate
                    where fireDate.isEqualToDate(date)
                {
                    return scheduledNotification
                }
            }
        }
        return nil
    }
}
