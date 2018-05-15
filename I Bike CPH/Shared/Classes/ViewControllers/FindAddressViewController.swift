//
//  FindAddressViewController.swift
//  I Bike CPH
//
//  Created by Tobias Due Munk on 05/06/15.
//  Copyright (c) 2015 I Bike CPH. All rights reserved.
//

import UIKit
import Async

protocol FindAddressViewControllerProtocol {
    
    func foundAddress(_ item: SearchListItem)
}


class FindAddressViewController: SMTranslatedViewController {

    @IBOutlet weak var currentItemButton: UIButton!
    @IBOutlet weak var tableView: UITableView!
    
    fileprivate let maxHistory = 3
    enum Section: Int {
        case history
        case favorites
        static var count: Int {
            var max = 1
            while let _ = self.init(rawValue: max) {
                max += 1
            }
            return max
        }
    }
    
    var currentItem: SearchListItem? {
        didSet {
            var title = "search_to_placeholder".localized
            if let item = currentItem {
                title = self.textFromItem(item)
            }
            currentItemButton.setTitle(title, for: UIControlState())
            
            if let item = currentItem {
                // Close view controller
                Async.main { self.dismiss() }
                // Notify delegate
                delegate?.foundAddress(item)
            }
        }
    }
    var history = [HistoryItem]()
    var favorites = [FavoriteItem]()
    var delegate: FindAddressViewControllerProtocol?
    
    @IBAction func findAddressTapped(_ sender: AnyObject) {
        performSegue(withIdentifier: "searchSegue", sender: self)
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
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if
            segue.identifier == "searchSegue",
            let viewController = segue.destination as? SMSearchController
        {
            viewController.delegate = self
            viewController.shouldAllowCurrentPosition = false
            if let item = currentItem as? SearchListItem & NSObjectProtocol {
                viewController.locationItem = item
            }
        }
    }
    
    func textFromItem(_ item: SearchListItem) -> String {
        var text = item.name
        let address = item.address.trimmingCharacters(in: .whitespacesAndNewlines)
        if (address != "") && (address != item.name) {
            text += ", " + address
        }
        return text
    }
    
    override var preferredStatusBarStyle : UIStatusBarStyle {
        return .lightContent
    }
}

extension FindAddressViewController: UITableViewDataSource {
    
    func itemsForSection(_ section: Int) -> [SearchListItem] {
        let section = Section(rawValue: section)!
        switch section {
            case .history: return history
            case .favorites: return favorites
        }
    }
    
    func itemForIndexPath(_ indexPath: IndexPath) -> SearchListItem {
        return itemsForSection(indexPath.section)[indexPath.row]
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return Section.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let section = Section(rawValue: section)!
        switch section {
            case .history: return history.count
            case .favorites: return favorites.count
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.cellWithIdentifier("iconLabelTableViewCell", forIndexPath: indexPath) as IconLabelTableViewCell
        let item = itemForIndexPath(indexPath)
        cell.configure(item)
        return cell
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        let section = Section(rawValue: section)!
        switch section {
            case .history: return history.count == 0 ? "" : "recent_results".localized
            case .favorites: return favorites.count == 0 ? "" : "favorites".localized
        }
    }
}

extension FindAddressViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        currentItem = itemForIndexPath(indexPath)
    }
}

extension FindAddressViewController: SMSearchDelegate {
    
    func locationFound(_ locationItem: (SearchListItem & NSObjectProtocol)!) {
        currentItem = locationItem
        
        let date = Date()
        let historyItem = HistoryItem(other: locationItem, startDate: date, endDate: date)
        SMSearchHistory.save(toSearchHistory: historyItem)
        if UserHelper.loggedIn() {
            SMSearchHistory.instance().addSearch(toServer: historyItem)
        }
    }
}
