//
//  NotificationCenter.swift
//  I Bike CPH
//
//  Created by Tobias Due Munk on 13/03/15.
//  Copyright (c) 2015 I Bike CPH. All rights reserved.
//

import UIKit
import Async

class NotificationCenter {
    
    class func post(_ name: String, object: AnyObject? = nil, userInfo: [AnyHashable: Any]? = nil) {
        Async.main {
            Foundation.NotificationCenter.default.post(name: Notification.Name(rawValue: name), object: object, userInfo: userInfo)
        }
    }
    
    class func observe(_ name: NSNotification.Name, object: AnyObject? = nil, queue: OperationQueue? = nil, usingBlock block: @escaping (Notification!) -> ()) -> NSObjectProtocol {
        return Foundation.NotificationCenter.default.addObserver(forName: name, object: object, queue: queue, using: block)
    }
    
    class func observe(_ name: String, object: AnyObject? = nil, queue: OperationQueue? = nil, usingBlock block: @escaping (Notification!) -> ()) -> NSObjectProtocol {
        return Foundation.NotificationCenter.default.addObserver(forName: NSNotification.Name(name), object: object, queue: queue, using: block)
    }
    
    class func unobserve(_ observer: AnyObject, name: String? = nil, object: AnyObject? = nil) {
        Foundation.NotificationCenter.default.removeObserver(observer, name: name.map { NSNotification.Name(rawValue: $0) }, object: object)
    }
}
