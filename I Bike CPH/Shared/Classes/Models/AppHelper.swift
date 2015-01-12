//
//  App.swift
//  I Bike CPH
//
//  Created by Tobias Due Munk on 12/01/15.
//  Copyright (c) 2015 I Bike CPH. All rights reserved.
//

import Foundation

class AppHelper {
    
    class func delegate() -> SMAppDelegate? {
        return UIApplication.sharedApplication().delegate as? SMAppDelegate ?? nil
    }
}