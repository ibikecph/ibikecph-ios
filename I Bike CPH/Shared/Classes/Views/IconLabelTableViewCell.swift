//
//  IconLabelTableViewCell.swift
//  I Bike CPH
//
//  Created by Tobias Due Munk on 08/12/14.
//  Copyright (c) 2014 I Bike CPH. All rights reserved.
//

import UIKit
import NibDesignable

class IconLabelTableViewCell: NibDesignableTableViewCell {

    @IBOutlet weak var iconImageView: UIImageView!
    @IBOutlet weak var label: UILabel!
    
    func configure(#text: String, textColor: UIColor = Styler.foregroundColor(), icon: UIImage? = nil) {
        
        label.textColor = textColor
        label.text = text
        
        iconImageView.image = icon?.imageWithRenderingMode(.AlwaysTemplate)
    }
    
    func configure(item: SearchListItem) {
        var imageName = ""
        if let favorite = item as? FavoriteItem {
            imageName = {
                switch favorite.origin {
                    case .Home: return "favoriteHome"
                    case .School: return "favoriteSchool"
                    case .Work: return "favoriteWork"
                    case .Unknown: return "Favorite"
                }
            }()
        } else if let item = item as? HistoryItem {
            imageName = "findHistory"
        }
        let icon = UIImage(named: imageName)
        configure(text: item.name, icon: icon)
    }
}
