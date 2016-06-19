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
    
    lazy var dateFormatter: NSDateFormatter = {
        let formatter = NSDateFormatter()
        formatter.timeStyle = .ShortStyle
        formatter.dateStyle = .NoStyle // No date
        return formatter
    }()

    override func prepareForReuse() {
        super.prepareForReuse()
        updateTo("", durationLeft: "", eta: NSDate())
    }
    
    func updateToRoute(routeComposite: RouteComposite) {
        let distanceLeft = routeComposite.formattedBikeDistanceLeft
        let durationLeft = routeComposite.formattedDurationLeft
        let eta = routeComposite.estimatedTimeOfArrival
        updateTo(distanceLeft, durationLeft: durationLeft, eta: eta)
    }
    
    func updateTo(distanceLeft: String, durationLeft: String, eta: NSDate?) {
        distanceLabel.text = distanceLeft
        durationLabel.text = durationLeft
        arrivalTime.text = eta == nil ? "" : dateFormatter.stringFromDate(eta!)
    }
}
