//
//  Statistics.swift
//  I Bike CPH
//
//  Created by Tobias Due Munk on 09/03/15.
//  Copyright (c) 2015 I Bike CPH. All rights reserved.
//

import UIKit

class BikeStatistics {
   
    /**
    :returns: All bike tracks as an RLMResults
    */
    class func tracks() -> RLMResults {
        return Track.objectsWhere("activity.cycling == TRUE")
    }
    
    /**
    Total distance of bike all tracks
    
    :returns: Total distance in meters [m]
     */
    class func totalDistance() -> Double {
        return (tracks().sumOfProperty("length")?.doubleValue ?? 0)
    }
    
    /**
    Total duration of bike all tracks
    
    :returns: Total duration in seconds [s]
    */
    class func totalDuration() -> Double {
        return (tracks().sumOfProperty("duration")?.doubleValue ?? 0)
    }
    
    /**
    Average speed of bike all tracks
    
    :returns: Average speed in meter pr. second [m/s]
    */
    class func averageSpeed() -> Double {
        let duration = totalDuration()
        return duration == 0 ? 0 : totalDistance() / duration
    }
    
    /**
    Average distance of bike all tracks
    
    :returns: Average track distance in meters [m]
    */
    class func averageTrackDistance() -> Double {
        return tracks().averageOfProperty("length")?.doubleValue ?? 0
    }
}
