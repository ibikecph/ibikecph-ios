//
//  FindRouteViewController.swift
//  I Bike CPH
//
//  Created by Tobias Due Munk on 17/06/15.
//  Copyright (c) 2015 I Bike CPH. All rights reserved.
//

import UIKit

class FindRouteViewController: MapViewController {
    
    private var currentRequestOSRM: SMRequestOSRM?
    
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
        searchForNewRoute(RouteTypeHandler.instance.type.server)
    }
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return .LightContent
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if
            segue.identifier == findRouteToRouteNavigationSegue,
            let routeNavigationViewController = segue.destinationViewController as? RouteNavigationViewController,
            routeComposite = routeComposite
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
     
    private func searchForNewRoute(server: String) {
        self.currentRequestOSRM?.delegate = nil
        if let toItem = toItem {
            self.currentRequestOSRM = routeManager.findRoute(self.fromItem, to: toItem, server: server)
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
            searchForNewRoute(RouteTypeHandler.instance.type.server)

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
        searchForNewRoute(type.server)
    }
}

extension FindRouteViewController: RouteManagerDelegate {
    func didGetResultForRoute(result: RouteManager.Result) {
        UIApplication.sharedApplication().networkActivityIndicatorVisible = false
        switch result {
            case .Error(let error):
                print(error)
                fallthrough
            case .ErrorOfType(_):
                let alert = UIAlertController(title: nil, message: "error_route_not_found".localized, preferredStyle: .Alert)
                alert.addAction(UIAlertAction(title: "Cancel".localized, style: .Cancel) { action in
                    self.clearUI()
                    self.findRouteToolbarView.showBrokenRoute = false
                    })
                alert.addAction(UIAlertAction(title: "Try_again".localized, style: .Default) { action in
                    self.clearUI()
                    self.searchForNewRoute(RouteTypeHandler.instance.type.server)
                    })
                presentViewController(alert, animated: true, completion: nil)
            case .Success(let json, let osrmServer):
                let estimatedAverageSpeed = RouteType.estimatedAverageSpeedForOSRMServer(osrmServer)
                
                switch osrmServer {
                case SMRouteSettings.sharedInstance().broken_journey_server:
                    if let routes = json["routes"].array {
                        routeCompositeSuggestions.removeAll(keepCapacity: true)

                        for route in routes {
                            if let legs = route["legs"].array,
                                toItem = self.toItem
                            {
                                let estimatedDistance = route["distance"].doubleValue
                                let estimatedBikeDistance = route["distance_bike"].doubleValue
                                let estimatedTime = route["duration"].doubleValue
                                var subRoutes: [SMRoute] = []
                                for leg in legs {
                                    let route = SMRoute(routeJSON: leg.dictionaryObject, delegate: self)
                                    route.estimatedAverageSpeed = estimatedAverageSpeed
                                    subRoutes.append(route)
                                }
                                let routeComposite = RouteComposite(routes: subRoutes, from: self.fromItem, to: toItem, estimatedDistance: estimatedDistance, estimatedBikeDistance: estimatedBikeDistance, estimatedTime: estimatedTime)
                                routeCompositeSuggestions.append(routeComposite)
                            }
                        }
                        self.routeComposite = routeCompositeSuggestions.first
                        updateRouteSuggestionsUI()
                    }
                default:
                    if let
                        toItem = self.toItem,
                        fromCoordinate = self.fromItem.location?.coordinate,
                        toCoordinate = toItem.location?.coordinate
                    {
                        let route = SMRoute(routeStart: fromCoordinate, end: toCoordinate, routeJSON: json.dictionaryObject, delegate: self)
                        route.estimatedAverageSpeed = estimatedAverageSpeed
                        route.osrmServer = osrmServer
                        let routeComposite = RouteComposite(route: route, from: fromItem, to: toItem)
                        self.routeComposite = routeComposite
                    }
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
        searchForNewRoute(RouteTypeHandler.instance.type.server)

        clearUI()
    }
}
