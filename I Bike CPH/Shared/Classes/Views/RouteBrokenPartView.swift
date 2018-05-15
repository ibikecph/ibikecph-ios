//
//  RouteBrokenPartView.swift
//  I Bike CPH
//
//  Created by Tobias Due Munk on 18/11/15.
//  Copyright (c) 2015 I Bike CPH. All rights reserved.
//

import UIKit
import ORStackView


class RouteBrokenPartView: UIView {

    let route: SMRoute

    fileprivate let hourMinuteFormatter = HourMinuteFormatter()
    fileprivate let distanceFormatter = DistanceFormatter()
    lazy var timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .none // No date
        return formatter
    }()

    fileprivate lazy var stackView: ORStackView = {
        let scroll = ORStackView()
        scroll.direction = .horizontal
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

    fileprivate lazy var typeImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .center
        return imageView
    }()
    fileprivate lazy var dotsImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .center
        return imageView
    }()
    fileprivate lazy var departureLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.preferredFont(forTextStyle: UIFontTextStyle.body)
        label.textColor = Styler.foregroundColor()
        label.numberOfLines = 1
        label.textAlignment = .right
        return label
    }()
    fileprivate lazy var arrivalLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.preferredFont(forTextStyle: UIFontTextStyle.footnote)
        label.textColor = Styler.foregroundSecondaryColor()
        label.numberOfLines = 2
        label.textAlignment = .right
        return label
    }()
    fileprivate lazy var topLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.preferredFont(forTextStyle: UIFontTextStyle.body)
        label.textColor = Styler.foregroundColor()
        label.numberOfLines = 1
        return label
    }()
    fileprivate lazy var bottomLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.preferredFont(forTextStyle: UIFontTextStyle.footnote)
        label.textColor = Styler.foregroundSecondaryColor()
        label.numberOfLines = 2
        return label
    }()

    init(route: SMRoute) {
        self.route = route
        super.init(frame: CGRect.zero)

        // Setup view
        setupView()
        populateView()
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }


    fileprivate func setupView() {
        let horizontalPadding: CGFloat = 10

        let leftContainer = ORStackView()
        leftContainer.addSubview(departureLabel, withPrecedingMargin: 0, sideMargin: 0)
        leftContainer.addSubview(arrivalLabel, withPrecedingMargin: 0, sideMargin: 0)
        leftContainer.addConstraint(
            NSLayoutConstraint(item: leftContainer, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 0, constant: 70)
        )

        let centerContainer = ORStackView()
        centerContainer.addSubview(typeImageView, withPrecedingMargin: 0, sideMargin: 0)
        centerContainer.addSubview(dotsImageView, withPrecedingMargin: 0, sideMargin: 0)
        centerContainer.addConstraint(
            NSLayoutConstraint(item: centerContainer, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 0, constant: 22)
        )

        let rightContainer = ORStackView()
        rightContainer.addSubview(topLabel, withPrecedingMargin: 0, sideMargin: 0)
        rightContainer.addSubview(bottomLabel, withPrecedingMargin: 0, sideMargin: 0)

        stackView.addSubview(leftContainer, withPrecedingMargin: horizontalPadding, sideMargin: 0)
        stackView.addSubview(centerContainer, withPrecedingMargin: horizontalPadding, sideMargin: 0)
        stackView.addSubview(rightContainer, withPrecedingMargin: horizontalPadding, sideMargin: 0)

        stackView.lastMarginHeight = horizontalPadding
    }

    fileprivate func populateView() {
        let departureDate = route.startDate ?? Date()
        let arrivalDate = route.endDate ?? departureDate.addingTimeInterval(TimeInterval(route.estimatedRouteDistance))
        let startPlace = route.startDescription.localized
        let endPlace = route.endDescription.localized
        let distance = distanceFormatter.string(Double(route.estimatedRouteDistance))
        let duration = hourMinuteFormatter.string(TimeInterval(route.estimatedTimeForRoute))

        var topLabelString = startPlace
        var bottomLabelString = route.transportLine + " " + "to".localized + "\n" + endPlace
        var imageName = ""

        switch route.routeType {
        case .bike:
            imageName = "Bike"
            topLabelString = "vehicle_1".localized + " " + distance +  ", " + duration
            bottomLabelString = "from".localized + " " + startPlace + " " + "to".localized + "\n" + endPlace
        case .walk:
            imageName = "Walk"
            topLabelString = "vehicle_2".localized + " " + distance +  ", " + duration
            bottomLabelString = "from".localized + " " + startPlace + " " + "to".localized + "\n" + endPlace
        case .sTrain:
            imageName = "STrain"
        case .metro:
            imageName = "Metro"
        case .ferry:
            imageName = "Ferry"
        case .bus:
            imageName = "Bus"
        case .train:
            imageName = "Train"
        }

        typeImageView.image = UIImage(named: imageName)
        dotsImageView.image = UIImage(named: "RouteLine")

        departureLabel.text = timeFormatter.string(from: departureDate)
        arrivalLabel.text = "\0\n" + timeFormatter.string(from: arrivalDate)

        topLabel.text = topLabelString
        bottomLabel.text = bottomLabelString
    }
}
