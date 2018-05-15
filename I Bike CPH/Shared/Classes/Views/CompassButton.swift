//
//  CompassButton.swift
//  I Bike CPH
//
//  Created by Tobias Due Munk on 04/06/15.
//  Copyright (c) 2015 I Bike CPH. All rights reserved.
//

import UIKit


class CompassButton: UIButton {

    var userTrackingMode: MapView.UserTrackingMode = .none {
        didSet {
            let imageName: String = {
                switch self.userTrackingMode {
                    case .none: return "Compas unselected"
                    case .follow: return "Compas selected"
                    case .followWithHeading: return "Compas active"
                }
            }()
            setImage(UIImage(named: imageName), for: UIControlState())
        }
    }
    var circleColor: UIColor = Styler.tintColor()
    override var isHighlighted: Bool {
        didSet {
            highlight(isHighlighted)
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    init() {
        super.init(frame: CGRect.zero)
        setup()
    }
    
    func setup() {
        adjustsImageWhenHighlighted = false
        highlight(false)
    }
    
    func highlight(_ highlight: Bool = false) {
        shadow(highlight)
    }
    
    func shadow(_ lifted: Bool = false) {
        layer.masksToBounds = false
        let offset = lifted  ? 4 : 0.5
        layer.shadowOffset = CGSize(width: 0, height: offset)
        layer.shadowRadius = lifted ? 4.5 : 1.5
        layer.shadowOpacity =  0.5
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
    }
    
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        
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
        context?.setFillColor(circleColor.cgColor)
        context?.fillEllipse (in: circleRect)
        context?.fillPath()
    }
}
