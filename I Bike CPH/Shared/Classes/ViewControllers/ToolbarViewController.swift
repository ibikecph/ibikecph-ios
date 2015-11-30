//
//  ToolbarViewController.swift
//  I Bike CPH
//
//  Created by Tobias Due Munk on 04/06/15.
//  Copyright (c) 2015 I Bike CPH. All rights reserved.
//

import UIKit

class ToolbarViewController: SMTranslatedViewController {

    @IBOutlet weak var toolbarContainer: UIView!
    
    private(set) var toolbarView: ToolbarView?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        toolbarContainer.layer.masksToBounds = false
        toolbarContainer.layer.shadowOffset = CGSize(width: 0, height: 0.5)
        toolbarContainer.layer.shadowRadius = 0
        toolbarContainer.layer.shadowOpacity = 0.125
    }
    
    func add(toolbarView new: ToolbarView) {
        if toolbarView == new {
            return
        }
        removeToolbar()
        // Add new toolbar
        toolbarView = new
        toolbarContainer.addSubview(new)
        new.setTranslatesAutoresizingMaskIntoConstraints(false)
        toolbarContainer.addConstraints([
            NSLayoutConstraint(item: new, attribute: .Top, relatedBy: .Equal, toItem: toolbarContainer, attribute: .Top, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: new, attribute: .Left, relatedBy: .Equal, toItem: toolbarContainer, attribute: .Left, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: new, attribute: .Right, relatedBy: .Equal, toItem: toolbarContainer, attribute: .Right, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: new, attribute: .Bottom, relatedBy: .Equal, toItem: toolbarContainer, attribute: .Bottom, multiplier: 1, constant: 0)
        ])
    }
    
    func removeToolbar() {
        if let existing = toolbarView {
            existing.removeFromSuperview()
        }
        toolbarView = nil
    }
}
