//
//  SMRoute_Tests.swift
//  I Bike CPH
//
//  Created by Tobias Due Munk on 29/01/15.
//  Copyright (c) 2015 I Bike CPH. All rights reserved.
//

import UIKit
import XCTest
import CoreLocation

class SMRoute_Tests: XCTestCase {

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

//    func testOffRoute() {
//        class MockSMRoute: SMRoute {
//            override func recalculateRoute(loc: CLLocation) {
//                XCTAssert(true, "Should recalc")
//            }
//        }
//        
//        let start = CLLocationCoordinate2DMake(55.691326, 12.553318)
//        let end = CLLocationCoordinate2DMake(55.677849, 12.570681)
//        let json = jsonRoute()
//        let route = MockSMRoute(routeStart: start, andEnd: end, andDelegate: nil, andJSON: json)
//        route.estimatedAverageSpeed = 15
//        
//        let off = CLLocationCoordinate2DMake(55.691326, 12.553318)
//        let offLocation = CLLocation(coordinate: off, altitude: 0, horizontalAccuracy: 0, verticalAccuracy: 0, timestamp: NSDate())
//        route.visitLocation(offLocation)
//    }
    
    
    func routeInstructions() -> [[AnyObject]] {
        return [
            [ 10, "Nørrebrogade", 736, 0, 209, "736m", "SE", 139, 1 ],
            [ 1, "Dronning Louises Bro", 211, 14, 55, "211m", "SE", 124, 1 ],
            [ 1, "Frederiksborggade", 12, 19, 11, "12m", "SE", 119, 1 ],
            [ 3, "{highway:cycleway}", 70, 20, 20, "70m", "SE", 156, 1 ],
            [ 8, "Vendersgade", 468, 24, 126, "468m", "SE", 135, 1 ],
            [ 3, "Nørre Voldgade", 220, 33, 59, "219m", "SW", 217, 1 ],
            [ 1, "Nørre Voldgade", 17, 40, 4, "16m", "SW", 215, 2 ],
            [ 1, "Nørre Voldgade", 130, 41, 35, "129m", "SW", 217, 2 ],
            [ 8, "Teglgårdstræde", 134, 42, 32, "133m", "SE", 135, 1 ],
            [ 1, "Larsbjørnsstræde", 180, 44, 52, "179m", "SE", 151, 1 ],
            [ 7, "Vestergade", 38, 46, 5, "37m", "NE", 57, 1 ],
            [ 15, "", 0, 47, 0, "0m", "N", 0 ]
        ]
    }
    
    func routeSummary() -> [String : AnyObject] {
        return [
            "end_point": "Vestergade",
            "start_point": "Nørrebrogade",
            "total_distance": 2216,
            "total_time": 606,
        ]
    }
    func hintData() -> [String : AnyObject] {
        return [
            "locations": [
                "uTkAAMM5AABDAAAARgAAAJUAAAAAAAAAAAAAAP____84yFEDc4y_AAAAEbU",
                "gwwAABoyAABkAAAAZAAAADcAAADJAAAAAAAAAGBVAgCZk1EDOdC_AAEAEgA"
            ],
        ]
    }
    func viaPoints() -> [[String]] {
        return [ [ "55.691319", "12.553331" ], [ "55.677849", "12.570681" ] ]
    }
    
    func jsonRoute() -> [NSObject : AnyObject] {
        return [
            "found_alternative": 0,
            "hint_data": hintData(),
            "route_geometry": "obcfiBefe]VjYmg tUw_ `Ta_ h]yo |\\elAzCoKhD]LxNih zHwY|WaaArJe` rR [v tOek hOal rC]Jvo o [BvFoIfEaM`BaFtBqIjGqEvBdAdRbSjB`Czr s [A|Zit r[ejApMmc `CsIvDwLtCoK`Vky bDgEjWd_ xSvZnOvU~IxOzDVrMz bJj tFxHry jlA`CuEz [ e [ pa y` nt su sJw^",
            "route_instructions": routeInstructions(),
            "route_name": [ "Nørrebrogade", "Vendersgade"],
            "route_summary": routeSummary(),
            "status": 0,
            "status_message": "Found route between points",
            "via_indices": [ 0, 48],
            "via_points": viaPoints(),
        ]
    }


}




