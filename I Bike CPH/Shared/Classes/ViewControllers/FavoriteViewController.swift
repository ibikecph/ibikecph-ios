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
                title = SMTranslation.decodeString("Home")
                iconImage = UIImage(named: "favoriteHome")
            case .Work:
                title = SMTranslation.decodeString("Work")
                iconImage = UIImage(named: "favoriteWork")
            case .School:
                title = SMTranslation.decodeString("School")
                iconImage = UIImage(named: "favoriteSchool")
            case .Unknown:
                title = SMTranslation.decodeString("Favorite")
                iconImage = UIImage(named: "favorites")
        }
    }
}

class FavoriteViewController: UIViewController {

    @IBOutlet weak var saveButton: UIBarButtonItem!
    @IBOutlet weak var addressTextField: UITextField!
    @IBOutlet weak var nameTextField: UITextField!
    
    @IBOutlet weak var tableView: UITableView!
    private let cellID = "FavoriteTypeCellID"
    
    private let searchAddressSegue = "favoriteToSearch"
    
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

        // Do any additional setup after loading the view.
        SMTranslation.translateView(view)
        addressTextField.delegate = self
        nameTextField.delegate = self
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "didChangeNameTextField:", name: UITextFieldTextDidChangeNotification, object: nameTextField)
        
        if favoriteItem == nil {
            creating = true
        }
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return .LightContent
    }

    // MARK: -
    
    func updateViews() {
        if view == nil {
            return
        }
        if let item = favoriteItem {
            let add = item.address
            addressTextField.text = item.address
            nameTextField.text = item.name
            tableView.hidden = false
        } else {
            addressTextField.text = nil
            nameTextField.text = nil
            tableView.hidden = true
        }
        tableView.reloadData()
        
        let hasContent = addressTextField.text != nil && nameTextField.text != nil
        saveButton.enabled = hasContent
    }
    
    func updateItemType(type: FavoriteItemType) {
        let nameMatchesCurrentType = nameTextField.text == FavoriteTypeViewModel(type: type).title
        let noName = nameTextField.text == "" || nameTextField.text == nil
        let updateNameToNewType = nameMatchesCurrentType || noName
        if updateNameToNewType {
            // Only update name if it currently matches it's type (or no current name)
            favoriteItem?.name = FavoriteTypeViewModel(type: type).title
        }
        favoriteItem?.origin = type
        updateViews()
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == searchAddressSegue {
            if let searchViewController = segue.destinationViewController as? SMSearchController {
                searchViewController.shouldAllowCurrentPosition = false
                searchViewController.locationItem = favoriteItem
                searchViewController.delegate = self
            }
        }
    }
    
    // MARK: - Actions
    
    @IBAction func saveButtonTapped(sender: AnyObject) {
        if creating {
            if let item = favoriteItem {
                SMFavoritesUtil.instance().addFavoriteToServer(item)
            } else {
                println("No item to save")
                return
            }
        } else {
            SMFavoritesUtil.instance().editFavorite(favoriteItem)
        }
        dismiss()
    }
}

extension FavoriteViewController: UITableViewDataSource {
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return typeItems.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCellWithIdentifier(cellID, forIndexPath: indexPath) as IconLabelTableViewCell
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

extension FavoriteViewController {
    
    func didChangeNameTextField(notification: NSNotification) {
        favoriteItem?.name = nameTextField.text
    }
}

extension FavoriteViewController: SMSearchDelegate {
    
    func locationFound(locationItem: NSObject!) {
        if let foundItem = locationItem as? SearchListItem {
            if let currentItem = favoriteItem {
                // Update current item
                let currentName = currentItem.name
                let currentOrigin = currentItem.origin
                let newItem = FavoriteItem(other: foundItem)
                newItem.name = currentName
                newItem.origin = currentOrigin
                favoriteItem = newItem
            } else {
                // Create new favorite item
                favoriteItem = FavoriteItem(other: foundItem)
                if let currentName = nameTextField.text {
                    favoriteItem?.name = currentName
                }
            }
        }
    }
}

