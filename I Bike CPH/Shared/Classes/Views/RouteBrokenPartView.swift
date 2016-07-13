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

    private let hourMinuteFormatter = HourMinuteFormatter()
    private let distanceFormatter = DistanceFormatter()
    lazy var timeFormatter: NSDateFormatter = {
        let formatter = NSDateFormatter()
        formatter.timeStyle = .ShortStyle
        formatter.dateStyle = .NoStyle // No date
        return formatter
    }()

    private lazy var stackView: ORStackView = {
        let scroll = ORStackView()
        scroll.direction = .Horizontal
        self.addSubview(scroll)
        scroll.translatesAutoresizingMaskIntoConstraints = false
        self.addConstraints([
            NSLayoutConstraint(item: scroll, attribute: .Top, relatedBy: .Equal, toItem: self, attribute: .Top, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: scroll, attribute: .Left, relatedBy: .Equal, toItem: self, attribute: .Left, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: scroll, attribute: .Right, relatedBy: .Equal, toItem: self, attribute: .Right, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: scroll, attribute: .Bottom, relatedBy: .Equal, toItem: self, attribute: .Bottom, multiplier: 1, constant: 0)
            ])
        return scroll
    }()

    private lazy var typeImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .Center
        return imageView
    }()
    private lazy var dotsImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .Center
        return imageView
    }()
    private lazy var departureLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.preferredFontForTextStyle(UIFontTextStyleBody)
        label.textColor = Styler.foregroundColor()
        label.numberOfLines = 1
        label.textAlignment = .Right
        return label
    }()
    private lazy var arrivalLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.preferredFontForTextStyle(UIFontTextStyleFootnote)
        label.textColor = Styler.foregroundSecondaryColor()
        label.numberOfLines = 2
        label.textAlignment = .Right
        return label
    }()
    private lazy var topLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.preferredFontForTextStyle(UIFontTextStyleBody)
        label.textColor = Styler.foregroundColor()
        label.numberOfLines = 1
        return label
    }()
    private lazy var bottomLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.preferredFontForTextStyle(UIFontTextStyleFootnote)
        label.textColor = Styler.foregroundSecondaryColor()
        label.numberOfLines = 2
        return label
    }()

    init(route: SMRoute) {
        self.route = route
        super.init(frame: CGRectZero)

        // Setup view
        setupView()
        populateView()
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }


    private func setupView() {
        let horizontalPadding: CGFloat = 10

        let leftContainer = ORStackView()
        leftContainer.addSubview(departureLabel, withPrecedingMargin: 0, sideMargin: 0)
        leftContainer.addSubview(arrivalLabel, withPrecedingMargin: 0, sideMargin: 0)
        leftContainer.addConstraint(
            NSLayoutConstraint(item: leftContainer, attribute: .Width, relatedBy: .Equal, toItem: nil, attribute: .NotAnAttribute, multiplier: 0, constant: 70)
        )

        let centerContainer = ORStackView()
        centerContainer.addSubview(typeImageView, withPrecedingMargin: 0, sideMargin: 0)
        centerContainer.addSubview(dotsImageView, withPrecedingMargin: 0, sideMargin: 0)
        centerContainer.addConstraint(
            NSLayoutConstraint(item: centerContainer, attribute: .Width, relatedBy: .Equal, toItem: nil, attribute: .NotAnAttribute, multiplier: 0, constant: 22)
        )

        let rightContainer = ORStackView()
        rightContainer.addSubview(topLabel, withPrecedingMargin: 0, sideMargin: 0)
        rightContainer.addSubview(bottomLabel, withPrecedingMargin: 0, sideMargin: 0)

        stackView.addSubview(leftContainer, withPrecedingMargin: horizontalPadding, sideMargin: 0)
        stackView.addSubview(centerContainer, withPrecedingMargin: horizontalPadding, sideMargin: 0)
        stackView.addSubview(rightContainer, withPrecedingMargin: horizontalPadding, sideMargin: 0)

        stackView.lastMarginHeight = horizontalPadding
    }

    private func populateView() {
        let departureDate = route.startDate ?? NSDate()
        let arrivalDate = route.endDate ?? departureDate.dateByAddingTimeInterval(NSTimeInterval(route.estimatedRouteDistance))
        let startPlace = route.startDescription.localized
        let endPlace = route.endDescription.localized
        let distance = distanceFormatter.string(Double(route.estimatedRouteDistance))
        let duration = hourMinuteFormatter.string(NSTimeInterval(route.estimatedTimeForRoute))

        var topLabelString = startPlace
        var bottomLabelString = route.transportLine + " " + "to".localized + "\n" + endPlace
        var imageName = ""

        switch route.routeType {
        case .Bike:
            imageName = "Bike"
            topLabelString = "vehicle_1".localized + " " + distance +  ", " + duration
            bottomLabelString = "from".localized + " " + startPlace + " " + "to".localized + "\n" + endPlace
        case .Walk:
            imageName = "Walk"
            topLabelString = "vehicle_2".localized + " " + distance +  ", " + duration
            bottomLabelString = "from".localized + " " + startPlace + " " + "to".localized + "\n" + endPlace
        case .STrain:
            imageName = "STrain"
        case .Metro:
            imageName = "Metro"
        case .Ferry:
            imageName = "Ferry"
        case .Bus:
            imageName = "Bus"
        case .Train:
            imageName = "Train"
        default: break
        }

        typeImageView.image = UIImage(named: imageName)
        dotsImageView.image = UIImage(named: "RouteLine")

        departureLabel.text = timeFormatter.stringFromDate(departureDate)
        arrivalLabel.text = "\0\n" + timeFormatter.stringFromDate(arrivalDate)

        topLabel.text = topLabelString
        bottomLabel.text = bottomLabelString
    }
}
