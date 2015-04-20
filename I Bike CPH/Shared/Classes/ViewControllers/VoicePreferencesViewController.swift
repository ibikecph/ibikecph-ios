//
//  VoicePreferencesViewController.swift
//  I Bike CPH
//
//  Created by Tobias Due Munk on 26/01/15.
//  Copyright (c) 2015 I Bike CPH. All rights reserved.
//

import UIKit

private protocol VoiceItemProtocol {
    var title: String { get }
    var iconImageName: String { get }
}

private struct VoiceItem : VoiceItemProtocol {
    let title: String
    let iconImageName: String
    let action: VoicePreferencesViewController -> ()
}

private struct VoiceSwitchItem: VoiceItemProtocol {
    let title: String
    let iconImageName: String
    let on: Bool
    let switchAction: (VoicePreferencesViewController, Bool) -> ()
}

class VoicePreferencesViewController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    
    let cellID = "VoiceCellID"
    let cellSwitchID = "VoiceSwitchCellID"
    
    private let sections: [SectionViewModel<VoiceItemProtocol>] = [
        SectionViewModel(title: nil, footer: "voice_option_detail".localized, items:
            [
                VoiceSwitchItem(title: "voice_option".localized, iconImageName: "speaker", on: settings.voice.on, switchAction: { voiceViewController, on in
                        settings.voice.on = on
                }),
            ]
        ),
    ]
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = "voice".localized
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

extension VoicePreferencesViewController: UITableViewDataSource {
    
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
        
        if let item = item as? VoiceSwitchItem {
            tableView.cellWithIdentifier(reuseIdentifier: cellSwitchID)
            let cell = tableView.dequeueReusableCellWithIdentifier(cellSwitchID, forIndexPath: indexPath) as! IconLabelSwitchTableViewCell
            cell.configure(text: item.title, icon: UIImage(named: item.iconImageName))
            cell.switcher.on = item.on
            cell.switchChanged = { on in item.switchAction(self, on) }
            return cell
        }
        let cell = tableView.dequeueReusableCellWithIdentifier(cellID, forIndexPath: indexPath) as! IconLabelTableViewCell
        cell.configure(text: item.title, icon: UIImage(named: item.iconImageName))
        return cell
    }
}

extension VoicePreferencesViewController: UITableViewDelegate {
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if let item = sections[indexPath.section].items[indexPath.row] as? VoiceItem {
            item.action(self)
        }
        tableView .deselectRowAtIndexPath(indexPath, animated: true)
    }
}


