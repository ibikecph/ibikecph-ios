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
        new.setTranslatesAutoresizingMaskIntoConstraints(false)
        addConstraints([
            NSLayoutConstraint(item: new, attribute: .Top, relatedBy: .Equal, toItem: self, attribute: .Top, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: new, attribute: .Left, relatedBy: .Equal, toItem: self, attribute: .Left, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: new, attribute: .Right, relatedBy: .Equal, toItem: self, attribute: .Right, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: new, attribute: .Bottom, relatedBy: .Equal, toItem: self, attribute: .Bottom, multiplier: 1, constant: 0)
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
