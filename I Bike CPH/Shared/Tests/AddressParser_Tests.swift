//
//  AddressParser_Tests.swift
//  I Bike CPH
//
//  Created by Tobias Due Munk on 02/01/15.
//  Copyright (c) 2015 I Bike CPH. All rights reserved.
//

import UIKit
import XCTest

func assertEqualIfExists<T: Equatable>(_ left: T?, right: T, message: String) {
    if let left = left {
        XCTAssert(left == right, message)
    }
}

class AddressParser_Tests: XCTestCase {

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func shorthand(_ address: String, expectedStreet: String? = nil, expectedNumber: String? = nil, expectedZip: String? = nil, expectedCity: String? = nil) {
        let result = SMAddressParser.parseAddress(address)
        
        assertEqualIfExists(expectedStreet, result.street, "Wrong street")
        assertEqualIfExists(expectedNumber, result.number, "Wrong number")
        assertEqualIfExists(expectedZip, result.zip, "Wrong zip")
        assertEqualIfExists(expectedCity, result.city, "Wrong city")
    }
    
    func testParseZipCity() {
        shorthand("2100 København Ø", expectedZip: "2100", expectedCity: "København Ø")
        shorthand("1180 København K", expectedZip: "1180", expectedCity: "København K")
        shorthand("8600 Aarhus", expectedZip: "8600", expectedCity: "Aarhus")
    }
    
    func testStreetWithDigits() {
        shorthand("Vej 6", expectedStreet: "Vej", expectedNumber: "6")
        shorthand("Vej 6, 45", expectedStreet: "Vej 6", expectedNumber: "45")
        shorthand("Vej 6 45", expectedStreet: "Vej 6", expectedNumber: "45")
        shorthand("Vej 6, 432b", expectedStreet: "Vej 6", expectedNumber: "432b")
        shorthand("Vej 6 1A", expectedStreet: "Vej 6", expectedNumber: "1A")
        shorthand("Vej 6, 45 2200", expectedStreet: "Vej 6", expectedNumber: "45", expectedZip: "2200")
        shorthand("Vej 6 45, 2200", expectedStreet: "Vej 6", expectedNumber: "45", expectedZip: "2200")
        shorthand("Christian d. 10's vej 45, 2200", expectedStreet: "Christian d. 10's vej", expectedNumber: "45", expectedZip: "2200")
        shorthand("Hans 10's og Ulla 20's Plads 50 2200", expectedStreet: "Hans 10's og Ulla 20's Plads", expectedNumber: "50", expectedZip: "2200")
        shorthand("Boulevard 20x30, 99, 5500", expectedStreet: "Boulevard 20x30", expectedNumber: "99", expectedZip: "5500")
    }
    
    func testStreetWithSpecialCharacters() {
        shorthand("Skt. Hans Torv", expectedStreet: "Skt. Hans Torv")
        shorthand("Christian X's Vej", expectedStreet: "Christian X's Vej")
    }

    func testStreetNoWithLetter() {
        shorthand("Bredgade 55A", expectedStreet: "bredgade", expectedNumber: "b55")
        shorthand("Bredgade 55,A", expectedStreet: "bredgade", expectedNumber: "b55")
        shorthand("Bredgade 55 , A", expectedStreet: "bredgade", expectedNumber: "b55")
        shorthand("Bredgade 55 A", expectedStreet: "bredgade", expectedNumber: "b55")
        shorthand("Bredgade 55  A", expectedStreet: "bredgade", expectedNumber: "b55")
        shorthand("Bredgade 55-A", expectedStreet: "bredgade", expectedNumber: "b55")
        shorthand("Bredgade 55 - A", expectedStreet: "bredgade", expectedNumber: "b55")
    }
    
    func testNoWithLetterCityZip() {
        shorthand("Bredgade 55A, Hven", expectedStreet: "Bredgade", expectedNumber: "b55", expectedCity: "Hven")
        shorthand("Bredgade 55 A, Hven", expectedStreet: "Bredgade", expectedNumber: "b55", expectedCity: "Hven")
        shorthand("Bredgade 55  A, Hven", expectedStreet: "Bredgade", expectedNumber: "b55", expectedCity: "Hven")
        shorthand("Bredgade 55-A, Hven", expectedStreet: "Bredgade", expectedNumber: "b55", expectedCity: "Hven")
        shorthand("Bredgade 55 - A, Hven", expectedStreet: "Bredgade", expectedNumber: "b55", expectedCity: "Hven")
        shorthand("Bredgade 55A, 4500", expectedStreet: "Bredgade", expectedNumber: "b55", expectedZip: "4500")
        shorthand("Bredgade 55 A, 4500", expectedStreet: "Bredgade", expectedNumber: "b55", expectedZip: "4500")
        shorthand("Bredgade 55  A, 4500", expectedStreet: "Bredgade", expectedNumber: "b55", expectedZip: "4500")
        shorthand("Bredgade 55-A, 4500", expectedStreet: "Bredgade", expectedNumber: "b55", expectedZip: "4500")
        shorthand("Bredgade 55 - A, 4500", expectedStreet: "Bredgade", expectedNumber: "b55", expectedZip: "4500")
    }
    
    func testNoRanges() {
        shorthand("Bredgade 1-2, Hven", expectedStreet: "Bredgade", expectedNumber: "1-2", expectedCity: "Hven")
        shorthand("Bredgade 843-844, Hven", expectedStreet: "Bredgade", expectedNumber: "843-844", expectedCity: "Hven")
        shorthand("Bredgade 55-59, Hven", expectedStreet: "Bredgade", expectedNumber: "55-59", expectedCity: "Hven")
    }
    
    func testStreetNo() {
        shorthand("Bredgade 1", expectedStreet: "Bredgade", expectedNumber: "1")
        shorthand("Bredgade 90", expectedStreet: "Bredgade", expectedNumber: "90")
        shorthand("Bredgade 345", expectedStreet: "Bredgade", expectedNumber: "345")
        shorthand("Bredgade 1A", expectedStreet: "Bredgade", expectedNumber: "1A")
        shorthand("Bredgade 90C", expectedStreet: "Bredgade", expectedNumber: "90C")
        shorthand("Bredgade 345Z", expectedStreet: "Bredgade", expectedNumber: "345Z")
        shorthand("Yrsas Plads 7", expectedStreet: "Yrsas Plads", expectedNumber: "7")
        shorthand("Yrsas Plads 12", expectedStreet: "Yrsas Plads", expectedNumber: "12")
        shorthand("Yrsas Plads 921", expectedStreet: "Yrsas Plads", expectedNumber: "921")
        shorthand("Yrsas Plads 7D", expectedStreet: "Yrsas Plads", expectedNumber: "7D")
        shorthand("Yrsas Plads 12K", expectedStreet: "Yrsas Plads", expectedNumber: "12K")
        shorthand("Yrsas Plads 921B", expectedStreet: "Yrsas Plads", expectedNumber: "921B")
    }
    
    func testStreetNoLetter() {
        shorthand("Bredgade, 1", expectedStreet: "Bredgade", expectedNumber: "1")
        shorthand("Bredgade, 90", expectedStreet: "Bredgade", expectedNumber: "90")
        shorthand("Bredgade, 345", expectedStreet: "Bredgade", expectedNumber: "345")
        shorthand("Bredgade, 1A", expectedStreet: "Bredgade", expectedNumber: "1A")
        shorthand("Bredgade, 90C", expectedStreet: "Bredgade", expectedNumber: "90C")
        shorthand("Bredgade, 345Z", expectedStreet: "Bredgade", expectedNumber: "345Z")
        shorthand("Yrsas Plads, 7", expectedStreet: "Yrsas Plads", expectedNumber: "7")
        shorthand("Yrsas Plads, 12", expectedStreet: "Yrsas Plads", expectedNumber: "12")
        shorthand("Yrsas Plads, 921", expectedStreet: "Yrsas Plads", expectedNumber: "921")
        shorthand("Yrsas Plads, 7D", expectedStreet: "Yrsas Plads", expectedNumber: "7D")
        shorthand("Yrsas Plads, 12K", expectedStreet: "Yrsas Plads", expectedNumber: "12K")
        shorthand("Yrsas Plads, 921B", expectedStreet: "Yrsas Plads", expectedNumber: "921B")
    }
    
    func testStreetNoCity() {
        shorthand("Bredgade 35C Valby", expectedStreet: "Bredgade", expectedNumber: "35C", expectedCity: "Valby")
        shorthand("Bredgade, 35C Valby", expectedStreet: "Bredgade", expectedNumber: "35C", expectedCity: "Valby")
        shorthand("Bredgade, 35C, Valby", expectedStreet: "Bredgade", expectedNumber: "35C", expectedCity: "Valby")
        shorthand("Bredgade, 35C, Valby", expectedStreet: "Bredgade", expectedNumber: "35C", expectedCity: "Valby")
    
    }
    
    func testStreetCityZip() {
        shorthand("Bredgade, 2300 Valby", expectedStreet: "Bredgade", expectedZip: "2300", expectedCity: "Valby")
        shorthand("Bredgade, 2300, Valby", expectedStreet: "Bredgade", expectedZip: "2300", expectedCity: "Valby")
        shorthand("Bredgade, Valby 2300", expectedStreet: "Bredgade", expectedZip: "2300", expectedCity: "Valby")
        shorthand("Bredgade, Valby, 2300", expectedStreet: "Bredgade", expectedZip: "2300", expectedCity: "Valby")
        shorthand("Bredgade 2300 Valby", expectedStreet: "Bredgade", expectedZip: "2300", expectedCity: "Valby")
        shorthand("Bredgade 2300, Valby", expectedStreet: "Bredgade", expectedZip: "2300", expectedCity: "Valby")
    
    }
    
    func testStreetCity() {
        shorthand("Bredgade, Valby", expectedStreet: "Bredgade", expectedCity: "Valby")
        shorthand("Bredgade, Kongens Lyngby", expectedStreet: "Bredgade", expectedCity: "Kongens Lyngby")
        shorthand("Bredgade, Kgs. Lyngby", expectedStreet: "Bredgade", expectedCity: "Kgs. Lyngby")
    }
    
    func testStreetNoCityZip() {
        shorthand("Bredgade 67, 2300 Valby", expectedStreet: "Bredgade", expectedNumber: "67", expectedZip: "2300", expectedCity: "Valby")
        shorthand("Bredgade 67, 2300, Valby", expectedStreet: "Bredgade", expectedNumber: "67", expectedZip: "2300", expectedCity: "Valby")
        shorthand("Bredgade 67, Valby 2300", expectedStreet: "Bredgade", expectedNumber: "67", expectedZip: "2300", expectedCity: "Valby")
        shorthand("Bredgade 67, Valby, 2300", expectedStreet: "Bredgade", expectedNumber: "67", expectedZip: "2300", expectedCity: "Valby")
        shorthand("Bredgade 67 2300 Valby", expectedStreet: "Bredgade", expectedNumber: "67", expectedZip: "2300", expectedCity: "Valby")
        shorthand("Bredgade 67 2300, Valby", expectedStreet: "Bredgade", expectedNumber: "67", expectedZip: "2300", expectedCity: "Valby")
        shorthand("Bredgade 67 Valby 2300", expectedStreet: "Bredgade", expectedNumber: "67", expectedZip: "2300", expectedCity: "Valby")
        shorthand("Bredgade 67 Valby, 2300", expectedStreet: "Bredgade", expectedNumber: "67", expectedZip: "2300", expectedCity: "Valby")
        shorthand("Bredgade, 67, 2300 Valby", expectedStreet: "Bredgade", expectedNumber: "67", expectedZip: "2300", expectedCity: "Valby")
        shorthand("Bredgade, 67, 2300, Valby", expectedStreet: "Bredgade", expectedNumber: "67", expectedZip: "2300", expectedCity: "Valby")
        shorthand("Bredgade, 67, Valby 2300", expectedStreet: "Bredgade", expectedNumber: "67", expectedZip: "2300", expectedCity: "Valby")
        shorthand("Bredgade, 67, Valby, 2300", expectedStreet: "Bredgade", expectedNumber: "67", expectedZip: "2300", expectedCity: "Valby")
        shorthand("Bredgade, 67 2300 Valby", expectedStreet: "Bredgade", expectedNumber: "67", expectedZip: "2300", expectedCity: "Valby")
        shorthand("Bredgade, 67 2300, Valby", expectedStreet: "Bredgade", expectedNumber: "67", expectedZip: "2300", expectedCity: "Valby")
        shorthand("Bredgade, 67 Valby 2300", expectedStreet: "Bredgade", expectedNumber: "67", expectedZip: "2300", expectedCity: "Valby")
        shorthand("Bredgade, 67 Valby, 2300", expectedStreet: "Bredgade", expectedNumber: "67", expectedZip: "2300", expectedCity: "Valby")
    }
    
    func testHandleTrailingNoise() {
        shorthand("Bredgade 67, 2300 Valby", expectedStreet: "Bredgade", expectedNumber: "67", expectedZip: "2300", expectedCity: "Valby")
        shorthand("Bredgade 67, 2300, Valby,", expectedStreet: "Bredgade", expectedNumber: "67", expectedZip: "2300", expectedCity: "Valby")
        shorthand("Bredgade 67, Valby 2300,,", expectedStreet: "Bredgade", expectedNumber: "67", expectedZip: "2300", expectedCity: "Valby")
        shorthand("Bredgade 67, Valby, 2300, , ,", expectedStreet: "Bredgade", expectedNumber: "67", expectedZip: "2300", expectedCity: "Valby")
        shorthand("Bredgade 67 2300 Valby", expectedStreet: "Bredgade", expectedNumber: "67", expectedZip: "2300", expectedCity: "Valby")
        shorthand("Bredgade 67 Valby 2300,,", expectedStreet: "Bredgade", expectedNumber: "67", expectedZip: "2300", expectedCity: "Valby")
        shorthand("Bredgade 67 Valby 2300, , ,", expectedStreet: "Bredgade", expectedNumber: "67", expectedZip: "2300", expectedCity: "Valby")
    }
    
    func testIgnoreAdditionalItems() {
        shorthand("Bredgade, 67, 2300, Valby, Sjælland", expectedStreet: "Bredgade", expectedNumber: "67", expectedZip: "2300", expectedCity: "Valby")
        shorthand("Bredgade, 67, 2300, Valby, Sjælland, Denmark", expectedStreet: "Bredgade", expectedNumber: "67", expectedZip: "2300", expectedCity: "Valby")
        shorthand("Bredgade, 67, 2300, Valby, Sjælland, Denmark, Europe", expectedStreet: "Bredgade", expectedNumber: "67", expectedZip: "2300", expectedCity: "Valby")
        shorthand("Bredgade 67, 2300, Valby, Sjælland", expectedStreet: "Bredgade", expectedNumber: "67", expectedZip: "2300", expectedCity: "Valby")
        shorthand("Bredgade 67, 2300, Valby, Sjælland, Denmark", expectedStreet: "Bredgade", expectedNumber: "67", expectedZip: "2300", expectedCity: "Valby")
        shorthand("Bredgade 67, 2300, Valby, Sjælland, Denmark, Europe", expectedStreet: "Bredgade", expectedNumber: "67", expectedZip: "2300", expectedCity: "Valby")
        shorthand("Bredgade 67 2300 Valby, Sjælland", expectedStreet: "Bredgade", expectedNumber: "67", expectedZip: "2300", expectedCity: "Valby")
        shorthand("Bredgade 67 2300 Valby, Sjælland, Denmark", expectedStreet: "Bredgade", expectedNumber: "67", expectedZip: "2300", expectedCity: "Valby")
        shorthand("Bredgade 67 2300 Valby, Sjælland, Denmark, Europe", expectedStreet: "Bredgade", expectedNumber: "67", expectedZip: "2300", expectedCity: "Valby")
    }
    
    func testExpandCPH() {
        shorthand("Bredgade, 35C kbh N", expectedStreet: "Bredgade", expectedNumber: "35C", expectedCity: "København N")
        shorthand("Bredgade, 35C, KBH. V", expectedStreet: "Bredgade", expectedNumber: "35C", expectedCity: "København V")
        shorthand("Bredgade, 35C, KBH.S", expectedStreet: "Bredgade", expectedNumber: "35C", expectedCity: "København S")
        shorthand("Bredgade 35C Akbhøj", expectedStreet: "Bredgade", expectedNumber: "35C", expectedCity: "Akbhøj")
        shorthand("Bredgade, 35C Kbhøj", expectedStreet: "Bredgade", expectedNumber: "35C", expectedCity: "Kbhøj")
        shorthand("Bredgade, 35C, Kokbh", expectedStreet: "Bredgade", expectedNumber: "35C", expectedCity: "Kokbh")
        shorthand("Bredgade 35C Cph", expectedStreet: "Bredgade", expectedNumber: "35C", expectedCity: "København")
        shorthand("Bredgade, 35C Cph N", expectedStreet: "Bredgade", expectedNumber: "35C", expectedCity: "København N")
        shorthand("Bredgade, 35C, CPH. V", expectedStreet: "Bredgade", expectedNumber: "35C", expectedCity: "København V")
        shorthand("Bredgade, 35C, CPH.S", expectedStreet: "Bredgade", expectedNumber: "35C", expectedCity: "København S")
        shorthand("Bredgade 35C Acphøj", expectedStreet: "Bredgade", expectedNumber: "35C", expectedCity: "Acphøj")
        shorthand("Bredgade, 35C Cphøj", expectedStreet: "Bredgade", expectedNumber: "35C", expectedCity: "Cphøj")
        shorthand("Bredgade, 35C, Kocph", expectedStreet: "Bredgade", expectedNumber: "35C", expectedCity: "Kocph")
        shorthand("Bredgade 35C 1571 Kbh NV", expectedStreet: "Bredgade", expectedNumber: "35C", expectedZip: "1571", expectedCity: "København NV")
        shorthand("Bredgade 35C 1571 Cph K", expectedStreet: "Bredgade", expectedNumber: "35C", expectedZip: "1571", expectedCity: "København K")
    }
}
