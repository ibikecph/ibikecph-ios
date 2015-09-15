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

let routeToItemNotificationKey = "routeToItemNotificationKey"
let routeToItemNotificationItemKey = "routeToItemNotificationItemKey"

class MainMapViewController: MapViewController {

    private let trackingToolbarView = TrackingToolbarView()
    private let addressToolbarView = AddressToolbarView()
    private let mainToTrackingSegue = "mainToTracking"
    private let mainToFindRouteSegue = "mainToFindRoute"
    private let mainToLoginSegue = "mainToLogin"
    private let mainToFindAddressSegue = "mainToFindAddress"
    private let mainToUserTermsSegue = "mainToUserTerms"
    private let mainToActivateTrackingSegue = "mainToActivateTracking"
    private var pinAnnotation: PinAnnotation?
    private var currentLocationItem: SearchListItem?
    private var pendingUserTerms: UserTerms?
    private var observerTokens = [AnyObject]()
    
    deinit {
        unobserve()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        observerTokens.append(NotificationCenter.observe("UserLoggedIn") { [weak self] notification in
            self?.checkUserTerms()
        })
        observerTokens.append(NotificationCenter.observe("UserRegistered") { [weak self] notification in
            self?.checkUserTerms(forceAccept: true)
        })
        
        // Follow user if possible
        mapView.userTrackingMode = .Follow
        
        // Toolbar delegate
        trackingToolbarView.delegate = self
        addressToolbarView.delegate = self
        
        // MapView delegate 
        mapView.delegate = self
        
        // Tracking changes
        updateTrackingToolbarView()
        observerTokens.append(NotificationCenter.observe(processedBigNoticationKey) { [weak self] notification in
            self?.updateTrackingToolbarView()
        })
        observerTokens.append(NotificationCenter.observe(settingsUpdatedNotification) { [weak self] notification in
            self?.updateTrackingToolbarView()
        })
        
        // Observe
        observerTokens.append(NotificationCenter.observe(routeToItemNotificationKey) { [weak self] notification in
            if let
                item = notification.userInfo?[routeToItemNotificationItemKey] as? FavoriteItem,
                myself = self
            {
                myself.updateToCurrentItem(item)
                myself.performSegueWithIdentifier(myself.mainToFindRouteSegue, sender: myself)
            }
        })
        observerTokens.append(NotificationCenter.observe(kFAVORITES_CHANGED){ [weak self] notification in
            if let item = self?.currentLocationItem {
                let oldFavorite = item
                let newFavorite = self?.favoriteForItem(item) ?? item
                self?.currentLocationItem = newFavorite
                self?.addressToolbarView.updateToItem(item)
            }
        })
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        // Update tracking information
        if Settings.instance.tracking.on {
            TracksHandler.setNeedsProcessData(userInitiated: true)
        }
        
        let showedActivateTracking = checkActivateTracking()
        if !showedActivateTracking {
            checkUserTerms()
        }
    }
    
    private func unobserve() {
        for observerToken in observerTokens {
            NotificationCenter.unobserve(observerToken)
        }
        NotificationCenter.unobserve(self)
    }

    @IBAction func openMenu(sender: AnyObject) {
        NotificationCenter.post("openMenu")
    }
    
    func showUserTerms() {
        if pendingUserTerms != nil {
            self.performSegueWithIdentifier(self.mainToUserTermsSegue, sender: self)
        }
    }
    
    func checkActivateTracking() -> Bool {
        if Settings.instance.onboarding.didSeeActivateTracking {
            return false
        }
        performSegueWithIdentifier(mainToActivateTrackingSegue, sender: self)
        return true
    }
    
    func checkUserTerms(forceAccept: Bool = false) {
        if !UserHelper.loggedIn() {
            return // Only check when logged in
        }
        // Check if user has accepted user terms
        UserTermsClient.instance.requestUserTerms() { result in
            switch result {
                case .Success(let userTerms, let new) where new == true:
                    if forceAccept {
                        UserTermsClient.instance.latestVerifiedVersion = userTerms.version
                        return
                    }
                    self.pendingUserTerms = userTerms
                    if self.isViewLoaded() {
                        self.showUserTerms()
                    }
                case .Success(_, _):
                    print("No new user terms")
                default:
                    print("Failed to get user terms: \(result)")
            }
        }
    }
    
    func updateTrackingToolbarView() {
        if currentLocationItem != nil {
            // Do nothing if a location item is currently used
            return
        }
        
        let trackingOn = Settings.instance.tracking.on
        let hasBikeTracks = BikeStatistics.hasTrackedBikeData()
        let showTrackingView = trackingOn || hasBikeTracks
        if showTrackingView {
            let distance = BikeStatistics.distanceThisDate()
            trackingToolbarView.distance = distance
            trackingToolbarView.duration = BikeStatistics.durationThisDate()
            trackingToolbarView.kiloCalories = BikeStatistics.kiloCaloriesPerBikedDistance(distance)
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
        currentLocationItem = nil
        removeToolbar()
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
            destinationController.toItem = currentLocationItem
        }
        if
            segue.identifier == mainToUserTermsSegue,
            let destinationController = segue.destinationViewController as? UserTermsViewController
        {
            destinationController.userTerms = pendingUserTerms
            pendingUserTerms = nil
        }
    }
    
    func dismissViewController() {
         dismissViewControllerAnimated(true, completion: nil)
    }
    
    func favoriteForItem(item: SearchListItem) -> FavoriteItem? {
        if let
            favorites = SMFavoritesUtil.favorites() as? [FavoriteItem],
            favorite = favorites.filter({ $0.address == item.address }).first
        {
            return favorite
        }
        return nil
    }
    
    func updateToCurrentItem(item: SearchListItem) {
        currentLocationItem = item
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
            if let item = currentLocationItem {
                // Check if current item is already favorite
                if let favorite = item as? FavoriteItem {
                    addressToolbarView.updateToItem(favorite)
                    return
                }
                let favorite = FavoriteItem(other: item)
                currentLocationItem = favorite
                addressToolbarView.updateToItem(favorite)
                // Add to server
                SMFavoritesUtil.instance().addFavoriteToServer(favorite)
            }
        } else if let item = currentLocationItem as? FavoriteItem {
            // Remove from server
            SMFavoritesUtil.instance().deleteFavoriteFromServer(item)
            // Downgrade to non-favorite item
            let nonFavorite = UnknownSearchListItem(other: item)
            currentLocationItem = nonFavorite
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
        currentLocationItem = nil
        addressToolbarView.prepareForReuse()
        SMGeocoder.reverseGeocode(coordinate, synchronous: false) { [weak self] item, error in
            if let error = error {
                self?.failedFindSelectCoordinate()
                return
            }
            // Reverse geocode doesn't provide a location for the found item.
            item.location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
            
            let item: SearchListItem = self?.favoriteForItem(item) ?? item // Attempt upgrade to Favorite
            self?.currentLocationItem = item
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
            pinAnnotation = nil
            // Remove address toolbar
            closeAddressToolbarView()
        }
    }
}


extension MainMapViewController: FindAddressViewControllerProtocol {
    
    func foundAddress(item: SearchListItem) {
        // Update current item
        let item: SearchListItem = favoriteForItem(item) ?? item // Attempt upgrade to Favorite
        updateToCurrentItem(item)
    }
}


