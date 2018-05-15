//
//  HistoryItem.swift
//  I Bike CPH
//
//  Created by Tobias Due Munk on 20/11/14.
//  Copyright (c) 2014 I Bike CPH. All rights reserved.
//

import UIKit
import CoreLocation
import SwiftyJSON

// https://github.com/ibikecph/ibikecph-lib-android/blob/master/IBikeCPHLib/src/com/spoiledmilk/ibikecph/search/HistoryData.java
@objc class HistoryItem: NSObject, SearchListItem {
   
    var type: SearchListItemType = .history
    var name: String
    var address: String
    var street: String = ""
    var number: String = ""
    var order: Int = 1
    var zip: String = ""
    var city: String = ""
    var country: String = ""
    var location: CLLocation? = CLLocation()
    var relevance: Int = 0
    
    var startDate: Date?
    var endDate: Date?
    
    init(name: String, address: String? = nil, location: CLLocation, startDate: Date? = nil, endDate: Date? = nil) {
        self.name = name
        self.address = address ?? name
        self.location = location
        self.startDate = startDate
        self.endDate = endDate
    }
    
    init(other: SearchListItem, startDate: Date? = nil, endDate: Date? = nil) {
        self.name = other.name
        self.address = other.address
        self.street = other.street
        self.number = other.number
        self.zip = other.zip
        self.city = other.city
        self.country = other.country
        self.location = other.location
        self.startDate = startDate
        self.endDate = endDate
    }
    
    init(plistDictionary: NSDictionary) {
        let json = JSON(plistDictionary)
        
        name = json["name"].stringValue
        address = json["address"].stringValue
        if let startDateData = plistDictionary["startDate"] as? Data {
            startDate = NSKeyedUnarchiver.unarchiveObject(with: startDateData) as? Date
        }
        if let endDateData = plistDictionary["endDate"] as? Data {
            endDate = NSKeyedUnarchiver.unarchiveObject(with: endDateData) as? Date
        }
        
        // Parse address string to make details
        let parsedAddressItem = SMAddressParser.parseAddress(address)
        number = (parsedAddressItem?.number)!
        city = (parsedAddressItem?.city)!
        zip = (parsedAddressItem?.zip)!
        street = (parsedAddressItem?.street)!
        
        // Location
        let latitude = json["lat"].doubleValue
        let longitude = json["long"].doubleValue
        location = CLLocation(latitude: CLLocationDegrees(latitude), longitude: CLLocationDegrees(longitude))
    }
    
    func plistRepresentation() -> [String : AnyObject] {
        return [
            "name" :  self.name as AnyObject,
            "address" : self.address as AnyObject,
            "startDate" : NSKeyedArchiver.archivedData(withRootObject: self.startDate!) as AnyObject,
            "endDate" : NSKeyedArchiver.archivedData(withRootObject: self.endDate!) as AnyObject,
            "lat" : self.location?.coordinate.latitude as AnyObject,
            "long" : self.location?.coordinate.longitude as AnyObject
        ]
    }
    
    override var description: String {
        return "Name: \(name), Address: \(address), Street: \(street), Number: \(number), Zip: \(zip), City: \(city), Country: \(country), Location: (\(location?.coordinate.latitude), \(location?.coordinate.longitude)), Order: \(order), Relevance: \(relevance), Date: \(startDate) -> \(endDate)"
    }
}
