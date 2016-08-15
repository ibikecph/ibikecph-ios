//
//  RouteComposite.swift
//  I Bike CPH
//

import Foundation

struct RouteComposite {
    enum Composite {
        case Single(SMRoute)
        case Multiple([SMRoute])
    }
    let composite: Composite
    let from: SearchListItem
    let to: SearchListItem
    let estimatedDistance: Double
    let estimatedBikeDistance: Double
    let estimatedTime: NSTimeInterval
    var distanceLeft: Double {
        switch composite {
        case .Single(let route):
            return Double(route.distanceLeft)
        case .Multiple(let routes):
            return routes.map { Double($0.distanceLeft) }.reduce(0) { $0 + $1 }
        }
    }
    var formattedBikeDistanceLeft: String {
        let distanceFormatter = DistanceFormatter()
        return distanceFormatter.string(self.bikeDistanceLeft)
    }
    var bikeDistanceLeft: Double {
        switch composite {
        case .Single(let route):
            return Double(route.distanceLeft)
        case .Multiple(let routes):
            let bikeRoutes = routes.filter { return .Bike == $0.routeType }
            return bikeRoutes.map { Double($0.distanceLeft) }.reduce(0) { $0 + $1 }
        }
    }
    var currentRouteIndex: Int = 0
    var currentRoute: SMRoute? {
        switch composite {
        case .Single(let route): return route
        case .Multiple(let routes):
            if currentRouteIndex < routes.count {
                return routes[currentRouteIndex]
            }
            return nil
        }
    }
    var formattedDurationLeft: String {
        let hourMinuteFormatter = HourMinuteFormatter()
        return hourMinuteFormatter.string(self.durationLeft)
    }
    var durationLeft: NSTimeInterval {
        switch self.composite {
        case .Single(let route):
            if (route.estimatedAverageSpeed == 0) {
                // Use estimate from OSRM server
                return self.estimatedTime * self.distanceLeft / self.estimatedDistance
            } else {
                // Create own estimate
                return self.bikeDistanceLeft / Double(route.estimatedAverageSpeed)
            }
        case .Multiple(let routes):
            let route = routes.last!
            var duration: NSTimeInterval = 0
            if currentRouteIndex == routes.count-1 {
                // User is currently on the last route
                if route.routeType == .Bike {
                    if (route.estimatedAverageSpeed == 0) {
                        // Use estimate from OSRM server
                        duration += Double(route.distanceLeft) / Double(route.estimatedRouteDistance) * NSTimeInterval(route.estimatedTimeForRoute)
                    } else {
                        // Create own estimate
                        duration += Double(route.distanceLeft) / Double(route.estimatedAverageSpeed)
                    }
                } else {
                    if let endDate = route.endDate {
                        duration = endDate.timeIntervalSinceNow
                    }
                }
            } else {
                // User is not on the last route yet
                if let endDate = route.endDate {
                    duration = endDate.timeIntervalSinceNow
                }
            }
            // At this point the duration could be zero
            return duration
        }
    }
    var estimatedTimeOfArrival: NSDate {
        return NSDate(timeIntervalSinceNow: self.durationLeft)
    }
    private init(composite: Composite, from: SearchListItem, to: SearchListItem, estimatedDistance: Double, estimatedBikeDistance: Double? = nil, estimatedTime: NSTimeInterval) {
        self.composite = composite
        self.from = from
        self.to = to
        self.estimatedDistance = estimatedDistance
        self.estimatedBikeDistance = estimatedBikeDistance ?? estimatedDistance
        self.estimatedTime = estimatedTime
        switch composite {
        case .Multiple(let routes):

            for (index, route) in routes.enumerate() {
                // If route is public, finish route earlier
                if route.routeType != .Bike &&
                    route.routeType != .Walk {
                        route.maxMarginRadius = CGFloat(MAX_DISTANCE_FOR_PUBLIC_TRANSPORT)
                }
                // If next route is public, finish current route earlier
                if index+1 < routes.count {
                    let nextRoute = routes[index+1]
                    if nextRoute.routeType != .Bike &&
                        nextRoute.routeType != .Walk {
                        route.maxMarginRadius = CGFloat(MAX_DISTANCE_FOR_PUBLIC_TRANSPORT)
                    }
                }
            }
        default: break
        }
    }
    init(route: SMRoute, from: SearchListItem, to: SearchListItem) {
        self.init(composite: .Single(route), from: from, to: to, estimatedDistance: Double(route.estimatedRouteDistance), estimatedTime: Double(route.estimatedTimeForRoute))
    }
    init(routes: [SMRoute], from: SearchListItem, to: SearchListItem, estimatedDistance: Double, estimatedBikeDistance: Double, estimatedTime: NSTimeInterval) {
        self.init(composite: .Multiple(routes), from: from, to: to, estimatedDistance: estimatedDistance, estimatedBikeDistance: estimatedBikeDistance, estimatedTime: estimatedTime)
    }
}
