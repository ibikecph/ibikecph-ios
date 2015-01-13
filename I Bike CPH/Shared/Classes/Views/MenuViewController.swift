//
//  MenuViewController.swift
//  I Bike CPH
//
//  Created by Tobias Due Munk on 08/12/14.
//  Copyright (c) 2014 I Bike CPH. All rights reserved.
//

import UIKit


struct SectionViewModel {
    let title: String? = nil
    let items: [MenuItem]
}

struct MenuItem {
    let title: String
    let iconImageName: String
    let action: MenuViewController -> ()
}

class MenuViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    
    let cellID = "MenuCellID"

    let sections = [
        SectionViewModel(title: nil, items:
            [
                MenuItem(title: SMTranslation.decodeString("favorites"), iconImageName: "favorite", action: { menuViewController in
                    menuViewController.performSegueWithIdentifier("menuToFavorites", sender: menuViewController)
                }),
                MenuItem(title: SMTranslation.decodeString("reminder_title"), iconImageName: "reminders", action: { menuViewController in
                    menuViewController.performSegueWithIdentifier("menuToReminders", sender: menuViewController)
                }),
                MenuItem(title: SMTranslation.decodeString(UserHelper.loggedIn() ? "account" : "account_login"), iconImageName: "profile", action: { menuViewController in
                    if UserHelper.loggedIn() {
                        if UserHelper.isFacebook() {
                            menuViewController.performSegueWithIdentifier("menuToAccountFacebook", sender: menuViewController)
                        } else {
                            menuViewController.performSegueWithIdentifier("menuToAccountNative", sender: menuViewController)
                        }
                    } else {
                        menuViewController.performSegueWithIdentifier("menuToLogin", sender: menuViewController)
                    }
                }),
                MenuItem(title: SMTranslation.decodeString("about"), iconImageName: "info", action: { menuViewController in
                    menuViewController.performSegueWithIdentifier("menuToAbout", sender: menuViewController)
                })
            ]
        ),
        SectionViewModel(title: SMTranslation.decodeString("preferences"), items:
            [
                MenuItem(title: SMTranslation.decodeString("map_overlays"), iconImageName: "", action: { menuViewController in
                    menuViewController.performSegueWithIdentifier("menuToOverlays", sender: menuViewController)
                }),
                MenuItem(title: SMTranslation.decodeString("bike"), iconImageName: "bike", action: { menuViewController in
                    menuViewController.performSegueWithIdentifier("menuToBike", sender: menuViewController)
                }),
                MenuItem(title: SMTranslation.decodeString("voice"), iconImageName: "", action: { menuViewController in
                    menuViewController.performSegueWithIdentifier("menuToVoice", sender: menuViewController)
                }),
                MenuItem(title: SMTranslation.decodeString("speedguide"), iconImageName: "", action: { menuViewController in
                    menuViewController.performSegueWithIdentifier("menuToSpeedGuide", sender: menuViewController)
                }),
                MenuItem(title: SMTranslation.decodeString("tracking"), iconImageName: "", action: { menuViewController in
                    menuViewController.performSegueWithIdentifier("menuToTracking", sender: menuViewController)
                })
            ]
        )
    ]
        
    
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

