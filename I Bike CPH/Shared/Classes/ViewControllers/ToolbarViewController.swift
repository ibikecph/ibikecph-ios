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
    
    fileprivate(set) var toolbarView: ToolbarView?
    
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
        new.translatesAutoresizingMaskIntoConstraints = false
        toolbarContainer.addConstraints([
            NSLayoutConstraint(item: new, attribute: .top, relatedBy: .equal, toItem: toolbarContainer, attribute: .top, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: new, attribute: .left, relatedBy: .equal, toItem: toolbarContainer, attribute: .left, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: new, attribute: .right, relatedBy: .equal, toItem: toolbarContainer, attribute: .right, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: new, attribute: .bottom, relatedBy: .equal, toItem: toolbarContainer, attribute: .bottom, multiplier: 1, constant: 0)
        ])
    }
    
    func removeToolbar() {
        if let existing = toolbarView {
            existing.removeFromSuperview()
        }
        toolbarView = nil
    }
}
