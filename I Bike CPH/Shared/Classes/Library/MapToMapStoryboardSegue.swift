//
//  LeftSlideOutSegue.swift
//  I Bike CPH
//
//  Created by Tobias Due Munk on 21/05/15.
//  Copyright (c) 2015 I Bike CPH. All rights reserved.
//

import UIKit

public class MapToMapStoryboardSegue: UIStoryboardPopoverSegue {
    
    public override func perform() {
        var firstView = self.sourceViewController.view as UIView!
        var secondView = self.destinationViewController.view as UIView!
        
        // Get the screen width and height.
        let screenWidth = UIScreen.mainScreen().bounds.size.width
        let screenHeight = UIScreen.mainScreen().bounds.size.height
        
        // Initial position
        secondView.frame = CGRectMake(-screenWidth, 0, screenWidth, screenHeight)
        
        // Access the app's key window and insert the destination view above the current (source) one.
        let window = UIApplication.sharedApplication().keyWindow
        window?.insertSubview(secondView, aboveSubview: firstView)
        
        // Animate the transition.
        UIView.animateWithDuration(0.4, animations: { () -> Void in
            firstView.frame = CGRectOffset(firstView.frame, 0.0, -screenHeight)
            secondView.frame = CGRectOffset(secondView.frame, 0.0, -screenHeight)
            
            }) { (Finished) -> Void in
                
        }
    }
}
