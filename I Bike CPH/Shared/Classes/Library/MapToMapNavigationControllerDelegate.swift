//
//  MapToMapNavigationControllerDelegate.swift
//  MapToMapTransition
//
//  Created by Tobias Due Munk on 26/06/15.
//  Copyright (c) 2015 I Bike CPH. All rights reserved.
//

import UIKit
// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}

// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func > <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l > r
  default:
    return rhs < lhs
  }
}


class MapToMapNavigationControllerDelegate: NSObject, UINavigationControllerDelegate {
    @IBOutlet weak var navigationController: UINavigationController?
    
    var interactionController: UIPercentDrivenInteractiveTransition?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        let panGesture = UIScreenEdgePanGestureRecognizer(target: self, action: #selector(MapToMapNavigationControllerDelegate.panned(_:)))
        panGesture.edges = .left
        panGesture.delegate = self
        self.navigationController!.view.addGestureRecognizer(panGesture)
    }
    
    @IBAction func panned(_ gestureRecognizer: UIPanGestureRecognizer) {
        switch gestureRecognizer.state {
        case .began:
            self.interactionController = UIPercentDrivenInteractiveTransition()
            if self.navigationController?.viewControllers.count > 1 {
                self.navigationController?.popViewController(animated: true)
            }
        case .changed:
            let translation = gestureRecognizer.translation(in: self.navigationController!.view)
            let completionProgress = translation.x/self.navigationController!.view.bounds.width
            self.interactionController?.update(completionProgress)
        case .ended:
            if (gestureRecognizer.velocity(in: self.navigationController!.view).x > 0) {
                self.interactionController?.finish()
            } else {
                self.interactionController?.cancel()
            }
            self.interactionController = nil
            
        default:
            self.interactionController?.cancel()
            self.interactionController = nil
        }
    }
    
    func navigationController(_ navigationController: UINavigationController, animationControllerFor operation: UINavigationControllerOperation, from fromVC: UIViewController, to toVC: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        if fromVC is MapViewController && toVC is MapViewController {
            return MapToMapTransitionAnimator()
        }
        return nil
    }
    
    func navigationController(_ navigationController: UINavigationController, interactionControllerFor animationController: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        if animationController is MapToMapTransitionAnimator {
            return self.interactionController
        }
        return nil
    }
}


extension MapToMapNavigationControllerDelegate: UIGestureRecognizerDelegate {
    
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        // Check if did push from Map to Map
        let stackCount = navigationController?.viewControllers.count ?? 0
        if stackCount >= 2 {
            return true
        }
        return false
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldBeRequiredToFailBy otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        // Overrule all other gestures
        return true
    }
}
