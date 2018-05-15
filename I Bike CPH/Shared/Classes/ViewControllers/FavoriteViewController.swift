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
            case .home:
                title = "Home".localized
                iconImage = UIImage(named: "favoriteHome")
            case .work:
                title = "Work".localized
                iconImage = UIImage(named: "favoriteWork")
            case .school:
                title = "School".localized
                iconImage = UIImage(named: "favoriteSchool")
            case .unknown:
                title = "Favorite".localized
                iconImage = UIImage(named: "Favorite")
        }
    }
}

class FavoriteViewController: SMTranslatedViewController {

    @IBOutlet weak var addressTextField: UITextField!
    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var routeBarButton: UIBarButtonItem!

    @IBOutlet weak var tableView: UITableView!
    fileprivate let cellID = "FavoriteTypeCellID"

    fileprivate let searchAddressSegue = "favoriteToSearch"
    
    fileprivate var observerTokens = [AnyObject]()
    
    var favoriteItem: FavoriteItem? {
        didSet {
            updateViews()
        }
    }
    fileprivate var creating: Bool = false
    
    let typeItems = [
        FavoriteTypeViewModel(type: .home),
        FavoriteTypeViewModel(type: .work),
        FavoriteTypeViewModel(type: .school),
        FavoriteTypeViewModel(type: .unknown)]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Delegates
        addressTextField.delegate = self
        nameTextField.delegate = self
        
        // Observers
        observerTokens.append(NotificationCenter.observe("UITextFieldTextDidChange") { [weak self] notification in
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
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        save()
    }
    
    deinit {
        unobserve()
    }
    
    override var preferredStatusBarStyle : UIStatusBarStyle {
        return .lightContent
    }

    // MARK: -
    
    fileprivate func unobserve() {
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
            addressTextField.text = item.address
            nameTextField.text = item.name
            nameLabel.isHidden = false
            nameTextField.isHidden = false
            tableView.isHidden = false
            routeBarButton.isEnabled = true
        } else {
            addressTextField.text = nil
            nameTextField.text = nil
            nameLabel.isHidden = true
            nameTextField.isHidden = true
            tableView.isHidden = true
            routeBarButton.isEnabled = false
        }
        tableView.reloadData()
    }
    
    func updateItemType(_ type: FavoriteItemType) {
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
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if
            segue.identifier == searchAddressSegue,
            let searchViewController = segue.destination as? SMSearchController
        {
            searchViewController.shouldAllowCurrentPosition = false
            searchViewController.locationItem = favoriteItem
            searchViewController.delegate = self
        }
    }
    
    func save() {
        let hasContent = addressTextField.text != nil && nameTextField.text != nil
        if !hasContent {
            print("No content to save")
            return
        }
        if creating {
            if let item = favoriteItem {
                SMFavoritesUtil.instance().addFavorite(toServer: item)
                creating = false
            } else {
                print("No item to save")
                return
            }
        } else {
            SMFavoritesUtil.instance().editFavorite(favoriteItem)
        }
    }
    
    @IBAction func newRouteButtonTapped(_ sender: AnyObject) {
        if let item = favoriteItem {
            NotificationCenter.post("closeMenu")
            NotificationCenter.post(routeToItemNotificationKey, userInfo: [routeToItemNotificationItemKey : item])
        }
    }
}

extension FavoriteViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return typeItems.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.cellWithIdentifier(cellID, forIndexPath: indexPath) as IconLabelTableViewCell
        let typeItem = typeItems[indexPath.row]
        
        cell.configure(typeItem.title, icon: typeItem.iconImage)
        cell.accessoryType = favoriteItem?.origin == typeItem.type ? .checkmark : .none

        return cell
    }
}

extension FavoriteViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView .deselectRow(at: indexPath, animated: true)
        
        let typeItem = typeItems[indexPath.row]
        updateItemType(typeItem.type)
    }
}

extension FavoriteViewController: UITextFieldDelegate {
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        if textField == addressTextField {
            self.performSegue(withIdentifier: searchAddressSegue, sender: self)
        }
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        if textField == nameTextField {
            favoriteItem?.name = nameTextField.text ?? ""
            save()
        }
        updateViews()
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == nameTextField {
            textField.resignFirstResponder()
            return false
        }
        return true
    }
}


extension FavoriteViewController: SMSearchDelegate {
    
    func locationFound(_ locationItem: (SearchListItem & NSObjectProtocol)!) {
        if let currentItem = favoriteItem {
            // Update current item
            let newItem = FavoriteItem(other: locationItem)
            newItem.name = currentItem.name
            newItem.origin = currentItem.origin
            newItem.identifier = currentItem.identifier
            favoriteItem = newItem
            save()
        } else {
            // Create new favorite item
            favoriteItem = FavoriteItem(other: locationItem)
            if let currentName = nameTextField.text {
                favoriteItem?.name = currentName
            }
            save()
        }
    }
}

