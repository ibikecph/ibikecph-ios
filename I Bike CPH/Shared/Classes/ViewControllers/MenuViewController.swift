//
//  MenuViewController.swift
//  I Bike CPH
//
//  Created by Tobias Due Munk on 08/12/14.
//  Copyright (c) 2014 I Bike CPH. All rights reserved.
//

import UIKit

private struct MenuItem {
    let title: String
    let iconImageName: String
    let action: (MenuViewController) -> ()
}

class MenuViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    
    let cellID = "MenuCellID"
    
    fileprivate var pendingTracking: Bool = false

    fileprivate lazy var sections: [SectionViewModel<MenuItem>] = {
        
        let favItem = MenuItem(title: "favorites".localized, iconImageName: "Favorite", action: { menuViewController in
            menuViewController.performSegue(withIdentifier: "menuToFavorites", sender: menuViewController)
        })
        let profileItem = MenuItem(title: (UserHelper.loggedIn() ? "account" : "profile").localized, iconImageName: "User", action: { menuViewController in
            if UserHelper.loggedIn() {
                if UserHelper.isFacebook() {
                    menuViewController.performSegue(withIdentifier: "menuToAccountFacebook", sender: menuViewController)
                } else {
                    menuViewController.performSegue(withIdentifier: "menuToAccountNative", sender: menuViewController)
                }
            } else {
                menuViewController.performSegue(withIdentifier: "menuToLogin", sender: menuViewController)
            }
        })
        let overlayItem = MenuItem(title: "map_overlays".localized, iconImageName: "Maps overlay", action: { menuViewController in
            menuViewController.performSegue(withIdentifier: "menuToOverlays", sender: menuViewController)
        })
        let speedItem = MenuItem(title: "speedguide".localized, iconImageName: "Fartguide", action: { menuViewController in
            menuViewController.performSegue(withIdentifier: "menuToSpeedGuide", sender: menuViewController)
        })
        #if TRACKING_ENABLED
            let trackingItem = MenuItem(title: "tracking".localized, iconImageName: "Bikedata", action: { menuViewController in
                let trackingAvailable = trackingHandler.trackingAvailable
                if !trackingAvailable {
                    menuViewController.performSegueWithIdentifier("menuToTrackingNotAvailable", sender: menuViewController)
                    return
                }
                let trackingOn = Settings.sharedInstance.tracking.on
                let hasBikeTracks = BikeStatistics.hasTrackedBikeData()
                let showTrackingView = trackingOn || hasBikeTracks
                if showTrackingView {
                    menuViewController.performSegueWithIdentifier("menuToTracking", sender: menuViewController)
                    return
                }
                menuViewController.performSegueWithIdentifier("menuToTrackingPrompt", sender: menuViewController)
                menuViewController.pendingTracking = true
            })
        #endif
        let aboutItem = MenuItem(title: (macro.isIBikeCph ? "about_app_ibc" : "about_app_cp").localized, iconImageName: "information", action: { menuViewController in
            menuViewController.performSegue(withIdentifier: "menuToAbout", sender: menuViewController)
        })
        
        var menuItems = [favItem]
        
        if OverlaysManager.sharedInstance.availableOverlays.count > 0 {
            menuItems.append(overlayItem)
        }
//        menuItems.append(speedItem)
        #if TRACKING_ENABLED
            menuItems.append(trackingItem)
        #endif
        menuItems.append(profileItem)
        menuItems.append(aboutItem)
        
        var firstSection = SectionViewModel(items: menuItems)
        return [firstSection]
    }()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

//        self.title = SMTranslation.translateView("menu")
        
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if pendingTracking && Settings.sharedInstance.tracking.on {
            performSegue(withIdentifier: "menuToTracking", sender: self)
        }
        pendingTracking = false
    }
    
    override var preferredStatusBarStyle : UIStatusBarStyle {
        return .lightContent
    }
    
    deinit {
        Foundation.NotificationCenter.default.removeObserver(self)
    }
    
    // Mark: - Actions
    
    @IBAction func doneButtonPressed(_ sender: AnyObject) {
        NotificationCenter.post("closeMenu")
    }
}

extension MenuViewController: UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return sections[section].title
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sections[section].items.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.cellWithIdentifier(cellID, forIndexPath: indexPath) as IconLabelTableViewCell
        let item = sections[indexPath.section].items[indexPath.row]
        cell.configure(item.title, icon: UIImage(named: item.iconImageName)?.withRenderingMode(.alwaysTemplate))
        
        return cell
    }
}

extension MenuViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let item = sections[indexPath.section].items[indexPath.row]
        item.action(self)
        tableView .deselectRow(at: indexPath, animated: true)
    }
}

