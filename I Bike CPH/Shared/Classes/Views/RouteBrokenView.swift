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
        scroll.stackView.direction = .vertical
        self.addSubview(scroll)
        scroll.translatesAutoresizingMaskIntoConstraints = false
        self.addConstraints([
            NSLayoutConstraint(item: scroll, attribute: .top, relatedBy: .equal, toItem: self, attribute: .top, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: scroll, attribute: .left, relatedBy: .equal, toItem: self, attribute: .left, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: scroll, attribute: .right, relatedBy: .equal, toItem: self, attribute: .right, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: scroll, attribute: .bottom, relatedBy: .equal, toItem: self, attribute: .bottom, multiplier: 1, constant: 0)
            ])
        return scroll
    }()

    init(route: RouteComposite) {
        self.routeComposite = route
        super.init(frame: CGRect.zero)

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
            case .single(let route): return [route]
            case .multiple(let routes): return routes
            }
        }()
        for route in subRoutes {
            let subView = RouteBrokenPartView(route: route)
            stackScrollView.stackView.addSubview(subView, withPrecedingMargin: 0, sideMargin: 0)
        }
    }
}





