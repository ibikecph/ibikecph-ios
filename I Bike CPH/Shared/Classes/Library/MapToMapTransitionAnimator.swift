//
//  MapToMapTransitionAnimator.swift
//  MapToMapTransition
//
//  Created by Tobias Due Munk on 26/06/15.
//  Copyright (c) 2015 I Bike CPH. All rights reserved.
//

import UIKit

class MapToMapTransitionAnimator: NSObject, UIViewControllerAnimatedTransitioning {
  
    weak var transitionContext: UIViewControllerContextTransitioning?
  
    func transitionDuration(transitionContext: UIViewControllerContextTransitioning) -> NSTimeInterval {
        return 0.2;
    }
  
    func animateTransition(transitionContext: UIViewControllerContextTransitioning) {
        self.transitionContext = transitionContext
        
        var containerView = transitionContext.containerView()
        if let
            fromViewController = transitionContext.viewControllerForKey(UITransitionContextFromViewControllerKey) as? MapViewController,
            toViewController = transitionContext.viewControllerForKey(UITransitionContextToViewControllerKey) as? MapViewController
        {
            // Add toViewController to view hierarchy
            containerView.addSubview(toViewController.view)
            
            // Fade in toViewController
            var maskLayerAnimation = CABasicAnimation(keyPath:NSStringFromSelector(Selector("opacity")))
            maskLayerAnimation.fromValue = 0
            maskLayerAnimation.toValue = 1
            maskLayerAnimation.duration = self.transitionDuration(transitionContext)
            maskLayerAnimation.delegate = self
            toViewController.view.layer.addAnimation(maskLayerAnimation, forKey: "opacity")
        }
    }
  
    override func animationDidStop(anim: CAAnimation!, finished flag: Bool) {
        self.transitionContext?.completeTransition(!self.transitionContext!.transitionWasCancelled())
    }
}
