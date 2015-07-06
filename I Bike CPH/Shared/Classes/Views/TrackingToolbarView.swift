//
//  TrackingToolbarView.swift
//  I Bike CPH
//
//  Created by Tobias Due Munk on 04/06/15.
//  Copyright (c) 2015 I Bike CPH. All rights reserved.
//

import UIKit

protocol TrackingToolbarDelegate {
    func didSelectOpenTracking()
}

class TrackingToolbarView: ToolbarView {

    @IBOutlet weak var distanceLabel: UILabel!
    @IBOutlet weak var durationLabel: UILabel!
    
    var delegate: TrackingToolbarDelegate?
    
    private let hourMinutesFormatter = HourMinuteFormatter()
    private let distanceFormatter = DistanceFormatter()
    
    var distance: Double = 0 {
        didSet {
            distanceLabel?.text = distanceFormatter.string(meters: distance)
        }
    }
    var duration: Double = 0 {
        didSet {
            durationLabel?.text = hourMinutesFormatter.string(seconds: duration)
        }
    }
    @IBAction func didTapView(sender: AnyObject) {
        delegate?.didSelectOpenTracking()
    }
}
