//
//  CompassButton.swift
//  I Bike CPH
//
//  Created by Tobias Due Munk on 04/06/15.
//  Copyright (c) 2015 I Bike CPH. All rights reserved.
//

import UIKit
import MapboxGL


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
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    init() {
        super.init(frame: CGRectZero)
        setup()
    }
    
    func setup() {
        shadow(lifted: false)
    }
    
    override func touchesBegan(touches: Set<NSObject>, withEvent event: UIEvent) {
        super.touchesBegan(touches, withEvent: event)
        shadow(lifted: true)
    }
    
    override func touchesCancelled(touches: Set<NSObject>!, withEvent event: UIEvent!) {
        super.touchesCancelled(touches, withEvent: event)
        shadow(lifted: false)
    }
    
    override func touchesEnded(touches: Set<NSObject>, withEvent event: UIEvent) {
        super.touchesEnded(touches, withEvent: event)
        shadow(lifted: false)
    }
    
    func shadow(lifted: Bool = false) {
        layer.masksToBounds = false
        let offset = lifted  ? 4 : 0.5
        layer.shadowOffset = CGSize(width: 0, height: offset)
        layer.shadowRadius = lifted ? 4.5 : 1.5
        layer.shadowOpacity =  0.5
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
    }
    
    override func drawRect(rect: CGRect) {
        super.drawRect(rect)
        
        // Take account for off-center content 
        let verticalOffset = contentEdgeInsets.top - contentEdgeInsets.bottom
        let horizontalOffset = contentEdgeInsets.left - contentEdgeInsets.right
        let topInset = max(verticalOffset, 0)
        let leftInset = max(horizontalOffset, 0)
        let bottomInset = max(-verticalOffset, 0)
        let rightInset = max(-horizontalOffset, 0)
        let inset = UIEdgeInsets(top: topInset, left: leftInset, bottom: bottomInset, right: rightInset)
        let circleRect = UIEdgeInsetsInsetRect(rect, inset)
        // Draw circle
        let context = UIGraphicsGetCurrentContext()
        CGContextSetFillColorWithColor(context, tintColor?.CGColor)
        CGContextFillEllipseInRect (context, circleRect)
        CGContextFillPath(context)
    }
}
