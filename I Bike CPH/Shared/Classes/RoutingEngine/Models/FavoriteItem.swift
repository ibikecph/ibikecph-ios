//
//  FavoriteItem.swift
//  I Bike CPH
//
//  Created by Tobias Due Munk on 20/11/14.
//  Copyright (c) 2014 I Bike CPH. All rights reserved.
//

import UIKit
import CoreLocation
import SwiftyJSON

@objc class FavoriteItem: NSObject, SearchListItem {
    
    var type: SearchListItemType = .favorite
    var name: String
    var address: String
    var street: String = ""
    var number: String = ""
    var order: Int = 0
    var zip: String = ""
    var city: String = ""
    var country: String = ""
    var location: CLLocation? = CLLocation()
    var relevance: Int = 0
    
    var startDate: Date?
    var endDate: Date?
    var origin: FavoriteItemType
    var identifier: String = ""
    
    init(name: String, address: String? = nil, street: String = "", number: String = "", zip: String = "", city: String = "", country: String = "", location: CLLocation, startDate: Date? = nil, endDate: Date? = nil, origin: FavoriteItemType) {
        self.name = name
        self.address = address ?? name
        self.street = street
        self.number = number
        self.zip = zip
        self.city = city
        self.country = country
        self.location = location
        self.startDate = startDate
        self.endDate = endDate
        self.origin = origin
    }
    
    init(name: String, address: String? = nil, location: CLLocation, startDate: Date? = nil, endDate: Date? = nil, origin: FavoriteItemType) {
        self.name = name
        self.address = address ?? name
        self.location = location
        self.startDate = startDate
        self.endDate = endDate
        self.origin = origin
    }
    
    init(other: SearchListItem) {
        self.name = other.name
        self.address = other.address
        self.street = other.street
        self.number = other.number
        self.zip = other.zip
        self.city = other.city
        self.country = other.country
        self.location = other.location
        self.origin = .unknown
        self.relevance = other.relevance
        if let favorite = other as? FavoriteItem {
            self.startDate = favorite.startDate
            self.endDate = favorite.endDate
            self.origin = favorite.origin
            self.identifier = favorite.identifier
        }
    }
    
    init(jsonDictionary: AnyObject) {
        let json = JSON(jsonDictionary)
        
        // Name and address
        name = json["name"].stringValue
        address = json["address"].stringValue
        
        // Dates
        startDate = Date()
        endDate = Date()
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy'-'MM'-'dd'T'HH':'mm':'ss'Z'ZZZ" // Format 2015-06-10T13:45:31ZUTC
        if let
            dateString = json["startDate"].string,
            let date = formatter.date(from: dateString)
        {
            startDate = date
        }
        if let
            dateString = json["endDate"].string,
            let date = formatter.date(from: dateString)
        {
            endDate = date
        }
        
        // Parse address string to make details
        let parsedAddressItem = SMAddressParser.parseAddress(address)
        number = (parsedAddressItem?.number)!
        city = (parsedAddressItem?.city)!
        zip = (parsedAddressItem?.zip)!
        street = (parsedAddressItem?.street)!
        
        // Location
        let latitude = json["lattitude"].doubleValue
        let longitude = json["longitude"].doubleValue
        location = CLLocation(latitude: CLLocationDegrees(latitude), longitude: CLLocationDegrees(longitude))
        
        self.origin = {
            switch json["source"].stringValue {
                case "home": return .home
                case "work": return .work
                case "school": return .school
                case "favourites": fallthrough
                default: return .unknown
            }
        }()
        
        self.identifier = json["id"].stringValue
    }
    
    init(plistDictionary: NSDictionary) {
        let json = JSON(plistDictionary)
        
        // Name and address
        name = json["name"].stringValue
        address = json["address"].stringValue
        
        // Street, name, address, city, zip. Fallback to full address string
        let parsedAddressItem = SMAddressParser.parseAddress(address)
        number = json["husnr"].string ?? (parsedAddressItem?.number)!
        city = json["by"].string ?? (parsedAddressItem?.city)!
        zip = json["postnummer"].string ?? (parsedAddressItem?.zip)!
        street = json["vej"].string ?? (parsedAddressItem?.street)!
        
        if let data = plistDictionary["startDate"] as? Data {
            startDate = NSKeyedUnarchiver.unarchiveObject(with: data) as? Date
        }
        if let data = plistDictionary["endDate"] as? Data {
            endDate = NSKeyedUnarchiver.unarchiveObject(with: data) as? Date
        }
        
        // Location
        let latitude = json["lat"].doubleValue
        let longitude = json["long"].doubleValue
        location = CLLocation(latitude: CLLocationDegrees(latitude), longitude: CLLocationDegrees(longitude))
        
        let origin = json["origin"].intValue
        self.origin = FavoriteItemType(rawValue: origin) ?? .unknown;
        
        self.identifier = json["identifier"].stringValue
    }
    
    func plistRepresentation() -> [String : Any] {
        return [
            "identifier" : identifier as AnyObject,
            "name" :  name as AnyObject,
            "address" : address as AnyObject,
            "husnr" : number as AnyObject,
            "by" : city as AnyObject,
            "postnummer" : zip as AnyObject,
            "vej" : street as AnyObject,
            "startDate" : NSKeyedArchiver.archivedData(withRootObject: startDate ?? Date()) as AnyObject,
            "endDate" : NSKeyedArchiver.archivedData(withRootObject: endDate ?? Date()),
            "origin" : origin.rawValue,
            "lat" : location?.coordinate.latitude ?? 0,
            "long" : location?.coordinate.longitude ?? 0
        ]
    }
    
    override var description: String {
        return "Name: \(name), Address: \(address), Street: \(street), Number: \(number), Zip: \(zip), City: \(city), Country: \(country), Location: (\(location?.coordinate.latitude), \(location?.coordinate.longitude)), Order: \(order), Relevance: \(relevance), Date: \(startDate) -> \(endDate), Origin: \(origin), Id: \(identifier)"
    }
}
