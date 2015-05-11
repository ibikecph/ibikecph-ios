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
        locationResponse["address"] = "Smallegade 1"
        locationResponse["city"] = "Frederiksberg"
        locationResponse["country"] = "Denmark"
        locationResponse["lat"] = 55.67815305484223
        locationResponse["lng"] = 12.53254652023315
        locationResponse["postalCode"] = 2000
        serverResponse["location"] = locationResponse
        serverResponse["name"] = "Frederiksberg Rådhusplads"
        
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
