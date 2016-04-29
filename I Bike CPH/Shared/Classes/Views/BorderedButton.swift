//
//  BorderedButton.swift
//  I Bike CPH
//
//  Created by Tobias Due Munk on 12/06/15.
//  Copyright (c) 2015 I Bike CPH. All rights reserved.
//

import UIKit

class BorderedButton: UIButton {

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    func setup() {
        layer.borderColor = UIColor.lightGrayColor().CGColor
        layer.borderWidth = 1 / UIScreen.mainScreen().scale
        layer.cornerRadius = 4
    }
}
