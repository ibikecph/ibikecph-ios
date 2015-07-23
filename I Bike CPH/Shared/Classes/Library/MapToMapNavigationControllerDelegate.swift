//
//  MapToMapNavigationControllerDelegate.swift
//  MapToMapTransition
//
//  Created by Tobias Due Munk on 26/06/15.
//  Copyright (c) 2015 I Bike CPH. All rights reserved.
//

import UIKit

class MapToMapNavigationControllerDelegate: NSObject, UINavigationControllerDelegate {
    @IBOutlet weak var navigationController: UINavigationController?
    
    var interactionController: UIPercentDrivenInteractiveTransition?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        var panGesture = UIScreenEdgePanGestureRecognizer(target: self, action: Selector("panned:"))
        panGesture.edges = .Left
        panGesture.delegate = self
        self.navigationController!.view.addGestureRecognizer(panGesture)
    }
    
    @IBAction func panned(gestureRecognizer: UIPanGestureRecognizer) {
        switch gestureRecognizer.state {
        case .Began:
            self.interactionController = UIPercentDrivenInteractiveTransition()
            if self.navigationController?.viewControllers.count > 1 {
                self.navigationController?.popViewControllerAnimated(true)
            }
        case .Changed:
            var translation = gestureRecognizer.translationInView(self.navigationController!.view)
            var completionProgress = translation.x/CGRectGetWidth(self.navigationController!.view.bounds)
            self.interactionController?.updateInteractiveTransition(completionProgress)
        case .Ended:
            if (gestureRecognizer.velocityInView(self.navigationController!.view).x > 0) {
                self.interactionController?.finishInteractiveTransition()
            } else {
                self.interactionController?.cancelInteractiveTransition()
            }
            self.interactionController = nil
            
        default:
            self.interactionController?.cancelInteractiveTransition()
            self.interactionController = nil
        }
    }
    
    func navigationController(navigationController: UINavigationController, animationControllerForOperation operation: UINavigationControllerOperation, fromViewController fromVC: UIViewController, toViewController toVC: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        if fromVC is MapViewController && toVC is MapViewController {
            return MapToMapTransitionAnimator()
        }
        return nil
    }
    
    func navigationController(navigationController: UINavigationController, interactionControllerForAnimationController animationController: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        if animationController is MapToMapTransitionAnimator {
            return self.interactionController
        }
        return nil
    }
}


extension MapToMapNavigationControllerDelegate: UIGestureRecognizerDelegate {
    
    func gestureRecognizerShouldBegin(gestureRecognizer: UIGestureRecognizer) -> Bool {
        // Check if did push from Map to Map
        let stackCount = navigationController?.viewControllers.count ?? 0
        if stackCount >= 2, let
            lastMap = navigationController?.viewControllers.last as? MapViewController,
            secondLastMap = navigationController?.viewControllers[stackCount-2] as? MapViewController
        {
            return true
        }
        return false
    }
    
    func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldBeRequiredToFailByGestureRecognizer otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        // Overrule all other gestures
        return true
    }
}
