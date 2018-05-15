//
//  NSDate_Tests.swift
//  I Bike CPH
//
//  Created by Tobias Due Munk on 30/04/15.
//  Copyright (c) 2015 I Bike CPH. All rights reserved.
//

import UIKit
import XCTest

class NSDate_Tests: XCTestCase {

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testNextMondayPreOnDay() {
        let weekday = 2 // Monday
        if let
            noon = Date().withComponents(year: 2015, month: 4, day: 6, hour: 12, minute: 0, second: 0),
            let preNoon = noon.withComponents(hour: 11),
            let nextWeekday = preNoon.nextWeekday(weekday, fromDate: noon)
        {
            XCTAssertEqual(nextWeekday, noon, "Next weekday should be on same day.")
            return
        } else {
             XCTAssertTrue(false, "Couldn't create dates")
        }
    }
    
    func testNextMondayPostOnDay() {
        let weekday = 2 // Monday
        if let
            noon = Date().withComponents(year: 2015, month: 4, day: 6, hour: 12, minute: 0, second: 0),
            let postNoon = noon.withComponents(hour: 13),
            let nextWeekday = postNoon.nextWeekday(weekday, fromDate: noon),
            let noonInAWeek = Calendar.currentCalendar().dateByAddingUnit(.CalendarUnitWeekOfYear, value: 1, toDate: noon, options: nil)
        {
            XCTAssertEqual(nextWeekday, noonInAWeek, "Next weekday should be noon in a week.")
            return
        } else {
            XCTAssertTrue(false, "Couldn't create dates")
        }
    }
    
    func testNextMondayDayBefore() {
        let weekday = 2 // Monday
        if let
            noon = Date().withComponents(year: 2015, month: 4, day: 6, hour: 12, minute: 0, second: 0),
            let noonDayBefore = noon.withComponents(day: 5),
            let nextWeekday = noonDayBefore.nextWeekday(weekday, fromDate: noon)
        {
            XCTAssertEqual(nextWeekday, noon, "Next weekday should be next day.")
            return
        } else {
            XCTAssertTrue(false, "Couldn't create dates")
        }
    }
    
    func testNextMondayDayAfter() {
        let weekday = 2 // Monday
        if let
            noon = Date().withComponents(year: 2015, month: 4, day: 6, hour: 12, minute: 0, second: 0),
            let noonDayAfter = noon.withComponents(day: 7),
            let nextWeekday = noonDayAfter.nextWeekday(weekday, fromDate: noon),
            let noonInAWeek = Calendar.currentCalendar().dateByAddingUnit(.CalendarUnitWeekOfYear, value: 1, toDate: noon, options: nil)
        {
            XCTAssertEqual(nextWeekday, noonInAWeek, "Next weekday should be noon in a week.")
            return
        } else {
            XCTAssertTrue(false, "Couldn't create dates")
        }
    }
}
