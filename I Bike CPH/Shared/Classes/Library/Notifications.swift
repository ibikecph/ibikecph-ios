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
        let settings = UIUserNotificationSettings(types: [.sound, .alert, .badge], categories: nil)
        UIApplication.shared.registerUserNotificationSettings(settings)
    }
    
    class func scheduleLocalNotification(_ description: String, fireDate: Date? = Date()) -> UILocalNotification  {
        let notification = UILocalNotification()
        notification.fireDate = fireDate
        notification.alertBody = description
        notification.applicationIconBadgeNumber = 0
        UIApplication.shared.scheduleLocalNotification(notification)
        return notification
    }
    
    class func localNotificationCancelScheduled()  {
        UIApplication.shared.cancelAllLocalNotifications()
    }
    
    class func cancelScheduledLocalNotification(_ localNotification: UILocalNotification)  {
        UIApplication.shared.cancelLocalNotification(localNotification)
    }
    
    class func localNotificationScheduledAtDate(_ date: Date) -> UILocalNotification? {
        if let scheduledNotifications = UIApplication.shared.scheduledLocalNotifications {
            for scheduledNotification in scheduledNotifications {
                if let
                    fireDate = scheduledNotification.fireDate, (fireDate == date)
                {
                    return scheduledNotification
                }
            }
        }
        return nil
    }
}
