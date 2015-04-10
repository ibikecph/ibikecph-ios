//
//  ReminderListViewController.swift
//  I Bike CPH
//
//  Created by Tobias Due Munk on 15/12/14.
//  Copyright (c) 2014 I Bike CPH. All rights reserved.
//

import UIKit

class ReminderListViewController: SMTranslatedViewController {

    let cellID = "reminderTableCell"
    
    let weekdays = [
        SMTranslation.decodeString("monday"),
        SMTranslation.decodeString("tuesday"),
        SMTranslation.decodeString("wednesday"),
        SMTranslation.decodeString("thursday"),
        SMTranslation.decodeString("friday")
    ]
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return .LightContent
    }
}

extension ReminderListViewController: UITableViewDataSource {
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return weekdays.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let cell = tableView.cellWithIdentifier(cellID, forIndexPath: indexPath) as SMReminderTableViewCell
        let weekday = weekdays[indexPath.row]
        cell.currentDay = Day(Int32(indexPath.row))
        cell.setupWithTitle(weekday)
        return cell
    }
}
