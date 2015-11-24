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
    
    func updateToRoute(routeComposite: RouteComposite) {
        let distanceLeft = routeComposite.bikeDistanceLeft
        let durationLeft: NSTimeInterval = {
            switch routeComposite.composite {
            case .Single(_):
                return routeComposite.estimatedTime * routeComposite.distanceLeft / routeComposite.estimatedDistance
            case .Multiple(let routes):
                let current = routeComposite.currentRoute
                let currentRoute = routes[current]
                var duration: NSTimeInterval = 0
                // Current route
                let bikeOrWalk = SMRouteTypeBike.value == currentRoute.routeType.value || SMRouteTypeWalk.value == currentRoute.routeType.value
                if bikeOrWalk,
                    let endDate = currentRoute.endDate {
                    duration += max(endDate.timeIntervalSinceNow, 0)
                } else {
                    return Double(currentRoute.distanceLeft) / Double(currentRoute.estimatedRouteDistance) * NSTimeInterval(currentRoute.estimatedTimeForRoute)
                }
                // Routes after current
                let afterCurrentRoutes = current+1 < routes.count ? routes[current+1..<routes.count] : []
                for route in afterCurrentRoutes {
                    duration += NSTimeInterval(route.estimatedTimeForRoute)
                }
                return duration
            }
        }()
        let eta = NSDate(timeIntervalSinceNow: durationLeft)
        updateTo(distance: distanceLeft, duration: durationLeft, eta: eta)
    }
    
    func updateTo(#distance: Double, duration: Double, eta: NSDate?) {
        distanceLabel.text = distanceFormatter.string(meters: distance)
        durationLabel.text = hourMinuteFormatter.string(seconds: duration)
        arrivalTime.text = eta == nil ? "" : dateFormatter.stringFromDate(eta!)
    }
}
