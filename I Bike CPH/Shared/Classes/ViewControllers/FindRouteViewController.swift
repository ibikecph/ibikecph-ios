//
//  FindRouteViewController.swift
//  I Bike CPH
//
//  Created by Tobias Due Munk on 17/06/15.
//  Copyright (c) 2015 I Bike CPH. All rights reserved.
//

import UIKit

class FindRouteViewController: MapViewController {
    
    fileprivate var currentRequestOSRM: SMRequestOSRM?
    
    fileprivate enum ItemOrigin {
        case from, to, none
    }
    
    fileprivate var findRouteToolbarView = FindRouteToolbarView()
    fileprivate let findRouteToRouteNavigationSegue = "findRouteToRouteNavigation"
    fileprivate let findRouteToFindAddressSegue = "findRouteToFindAddress"
    var fromItem: SearchListItem = CurrentLocationItem()
    var toItem: SearchListItem?
    fileprivate var itemOrigin: ItemOrigin = .none
    fileprivate let routeManager = RouteManager()
    fileprivate var routeComposite: RouteComposite? {
        didSet {
            updateUI()
        }
    }
    fileprivate var routeCompositeSuggestions: [RouteComposite] = []
    fileprivate var routeAnnotations = [Annotation]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Disable tracking
        mapView.userTrackingMode = .none
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
    
    override var preferredStatusBarStyle : UIStatusBarStyle {
        return .lightContent
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if
            segue.identifier == findRouteToRouteNavigationSegue,
            let routeNavigationViewController = segue.destination as? RouteNavigationViewController,
            let routeComposite = routeComposite
        {
            routeNavigationViewController.routeComposite = routeComposite
        }
        if
            segue.identifier == findRouteToFindAddressSegue,
            let findAddressViewController = segue.destination as? FindAddressViewController
        {
            // Delegate
            findAddressViewController.delegate = self
        }
    }
    
    fileprivate func favoriteForItem(_ item: SearchListItem) -> FavoriteItem? {
        if let favorite = item as? FavoriteItem {
            return favorite
        }
        if let
            favorites = SMFavoritesUtil.favorites() as? [FavoriteItem],
            let favorite = favorites.filter({ $0.address == item.address }).first
        {
            return favorite
        }
        return nil
    }

    fileprivate func clearUI() {
        routeComposite = nil
        routeCompositeSuggestions.removeAll(keepingCapacity: true)
        updateUI()
        updateRouteSuggestionsUI()
    }

    fileprivate func updateUI() {
        findRouteToolbarView.prepareForReuse()
        let isBroken = RouteType.broken == RouteTypeHandler.instance.type
        findRouteToolbarView.showBrokenRoute = isBroken
        mapView.removeAnnotations(routeAnnotations)
        routeAnnotations = [Annotation]()
        if let toItem = toItem {
            // Address
            findRouteToolbarView.updateWithFromItem(fromItem, toItem: toItem)
        }
        if let
            routeComposite = routeComposite,
            let toItem = toItem
        {
            // Route path
            routeAnnotations = mapView.addAnnotationsForRouteComposite(routeComposite, from: fromItem, to: toItem, zoom: true)
            // Stats
            findRouteToolbarView.routeStatsToolbarView.updateToRoute(routeComposite)
        } else {
            findRouteToolbarView.routeStatsToolbarView.prepareForReuse()
        }
    }

    fileprivate func updateRouteSuggestionsUI() {
        findRouteToolbarView.showBrokenRoute = RouteType.broken == RouteTypeHandler.instance.type
        if findRouteToolbarView.showBrokenRoute {
            findRouteToolbarView.brokenRouteToolbarView.updateToRoutes(routeCompositeSuggestions)
        }
    }
     
    fileprivate func searchForNewRoute(_ server: String) {
        self.currentRequestOSRM?.delegate = nil
        if let toItem = toItem {
            self.currentRequestOSRM = routeManager.findRoute(self.fromItem, to: toItem, server: server)
            UIApplication.shared.isNetworkActivityIndicatorVisible = true
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
        performSegue(withIdentifier: findRouteToRouteNavigationSegue, sender: self)
    }
    func didSelectFrom() {
        itemOrigin = .from
        performSegue(withIdentifier: findRouteToFindAddressSegue, sender: self)
    }
    func didSelectTo() {
        itemOrigin = .to
        performSegue(withIdentifier: findRouteToFindAddressSegue, sender: self)
    }
}

extension FindRouteViewController: RouteTypeToolbarDelegate {
    func didChangeType(_ type: RouteType) {
        clearUI()
        searchForNewRoute(type.server)
    }
}

extension FindRouteViewController: RouteManagerDelegate {
    func didGetResultForRoute(_ result: RouteManager.Result) {
        UIApplication.shared.isNetworkActivityIndicatorVisible = false
        switch result {
            case .error(let error):
                print(error)
                fallthrough
            case .errorOfType(_):
                let alert = UIAlertController(title: nil, message: "error_route_not_found".localized, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Cancel".localized, style: .cancel) { action in
                    self.clearUI()
                    self.findRouteToolbarView.showBrokenRoute = false
                    })
                alert.addAction(UIAlertAction(title: "Try_again".localized, style: .default) { action in
                    self.clearUI()
                    self.searchForNewRoute(RouteTypeHandler.instance.type.server)
                    })
                present(alert, animated: true, completion: nil)
            case .success(let json, let osrmServer):
                let estimatedAverageSpeed = RouteType.estimatedAverageSpeedForOSRMServer(osrmServer)
                
                switch osrmServer {
                case SMRouteSettings.sharedInstance().broken_journey_server:
                    if let routes = json["routes"].array {
                        routeCompositeSuggestions.removeAll(keepingCapacity: true)

                        for route in routes {
                            if let legs = route["legs"].array,
                                let toItem = self.toItem
                            {
                                let estimatedDistance = route["distance"].doubleValue
                                let estimatedBikeDistance = route["distance_bike"].doubleValue
                                let estimatedTime = route["duration"].doubleValue
                                var subRoutes: [SMRoute] = []
                                for leg in legs {
                                    let route = SMRoute(routeJSON: leg.dictionaryObject, delegate: self)
                                    route?.estimatedAverageSpeed = estimatedAverageSpeed
                                    subRoutes.append(route!)
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
                        let fromCoordinate = self.fromItem.location?.coordinate,
                        let toCoordinate = toItem.location?.coordinate
                    {
                        let route = SMRoute(routeStart: fromCoordinate, end: toCoordinate, routeJSON: json.dictionaryObject, delegate: self)
                        route?.estimatedAverageSpeed = estimatedAverageSpeed
                        route?.osrmServer = osrmServer
                        let routeComposite = RouteComposite(route: route!, from: fromItem, to: toItem)
                        self.routeComposite = routeComposite
                    }
                }
        }
    }
}


extension FindRouteViewController: RouteBrokenToolbarViewDelegate {

    func didChangePage(_ page: Int) {
        if routeCompositeSuggestions.count > page {
            routeComposite = routeCompositeSuggestions[page]
        }
    }
}


extension FindRouteViewController: SMRouteDelegate {
    func updateTurn(_ firstElementRemoved: Bool) {
        
    }
    func reachedDestination() {
        
    }
    func updateRoute() {
        
    }
    func start(_ route: SMRoute!) {
        
    }
    func routeNotFound() {
        
    }
    func serverError() {
        
    }
}


extension FindRouteViewController: FindAddressViewControllerProtocol {
    
    func foundAddress(_ item: SearchListItem) {
        switch itemOrigin {
            case .from: fromItem = item
            case .to: toItem = item
            default: break
        }
        itemOrigin = .none
        // Update route
        searchForNewRoute(RouteTypeHandler.instance.type.server)

        clearUI()
    }
}
