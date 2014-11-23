//
//  CurrentLocationItem.swift
//  I Bike CPH
//
//  Created by Tobias Due Munk on 20/11/14.
//  Copyright (c) 2014 I Bike CPH. All rights reserved.
//

import UIKit
import CoreLocation

// https://github.com/ibikecph/ibikecph-lib-android/blob/master/IBikeCPHLib/src/com/spoiledmilk/ibikecph/search/CurrentLocation.java#L43
@objc class CurrentLocationItem: NSObject, SearchListItem {
    
    var type: SearchListItemType = .CurrentLocation
    var name: String = ""
    var address: String = "" // TODO: Check if it should can be calculated somehow https://github.com/ibikecph/ibikecph-lib-android/blob/master/IBikeCPHLib/src/com/spoiledmilk/ibikecph/search/CurrentLocation.java#L43
    var street: String = ""
    var order: Int = -1
    var zip: String = ""
    var city: String = ""
    var country: String = ""
    var location: CLLocation {
        // TODO: Get current location
        return CLLocation()
    }
    
    // Have initializer for objc compability
    init(name: String, address: String? = nil, street: String, zip: String, city: String = "", country: String = "", location: CLLocation, startDate: NSDate? = nil, endDate: NSDate? = nil) {
        self.name = name
        self.address = address ?? name
        self.street = street
        self.zip = zip
        self.city = city
        self.country = country
    }
}
