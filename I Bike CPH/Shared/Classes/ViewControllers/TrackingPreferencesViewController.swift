//
//  TrackingPreferencesViewController.swift
//  I Bike CPH
//
//  Created by Tobias Due Munk on 09/03/15.
//  Copyright (c) 2015 I Bike CPH. All rights reserved.
//

import UIKit


private protocol TrackingItemProtocol {
    var title: String { get }
    var iconImageName: String { get }
}

private struct TrackingItem : TrackingItemProtocol {
    let title: String
    let iconImageName: String
    let action: TrackingPreferencesViewController -> ()
}

private struct TrackingSwitchItem: TrackingItemProtocol {
    let title: String
    let iconImageName: String
    let on: Bool
    let switchAction: (TrackingPreferencesViewController, Bool) -> ()
}


class TrackingPreferencesViewController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    
    let cellID = "TrackingCellID"
    let cellSwitchID = "TrackingSwitchCellID"
    
    private let sections: [SectionViewModel<TrackingItemProtocol>] = [
        SectionViewModel(items:
            [
                TrackingSwitchItem(title: "tracking_option".localized, iconImageName: "tracking", on: settings.tracking.on, switchAction: { voiceViewController, on in
                    settings.tracking.on = on
                }),
                // TODO: Add icon for milestones
                TrackingSwitchItem(title: "tracking_milestone_notifications".localized, iconImageName: "", on: settings.tracking.milestoneNotifications, switchAction: { voiceViewController, on in
                    settings.tracking.milestoneNotifications = on
                }),
                TrackingSwitchItem(title: "tracking_weekly_status_notifications".localized, iconImageName: "", on: settings.tracking.weeklyStatusNotifications, switchAction: { voiceViewController, on in
                    settings.tracking.weeklyStatusNotifications = on
                }),
            ]
        ),
    ]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
//        self.title = "tracking_preferences".localized
    }
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return .LightContent
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    // Mark: - Actions
    
    @IBAction func doneButtonPressed(sender: AnyObject) {
        dismiss()
    }
}

extension TrackingPreferencesViewController: UITableViewDataSource {
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return sections.count
    }
    
    func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return sections[section].title
    }
    
    func tableView(tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        return sections[section].footer
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sections[section].items.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let item = sections[indexPath.section].items[indexPath.row]
        
        if let item = item as? TrackingSwitchItem {
            let cell = tableView.cellWithIdentifier(cellSwitchID, forIndexPath: indexPath) as IconLabelSwitchTableViewCell
            cell.configure(text: item.title, icon: UIImage(named: item.iconImageName))
            cell.switcher.on = item.on
            cell.switchChanged = { on in item.switchAction(self, on) }
            return cell
        }
        let cell = tableView.cellWithIdentifier(cellID, forIndexPath: indexPath) as IconLabelTableViewCell
        cell.configure(text: item.title, icon: UIImage(named: item.iconImageName))
        return cell
    }
}

extension TrackingPreferencesViewController: UITableViewDelegate {
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if let item = sections[indexPath.section].items[indexPath.row] as? TrackingItem {
            item.action(self)
        }
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
    }
}
