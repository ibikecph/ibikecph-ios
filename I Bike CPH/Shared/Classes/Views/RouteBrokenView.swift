//
//  RouteBrokenView.swift
//  I Bike CPH
//
//  Created by Tobias Due Munk on 18/11/15.
//  Copyright (c) 2015 I Bike CPH. All rights reserved.
//

import UIKit
import ORStackView


class RouteBrokenView: UIView {

    let routeComposite: RouteComposite

    lazy var stackScrollView: ORStackScrollView = {
        let scroll = ORStackScrollView()
        scroll.stackView.direction = .Vertical
        self.addSubview(scroll)
        scroll.setTranslatesAutoresizingMaskIntoConstraints(false)
        self.addConstraints([
            NSLayoutConstraint(item: scroll, attribute: .Top, relatedBy: .Equal, toItem: self, attribute: .Top, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: scroll, attribute: .Left, relatedBy: .Equal, toItem: self, attribute: .Left, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: scroll, attribute: .Right, relatedBy: .Equal, toItem: self, attribute: .Right, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: scroll, attribute: .Bottom, relatedBy: .Equal, toItem: self, attribute: .Bottom, multiplier: 1, constant: 0)
            ])
        return scroll
    }()

    init(route: RouteComposite) {
        self.routeComposite = route
        super.init(frame: CGRectZero)

        // Setup view
        populateView()
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func populateView() {
        stackScrollView.stackView.removeAllSubviews()
        let subRoutes: [SMRoute] = {
            switch self.routeComposite.composite {
            case .Single(let route): return [route]
            case .Multiple(let routes): return routes
            }
        }()
        for route in subRoutes {
            let subView = RouteBrokenPartView(route: route)
            stackScrollView.stackView.addSubview(subView, withPrecedingMargin: 0, sideMargin: 0)
        }
    }
}





