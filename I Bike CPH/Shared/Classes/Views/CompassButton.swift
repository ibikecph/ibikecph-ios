//
//  CompassButton.swift
//  I Bike CPH
//
//  Created by Tobias Due Munk on 04/06/15.
//  Copyright (c) 2015 I Bike CPH. All rights reserved.
//

import UIKit
import MapboxGL

@IBDesignable
class CompassButton: UIButton {

    var userTrackingMode: MGLUserTrackingMode = .None {
        didSet {
            let imageName: String = {
                switch self.userTrackingMode {
                    case .None: return "Compas unselected"
                    case .Follow: return "Compas selected"
                    case .FollowWithHeading: return "Compas active"
                }
            }()
            setImage(UIImage(named: imageName), forState: .Normal)
        }
    }
    
    override func prepareForInterfaceBuilder() {
        setTitle("TEST", forState: .Normal)
        
//        setImage(UIImage(named: "Compass unselected"), forState: .Normal)
    }
}
