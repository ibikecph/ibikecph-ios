//
//  RouteNavigationToolbarView.swift
//  I Bike CPH
//
//  Created by Tobias Due Munk on 04/06/15.
//  Copyright (c) 2015 I Bike CPH. All rights reserved.
//

import UIKit

class RouteNavigationToolbarView: ToolbarView {
    
    @IBOutlet weak var routeStatsToolbarView: RouteStatsToolbarView!
    
    @IBOutlet weak var destinationLabel: UILabel!
}

extension RouteNavigationToolbarView {
    
    override func prepareForReuse() {
        super.prepareForReuse()
        destinationLabel.text = nil
    }
    
    func updateWithItem(item: SearchListItem?) {
        destinationLabel.text = item?.name
    }
}
