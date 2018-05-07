//
//  RouteComposite.swift
//  I Bike CPH
//

import Foundation

struct RouteComposite {
    enum Composite {
        case single(SMRoute)
        case multiple([SMRoute])
    }
    let composite: Composite
    let from: SearchListItem
    let to: SearchListItem
    let estimatedDistance: Double
    let estimatedBikeDistance: Double
    let estimatedTime: TimeInterval
    var distanceLeft: Double {
        switch composite {
        case .single(let route):
            return Double(route.distanceLeft)
        case .multiple(let routes):
            return routes.map { Double($0.distanceLeft) }.reduce(0) { $0 + $1 }
        }
    }
    var formattedBikeDistanceLeft: String {
        let distanceFormatter = DistanceFormatter()
        return distanceFormatter.string(self.bikeDistanceLeft)
    }
    var bikeDistanceLeft: Double {
        switch composite {
        case .single(let route):
            return Double(route.distanceLeft)
        case .multiple(let routes):
            let bikeRoutes = routes.filter { return .bike == $0.routeType }
            return bikeRoutes.map { Double($0.distanceLeft) }.reduce(0) { $0 + $1 }
        }
    }
    var currentRouteIndex: Int = 0
    var currentRoute: SMRoute? {
        switch composite {
        case .single(let route): return route
        case .multiple(let routes):
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
    var durationLeft: TimeInterval {
        switch self.composite {
        case .single(let route):
            if (route.estimatedAverageSpeed == 0) {
                // Use estimate from OSRM server
                return self.estimatedTime * self.distanceLeft / self.estimatedDistance
            } else {
                // Create own estimate
                return self.bikeDistanceLeft / Double(route.estimatedAverageSpeed)
            }
        case .multiple(let routes):
            let route = routes.last!
            var duration: TimeInterval = 0
            if currentRouteIndex == routes.count-1 {
                // User is currently on the last route
                if route.routeType == .bike {
                    if (route.estimatedAverageSpeed == 0) {
                        // Use estimate from OSRM server
                        duration += Double(route.distanceLeft) / Double(route.estimatedRouteDistance) * TimeInterval(route.estimatedTimeForRoute)
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
    var estimatedTimeOfArrival: Date {
        return Date(timeIntervalSinceNow: self.durationLeft)
    }
    fileprivate init(composite: Composite, from: SearchListItem, to: SearchListItem, estimatedDistance: Double, estimatedBikeDistance: Double? = nil, estimatedTime: TimeInterval) {
        self.composite = composite
        self.from = from
        self.to = to
        self.estimatedDistance = estimatedDistance
        self.estimatedBikeDistance = estimatedBikeDistance ?? estimatedDistance
        self.estimatedTime = estimatedTime
        switch composite {
        case .multiple(let routes):

            for (index, route) in routes.enumerated() {
                // If route is public, finish route earlier
                if route.routeType != .bike &&
                    route.routeType != .walk {
                        route.maxMarginRadius = CGFloat(MAX_DISTANCE_FOR_PUBLIC_TRANSPORT)
                }
                // If next route is public, finish current route earlier
                if index+1 < routes.count {
                    let nextRoute = routes[index+1]
                    if nextRoute.routeType != .bike &&
                        nextRoute.routeType != .walk {
                        route.maxMarginRadius = CGFloat(MAX_DISTANCE_FOR_PUBLIC_TRANSPORT)
                    }
                }
            }
        default: break
        }
    }
    init(route: SMRoute, from: SearchListItem, to: SearchListItem) {
        self.init(composite: .single(route), from: from, to: to, estimatedDistance: Double(route.estimatedRouteDistance), estimatedTime: Double(route.estimatedTimeForRoute))
    }
    init(routes: [SMRoute], from: SearchListItem, to: SearchListItem, estimatedDistance: Double, estimatedBikeDistance: Double, estimatedTime: TimeInterval) {
        self.init(composite: .multiple(routes), from: from, to: to, estimatedDistance: estimatedDistance, estimatedBikeDistance: estimatedBikeDistance, estimatedTime: estimatedTime)
    }
}
