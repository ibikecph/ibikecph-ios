//
//  MainMapViewController.swift
//  I Bike CPH
//
//  Created by Tobias Due Munk on 04/06/15.
//  Copyright (c) 2015 I Bike CPH. All rights reserved.
//

import UIKit
import MapboxGL
import PSTAlertController

class MainMapViewController: MapViewController {

    var trackingToolbarView = TrackingToolbarView()
    var addressToolbarView = AddressToolbarView()
    let mainToTrackingSegue = "mainToTracking"
    let mainToRouteSegue = "mainToRoute"
    let mainToLoginSegue = "mainToLogin"
    let mainToFindAddressSegue = "mainToFindAddress"
    var pinAnnotation: PinAnnotation?
    var currentItem: SearchListItem?
    
    deinit {
        NotificationCenter.unobserve(self)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Follow user if possible
        mapView.mapView.userTrackingMode = .Follow
        
        // Toolbar delegate
        trackingToolbarView.delegate = self
        addressToolbarView.delegate = self
        
        // MapView delegate 
        mapView.delegate = self
        
        // Tracking changes
        updateTrackingToolbarView()
        NotificationCenter.observe(processedBigNoticationKey) { notification in
            self.updateTrackingToolbarView()
        }
        NotificationCenter.observe(settingsUpdatedNotification) { notification in
            self.updateTrackingToolbarView()
        }
    }

    @IBAction func openMenu(sender: AnyObject) {
        NotificationCenter.post("openMenu")
    }
    
    func updateTrackingToolbarView() {
        let trackingOn = settings.tracking.on
        let hasBikeTracks = BikeStatistics.hasTrackedBikeData()
        let showTrackingView = trackingOn || hasBikeTracks
        if showTrackingView {
            trackingToolbarView.distance = BikeStatistics.distanceThisDate()
            trackingToolbarView.duration = BikeStatistics.durationThisDate()
            add(toolbarView: trackingToolbarView)
        } else {
            removeToolbar()
        }
        // Remove any pin
        if let pin = pinAnnotation {
            removePin(pin)
        }
    }
    
    func closeAddressToolbarView() {
        updateTrackingToolbarView()
    }
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return .LightContent
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if
            segue.identifier == mainToTrackingSegue,
            let navigationController = segue.destinationViewController as? UINavigationController
        {
            let backButton = UIBarButtonItem(barButtonSystemItem: .Done, target: self, action: "dismissViewController")
            navigationController.viewControllers.first?.navigationItem.leftBarButtonItem = backButton
        }
        if
            segue.identifier == mainToFindAddressSegue,
            let destinationController = segue.destinationViewController as? FindAddressViewController
        {
            destinationController.delegate = self
        }
    }
    
    func dismissViewController() {
         dismissViewControllerAnimated(true, completion: nil)
    }
    
    func selectedAnnotation(annotation: MGLAnnotation) {
        // Remove annotation if the selected one is the pinAnnotation
        if let
            pin = pinAnnotation,
            annotation = annotation as? PinAnnotation
            where pin == annotation
        {
            // Remove pin
            removePin(pin)
            // Remove address toolbar
            closeAddressToolbarView()
        }
    }
    
    func favoriteForItem(item: SearchListItem) -> FavoriteItem? {
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
}

extension MainMapViewController: TrackingToolbarDelegate {
    
    func didSelectOpenTracking() {
        performSegueWithIdentifier(mainToTrackingSegue, sender: self)
    }
}

extension MainMapViewController: AddressToolbarDelegate {
    
    func didSelectRoute() {
        performSegueWithIdentifier(mainToRouteSegue, sender: self)
    }
    
    func didSelectFavorites(selected: Bool) {
        // Check if logged in 
        if !UserHelper.loggedIn() {
            if selected {
                // TODO: Change strings
                let alertController = PSTAlertController(title: "", message: "log_in_to_favorite_prompt".localized, preferredStyle: .Alert)
                alertController.addCancelActionWithHandler(nil)
                let loginAction = PSTAlertAction(title: "log_in".localized) { action in
                    self.performSegueWithIdentifier(self.mainToLoginSegue, sender: self)
                }
                alertController.addAction(loginAction)
                alertController.showWithSender(self, controller: self, animated: true, completion: nil)
                // De-select in view
                addressToolbarView.favoriteSelected = false
            }
            return
        }
        
        // Add or remove from favorite accordingly
        if selected {
            if let item = currentItem {
                // Check if current item is already favorite
                if let favorite = item as? FavoriteItem {
                    addressToolbarView.updateToItem(favorite)
                    return
                }
                let favorite = FavoriteItem(other: item)
                currentItem = favorite
                addressToolbarView.updateToItem(favorite)
                // Add to server
                SMFavoritesUtil.instance().addFavoriteToServer(favorite)
            }
        } else if let item = currentItem as? FavoriteItem {
            // Remove from server
            SMFavoritesUtil.instance().deleteFavoriteFromServer(item)
            // Downgrade to non-favorite item
            let nonFavorite = UnknownSearchListItem(other: item)
            currentItem = nonFavorite
            addressToolbarView.updateToItem(nonFavorite)
        }
    }
}

extension MainMapViewController: MGLMapViewDelegate {
    func mapView(mapView: MGLMapView, annotationCanShowCallout annotation: MGLAnnotation) -> Bool {
        selectedAnnotation(annotation)
        return false // Don't show call out view
    }
}

extension MainMapViewController: MapViewDelegate {
    func didSelectCoordinate(coordinate: CLLocationCoordinate2D) {
        // Remove existin pin
        if let pin = pinAnnotation {
            removePin(pin)
        }
        // Add pin to map
        pinAnnotation = addPin(coordinate)
        // Show address in toolbar
        add(toolbarView: addressToolbarView)
        // Clear
        currentItem = nil
        addressToolbarView.prepareForReuse()
        SMGeocoder.reverseGeocode(coordinate, synchronous: false) { [weak self] item, error in
            if let error = error {
                if let pin = self?.pinAnnotation {
                    self?.removePin(pin)
                }
                // Close address toolbar
                self?.closeAddressToolbarView()
                return
            }
            let item: SearchListItem = self?.favoriteForItem(item) ?? item // Attempt upgrade to Favorite
            self?.currentItem = item
            self?.addressToolbarView.updateToItem(item)
        }
    }
}

extension MainMapViewController: FindAddressViewControllerProtocol {
    
    func foundAddress(item: SearchListItem) {
        // Update current item
        let item: SearchListItem = favoriteForItem(item) ?? item // Attempt upgrade to Favorite
        currentItem = item
        // Show address in toolbar
        addressToolbarView.updateToItem(item)
        add(toolbarView: addressToolbarView)
        // Remove any existing pin
        if let pin = pinAnnotation {
            removePin(pin)
        }
        // Add new pin if item has location
        if
            let coordinate = item.location?.coordinate
            where coordinate.latitude != 0 && coordinate.longitude != 0
        {
            pinAnnotation = addPin(coordinate)
            mapView.mapView.setCenterCoordinate(coordinate, zoomLevel: DEFAULT_MAP_ZOOM, animated: true)
        }
    }
}


