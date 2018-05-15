//
//  EnableTrackingToolbarView.swift
//  I Bike CPH
//
//  Created by Tobias Due Munk on 10/06/15.
//  Copyright (c) 2015 I Bike CPH. All rights reserved.
//

import UIKit

protocol EnableTrackingToolbarDelegate {
    func didSelectEnableTracking()
}

class EnableTrackingToolbarView: ToolbarView {
    
    var delegate: EnableTrackingToolbarDelegate?
    
    @IBAction func didTapView(_ sender: AnyObject) {
        delegate?.didSelectEnableTracking()
    }
}
