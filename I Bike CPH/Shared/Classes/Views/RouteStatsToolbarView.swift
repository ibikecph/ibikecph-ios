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

    override func prepareForReuse() {
        super.prepareForReuse()
        updateTo(distance: 0, duration: 0, eta: NSDate())
    }
    
    func updateToRoute(route: SMRoute) {
        let distance = Double(route.distanceLeft)
        let partLeft = route.distanceLeft / CGFloat(route.estimatedRouteDistance)
        let duration = NSTimeInterval(CGFloat(route.estimatedTimeForRoute) * partLeft)
        let eta = NSDate(timeIntervalSinceNow: duration)
        updateTo(distance: distance, duration: duration, eta: eta)
    }
    
    func updateTo(#distance: Double, duration: Double, eta: NSDate?) {
        distanceLabel.text = distanceFormatter.string(meters: distance)
        durationLabel.text = hourMinuteFormatter.string(seconds: duration)
        arrivalTime.text = eta == nil ? "" : dateFormatter.stringFromDate(eta!)
    }
}
