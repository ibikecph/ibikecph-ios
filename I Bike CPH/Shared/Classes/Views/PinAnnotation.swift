//
//  PinAnnotation.swift
//  I Bike CPH
//
//  Created by Tobias Due Munk on 08/06/15.
//  Copyright (c) 2015 I Bike CPH. All rights reserved.
//

import UIKit
import MapboxGL

class PinAnnotation: NSObject, MGLAnnotation {
   
    @objc var coordinate: CLLocationCoordinate2D
    @objc var title: String = ""
    @objc var subtitle: String = ""
    
    init(coordinate: CLLocationCoordinate2D) {
        self.coordinate = coordinate
//        super.init(frame: CGRectMake(0, 0, 40, 40))
//        backgroundColor = UIColor.blueColor()
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
