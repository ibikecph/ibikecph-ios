//
//  TrackTableViewCell.swift
//  I Bike CPH
//
//  Created by Tobias Due Munk on 16/03/15.
//  Copyright (c) 2015 I Bike CPH. All rights reserved.
//

import UIKit

class TrackTableViewCell: UITableViewCell {

    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var topAddressLabel: UILabel!
    @IBOutlet weak var bottomAddressLabel: UILabel!
    
    @IBOutlet weak var durationLabel: UILabel!
    @IBOutlet weak var distanceLabel: UILabel!
    
    private let dateFormatter: NSDateFormatter = {
        let formatter = NSDateFormatter()
        formatter.timeStyle = .ShortStyle
        return formatter
    }()
    
    let hourMinutesFormatter = HourMinuteFormatter()
    let distanceFormatter = DistanceFormatter()
    
    func updateToTrack(track: Track?) {
        if let track = track where !track.invalidated {
            var time = ""
            if let date = track.startDate() {
                time += dateFormatter.stringFromDate(date)
            }
            if let date = track.endDate() {
                time += " - " + dateFormatter.stringFromDate(date)
            }
            timeLabel.text = time
            
            // Duration in minutes
            let duration = track.duration
            durationLabel.text = hourMinutesFormatter.string(seconds: duration)
            // Distance in km
            let distance = track.length
            distanceLabel.text = distanceFormatter.string(meters: distance)
            
            topAddressLabel.text = track.end == "" ? "–" : track.end
            bottomAddressLabel.text = track.start == "" ? "–" : track.start
        } else {
            timeLabel.text = "–"
            durationLabel.text = hourMinutesFormatter.string(seconds: 0)
            distanceLabel.text = distanceFormatter.string(meters: 0)
            topAddressLabel.text = "–"
            bottomAddressLabel.text = "–"
        }
        SMTranslation.translateView(contentView)
    }
}
