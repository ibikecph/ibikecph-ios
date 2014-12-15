//
//  MenuViewController.swift
//  I Bike CPH
//
//  Created by Tobias Due Munk on 08/12/14.
//  Copyright (c) 2014 I Bike CPH. All rights reserved.
//

import UIKit


struct MenuItem {
    let title: String
    let iconImageName: String
    let action: MenuViewController -> ()
}

class MenuViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    
    let loggedIn = false // TODO 
    
    let cellID = "MenuCellID"

    let items = [
        MenuItem(title: SMTranslation.decodeString("favorites"), iconImageName: "favorite", action: { menuViewController in
            menuViewController.performSegueWithIdentifier("menuToFavorites", sender: menuViewController)
        }),
        MenuItem(title: SMTranslation.decodeString("reminder_title"), iconImageName: "reminders", action: { menuViewController in
            menuViewController.performSegueWithIdentifier("menuToReminders", sender: menuViewController)
        }),
        // TODO: Change title depending on logged in status
        MenuItem(title: SMTranslation.decodeString(true ? "account" : "account_login"), iconImageName: "profile", action: { menuViewController in
            if menuViewController.loggedIn {
                menuViewController.performSegueWithIdentifier("menuToAccount", sender: menuViewController)
            } else {
                menuViewController.performSegueWithIdentifier("menuToLogin", sender: menuViewController)
            }
        }),
        MenuItem(title: SMTranslation.decodeString("about"), iconImageName: "info", action: { menuViewController in
            menuViewController.performSegueWithIdentifier("menuToAbout", sender: menuViewController)
        })]
    
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
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCellWithIdentifier(cellID, forIndexPath: indexPath) as IconLabelTableViewCell
        let item = items[indexPath.row]
        cell.configure(text: item.title, icon: UIImage(named: item.iconImageName))
        
        return cell
    }
}

extension MenuViewController: UITableViewDelegate {
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let item = items[indexPath.row]
        item.action(self)
        tableView .deselectRowAtIndexPath(indexPath, animated: true)
    }
}

