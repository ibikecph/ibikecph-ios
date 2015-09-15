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
    let action: MenuViewController -> ()
}

class MenuViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    
    let cellID = "MenuCellID"
    
    private var pendingTracking: Bool = false

    private lazy var sections: [SectionViewModel<MenuItem>] = {
        
        let favItem = MenuItem(title: "favorites".localized, iconImageName: "Favorite", action: { menuViewController in
            menuViewController.performSegueWithIdentifier("menuToFavorites", sender: menuViewController)
        })
        let profileItem = MenuItem(title: (UserHelper.loggedIn() ? "account" : "profile").localized, iconImageName: "user", action: { menuViewController in
            if UserHelper.loggedIn() {
                if UserHelper.isFacebook() {
                    menuViewController.performSegueWithIdentifier("menuToAccountFacebook", sender: menuViewController)
                } else {
                    menuViewController.performSegueWithIdentifier("menuToAccountNative", sender: menuViewController)
                }
            } else {
                menuViewController.performSegueWithIdentifier("menuToLogin", sender: menuViewController)
            }
        })
        let overlayItem = MenuItem(title: "map_overlays".localized, iconImageName: "Maps overlay", action: { menuViewController in
            menuViewController.performSegueWithIdentifier("menuToOverlays", sender: menuViewController)
        })
        let voiceItem = MenuItem(title: "voice".localized, iconImageName: "Speaker", action: { menuViewController in
            menuViewController.performSegueWithIdentifier("menuToVoice", sender: menuViewController)
        })
        let speedItem = MenuItem(title: "speedguide".localized, iconImageName: "Fartguide", action: { menuViewController in
            menuViewController.performSegueWithIdentifier("menuToSpeedGuide", sender: menuViewController)
        })
        let trackingItem = MenuItem(title: "tracking".localized, iconImageName: "Bikedata", action: { menuViewController in
            let trackingAvailable = trackingHandler.trackingAvailable
            if !trackingAvailable {
                menuViewController.performSegueWithIdentifier("menuToTrackingNotAvailable", sender: menuViewController)
                return
            }
            let trackingOn = Settings.instance.tracking.on
            let hasBikeTracks = BikeStatistics.hasTrackedBikeData()
            let showTrackingView = trackingOn || hasBikeTracks
            if showTrackingView {
                menuViewController.performSegueWithIdentifier("menuToTracking", sender: menuViewController)
                return
            }
            menuViewController.performSegueWithIdentifier("menuToTrackingPrompt", sender: menuViewController)
            menuViewController.pendingTracking = true
            
        })
        let aboutItem = MenuItem(title: (macro.isIBikeCph ? "about_app_ibc" : "about_app_cp").localized, iconImageName: "information", action: { menuViewController in
            menuViewController.performSegueWithIdentifier("menuToAbout", sender: menuViewController)
        })
        
        //
        var menuItems = [favItem]
        
        if macro.isCykelPlanen {
            menuItems.append(overlayItem)
        }
//        menuItems.append(voiceItem)
        if macro.isIBikeCph {
        }
//        menuItems.append(speedItem)
        menuItems.append(trackingItem)
        menuItems.append(profileItem)
        menuItems.append(aboutItem)
        
        var firstSection = SectionViewModel(items: menuItems)
        return [firstSection]
    }()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

//        self.title = SMTranslation.translateView("menu")
        
        
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        if pendingTracking && Settings.instance.tracking.on {
            performSegueWithIdentifier("menuToTracking", sender: self)
        }
        pendingTracking = false
    }
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return .LightContent
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    // Mark: - Actions
    
    @IBAction func doneButtonPressed(sender: AnyObject) {
        NotificationCenter.post("closeMenu")
    }
}

extension MenuViewController: UITableViewDataSource {
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return sections.count
    }
    
    func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return sections[section].title
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sections[section].items.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let cell = tableView.cellWithIdentifier(cellID, forIndexPath: indexPath) as IconLabelTableViewCell
        let item = sections[indexPath.section].items[indexPath.row]
        cell.configure(text: item.title, icon: UIImage(named: item.iconImageName))
        
        return cell
    }
}

extension MenuViewController: UITableViewDelegate {
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let item = sections[indexPath.section].items[indexPath.row]
        item.action(self)
        tableView .deselectRowAtIndexPath(indexPath, animated: true)
    }
}

