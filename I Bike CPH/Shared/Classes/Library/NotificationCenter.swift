//
//  NotificationCenter.swift
//  I Bike CPH
//
//  Created by Tobias Due Munk on 13/03/15.
//  Copyright (c) 2015 I Bike CPH. All rights reserved.
//

import UIKit

class NotificationCenter {
    
    class func post(name: String, object: AnyObject? = nil) {
        Async.main {
            NSNotificationCenter.defaultCenter().postNotificationName(name, object: object)
        }
    }
    
    class func observe(name: String, object: AnyObject? = nil, queue: NSOperationQueue? = nil, usingBlock block: NSNotification! -> ()) {
        NSNotificationCenter.defaultCenter().addObserverForName(name, object: object, queue: queue, usingBlock: block)
    }
    
    class func unobserve(observer: AnyObject, name: String? = nil, object: AnyObject? = nil) {
        NSNotificationCenter.defaultCenter().removeObserver(observer, name: name, object: object)
    }
}