//
//  MainMapViewController.swift
//  I Bike CPH
//
//  Created by Tobias Due Munk on 04/06/15.
//  Copyright (c) 2015 I Bike CPH. All rights reserved.
//

import UIKit
import PSTAlertController
import MapKit


class MainMapViewController: MapViewController {

    var trackingToolbarView = TrackingToolbarView()
    var addressToolbarView = AddressToolbarView()
    let mainToTrackingSegue = "mainToTracking"
    let mainToFindRouteSegue = "mainToFindRoute"
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
        mapView.userTrackingMode = .Follow
        
        // Toolbar delegate
        trackingToolbarView.delegate = self
        addressToolbarView.delegate = self
        
        // MapView delegate 
        mapView.delegate = self
        
        // Tracking changes
        updateTrackingToolbarView()
        NotificationCenter.observe(processedBigNoticationKey) { [weak self] notification in
            self?.updateTrackingToolbarView()
        }
        NotificationCenter.observe(settingsUpdatedNotification) { [weak self] notification in
            self?.updateTrackingToolbarView()
        }
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        // Update tracking information
        if Settings.instance.tracking.on {
            TracksHandler.setNeedsProcessData(userInitiated: true)
        }
    }

    @IBAction func openMenu(sender: AnyObject) {
        NotificationCenter.post("openMenu")
    }
    
    func updateTrackingToolbarView() {
        if currentItem != nil {
            // Do nothing af a location item is currently used
            return
        }
        
        let trackingOn = Settings.instance.tracking.on
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
        if
            segue.identifier == mainToFindRouteSegue,
            let destinationController = segue.destinationViewController as? FindRouteViewController
        {
            destinationController.toItem = currentItem
        }
    }
    
    func dismissViewController() {
         dismissViewControllerAnimated(true, completion: nil)
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
        performSegueWithIdentifier(mainToFindRouteSegue, sender: self)
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
                self?.failedFindSelectCoordinate()
                return
            }
            // Reverse geocode doesn't provide a location for the found item.
            item.location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
            
            let item: SearchListItem = self?.favoriteForItem(item) ?? item // Attempt upgrade to Favorite
            self?.currentItem = item
            self?.addressToolbarView.updateToItem(item)
            
            // Reverse geocode doesn't provide a location for the found item.
            // TODO: Check if found address is "far" from pin
//            SMGeocoder.geocode(item.address) { placemark, error in
//                if let error = error {
//                    self?.failedFindSelectCoordinate()
//                    return
//                }
//                if let placemark = placemark.first as? MKPlacemark {
//                    let location = placemark.location
//                    self?.currentItem?.location = location
//                    // Update pin location
//                    self?.pinAnnotation?.coordinate = location.coordinate
//                    return
//                }
//                self?.failedFindSelectCoordinate()
//            }
        }
    }
    
    func failedFindSelectCoordinate() {
        if let pin = pinAnnotation {
            removePin(pin)
        }
        // Close address toolbar
        closeAddressToolbarView()
    }
    
    func didSelectAnnotation(annotation: Annotation) {
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
            mapView.centerCoordinate(coordinate, zoomLevel: DEFAULT_MAP_ZOOM, animated: true)
        }
    }
}


