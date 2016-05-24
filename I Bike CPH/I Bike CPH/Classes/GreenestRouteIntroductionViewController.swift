//
//  GreenestRouteIntroductionViewController.swift
//  I Bike CPH
//
//  Created by Troels Michael Trebbien on 24/05/16.
//  Copyright © 2016 I Bike CPH. All rights reserved.
//

import UIKit

class GreenestRouteIntroductionViewController: UIViewController {
    
    override func loadView() {
        self.view = GreenestRouteIntroductionView()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if let view = self.view as? GreenestRouteIntroductionView {
            view.footerButton.addTarget(self, action: #selector(pressedFooterButton), forControlEvents: .TouchUpInside)
        }
    }
    
    func pressedFooterButton(sender: UIButton) {
        Settings.sharedInstance.turnstile.didSeeGreenestRouteIntroduction = true
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return .Default
    }
}
