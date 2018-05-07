//
//  ToolbarViewContainer.swift
//  I Bike CPH
//
//  Created by Tobias Due Munk on 12/11/15.
//  Copyright (c) 2015 I Bike CPH. All rights reserved.
//

import UIKit


class ToolbarViewContainer: UIView {

    var toolbarView: ToolbarView? = nil

    func add(toolbarView new: ToolbarView) {
        if toolbarView == new {
            return
        }
        removeToolbar()
        // Add new toolbar
        toolbarView = new
        addSubview(new)
        new.translatesAutoresizingMaskIntoConstraints = false
        addConstraints([
            NSLayoutConstraint(item: new, attribute: .top, relatedBy: .equal, toItem: self, attribute: .top, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: new, attribute: .left, relatedBy: .equal, toItem: self, attribute: .left, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: new, attribute: .right, relatedBy: .equal, toItem: self, attribute: .right, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: new, attribute: .bottom, relatedBy: .equal, toItem: self, attribute: .bottom, multiplier: 1, constant: 0)
            ])
        setNeedsLayout()
    }

    func removeToolbar() {
        if let existing = toolbarView {
            existing.removeFromSuperview()
        }
        toolbarView = nil
    }
}
