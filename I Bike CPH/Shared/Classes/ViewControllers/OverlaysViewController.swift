//
//  OverlaysViewController.swift
//  I Bike CPH
//
//  Created by Tobias Due Munk on 08/01/15.
//  Copyright (c) 2015 I Bike CPH. All rights reserved.
//

import UIKit

private struct OverlayTypeViewModel {
    var title: String {
        return self.type.localizedDescription
    }
    var iconImage: UIImage? {
        let name: String = {
            switch self.type {
                case .CycleSuperHighways: return "bikeRoute"
                case .BikeServiceStations: return "serviceStation"
                case .STrainStations: return "sStation"
                case .MetroStations: return "metro"
                case .LocalTrainStation: return "localTrain"
            }
        }()
        return UIImage(named: name)
    }
    let type: OverlayType
    var selected: Bool {
        get {
            if let overlays = OverlayTypeViewModel.mapOverlays() {
                switch type {
                    case .CycleSuperHighways: return overlays.pathVisible
                    case .BikeServiceStations: return overlays.serviceMarkersVisible
                    case .STrainStations: return overlays.stationMarkersVisible
                    case .MetroStations: return overlays.metroMarkersVisible
                    case .LocalTrainStation: return overlays.localTrainMarkersVisible
                }
            }
            return false
        }
        set {
            if let mapOverlays = OverlayTypeViewModel.mapOverlays() {
                mapOverlays.toggleMarkers(type.key, state: newValue)
            }
        }
    }
    
    static func appDelegate() -> SMAppDelegate? {
        return UIApplication.sharedApplication().delegate as? SMAppDelegate ?? nil
    }
    
    static func mapOverlays() -> SMMapOverlays? {
        return OverlayTypeViewModel.appDelegate()?.mapOverlays
    }
    
    init(type: OverlayType) {
        self.type = type
    }
}


class OverlaysViewController: UIViewController {

    private let cellID = "OverlayCellID"
    
    private let items = [
        OverlayTypeViewModel(type: .CycleSuperHighways),
        OverlayTypeViewModel(type: .BikeServiceStations),
        OverlayTypeViewModel(type: .STrainStations),
        OverlayTypeViewModel(type: .MetroStations),
        OverlayTypeViewModel(type: .LocalTrainStation),
    ]
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return .LightContent
    }
}


extension OverlaysViewController: UITableViewDataSource {
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let cell = tableView.cellWithIdentifier(cellID, forIndexPath: indexPath) as IconLabelTableViewCell
        let item = items[indexPath.row]
        
        cell.configure(text: item.title, icon: item.iconImage)
        cell.accessoryType = item.selected ? .Checkmark : .None
        
        return cell
    }
}

extension OverlaysViewController: UITableViewDelegate {
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView .deselectRowAtIndexPath(indexPath, animated: true)
        
        var item = items[indexPath.row]
        item.selected = !item.selected
        tableView.reloadRowsAtIndexPaths([indexPath], withRowAnimation: UITableViewRowAnimation.None)
    }
}