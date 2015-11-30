//
//  FindRouteViewController.swift
//  I Bike CPH
//
//  Created by Tobias Due Munk on 17/06/15.
//  Copyright (c) 2015 I Bike CPH. All rights reserved.
//

import UIKit


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
    var bikeDistanceLeft: Double {
        switch composite {
        case .Single(let route):
            return Double(route.distanceLeft)
        case .Multiple(let routes):
            let bikeRoutes = routes.filter { return SMRouteTypeBike.value == $0.routeType.value }
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
    private init(composite: Composite, from: SearchListItem, to: SearchListItem, estimatedDistance: Double, estimatedBikeDistance: Double? = nil, estimatedTime: NSTimeInterval) {
        self.composite = composite
        self.from = from
        self.to = to
        self.estimatedDistance = estimatedDistance
        self.estimatedBikeDistance = estimatedBikeDistance ?? estimatedDistance
        self.estimatedTime = estimatedTime
        switch composite {
        case .Multiple(let routes):

            for (index, route) in enumerate(routes) {
                // If route is public, finish route earlier
                if route.routeType.value != SMRouteTypeBike.value &&
                    route.routeType.value != SMRouteTypeWalk.value {
                        route.distanceToFinishRange = 100
                }
                // If next route is public, finish current route earlier
                if index+1 < routes.count {
                    let nextRoute = routes[index+1]
                    if nextRoute.routeType.value != SMRouteTypeBike.value &&
                        nextRoute.routeType.value != SMRouteTypeWalk.value {
                        route.distanceToFinishRange = 100
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

class FindRouteViewController: MapViewController {
    
    private enum ItemOrigin {
        case From, To, None
    }
    
    private var findRouteToolbarView = FindRouteToolbarView()
    private let findRouteToRouteNavigationSegue = "findRouteToRouteNavigation"
    private let findRouteToFindAddressSegue = "findRouteToFindAddress"
    var fromItem: SearchListItem = CurrentLocationItem()
    var toItem: SearchListItem?
    private var itemOrigin: ItemOrigin = .None
    private let routeManager = RouteManager()
    private var routeComposite: RouteComposite? {
        didSet {
            updateUI()
        }
    }
    private var routeCompositeSuggestions: [RouteComposite] = []
    private var routeAnnotations = [Annotation]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Disable tracking
        mapView.userTrackingMode = .None
        // Show user location
        mapView.showsUserLocation = true
        
        // Toolbar
        add(toolbarView: findRouteToolbarView)
        findRouteToolbarView.delegate = self
        findRouteToolbarView.brokenRouteToolbarView.delegate = self
        updateUI()
        
        // Route delegate
        routeManager.delegate = self
        
        // Search for route
        searchForNewRoute(server: RouteTypeHandler.instance.type.server)
    }
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return .LightContent
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if
            segue.identifier == findRouteToRouteNavigationSegue,
            let routeNavigationViewController = segue.destinationViewController as? RouteNavigationViewController,
            routeComposite = routeComposite,
            toItem = toItem
        {
            routeNavigationViewController.routeComposite = routeComposite
        }
        if
            segue.identifier == findRouteToFindAddressSegue,
            let findAddressViewController = segue.destinationViewController as? FindAddressViewController
        {
            // Delegate
            findAddressViewController.delegate = self
        }
    }
    
    private func favoriteForItem(item: SearchListItem) -> FavoriteItem? {
        if let favorite = item as? FavoriteItem {
            return favorite
        }
        if let
            favorites = SMFavoritesUtil.favorites() as? [FavoriteItem],
            favorite = favorites.filter({ $0.address == item.address }).first
        {
            return favorite
        }
        return nil
    }

    private func clearUI() {
        routeComposite = nil
        routeCompositeSuggestions.removeAll(keepCapacity: true)
        updateUI()
        updateRouteSuggestionsUI()
    }

    private func updateUI() {
        findRouteToolbarView.prepareForReuse()
        let isBroken = RouteType.Broken == RouteTypeHandler.instance.type
        findRouteToolbarView.showBrokenRoute = isBroken
        mapView.removeAnnotations(routeAnnotations)
        routeAnnotations = [Annotation]()
        if let toItem = toItem {
            // Address
            findRouteToolbarView.updateWithFromItem(fromItem, toItem: toItem)
        }
        if let
            routeComposite = routeComposite,
            toItem = toItem
        {
            // Route path
            routeAnnotations = mapView.addAnnotationsForRouteComposite(routeComposite, from: fromItem, to: toItem, zoom: true)
            // Stats
            findRouteToolbarView.routeStatsToolbarView.updateToRoute(routeComposite)
        } else {
            findRouteToolbarView.routeStatsToolbarView.prepareForReuse()
        }
    }

    private func updateRouteSuggestionsUI() {
        findRouteToolbarView.showBrokenRoute = RouteType.Broken == RouteTypeHandler.instance.type
        if findRouteToolbarView.showBrokenRoute {
            findRouteToolbarView.brokenRouteToolbarView.updateToRoutes(routeCompositeSuggestions)
        }
    }
    
    private func searchForNewRoute(#server: String) {
        if let toItem = toItem {
            routeManager.findRoute(self.fromItem, to: toItem, server: server)
            UIApplication.sharedApplication().networkActivityIndicatorVisible = true
        }
    }
}


extension FindRouteViewController: FindRouteToolbarDelegate {
    func didSelectReverseRoute() {
        let fromItem = self.fromItem
        if let toItem = toItem
        {
            // Reverse to and from items
            self.fromItem = toItem
            self.toItem = fromItem
            // Update route
            searchForNewRoute(server: RouteTypeHandler.instance.type.server)

            clearUI()
        }
    }
    func didSelectRoute() {
        performSegueWithIdentifier(findRouteToRouteNavigationSegue, sender: self)
    }
    func didSelectFrom() {
        itemOrigin = .From
        performSegueWithIdentifier(findRouteToFindAddressSegue, sender: self)
    }
    func didSelectTo() {
        itemOrigin = .To
        performSegueWithIdentifier(findRouteToFindAddressSegue, sender: self)
    }
}


extension FindRouteViewController: RouteTypeToolbarDelegate {
    func didChangeType(type: RouteType) {
        clearUI()
        searchForNewRoute(server: type.server)
    }
}


extension FindRouteViewController: RouteManagerDelegate {
    func didGetResultForRoute(result: RouteManager.Result) {
        UIApplication.sharedApplication().networkActivityIndicatorVisible = false
        switch result {
            case .Error(let error):
                println(error)
                fallthrough
            case .ErrorOfType(_):
                let alert = UIAlertView(title: nil, message: "error_route_not_found".localized, delegate: nil, cancelButtonTitle: "Ok".localized)
                alert.show()
            case .Success(let json, let osrmServer):
                if let routesJson = json.array {
                    routeCompositeSuggestions.removeAll(keepCapacity: true)

                    for routeSuggestion in routesJson {
                        let summary = routeSuggestion["journey_summary"]

                        if let subRoutesJson = routeSuggestion["journey"].array,
                            toItem = toItem
                        {
                            let estimatedDistance = summary["total_distance"].doubleValue
                            let estimatedBikeDistance = summary["total_bike_distance"].doubleValue
                            let estimatedTime = summary["total_time"].doubleValue
                            var subRoutes: [SMRoute] = []
                            for subRouteJson in subRoutesJson {
                                if let viaPoints = subRouteJson["via_points"].array,
                                    from = viaPoints.first?.array,
                                    fromLatitude = from.first?.doubleValue,
                                    fromLongitude = from.last?.doubleValue,
                                    to = viaPoints.last?.array,
                                    toLatitude = to.first?.doubleValue,
                                    toLongitude = to.last?.doubleValue,
                                    subDictionary = subRouteJson.dictionaryObject
                                {
                                    let fromCoordinate = CLLocationCoordinate2D(latitude: fromLatitude, longitude: fromLongitude)
                                    let toCoordinate = CLLocationCoordinate2D(latitude: toLatitude, longitude: toLongitude)
                                    let route = SMRoute(routeStart: fromCoordinate, andEnd: toCoordinate, andDelegate: self, andJSON: subDictionary)
                                    subRoutes.append(route)
                                } else {
                                    print("Failed parsing broken route")
                                }
                            }
                            let routeComposite = RouteComposite(routes: subRoutes, from: fromItem, to: toItem, estimatedDistance: estimatedDistance, estimatedBikeDistance: estimatedBikeDistance, estimatedTime: estimatedTime)
                            routeCompositeSuggestions.append(routeComposite)
                        }
                    }
                    self.routeComposite = routeCompositeSuggestions.first
                    updateRouteSuggestionsUI()
                } else if let
                    toItem = toItem,
                    fromCoordinate = fromItem.location?.coordinate,
                    toCoordinate = toItem.location?.coordinate
                {
                    let route = SMRoute(routeStart: fromCoordinate, andEnd: toCoordinate, andDelegate: self, andJSON: json.dictionaryObject)
                    route.osrmServer = osrmServer
                    let routeComposite = RouteComposite(route: route, from: fromItem, to: toItem)
                    self.routeComposite = routeComposite
                }
        }
    }
}


extension FindRouteViewController: RouteBrokenToolbarViewDelegate {

    func didChangePage(page: Int) {
        if routeCompositeSuggestions.count > page {
            routeComposite = routeCompositeSuggestions[page]
        }
    }
}


extension FindRouteViewController: SMRouteDelegate {
    func updateTurn(firstElementRemoved: Bool) {
        
    }
    func reachedDestination() {
        
    }
    func updateRoute() {
        
    }
    func startRoute(route: SMRoute!) {
        
    }
    func routeNotFound() {
        
    }
    func serverError() {
        
    }
}


extension FindRouteViewController: FindAddressViewControllerProtocol {
    
    func foundAddress(item: SearchListItem) {
        switch itemOrigin {
            case .From: fromItem = item
            case .To: toItem = item
            default: break
        }
        itemOrigin = .None
        // Update route
        searchForNewRoute(server: RouteTypeHandler.instance.type.server)

        clearUI()
    }
}
