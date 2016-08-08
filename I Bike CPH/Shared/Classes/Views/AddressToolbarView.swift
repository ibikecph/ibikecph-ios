//
//  TrackingToolbarView.swift
//  I Bike CPH
//
//  Created by Tobias Due Munk on 04/06/15.
//  Copyright (c) 2015 I Bike CPH. All rights reserved.
//

import UIKit

protocol AddressToolbarDelegate {
    func didSelectFavorites(selected: Bool)
    func didSelectRoute()
}

class AddressToolbarView: ToolbarView {

    var delegate: AddressToolbarDelegate?
    
    @IBOutlet weak var favoriteButton: UIButton!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var addresslabel: UILabel!
    
    var favoriteSelected: Bool = true {
        didSet {
            favoriteButton.tintColor = favoriteSelected ? Styler.tintColor() : Styler.foregroundColor()
            if favoriteSelected != oldValue {
                delegate?.didSelectFavorites(favoriteSelected)
            }
        }
    }
    
    @IBAction func didTapRoute(sender: UIButton) {
        delegate?.didSelectRoute()
    }
    
    @IBAction func didTapFavorite(sender: UIButton) {
        favoriteSelected = !favoriteSelected
    }
}

extension AddressToolbarView {
    
    override func prepareForReuse() {
        super.prepareForReuse()
        nameLabel.text = "\0"
        addresslabel.text = "\0\n\0"
        favoriteSelected = false
    }
    
    func updateToItem(item: SearchListItem) {
        let addressLine1 = item.street + ((item.number.characters.count > 0) ? " \(item.number)" : "")
        let addressLine2 = ((item.zip.characters.count > 0) ? "\(item.zip)" : "") + " \(item.city)"
        let doubleAddressLine = "\(addressLine1)\n\(addressLine2)"
        if let favorite = item as? FavoriteItem {
            favoriteSelected = true
            nameLabel.text = favorite.name
            addresslabel.text = doubleAddressLine
            return
        }
        favoriteSelected = false
        if let foursquare = item as? FoursquareItem {
            nameLabel.text = foursquare.name
            addresslabel.text = doubleAddressLine
            return
        }
        if item.name.rangeOfString(item.address) == nil {
            nameLabel.text = item.name
            addresslabel.text = doubleAddressLine
            return
        }
        nameLabel.text = addressLine1
        addresslabel.text = addressLine2 + "\n"
    }
}
