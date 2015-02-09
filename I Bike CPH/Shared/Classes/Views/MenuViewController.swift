//
//  MenuViewController.swift
//  I Bike CPH
//
//  Created by Tobias Due Munk on 08/12/14.
//  Copyright (c) 2014 I Bike CPH. All rights reserved.
//

import UIKit

private struct SectionViewModel {
    let title: String? = nil
    let items: [MenuItem]
}

private struct MenuItem {
    let title: String
    let iconImageName: String
    let action: MenuViewController -> ()
}

class MenuViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    
    let cellID = "MenuCellID"

    private lazy var sections: [SectionViewModel] = {
        
        let favItem = MenuItem(title: SMTranslation.decodeString("favorites"), iconImageName: "favorite", action: { menuViewController in
            menuViewController.performSegueWithIdentifier("menuToFavorites", sender: menuViewController)
        })
        let reminderItem = MenuItem(title: SMTranslation.decodeString("reminder_title"), iconImageName: "Notifications", action: { menuViewController in
            menuViewController.performSegueWithIdentifier("menuToReminders", sender: menuViewController)
        })
        let profileItem = MenuItem(title: SMTranslation.decodeString(UserHelper.loggedIn() ? "account" : "profile"), iconImageName: "User", action: { menuViewController in
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
        let overlayItem = MenuItem(title: SMTranslation.decodeString("map_overlays"), iconImageName: "Kortlag", action: { menuViewController in
            menuViewController.performSegueWithIdentifier("menuToOverlays", sender: menuViewController)
        })
        let bikeItem = MenuItem(title: SMTranslation.decodeString("bike_type"), iconImageName: "Route type", action: { menuViewController in
            menuViewController.performSegueWithIdentifier("menuToBike", sender: menuViewController)
        })
        let voiceItem = MenuItem(title: SMTranslation.decodeString("voice"), iconImageName: "Speaker loud", action: { menuViewController in
            menuViewController.performSegueWithIdentifier("menuToVoice", sender: menuViewController)
        })
        let speedItem = MenuItem(title: SMTranslation.decodeString("speedguide"), iconImageName: "fartguide", action: { menuViewController in
            menuViewController.performSegueWithIdentifier("menuToSpeedGuide", sender: menuViewController)
        })
        let trackingItem = MenuItem(title: SMTranslation.decodeString("tracking"), iconImageName: "Tracking", action: { menuViewController in
            menuViewController.performSegueWithIdentifier("menuToTracking", sender: menuViewController)
        })
        let aboutItem = MenuItem(title: SMTranslation.decodeString("about"), iconImageName: "info", action: { menuViewController in
            menuViewController.performSegueWithIdentifier("menuToAbout", sender: menuViewController)
        })
        
        var menuItems = [favItem]
        
        if Macro.isCykelPlanen() {
            menuItems.append(overlayItem)
        }
        menuItems.append(voiceItem)
        if Macro.isIBikeCph() {
            menuItems.append(bikeItem)
        }
//        menuItems.append(speedItem)
//        menuItems.append(trackingItem)
        if Macro.isCykelPlanen() {
            menuItems.append(reminderItem)
        }
        menuItems.append(profileItem)
        menuItems.append(aboutItem)
        
        var firstSection = SectionViewModel(title: nil, items: menuItems)
        return [firstSection]
    }()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

//        self.title = SMTranslation.translateView("menu")
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
        
        let cell = tableView.dequeueReusableCellWithIdentifier(cellID, forIndexPath: indexPath) as IconLabelTableViewCell
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

