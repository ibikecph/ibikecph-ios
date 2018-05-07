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
    var routeComposite: RouteComposite? {
        didSet {
            // Read aloud the route destination
            if let routeComposite = routeComposite {
                InstructionTextToSpeechSynthesizer.sharedInstance.routeComposite = routeComposite
            }
        }
    }
    var routeAnnotations = [Annotation]()
    var observerTokens = [AnyObject]()
    
    @IBAction func didTapProblem(_ sender: AnyObject) {
        performSegue(withIdentifier: routeNavigationToReportErrorSegue, sender: self)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Disable user tracking
        mapView.userTrackingMode = .follow
        
        // Toolbar
        add(toolbarView: routeNavigationToolbarView)
        
        // Directions
        routeNavigationDirectionsToolbarView.delegate = self
        
        // Route delegate
        routeComposite?.currentRoute?.delegate = self
        
        // Setup UI
        updateUI(true)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        addObservers()
#if TRACKING_ENABLED
        TrackingHandler.sharedInstance().isCurrentlyRouting = true
#else
        NonTrackingHandler.sharedInstance().isCurrentlyRouting = true
#endif
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        unobserve()
        
        // Stop reading aloud
        InstructionTextToSpeechSynthesizer.sharedInstance.routeComposite = nil
        
#if TRACKING_ENABLED
        TrackingHandler.sharedInstance().isCurrentlyRouting = false
#else
        NonTrackingHandler.sharedInstance().isCurrentlyRouting = false
#endif
    }
    
    override var preferredStatusBarStyle : UIStatusBarStyle {
        return .lightContent
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if
            segue.identifier == routeNavigationToReportErrorSegue,
            let reportErrorController = segue.destination as? SMReportErrorController
        {
            var instructionDescriptions = [String]()
            if let routeComposite = routeComposite,
                let route = routeComposite.currentRoute {
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
    
    fileprivate func addObservers() {
        // Location updates
        unobserve()
        observerTokens.append(NotificationCenter.observe("refreshPosition") { [weak self] notification in
            if let
                locations = notification.userInfo?["locations"] as? [CLLocation],
                let location = locations.first,
                let routeComposite = self?.routeComposite
            {
                // Tell route about new user location
                routeComposite.currentRoute?.visit(location)
                // Update stats to reflect route progress
                self?.updateStats()
            }
        })
    }
    
    fileprivate func unobserve() {
        for observerToken in observerTokens {
            NotificationCenter.unobserve(observerToken)
        }
        NotificationCenter.unobserve(self)
    }
    
    fileprivate func updateUI(_ zoom: Bool) {
        updateRouteUI(zoom)
        // Directions
        updateTurnInstructions()
        // Stats
        updateStats()
    }

    fileprivate func updateRouteUI(_ zoom: Bool) {
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
    
    fileprivate func updateStats() {
        if let routeComposite = routeComposite {
            // Stats
            routeNavigationToolbarView.routeStatsToolbarView.updateToRoute(routeComposite)
        } else {
            routeNavigationToolbarView.routeStatsToolbarView.prepareForReuse()
        }
    }
    
    fileprivate func updateTurnInstructions() {
        if let instructions = routeComposite?.currentRoute?.turnInstructions.copy() as? [SMTurnInstruction] {
            // Default
            routeNavigationDirectionsToolbarView.instructions = instructions

            if let routeComposite = routeComposite {
                switch routeComposite.composite {
                case .multiple(let routes):
                    if let currentRoute = routeComposite.currentRoute {
                        let previousIndex = routeComposite.currentRouteIndex - 1
                        if previousIndex < 0 {
                            break
                        } // Has previous route
                        let previousRoute = routes[previousIndex]
                        if previousRoute.routeType == .bike ||
                            previousRoute.routeType == .walk {
                            break
                        } // Previous route was public
                        let distanceFromPreviousRouteEndLocation = previousRoute.getEndLocation().distance(from: currentRoute.lastCorrectedLocation)
                        if distanceFromPreviousRouteEndLocation > MAX_DISTANCE_FOR_PUBLIC_TRANSPORT {
                            break
                        } // Still closer than X meters
                        // Keep showing last instruction of previous route
                        if let lastInstruction = (previousRoute.turnInstructions.copy() as? [SMTurnInstruction])?.first {
                            routeNavigationDirectionsToolbarView.extraInstruction = lastInstruction
                            print("\(lastInstruction)")
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
        
        // The route has updated, so speak its next turn instruction
        InstructionTextToSpeechSynthesizer.sharedInstance.speakTurnInstruction()
    }
}


extension RouteNavigationViewController: RouteNavigationDirectionsToolbarDelegate {
    
    func didSwipeToInstruction(_ instruction: SMTurnInstruction, userAction: Bool) {
        if !userAction {
            return
        }
        if let
            firstInstruction = routeComposite?.currentRoute?.turnInstructions.firstObject as? SMTurnInstruction, firstInstruction == instruction
        {
            // If user swiped to the first instruction, enable .Follow
            mapView.userTrackingMode = .follow
        } else {
            // Disable tracking to allow user to swipe through turn instructions
            mapView.userTrackingMode = .none
            mapView.centerCoordinate(instruction.location.coordinate, zoomLevel: mapView.zoomLevel)
        }
    }
}


extension RouteNavigationViewController: SMRouteDelegate {
    
    func updateTurn(_ firstElementRemoved: Bool) {
        updateTurnInstructions()
    }
    func reachedDestination() {
        if let routeComposite = routeComposite {
            switch routeComposite.composite {
            case .single(_):
                InstructionTextToSpeechSynthesizer.sharedInstance.hasReachedDestination = true
                return
            case .multiple(let routes): //  Go to next route if route contains more subroutes
                if routeComposite.currentRouteIndex + 1 < routes.count {
                    self.routeComposite?.currentRoute?.delegate = nil
                    self.routeComposite?.currentRouteIndex += 1
                    self.routeComposite?.currentRoute?.delegate = self
                    updateTurnInstructions()
                    updateStats()
                } else {
                    InstructionTextToSpeechSynthesizer.sharedInstance.hasReachedDestination = true
                }
                return
            }
        }
    }
    func updateRoute() {
        updateUI(false)
    }
    func start(_ route: SMRoute!) {
        
    }
    func routeNotFound() {
        
    }
    func serverError() {
        
    }
    func routeRecalculationStarted() {
        InstructionTextToSpeechSynthesizer.sharedInstance.speakRecalculatingRoute()
    }
    
    func routeRecalculationDone() {
    }
}
