//
//  MapToMapTransitionAnimator.swift
//  MapToMapTransition
//
//  Created by Tobias Due Munk on 26/06/15.
//  Copyright (c) 2015 I Bike CPH. All rights reserved.
//

import UIKit

class MapToMapTransitionAnimator: NSObject, UIViewControllerAnimatedTransitioning, CAAnimationDelegate {
  
    weak var transitionContext: UIViewControllerContextTransitioning?
  
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 0.2;
    }
  
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        self.transitionContext = transitionContext
        
        let containerView = transitionContext.containerView
        if let toViewController = transitionContext.viewController(forKey: UITransitionContextViewControllerKey.to) as? MapViewController {
            // Add toViewController to view hierarchy
            containerView.addSubview(toViewController.view)
            
            // Fade in toViewController
            let maskLayerAnimation = CABasicAnimation(keyPath:NSStringFromSelector(#selector(getter: CALayer.opacity)))
            maskLayerAnimation.fromValue = 0
            maskLayerAnimation.toValue = 1
            maskLayerAnimation.duration = self.transitionDuration(using: transitionContext)
            maskLayerAnimation.delegate = self
            toViewController.view.layer.add(maskLayerAnimation, forKey: "opacity")
        }
    }
  
    // Removed the "override" annotation from the function below. TODO: Make sure the current implementation matches the function's purpose. 
    func animationDidStop(_ anim: CAAnimation, finished flag: Bool) {
        self.transitionContext?.completeTransition(!self.transitionContext!.transitionWasCancelled)
    }
}
