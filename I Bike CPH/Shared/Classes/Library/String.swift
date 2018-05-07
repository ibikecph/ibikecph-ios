//
//  String.swift
//  I Bike CPH
//
//  Created by Tobias Due Munk on 23/02/15.
//  Copyright (c) 2015 I Bike CPH. All rights reserved.
//

import UIKit


extension String {
    
    var localized: String {
        return NSLocalizedString(self, comment: "")
    }
}

extension NSString {
    
    var localized: NSString {
        return NSLocalizedString(self as String, comment: "") as NSString
    }
}
