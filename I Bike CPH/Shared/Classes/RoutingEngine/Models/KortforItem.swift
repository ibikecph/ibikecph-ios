//
//  KortforItem.swift
//  I Bike CPH
//
//  Created by Tobias Due Munk on 20/11/14.
//  Copyright (c) 2014 I Bike CPH. All rights reserved.
//

import Foundation
import CoreLocation
import SwiftyJSON

@objc class KortforItem: NSObject, SearchListItem {
    
    var type: SearchListItemType = .Kortfor
    var name: String
    var address: String = ""
    var street: String
    var number: String
    var order: Int = 2
    var zip: String
    var city: String
    var country: String = "Denmark"
    var location: CLLocation? = CLLocation()
    var relevance: Int = 0
    
    var distance: Double
    var isPlace: Bool
    var isFromStreetSearch: Bool = false
    
    init(jsonDictionary: AnyObject) {
        let json = JSON(jsonDictionary)
        
        let properties = json["properties"]
        // Street, name, address, city, zip
        self.street = ""
        if let streetName = properties["vej_navn"].string {
            self.street = streetName
        } else if let navn = properties["navn"].string {
            self.street = navn
        } else {
            if let stednavneliste = properties["stednavneliste"].array {
                for stednavn: JSON in stednavneliste {
                    if let navn = stednavn["navn"].string, let status = stednavn["status"].string {
                        self.street = navn
                        if status == "officielt" {
                            break
                        }
                    }
                }
            }
        }
        if let postalArea = properties["postdistrikt_navn"].string {
            self.city = postalArea
        } else {
            self.city = "\(properties["sogn_navn"].stringValue), \(properties["kommune_navn"])"
        }
        self.zip = properties["postdistrikt_kode"].stringValue
        
        // Location
        let geometry = json["geometry"]
        var latitude: Double = 0
        var longitude: Double = 0
        if let ymin = geometry["ymin"].double {
            latitude = ymin
            if let ymax = json["properties"]["ymax"].double {
                latitude += ymax
                latitude /= 2
            }
            longitude = json["properties"]["xmin"].doubleValue
            if let ymax = json["properties"]["xmax"].double {
                longitude += ymax
                longitude /= 2
            }
        } else if let coordinates = geometry["coordinates"].array {
            latitude = coordinates[1].doubleValue
            longitude = coordinates[0].doubleValue
        } else if let boundingBox = json["bbox"].array {
            if boundingBox.count > 3 {
                latitude = (boundingBox[1].doubleValue + boundingBox[3].doubleValue) / 2
                longitude = (boundingBox[0].doubleValue + boundingBox[2].doubleValue) / 2
            }
        }
        self.location = CLLocation(latitude: CLLocationDegrees(latitude), longitude: CLLocationDegrees(longitude))
        
        // Number, distance, isPlace
        self.number = properties["husnr"].stringValue
        self.distance = properties["afstand_afstand"].doubleValue
        self.isPlace = properties["kategori"].string != nil
        
        self.name = self.street
        self.name += (self.number.characters.count > 0) ? " \(self.number)," : ","
        self.name += (self.zip.characters.count > 0) ? " \(self.zip)" : ""
        self.name += " \(self.city)"
        self.address = self.name
        
        super.init()
    }
    
    override var description: String {
        return "Name: \(name), Address: \(address), Street: \(street), Number: \(number), Zip: \(zip), City: \(city), Country: \(country), Location: (\(location?.coordinate.latitude), \(location?.coordinate.longitude)), Order: \(order), Relevance: \(relevance), Distance: \(distance), isPlace: \(isPlace)"
    }
}
