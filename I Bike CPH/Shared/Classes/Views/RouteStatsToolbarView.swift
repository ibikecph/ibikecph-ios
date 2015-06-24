//
//  RouteStatsToolbarView.swift
//  I Bike CPH
//
//  Created by Tobias Due Munk on 04/06/15.
//  Copyright (c) 2015 I Bike CPH. All rights reserved.
//

import UIKit


class RouteStatsToolbarView: ToolbarView {

    
    @IBOutlet weak var distanceLabel: UILabel!
    @IBOutlet weak var durationLabel: UILabel!
    @IBOutlet weak var arrivalTime: UILabel!
    
    let hourMinuteFormatter = HourMinuteFormatter()
    let distanceFormatter = DistanceFormatter()
    lazy var dateFormatter: NSDateFormatter = {
        let formatter = NSDateFormatter()
        formatter.timeStyle = .ShortStyle
        formatter.dateStyle = .NoStyle // No date
        return formatter
    }()
}

extension RouteStatsToolbarView {
    
    func prepareForReuse() {
        distanceLabel.text = nil
        durationLabel.text = nil
        arrivalTime.text = nil
    }
    
    func updateToRoute(route: SMRoute) {
        distanceLabel.text = distanceFormatter.string(meters: Double(route.distanceLeft))
        let partLeft = route.distanceLeft / CGFloat(route.estimatedRouteDistance)
        let estimatedTimeForRoute = NSTimeInterval(CGFloat(route.estimatedTimeForRoute) * partLeft)
        durationLabel.text = hourMinuteFormatter.string(seconds: estimatedTimeForRoute)
        arrivalTime.text = dateFormatter.stringFromDate(NSDate(timeIntervalSinceNow: estimatedTimeForRoute))
    }
}
