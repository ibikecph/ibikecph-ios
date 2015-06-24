//
//  RouteNavigationToolbarView.swift
//  I Bike CPH
//
//  Created by Tobias Due Munk on 04/06/15.
//  Copyright (c) 2015 I Bike CPH. All rights reserved.
//

import UIKit

protocol RouteNavigationToolbarDelegate {
    func didSelectReportProblem()
}

class RouteNavigationToolbarView: ToolbarView {

    var delegate: RouteNavigationToolbarDelegate?
    
    @IBOutlet weak var routeStatsToolbarView: RouteStatsToolbarView!
    
    @IBOutlet weak var destinationLabel: UILabel!
    
    @IBAction func didTapProblem(sender: AnyObject) {
        delegate?.didSelectReportProblem()
    }
}

extension RouteNavigationToolbarView {
    
    func prepareForReuse() {
        destinationLabel.text = nil
    }
    
    func updateWithItem(item: SearchListItem?) {
        destinationLabel.text = item?.name
    }
}
