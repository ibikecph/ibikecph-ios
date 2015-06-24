//
//  FindRouteViewController.swift
//  I Bike CPH
//
//  Created by Tobias Due Munk on 17/06/15.
//  Copyright (c) 2015 I Bike CPH. All rights reserved.
//

import UIKit

struct RouteComposit {
    let route: SMRoute
    let from: SearchListItem
    let to: SearchListItem
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
    private var route: SMRoute? {
        didSet {
            updateUI()
        }
    }
    var routeAnnotations = [Annotation]()
    
    deinit {
        NotificationCenter.unobserve(self)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Disable tracking
        mapView.userTrackingMode = .None
        // Show user location
        mapView.showsUserLocation = true
        
        // Toolbar
        add(toolbarView: findRouteToolbarView)
        findRouteToolbarView.delegate = self
        
        // Route delegate
        routeManager.delegate = self
        
        // Search for route
        searchForNewRoute()
    }
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return .LightContent
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if
            segue.identifier == findRouteToRouteNavigationSegue,
            let routeNavigationViewController = segue.destinationViewController as? RouteNavigationViewController,
            route = route,
            toItem = toItem
        {
            routeNavigationViewController.route = RouteComposit(route: route, from: fromItem, to: toItem)
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
    
    private func updateUI() {
        findRouteToolbarView.prepareForReuse()
        mapView.removeAnnotations(routeAnnotations)
        routeAnnotations = [Annotation]()
        if let
            route = route,
            toItem = toItem
        {
            // TODO: Move this to extension on MapView to make reusable. Return all annotations related to route as an array for reference.
            // Route path
            routeAnnotations = mapView.addAnnotationsForRoute(route, from: fromItem, to: toItem, zoom: true)
            // Address
            findRouteToolbarView.updateWithFromItem(fromItem, toItem: toItem)
            // Stats
            findRouteToolbarView.routeStatsToolbarView.updateToRoute(route)
        } else {
            findRouteToolbarView.routeStatsToolbarView.prepareForReuse()
        }
    }
    
    private func searchForNewRoute() {
        if let toItem = toItem {
            routeManager.findRoute(self.fromItem, to: toItem)
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
            searchForNewRoute()
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
        searchForNewRoute()
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
            case .Success(let dictionary):
                if let
                    fromCoordinate = fromItem.location?.coordinate,
                    toCoordinate = toItem?.location?.coordinate
                {
                    let route = SMRoute(routeStart: fromCoordinate, andEnd: toCoordinate, andDelegate: self, andJSON: dictionary)
                    self.route = route
                }
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
        searchForNewRoute()
    }
}
