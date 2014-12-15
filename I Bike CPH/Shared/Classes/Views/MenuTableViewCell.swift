//
//  MenuTableViewCell.swift
//  I Bike CPH
//
//  Created by Tobias Due Munk on 08/12/14.
//  Copyright (c) 2014 I Bike CPH. All rights reserved.
//

import UIKit

class IconLabelTableViewCell: UITableViewCell {

    @IBOutlet weak var iconImageView: UIImageView!
    @IBOutlet weak var label: UILabel!
    
    func configure(#text: String, textColor: UIColor = Styler.foregroundColor(), icon: UIImage? = nil) {
        
        label.textColor = textColor
        label.text = text
        
        iconImageView.image = icon?.imageWithRenderingMode(.AlwaysTemplate)
    }
}
