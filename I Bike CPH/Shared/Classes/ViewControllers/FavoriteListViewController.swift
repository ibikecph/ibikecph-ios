//
//  FavoriteListViewController.swift
//  I Bike CPH
//
//  Created by Tobias Due Munk on 11/12/14.
//  Copyright (c) 2014 I Bike CPH. All rights reserved.
//

import UIKit

class FavoriteListViewController: SMTranslatedViewController {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var noProfileLabel: UILabel!
    @IBOutlet weak var addBarButtonItem: UIBarButtonItem!
    @IBOutlet weak var editBarButtonItem: UIBarButtonItem!
    
    fileprivate var items: [FavoriteItem] = [FavoriteItem]() {
        didSet {
            tableView.reloadData()
        }
    }

    fileprivate let cellID = "FavoriteCellID"
    
    fileprivate let editFavoriteSegue = "favoritesToFavorite"
    fileprivate var selectedItem: FavoriteItem?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "favorites".localized
        
        let userIsLoggedIn = UserHelper.loggedIn()
        if userIsLoggedIn {
            items = SMFavoritesUtil.favorites() as! [FavoriteItem] // Get local favorites
            SMFavoritesUtil.instance().delegate = self
            SMFavoritesUtil.instance().fetchFavoritesFromServer() // Fetch favorites from server
        }
        
        tableView.isHidden = !userIsLoggedIn
        noProfileLabel.isHidden = userIsLoggedIn
        addBarButtonItem.isEnabled = userIsLoggedIn
        editBarButtonItem.isEnabled = userIsLoggedIn
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tableView.reloadData()
    }

    @IBOutlet weak var toolbar: UIToolbar!
    
    @IBAction func add(_ sender: AnyObject) {
        selectedItem = nil
        self.performSegue(withIdentifier: editFavoriteSegue, sender: self)
    }
    @IBAction func edit(_ sender: UIBarButtonItem) {
        let edit = !tableView.isEditing
        tableView.setEditing(edit, animated: true)
        let systemItem: UIBarButtonSystemItem = edit ? .done : .edit
        let newButton = UIBarButtonItem(barButtonSystemItem: systemItem, target: self, action: #selector(FavoriteListViewController.edit(_:)))
        toolbar.setItems([newButton], animated: true)
    }
    
    override var preferredStatusBarStyle : UIStatusBarStyle {
        return .lightContent
    }
    
    // MARK: - Navigation
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if
            segue.identifier == editFavoriteSegue,
            let favoriteViewController = segue.destination as? FavoriteViewController
        {
            favoriteViewController.favoriteItem = selectedItem ?? nil
        }
    }
}

extension FavoriteListViewController: SMFavoritesDelegate {
    
    func favoritesOperation(_ req: AnyObject!, failedWithError error: NSError!) {
    }
    
    func favoritesOperationFinishedSuccessfully(_ req: Any!, withData data: Any!) {
        items = SMFavoritesUtil.favorites() as! [FavoriteItem] // Update favorites
    }
}

extension FavoriteListViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.cellWithIdentifier(cellID, forIndexPath: indexPath) as IconLabelTableViewCell
        let item = items[indexPath.row]
        cell.configure(item)
        return cell
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        let sourceIndex = sourceIndexPath.row
        let destinationIndex = destinationIndexPath.row
        let source = items[sourceIndex]
        items.remove(at: sourceIndex)
        items.insert(source, at: destinationIndex)
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            tableView.beginUpdates()
            let item = items.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .automatic)
            tableView.endUpdates()
            SMFavoritesUtil.instance().deleteFavorite(fromServer: item)
        }
    }
}

extension FavoriteListViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView .deselectRow(at: indexPath, animated: true)
        
        let item = items[indexPath.row]
        selectedItem = item
        self.performSegue(withIdentifier: editFavoriteSegue, sender: self)
    }
    
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCellEditingStyle {
        return .delete
    }
}


