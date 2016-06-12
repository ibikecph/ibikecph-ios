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
    let textToSpeechSynthesizer = TextToSpeechSynthesizer()
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
        updateUI(true)
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        addObservers()
#if TRACKING_ENABLED
        TrackingHandler.sharedInstance().isCurrentlyRouting = true
#else
        NonTrackingHandler.sharedInstance().isCurrentlyRouting = true
#endif
    }

    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        unobserve()
#if TRACKING_ENABLED
        TrackingHandler.sharedInstance().isCurrentlyRouting = false
#else
        NonTrackingHandler.sharedInstance().isCurrentlyRouting = false
#endif
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
    
    private func updateUI(zoom: Bool) {
        updateRouteUI(zoom)
        // Directions
        updateTurnInstructions()
        // Stats
        updateStats()
    }

    private func updateRouteUI(zoom: Bool) {
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
            
            if let instruction = instructions.first {
                self.readAloud(instruction)
            }

            if let routeComposite = routeComposite {
                switch routeComposite.composite {
                case .Multiple(let routes):
                    if let currentRoute = routeComposite.currentRoute {
                        let previousIndex = routeComposite.currentRouteIndex - 1
                        if previousIndex < 0 {
                            break
                        } // Has previous route
                        let previousRoute = routes[previousIndex]
                        if previousRoute.routeType == SMRouteTypeBike ||
                            previousRoute.routeType == SMRouteTypeWalk {
                            break
                        } // Previous route was public
                        let distanceFromPreviousRouteEndLocation = previousRoute.getEndLocation().distanceFromLocation(currentRoute.lastCorrectedLocation)
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
    }
    
    
    
    var lastSpokenTurnInstruction: String = ""
    var previousDistanceToNextTurn: Int = Int.max
    var turnInstructionSpoken: Bool = false
    
    func readAloud(instruction: SMTurnInstruction) {
        var nextTurnInstruction = instruction.fullDescriptionString
        let distanceToNextTurn = Int(instruction.lengthInMeters)
        let minimumDistanceBeforeTurn: Int = 50
        let distanceDelta: Int = 300
        if (self.lastSpokenTurnInstruction != nextTurnInstruction) {
            // The next turn instruction has changed
            if distanceToNextTurn < minimumDistanceBeforeTurn {
                self.lastSpokenTurnInstruction = nextTurnInstruction
                self.previousDistanceToNextTurn = distanceToNextTurn
                self.textToSpeechSynthesizer.speak(nextTurnInstruction)
                print(nextTurnInstruction)
            } else {
                self.lastSpokenTurnInstruction = nextTurnInstruction
                self.previousDistanceToNextTurn = distanceToNextTurn
                nextTurnInstruction = "In \(instruction.lengthWithUnit), " + nextTurnInstruction
                self.textToSpeechSynthesizer.speak(nextTurnInstruction)
                print(nextTurnInstruction)
            }
        } else {
            // The next turn instruction is the same as before
            if distanceToNextTurn < minimumDistanceBeforeTurn && self.previousDistanceToNextTurn >= minimumDistanceBeforeTurn {
                self.lastSpokenTurnInstruction = nextTurnInstruction
                self.previousDistanceToNextTurn = distanceToNextTurn
                self.textToSpeechSynthesizer.speak(nextTurnInstruction)
                print(nextTurnInstruction)
            } else if distanceToNextTurn <= (self.previousDistanceToNextTurn - distanceDelta) {
                self.lastSpokenTurnInstruction = nextTurnInstruction
                self.previousDistanceToNextTurn = distanceToNextTurn
                nextTurnInstruction = "in".localized + " \(instruction.lengthWithUnit), " + nextTurnInstruction
                self.textToSpeechSynthesizer.speak(nextTurnInstruction)
                print(nextTurnInstruction)
            }
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
                if routeComposite.currentRouteIndex + 1 < routes.count {
                    print("Going to next route segment")
                    self.routeComposite?.currentRoute?.delegate = nil
                    self.routeComposite?.currentRouteIndex += 1
                    self.routeComposite?.currentRoute?.delegate = self
                    updateTurnInstructions()
                    updateStats()
                }
            }
        }
    }
    func updateRoute() {
        updateUI(false)
    }
    func startRoute(route: SMRoute!) {
        
    }
    func routeNotFound() {
        
    }
    func serverError() {
        
    }
    func routeRecalculationStarted() {
    }
    
    func routeRecalculationDone() {
    }
}
