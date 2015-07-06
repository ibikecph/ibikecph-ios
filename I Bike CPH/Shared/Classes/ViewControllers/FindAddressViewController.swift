//
//  FindAddressViewController.swift
//  I Bike CPH
//
//  Created by Tobias Due Munk on 05/06/15.
//  Copyright (c) 2015 I Bike CPH. All rights reserved.
//

import UIKit


protocol FindAddressViewControllerProtocol {
    
    func foundAddress(item: SearchListItem)
}


class FindAddressViewController: SMTranslatedViewController {

    @IBOutlet weak var currentItemButton: UIButton!
    @IBOutlet weak var tableView: UITableView!
    
    private let maxHistory = 3
    enum Section: Int {
        case History
        case Favorites
        static var count: Int {
            var max = 0
            while let _ = self(rawValue: ++max) {}
            return max
        }
    }
    
    var currentItem: SearchListItem? {
        didSet {
            var title = "search_to_placeholder".localized
            if let item = currentItem {
                title = self.textFromItem(item)
            }
            currentItemButton.setTitle(title, forState: .Normal)
            
            if let item = currentItem {
                // Close view controller
                dismiss()
                // Notify delegate
                delegate?.foundAddress(item)
            }
        }
    }
    var history = [HistoryItem]()
    var favorites = [FavoriteItem]()
    var delegate: FindAddressViewControllerProtocol?
    
    @IBAction func findAddressTapped(sender: AnyObject) {
        performSegueWithIdentifier("searchSegue", sender: self)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Populate favorites
        favorites = SMFavoritesUtil.favorites() as? [FavoriteItem] ?? [FavoriteItem]()

        // Populate history
        let totalHistory = (appDelegate.searchHistory as? [HistoryItem] ?? [HistoryItem]()).filter { item in
            for favorite in self.favorites {
                if favorite.address == item.address {
                    return false
                }
            }
            return true
        }
        let historyCount = min(totalHistory.count, maxHistory)
        history = Array(totalHistory[0..<historyCount])
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if
            segue.identifier == "searchSegue",
            let viewController = segue.destinationViewController as? SMSearchController
        {
            viewController.delegate = self
            viewController.shouldAllowCurrentPosition = false
            if let item = currentItem as? NSObject {
                viewController.locationItem = item
            }
        }
    }
    
    func textFromItem(item: SearchListItem) -> String {
        var text = item.name
        let address = item.address.stringByTrimmingCharactersInSet(.whitespaceAndNewlineCharacterSet())
        if (address != "") && (address != item.name) {
            text += ", " + address
        }
        return text
    }
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return .LightContent
    }
}

extension FindAddressViewController: UITableViewDataSource {
    
    func itemsForSection(section: Int) -> [SearchListItem] {
        let section = Section(rawValue: section)!
        switch section {
            case .History: return history
            case .Favorites: return favorites
        }
    }
    
    func itemForIndexPath(indexPath: NSIndexPath) -> SearchListItem {
        return itemsForSection(indexPath.section)[indexPath.row]
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return Section.count
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let section = Section(rawValue: section)!
        switch section {
            case .History: return history.count
            case .Favorites: return favorites.count
        }
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.cellWithIdentifier("iconLabelTableViewCell", forIndexPath: indexPath) as IconLabelTableViewCell
        let item = itemForIndexPath(indexPath)
        cell.configure(item)
        return cell
    }
    
    func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        let section = Section(rawValue: section)!
        switch section {
            case .History: return history.count == 0 ? "" : "recent_results".localized
            case .Favorites: return favorites.count == 0 ? "" : "favorites".localized
        }
    }
}

extension FindAddressViewController: UITableViewDelegate {
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        currentItem = itemForIndexPath(indexPath)
    }
}

extension FindAddressViewController: SMSearchDelegate {
    
    func locationFound(locationItem: NSObject!) {
        if let item = locationItem as? SearchListItem {
            currentItem = item
            
            let date = NSDate()
            let historyItem = HistoryItem(other: item, startDate: date, endDate: date)
            SMSearchHistory.saveToSearchHistory(historyItem)
            if UserHelper.loggedIn() {
                SMSearchHistory.instance().addSearchToServer(historyItem)
            }
        }
    }
}
