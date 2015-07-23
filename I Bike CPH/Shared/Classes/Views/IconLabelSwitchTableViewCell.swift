//
//  IconLabelSwitchTableViewCell.swift
//  I Bike CPH
//
//  Created by Tobias Due Munk on 26/01/15.
//  Copyright (c) 2015 I Bike CPH. All rights reserved.
//

import UIKit

class IconLabelSwitchTableViewCell: IconLabelTableViewCell {

    @IBOutlet weak var switcher: UISwitch!
    
    override var enabled: Bool {
        didSet {
            switcher.enabled = enabled
        }
    }
    
    var switchChanged: ((on: Bool) -> ())? {
        didSet {
            switcher.addTarget(self, action: "switched:", forControlEvents: .ValueChanged)
        }
    }
    
    func switched(sender: UISwitch) {
        if let switchChanged = switchChanged {
            switchChanged(on: switcher.on)
        }
    }
}
