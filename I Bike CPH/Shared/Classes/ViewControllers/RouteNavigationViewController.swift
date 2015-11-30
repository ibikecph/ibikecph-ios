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
    var routeComposite: RouteComposite?
    var routeAnnotations = [Annotation]()
    var observerTokens = [AnyObject]()
    
    
    @IBAction func didTapProblem(sender: AnyObject) {
        performSegueWithIdentifier(routeNavigationToReportErrorSegue, sender: self)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Disable user tracking
        mapView.userTrackingMode = .Follow
        
        // Toolbar
        add(toolbarView: routeNavigationToolbarView)
        
        // Directions
        routeNavigationDirectionsToolbarView.delegate = self
        
        // Route delegate
        routeComposite?.currentRoute?.delegate = self
        
        // Setup UI
        updateUI(zoom: true)
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        addObservers()
    }

    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        unobserve()
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
            if let routeComposite = routeComposite,
                route = routeComposite.currentRoute {
                if let pastInstructions = route.pastTurnInstructions.copy() as? [SMTurnInstruction] {
                    instructionDescriptions += (pastInstructions.map { $0.fullDescriptionString } )
                }
                if let instructions = route.turnInstructions.copy() as? [SMTurnInstruction] {
                    instructionDescriptions += (instructions.map { $0.fullDescriptionString } )
                }
                reportErrorController.routeDirections = instructionDescriptions
                reportErrorController.destination = routeComposite.to.name
                reportErrorController.source = "\(routeComposite.from.type)"
                reportErrorController.destinationLoc = routeComposite.to.location
                reportErrorController.sourceLoc = routeComposite.from.location
            }
        }
    }
    
    private func addObservers() {
        // Location updates
        unobserve()
        observerTokens.append(NotificationCenter.observe("refreshPosition") { [weak self] notification in
            if let
                locations = notification.userInfo?["locations"] as? [CLLocation],
                location = locations.first,
                routeComposite = self?.routeComposite
            {
                // Tell route about new user location
                routeComposite.currentRoute?.visitLocation(location)
                // Update stats to reflect route progress
                self?.updateStats()
            }
        })
    }
    
    private func unobserve() {
        for observerToken in observerTokens {
            NotificationCenter.unobserve(observerToken)
        }
        NotificationCenter.unobserve(self)
    }
    
    private func updateUI(#zoom: Bool) {
        updateRouteUI(zoom: zoom)
        // Directions
        updateTurnInstructions()
        // Stats
        updateStats()
    }

    private func updateRouteUI(#zoom: Bool) {
        mapView.removeAnnotations(routeAnnotations)
        routeAnnotations = [Annotation]()
        if let routeComposite = routeComposite
        {
            // Route path
            routeAnnotations = mapView.addAnnotationsForRouteComposite(routeComposite, from: routeComposite.from, to: routeComposite.to, zoom: zoom)
            // Address
            routeNavigationToolbarView.updateWithItem(routeComposite.to)
        }
    }
    
    private func updateStats() {
        if let routeComposite = routeComposite {
            // Stats
            routeNavigationToolbarView.routeStatsToolbarView.updateToRoute(routeComposite)
        } else {
            routeNavigationToolbarView.routeStatsToolbarView.prepareForReuse()
        }
    }
    
    private func updateTurnInstructions() {
        if let instructions = routeComposite?.currentRoute?.turnInstructions.copy() as? [SMTurnInstruction] {
            // Default
            routeNavigationDirectionsToolbarView.instructions = instructions

            if let routeComposite = routeComposite {
                switch routeComposite.composite {
                case .Multiple(let routes):
                    if let currentRoute = routeComposite.currentRoute {
                        let previousIndex = routeComposite.currentRouteIndex - 1
                        if previousIndex < 0 {
                            break
                        } // Has previous route
                        let previousRoute = routes[previousIndex]
                        if previousRoute.routeType.value == SMRouteTypeBike.value ||
                            previousRoute.routeType.value == SMRouteTypeWalk.value {
                            break
                        } // Previous route was public
                        let distanceFromPreviousRouteEndLocation = previousRoute.getEndLocation().distanceFromLocation(currentRoute.lastCorrectedLocation)
                        if distanceFromPreviousRouteEndLocation > 100 {
                            break
                        } // Still closer than 100m
                        // Keep showing last instruction of previous route
                        if let lastInstruction = (previousRoute.turnInstructions.copy() as? [SMTurnInstruction])?.first {
                            routeNavigationDirectionsToolbarView.extraInstruction = lastInstruction
                            println("\(lastInstruction)")
                        }
                        return
                    }
                default: break
                }
                routeNavigationDirectionsToolbarView.extraInstruction = nil
            }

        } else {
            routeNavigationDirectionsToolbarView.prepareForReuse()
        }
    }
}


extension RouteNavigationViewController: RouteNavigationDirectionsToolbarDelegate {
    
    func didSwipeToInstruction(instruction: SMTurnInstruction, userAction: Bool) {
        if !userAction {
            return
        }
        if let
            firstInstruction = routeComposite?.currentRoute?.turnInstructions.firstObject as? SMTurnInstruction
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
        if let routeComposite = routeComposite {
            switch routeComposite.composite {
            case .Single(_): return
            case .Multiple(let routes): //  Go to next route if route contains more subroutes
                if routeComposite.currentRouteIndex < routes.count {
                    println("Going to next route segment")
                    self.routeComposite?.currentRoute?.delegate = nil
                    self.routeComposite?.currentRouteIndex++
                    self.routeComposite?.currentRoute?.delegate = self
                    updateTurnInstructions()
                    updateStats()
                }
            }
        }
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
