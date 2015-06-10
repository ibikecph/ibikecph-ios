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
            favoriteButton.tintColor = favoriteSelected ? tintColor : Styler.foregroundColor()
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
    
    func prepareForReuse() {
        nameLabel.text = "\0"
        addresslabel.text = "\0\n\0"
        favoriteSelected = false
    }
    
    func updateToItem(item: SearchListItem) {
        let addressLine1 = item.street + " " + item.number
        let addressLine2 = item.zip + " " + item.city
        if let favorite = item as? FavoriteItem {
            favoriteSelected = true
            nameLabel.text = favorite.name
            addresslabel.text = "\(addressLine1)\n\(addressLine2)"
            return
        }
        favoriteSelected = false
        nameLabel.text = addressLine1
        addresslabel.text = addressLine2 + "\n"
    }
}
