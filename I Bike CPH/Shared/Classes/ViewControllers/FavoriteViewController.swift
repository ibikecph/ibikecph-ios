//
//  FavoriteViewController.swift
//  I Bike CPH
//
//  Created by Tobias Due Munk on 11/12/14.
//  Copyright (c) 2014 I Bike CPH. All rights reserved.
//

import UIKit

struct FavoriteTypeViewModel {
    let title: String
    let iconImage: UIImage?
    let type: FavoriteItemType
    
    init(type: FavoriteItemType) {
        self.type = type
        switch type {
            case .Home:
                title = "Home".localized
                iconImage = UIImage(named: "favoriteHome")
            case .Work:
                title = "Work".localized
                iconImage = UIImage(named: "favoriteWork")
            case .School:
                title = "School".localized
                iconImage = UIImage(named: "favoriteSchool")
            case .Unknown:
                title = "Favorite".localized
                iconImage = UIImage(named: "Favorite")
        }
    }
}

class FavoriteViewController: SMTranslatedViewController {

    @IBOutlet weak var addressTextField: UITextField!
    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var nameLabel: UILabel!
    
    @IBOutlet weak var tableView: UITableView!
    private let cellID = "FavoriteTypeCellID"
    
    private let searchAddressSegue = "favoriteToSearch"
    
    private var observerTokens = [AnyObject]()
    
    var favoriteItem: FavoriteItem? {
        didSet {
            updateViews()
        }
    }
    private var creating: Bool = false
    
    let typeItems = [
        FavoriteTypeViewModel(type: .Home),
        FavoriteTypeViewModel(type: .Work),
        FavoriteTypeViewModel(type: .School),
        FavoriteTypeViewModel(type: .Unknown)]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Delegates
        addressTextField.delegate = self
        nameTextField.delegate = self
        
        // Observers
        observerTokens.append(NotificationCenter.observe(UITextFieldTextDidChangeNotification) { [weak self] notification in
            if let name = self?.nameTextField.text {
                self?.favoriteItem?.name = name
            }
        })
        observerTokens.append(NotificationCenter.observe("favoritesChanged") { [weak self] notification in
            // Find favorite that matches current and update accordingly
            if let favorites = SMFavoritesUtil.favorites() as? [FavoriteItem] {
                if let updatedFavorite = favorites.filter({ return $0.name == self?.favoriteItem?.name }).first {
                    self?.favoriteItem = updatedFavorite
                }
            }
        })
        
        if favoriteItem == nil {
            creating = true
        }
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        save()
    }
    
    deinit {
        unobserve()
    }
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return .LightContent
    }

    // MARK: -
    
    private func unobserve() {
        for observerToken in observerTokens {
            NotificationCenter.unobserve(observerToken)
        }
        NotificationCenter.unobserve(self)
    }
    
    func updateViews() {
        if view == nil {
            return
        }
        if let item = favoriteItem {
            let add = item.address
            addressTextField.text = item.address
            nameTextField.text = item.name
            nameLabel.hidden = false
            nameTextField.hidden = false
            tableView.hidden = false
        } else {
            addressTextField.text = nil
            nameTextField.text = nil
            nameLabel.hidden = true
            nameTextField.hidden = true
            tableView.hidden = true
        }
        tableView.reloadData()
    }
    
    func updateItemType(type: FavoriteItemType) {
        let currentType = favoriteItem?.origin
        let nameMatchesCurrentType = currentType == nil ? false : nameTextField.text == FavoriteTypeViewModel(type: currentType!).title
        let noName = nameTextField.text == "" || nameTextField.text == nil
        let addressName = nameTextField.text == addressTextField.text
        let updateNameToNewType = nameMatchesCurrentType || noName || addressName
        if updateNameToNewType {
            // Only update name if it currently matches it's type, or no current name, or name is just the address
            favoriteItem?.name = FavoriteTypeViewModel(type: type).title
        }
        favoriteItem?.origin = type
        updateViews()
        save()
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if
            segue.identifier == searchAddressSegue,
            let searchViewController = segue.destinationViewController as? SMSearchController
        {
            searchViewController.shouldAllowCurrentPosition = false
            searchViewController.locationItem = favoriteItem
            searchViewController.delegate = self
        }
    }
    
    func save() {
        let hasContent = addressTextField.text != nil && nameTextField.text != nil
        if !hasContent {
            println("No content to save")
            return
        }
        if creating {
            if let item = favoriteItem {
                SMFavoritesUtil.instance().addFavoriteToServer(item)
                creating = false
            } else {
                println("No item to save")
                return
            }
        } else {
            SMFavoritesUtil.instance().editFavorite(favoriteItem)
        }
    }
    
    @IBAction func newRouteButtonTapped(sender: AnyObject) {
        if let item = favoriteItem {
            NotificationCenter.post("closeMenu")
            NotificationCenter.post(routeToItemNotificationKey, userInfo: [routeToItemNotificationItemKey : item])
        }
    }
}

extension FavoriteViewController: UITableViewDataSource {
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return typeItems.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.cellWithIdentifier(cellID, forIndexPath: indexPath) as IconLabelTableViewCell
        let typeItem = typeItems[indexPath.row]
        
        cell.configure(text: typeItem.title, icon: typeItem.iconImage)
        cell.accessoryType = favoriteItem?.origin == typeItem.type ? .Checkmark : .None

        return cell
    }
}

extension FavoriteViewController: UITableViewDelegate {
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView .deselectRowAtIndexPath(indexPath, animated: true)
        
        let typeItem = typeItems[indexPath.row]
        updateItemType(typeItem.type)
    }
}

extension FavoriteViewController: UITextFieldDelegate {
    
    func textFieldDidBeginEditing(textField: UITextField) {
        if textField == addressTextField {
            self.performSegueWithIdentifier(searchAddressSegue, sender: self)
        }
    }
    
    func textFieldDidEndEditing(textField: UITextField) {
        if textField == nameTextField {
            favoriteItem?.name = nameTextField.text
            save()
        }
        updateViews()
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        if textField == nameTextField {
            textField.resignFirstResponder()
            return false
        }
        return true
    }
}


extension FavoriteViewController: SMSearchDelegate {
    
    func locationFound(locationItem: NSObject!) {
        if let foundItem = locationItem as? SearchListItem {
            if let currentItem = favoriteItem {
                // Update current item
                let newItem = FavoriteItem(other: foundItem)
                newItem.name = currentItem.name
                newItem.origin = currentItem.origin
                newItem.identifier = currentItem.identifier
                favoriteItem = newItem
                save()
            } else {
                // Create new favorite item
                favoriteItem = FavoriteItem(other: foundItem)
                if let currentName = nameTextField.text {
                    favoriteItem?.name = currentName
                }
                save()
            }
        }
    }
}

