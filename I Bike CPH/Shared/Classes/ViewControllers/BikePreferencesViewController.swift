//
//  BikePreferencesViewController.swift
//  I Bike CPH
//
//  Created by Tobias Due Munk on 08/01/15.
//  Copyright (c) 2015 I Bike CPH. All rights reserved.
//

import UIKit

private struct RouteTypeViewModel {
    var title: String {
        return self.type.localizedDescription
    }
    var iconImage: UIImage? {
        let name: String = {
            switch self.type {
                case .Regular: return "regularBike"
                case .Cargo: return "cargoBike"
            }
        }()
        return UIImage(named: name)
    }
    let type: RouteType
    var selected: Bool {
        get {
            return type == routeTypeHandler.type
        }
        set {
            if newValue {
                routeTypeHandler.type = type
            }
        }
    }
    
    init(type: RouteType) {
        self.type = type
    }
}


class BikePreferencesViewController: UIViewController {

    private let cellID = "RouteCellID"
    
    private let items = [
        RouteTypeViewModel(type: .Regular),
        RouteTypeViewModel(type: .Cargo),
    ]
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return .LightContent
    }
}


extension BikePreferencesViewController: UITableViewDataSource {
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCellWithIdentifier(cellID, forIndexPath: indexPath) as IconLabelTableViewCell
        let item = items[indexPath.row]
        
        cell.configure(text: item.title, icon: item.iconImage)
        cell.accessoryType = item.selected ? .Checkmark : .None
        
        return cell
    }
}

extension BikePreferencesViewController: UITableViewDelegate {
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView .deselectRowAtIndexPath(indexPath, animated: true)
        
        var item = items[indexPath.row]
        item.selected = !item.selected
        tableView.reloadRowsAtIndexPaths([indexPath], withRowAnimation: UITableViewRowAnimation.None)
    }
}