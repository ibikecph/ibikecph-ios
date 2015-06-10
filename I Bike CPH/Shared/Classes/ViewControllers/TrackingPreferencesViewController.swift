//
//  TrackingPreferencesViewController.swift
//  I Bike CPH
//
//  Created by Tobias Due Munk on 09/03/15.
//  Copyright (c) 2015 I Bike CPH. All rights reserved.
//

import UIKit
import PSTAlertController

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
    let switchAction: (TrackingPreferencesViewController, UISwitch, Bool) -> ()
}


class TrackingPreferencesViewController: SMTranslatedViewController {
    
    @IBOutlet weak var tableView: UITableView!
    
    let cellID = "TrackingCellID"
    let cellSwitchID = "TrackingSwitchCellID"
    
    private let sections: [SectionViewModel<TrackingItemProtocol>] = [
        SectionViewModel(items:
            [
                TrackingSwitchItem(title: "tracking_option".localized, iconImageName: "Bikedata", on: settings.tracking.on, switchAction: { viewController, switcher, on in
                    if !UserHelper.loggedIn() && on {
                        let alertController = PSTAlertController(title: "", message: "log_in_to_track_prompt".localized, preferredStyle: .Alert)
                        alertController.addCancelActionWithHandler(nil)
                        let loginAction = PSTAlertAction(title: "log_in".localized) { action in
                            viewController.performSegueWithIdentifier("trackingPreferencesToLogin", sender: viewController)
                        }
                        alertController.addAction(loginAction)
                        alertController.showWithSender(viewController, controller: viewController, animated: true, completion: nil)
                        switcher.setOn(false, animated: true)
                        return
                    }
                    settings.tracking.on = on
                }),
                TrackingSwitchItem(title: "tracking_milestone_notifications".localized, iconImageName: "Milestones", on: settings.tracking.milestoneNotifications, switchAction: { voiceViewController, switcher, on in
                    settings.tracking.milestoneNotifications = on
                }),
                TrackingSwitchItem(title: "tracking_weekly_status_notifications".localized, iconImageName: "Weekday", on: settings.tracking.weeklyStatusNotifications, switchAction: { voiceViewController, switcher, on in
                    settings.tracking.weeklyStatusNotifications = on
                }),
            ]
        ),
    ]
    
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
            cell.switchChanged = { on in item.switchAction(self, cell.switcher, on) }
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
