//
//  RouteNavigationViewController.swift
//  I Bike CPH
//
//  Created by Tobias Due Munk on 24/06/15.
//  Copyright (c) 2015 I Bike CPH. All rights reserved.
//

import UIKit

class RouteNavigationViewController: MapViewController {

    @IBOutlet var routeNavigationDirectionsToolbarView: RouteNavigationDirectionsToolbarView!
    let routeNavigationToolbarView = RouteNavigationToolbarView()
    let routeNavigationToReportErrorSegue = "routeNavigationToReportError"
    var route: RouteComposit?
    var routeAnnotations = [Annotation]()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Disable user tracking
        mapView.userTrackingMode = .Follow
        
        // Toolbar
        add(toolbarView: routeNavigationToolbarView)
        routeNavigationToolbarView.delegate = self
        
        // Directions
        routeNavigationDirectionsToolbarView.delegate = self
        
        // Route delegate
        route?.route.delegate = self
        
        // Setup UI
        updateUI(zoom: true)
        
        // Location updates
        NSNotificationCenter.defaultCenter().addObserverForName("refreshPosition", object: nil, queue: nil) { notification in
            if let
                locations = notification.userInfo?["locations"] as? [CLLocation],
                location = locations.first,
                route = self.route
            {
                // Tell route about new user location
                route.route.visitLocation(location)
                // Update stats to reflect route progress
                self.updateStats()
            }
        }
    }
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return .LightContent
    }

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if
            segue.identifier == routeNavigationToReportErrorSegue,
            let reportErrorController = segue.destinationViewController as? SMReportErrorController
        {
            var instructionDescriptions = [String]()
            if let route = route {
                if let pastInstructions = route.route.pastTurnInstructions.copy() as? [SMTurnInstruction] {
                    instructionDescriptions += (pastInstructions.map { $0.fullDescriptionString } )
                }
                if let instructions = route.route.turnInstructions.copy() as? [SMTurnInstruction] {
                    instructionDescriptions += (instructions.map { $0.fullDescriptionString } )
                }
                reportErrorController.routeDirections = instructionDescriptions
                reportErrorController.destination = route.to.name
                reportErrorController.source = "\(route.from.type)"
                reportErrorController.destinationLoc = route.to.location
                reportErrorController.sourceLoc = route.from.location
            }
        }
    }
    
    private func updateUI(#zoom: Bool) {
        mapView.removeAnnotations(routeAnnotations)
        routeAnnotations = [Annotation]()
        if let route = route
        {
            // Route path
            routeAnnotations = mapView.addAnnotationsForRoute(route.route, from: route.from, to: route.to, zoom: zoom)
            // Address
            routeNavigationToolbarView.updateWithItem(route.to)
        }
        // Directions
        updateTurnInstructions()
        // Stats
        updateStats()
    }
    
    private func updateStats() {
        if let route = route {
            // Stats
            routeNavigationToolbarView.routeStatsToolbarView.updateToRoute(route.route)
        } else {
            routeNavigationToolbarView.routeStatsToolbarView.prepareForReuse()
        }
    }
    
    private func updateTurnInstructions() {
        if let instructions = route?.route.turnInstructions.copy() as? [SMTurnInstruction] {
            routeNavigationDirectionsToolbarView.instructions = instructions
        } else {
            routeNavigationDirectionsToolbarView.prepareForReuse()
        }
    }
}

extension RouteNavigationViewController: RouteNavigationToolbarDelegate {
    
    func didSelectReportProblem() {
        performSegueWithIdentifier(routeNavigationToReportErrorSegue, sender: self)
    }
}


extension RouteNavigationViewController: RouteNavigationDirectionsToolbarDelegate {
    
    func didSwipeToInstruction(instruction: SMTurnInstruction, userAction: Bool) {
        if !userAction {
            return
        }
        if let
            firstInstruction = route?.route.turnInstructions.firstObject as? SMTurnInstruction
            where firstInstruction == instruction
        {
            // If user swiped to the first instruction, enable .Follow
            mapView.userTrackingMode = .Follow
        } else {
            // Disable tracking to allow user to swipe through turn instructions
            mapView.userTrackingMode = .None
            mapView.centerCoordinate(instruction.loc.coordinate, zoomLevel: mapView.zoomLevel)
        }
    }
}


extension RouteNavigationViewController: SMRouteDelegate {
    
    func updateTurn(firstElementRemoved: Bool) {
        if mapView.userTrackingMode != .None {
            updateTurnInstructions()
        }
    }
    func reachedDestination() {
        // TODO: Go to next route if brokenRoute
    }
    func updateRoute() {
        println("Found new route")
        updateUI(zoom: false)
    }
    func startRoute(route: SMRoute!) {
        
    }
    func routeNotFound() {
        
    }
    func serverError() {
        
    }
    func routeRecalculationStarted() {
        println("Recalculating")
    }
    
    func routeRecalculationDone() {
        println("")
    }
}
