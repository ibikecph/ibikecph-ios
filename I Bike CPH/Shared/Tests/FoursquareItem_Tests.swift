//
//  FoursquareItem_Tests.swift
//  I Bike CPH
//
//  Created by Tobias Due Munk on 20/11/14.
//  Copyright (c) 2014 I Bike CPH. All rights reserved.
//

import Foundation
import XCTest

class FoursquareItem_Tests: XCTestCase {

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testInit() {
        
        var serverResponse = [String: AnyObject]()
        
        var locationResponse = [String: AnyObject]()
        locationResponse["address"] = "Smallegade 1" as AnyObject
        locationResponse["city"] = "Frederiksberg" as AnyObject
        locationResponse["country"] = "Denmark" as AnyObject
        locationResponse["lat"] = 55.67815305484223 as AnyObject
        locationResponse["lng"] = 12.53254652023315 as AnyObject
        locationResponse["postalCode"] = 2000 as AnyObject
        serverResponse["location"] = locationResponse as AnyObject
        serverResponse["name"] = "Frederiksberg Rådhusplads" as AnyObject
        
        let foursquareItem = FoursquareItem(jsonDictionary: serverResponse as AnyObject)
        
        XCTAssert(foursquareItem.name == "Frederiksberg Rådhusplads", "Wrong name")
        XCTAssert(foursquareItem.address == "Smallegade 1", "Wrong address")
        XCTAssert(foursquareItem.street == "Smallegade", "Wrong street")
        XCTAssert(foursquareItem.city == "Frederiksberg", "Wrong city")
        XCTAssert(foursquareItem.country == "Denmark", "Wrong address")
        XCTAssert(foursquareItem.zip == "2000", "Wrong zip code")
        XCTAssert(foursquareItem.location!.coordinate.latitude == 55.67815305484223, "Wrong latitude")
        XCTAssert(foursquareItem.location!.coordinate.longitude == 12.53254652023315, "Wrong latitude")
    }
}
