//
//  RouteBrokenToolbarView.swift
//  I Bike CPH
//
//  Created by Tobias Due Munk on 04/06/15.
//  Copyright (c) 2015 I Bike CPH. All rights reserved.
//

import UIKit
import ORStackView

class RouteBrokenToolbarView: ToolbarView {

    @IBOutlet weak var contentView: UIView!

    let stackScrollView: ORStackScrollView = {
        let scroll = ORStackScrollView()
        scroll.stackView.direction = .Horizontal
        scroll.pagingEnabled = true
        scroll.alwaysBounceHorizontal = false
        scroll.showsHorizontalScrollIndicator = false
        return scroll
    }()

    override func prepareForReuse() {
        super.prepareForReuse()
        updateToViews([])
    }
    
    func updateToRoute(route: SMRoute) {
        updateToViews([])
    }

    func updateToViews(views: [UIView]) {
        if stackScrollView.superview == nil {
            contentView.addSubview(stackScrollView)
            stackScrollView.setTranslatesAutoresizingMaskIntoConstraints(false)
            addConstraints([
                NSLayoutConstraint(item: stackScrollView, attribute: .Top, relatedBy: .Equal, toItem: contentView, attribute: .Top, multiplier: 1, constant: 0),
                NSLayoutConstraint(item: stackScrollView, attribute: .Left, relatedBy: .Equal, toItem: contentView, attribute: .Left, multiplier: 1, constant: 0),
                NSLayoutConstraint(item: stackScrollView, attribute: .Right, relatedBy: .Equal, toItem: contentView, attribute: .Right, multiplier: 1, constant: 0),
                NSLayoutConstraint(item: stackScrollView, attribute: .Bottom, relatedBy: .Equal, toItem: contentView, attribute: .Bottom, multiplier: 1, constant: 0)
                ])
        }

        let stack = stackScrollView.stackView
        stack.removeAllSubviews()
        for view in views {
            stack.addSubview(view, withPrecedingMargin: 0, sideMargin: 0)
            addConstraint(NSLayoutConstraint(item: view, attribute: .Width, relatedBy: .Equal, toItem: contentView, attribute: .Width, multiplier: 1, constant: 0))
        }
    }
}