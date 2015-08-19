//
//  LaunchReadMoreViewController.swift
//  I Bike CPH
//
//  Created by Tobias Due Munk on 19/08/15.
//  Copyright (c) 2015 I Bike CPH. All rights reserved.
//

import UIKit

class LaunchReadMoreViewController: SMTranslatedViewController {
    
    @IBOutlet weak var textView: UITextView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        textView.font = UIFont.preferredFontForTextStyle(UIFontTextStyleBody)
        textView.textContainerInset = UIEdgeInsets(top: 20, left: 10, bottom: 20, right: 10)
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        navigationController?.setNavigationBarHidden(false, animated: true)
    }
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return .LightContent
    }
}
