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
        return self.type.menuIcon
    }
    let type: OverlayType
    var selected: Bool {
        get {
            if let overlays = OverlayTypeViewModel.mapOverlays() {
                switch type {
                    case .CycleSuperHighways: return Settings.sharedInstance.overlays.showCycleSuperHighways
                    case .BikeServiceStations: return Settings.sharedInstance.overlays.showBikeServiceStations
                    case .HarborRing: return Settings.sharedInstance.overlays.showHarborRing
                    case .GreenPaths: return Settings.sharedInstance.overlays.showGreenPaths
                }
            }
            return false
        }
        set {
            if let mapOverlays = OverlayTypeViewModel.mapOverlays() {
                switch type {
                    case .CycleSuperHighways: Settings.sharedInstance.overlays.showCycleSuperHighways = newValue
                    case .BikeServiceStations: Settings.sharedInstance.overlays.showBikeServiceStations = newValue
                    case .HarborRing: Settings.sharedInstance.overlays.showHarborRing = newValue
                    case .GreenPaths: Settings.sharedInstance.overlays.showGreenPaths = newValue
                }
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
    
    private let items: [OverlayTypeViewModel] = {
        if Macro.instance().isCykelPlanen {
            return [
//                OverlayTypeViewModel(type: .CycleSuperHighways),
                OverlayTypeViewModel(type: .BikeServiceStations)
            ]
        }
        if Macro.instance().isIBikeCph {
            return [
                OverlayTypeViewModel(type: .HarborRing),
                OverlayTypeViewModel(type: .GreenPaths)
            ]
        }
        return []
        
        }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "map_overlays".localized
    }
    
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
        
        cell.configure(item.title, icon: item.iconImage)
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