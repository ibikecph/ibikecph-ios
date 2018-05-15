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
    var enabled: Bool = true {
        didSet {
            label.isEnabled = enabled
            iconImageView.tintAdjustmentMode = enabled ? .normal : .dimmed
        }
    }
    
    func configure(_ text: String, textColor: UIColor = Styler.foregroundColor(), icon: UIImage? = nil) {
        
        label.textColor = textColor
        label.text = text.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        
        iconImageView.image = icon
    }
    
    func configure(_ item: SearchListItem) {
        var icon: UIImage?
        if let favorite = item as? FavoriteItem {
            icon = FavoriteTypeViewModel(type: favorite.origin).iconImage
        } else if item is HistoryItem {
            icon = UIImage(named: "findHistory")
        }
        configure(item.name, icon: icon)
    }
}
