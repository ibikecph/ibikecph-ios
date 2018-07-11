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
    var enabled: (() -> Bool)? { get }
}

private struct TrackingItem : TrackingItemProtocol {
    let title: String
    let iconImageName: String
    let action: (TrackingPreferencesViewController) -> ()
    var enabled: (() -> Bool)?
}

private struct TrackingSwitchItem: TrackingItemProtocol {
    let title: String
    let iconImageName: String
    let on: () -> Bool
    let switchAction: (TrackingPreferencesViewController, UISwitch, Bool) -> ()
    var enabled: (() -> Bool)?
}


class TrackingPreferencesViewController: SMTranslatedViewController {
    
    @IBOutlet weak var tableView: UITableView!
    
    fileprivate let cellID = "TrackingCellID"
    fileprivate let cellSwitchID = "TrackingSwitchCellID"
    fileprivate let toLoginSegue = "trackingPreferencesToLogin"
    fileprivate let toAddTrackTokenSegue = "trackingPreferencesToAddTrackToken"
    fileprivate var pendingEnableTracking = false
    
    fileprivate let sections: [SectionViewModel<TrackingItemProtocol>] = [
        SectionViewModel(items:
            [
                TrackingSwitchItem(
                    title: "tracking_option".localized,
                    iconImageName: "Bikedata",
                    on: { Settings.sharedInstance.tracking.on },
                    switchAction: { viewController, switcher, on in
                        
                        if on {
                            switch UserHelper.checkEnableTracking() {
                            case .notLoggedIn:
                                let alertController = PSTAlertController(title: "", message: "log_in_to_track_prompt".localized, preferredStyle: .alert)
                                alertController.addCancelAction(handler: nil)
                                let loginAction = PSTAlertAction(title: "log_in".localized) { action in
                                    viewController.pendingEnableTracking = true
                                    viewController.performSegue(withIdentifier: viewController.toLoginSegue, sender: viewController)
                                }
                                alertController.addAction(loginAction)
                                alertController.showWithSender(viewController, controller: viewController, animated: true, completion: nil)
                                switcher.setOn(false, animated: true)
                            case .allowed:
                                Settings.sharedInstance.tracking.on = true
                            case .lacksTrackToken:
                                // User is logged in but doesn't have a trackToken
                                switcher.setOn(false, animated: true)
                                viewController.pendingEnableTracking = true
                                viewController.performSegue(withIdentifier: viewController.toAddTrackTokenSegue, sender: viewController)
                                return
                            }
                        } else {
                            Settings.sharedInstance.tracking.on = false
                        }
                        if let indexPaths = viewController.tableView.indexPathsForVisibleRows {
                            viewController.tableView.beginUpdates()
                            viewController.tableView.reloadRows(at: indexPaths, with: .fade)
                            viewController.tableView.endUpdates()
                        }
                }, enabled: nil
                ),
                TrackingSwitchItem(
                    title: "tracking_milestone_notifications".localized,
                    iconImageName: "Milestones",
                    on: { Settings.sharedInstance.tracking.milestoneNotifications },
                    switchAction: { voiceViewController, switcher, on in
                        Settings.sharedInstance.tracking.milestoneNotifications = on
                    },
                    enabled: { Settings.sharedInstance.tracking.on }
                ),
                TrackingSwitchItem(
                    title: "tracking_weekly_status_notifications".localized,
                    iconImageName: "Weekday",
                    on: { Settings.sharedInstance.tracking.weeklyStatusNotifications },
                    switchAction: { voiceViewController, switcher, on in
                        Settings.sharedInstance.tracking.weeklyStatusNotifications = on
                    },
                    enabled: { Settings.sharedInstance.tracking.on }
                ),
            ]
        ),
    ]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "settings".localized
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
     
        if pendingEnableTracking && UserHelper.checkEnableTracking() == .allowed {
            Settings.sharedInstance.tracking.on = true
            if let indexPaths = tableView.indexPathsForVisibleRows {
                tableView.beginUpdates()
                tableView.reloadRows(at: indexPaths, with: .fade)
                tableView.endUpdates()
            }
        } else if pendingEnableTracking && UserHelper.checkEnableTracking() == .lacksTrackToken {
            performSegue(withIdentifier: toAddTrackTokenSegue, sender: self)
        } else {
            pendingEnableTracking = false
        }
    }
    
    override var preferredStatusBarStyle : UIStatusBarStyle {
        return .lightContent
    }
}

extension TrackingPreferencesViewController: UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return sections[section].title
    }
    
    func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        return sections[section].footer
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sections[section].items.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let item = sections[indexPath.section].items[indexPath.row]
        
        if let item = item as? TrackingSwitchItem {
            let cell = tableView.cellWithIdentifier(cellSwitchID, forIndexPath: indexPath) as IconLabelSwitchTableViewCell
            cell.configure(item.title, icon: UIImage(named: item.iconImageName))
            // Configure switcher
            cell.switcher.isOn = item.on()
            cell.switchChanged = { on in item.switchAction(self, cell.switcher, on) }
            let enabled = item.enabled?() ?? true
            cell.enabled = enabled
            return cell
        }
        let cell = tableView.cellWithIdentifier(cellID, forIndexPath: indexPath) as IconLabelTableViewCell
        cell.configure(item.title, icon: UIImage(named: item.iconImageName))
        return cell
    }
}

extension TrackingPreferencesViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let item = sections[indexPath.section].items[indexPath.row] as? TrackingItem {
            item.action(self)
        }
        tableView.deselectRow(at: indexPath, animated: true)
    }
}
