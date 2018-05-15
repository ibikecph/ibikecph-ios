//
//  OverlaysViewController.swift
//  I Bike CPH
//
//  Created by Tobias Due Munk on 08/01/15.
//  Copyright (c) 2015 I Bike CPH. All rights reserved.
//

import UIKit

class OverlaysViewController: UIViewController {

    fileprivate let cellID = "OverlayCellID"
    
    fileprivate var observerTokens = [AnyObject]()
    
    deinit {
        unobserve()
    }
    
    fileprivate func unobserve() {
        for observerToken in observerTokens {
            NotificationCenter.unobserve(observerToken)
        }
        NotificationCenter.unobserve(self)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "map_overlays".localized
        
        observerTokens.append(NotificationCenter.observe(overlaysUpdatedNotification) { [weak self] notification in
            // Find relevant table view in messy Nib labyrinth and update it
            if let view = self?.view {
                for v: UIView in view.subviews {
                    if let tv = v as? UITableView {
                        tv.reloadData()
                    }
                }
            }
        })
    }
    
    override var preferredStatusBarStyle : UIStatusBarStyle {
        return .lightContent
    }
}

extension OverlaysViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return OverlaysManager.sharedInstance.availableOverlays.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.cellWithIdentifier(cellID, forIndexPath: indexPath) as IconLabelTableViewCell
        let item = OverlaysManager.sharedInstance.availableOverlays[indexPath.row]
        
        let title = OverlaysManager.sharedInstance.titleForOverlay(item)
        let iconImage = OverlaysManager.sharedInstance.iconImageForOverlay(item)
        let selected = OverlaysManager.sharedInstance.isOverlaySelected(item)
        
        cell.configure(title, icon: iconImage)
        cell.accessoryType = selected ? .checkmark : .none
        
        return cell
    }
}

extension OverlaysViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView .deselectRow(at: indexPath, animated: true)
        
        let item = OverlaysManager.sharedInstance.availableOverlays[indexPath.row]
        let selected = OverlaysManager.sharedInstance.isOverlaySelected(item)
        OverlaysManager.sharedInstance.selectOverlay(!selected, type: item)
        tableView.reloadRows(at: [indexPath], with: UITableViewRowAnimation.none)
    }
}
