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
    
    private var items: [FavoriteItem] = [FavoriteItem]() {
        didSet {
            tableView.reloadData()
        }
    }

    private let cellID = "FavoriteCellID"
    
    private let editFavoriteSegue = "favoritesToFavorite"
    private var selectedItem: FavoriteItem?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let userIsLoggedIn = UserHelper.loggedIn()
        if userIsLoggedIn {
            items = SMFavoritesUtil.favorites() as! [FavoriteItem] // Get local favorites
            SMFavoritesUtil.instance().delegate = self
            SMFavoritesUtil.instance().fetchFavoritesFromServer() // Fetch favorites from server
        }
        
        tableView.hidden = !userIsLoggedIn
        noProfileLabel.hidden = userIsLoggedIn
        addBarButtonItem.enabled = userIsLoggedIn
        editBarButtonItem.enabled = userIsLoggedIn
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBOutlet weak var toolbar: UIToolbar!
    
    @IBAction func add(sender: AnyObject) {
        selectedItem = nil
        self.performSegueWithIdentifier(editFavoriteSegue, sender: self)
    }
    @IBAction func edit(sender: UIBarButtonItem) {
        let edit = !tableView.editing
        tableView.setEditing(edit, animated: true)
        let systemItem: UIBarButtonSystemItem = edit ? .Done : .Edit
        let newButton = UIBarButtonItem(barButtonSystemItem: systemItem, target: self, action: "edit:")
        toolbar.setItems([newButton], animated: true)
    }
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return .LightContent
    }
    
    // MARK: - Navigation
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if
            segue.identifier == editFavoriteSegue,
            let favoriteViewController = segue.destinationViewController as? FavoriteViewController
        {
            favoriteViewController.favoriteItem = selectedItem ?? nil
        }
    }
}

extension FavoriteListViewController: SMFavoritesDelegate {
    
    func favoritesOperation(req: AnyObject!, failedWithError error: NSError!) {
        // TODO:
    }
    
    func favoritesOperationFinishedSuccessfully(req: AnyObject!, withData data: AnyObject!) {
        // TODO: Update favorites
        items = SMFavoritesUtil.favorites() as! [FavoriteItem] // Update favorites
    }
}

extension FavoriteListViewController: UITableViewDataSource {
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let cell = tableView.cellWithIdentifier(cellID, forIndexPath: indexPath) as IconLabelTableViewCell
        let item = items[indexPath.row]
        let imageName: String = {
            switch item.origin {
                case .Home: return "favoriteHome"
                case .School: return "favoriteSchool"
                case .Work: return "favoriteWork"
                case .Unknown: return "favorites"
            }
        }()
        let icon = UIImage(named: imageName)
        cell.configure(text: item.name, icon: icon)
        return cell
    }
    
    func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
    
    func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
    
    func tableView(tableView: UITableView, moveRowAtIndexPath sourceIndexPath: NSIndexPath, toIndexPath destinationIndexPath: NSIndexPath) {
        let sourceIndex = sourceIndexPath.row
        let destinationIndex = destinationIndexPath.row
        let source = items[sourceIndex]
        items.removeAtIndex(sourceIndex)
        items.insert(source, atIndex: destinationIndex)
    }
    
    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            let item = items.removeAtIndex(indexPath.row)
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
            SMFavoritesUtil.instance().deleteFavoriteFromServer(item)
        }
    }
}

extension FavoriteListViewController: UITableViewDelegate {
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView .deselectRowAtIndexPath(indexPath, animated: true)
        
        let item = items[indexPath.row]
        selectedItem = item
        self.performSegueWithIdentifier(editFavoriteSegue, sender: self)
    }
    
    func tableView(tableView: UITableView, editingStyleForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCellEditingStyle {
        return .Delete
    }
}


