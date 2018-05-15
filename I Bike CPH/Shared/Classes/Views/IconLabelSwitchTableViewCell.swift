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
            switcher.isEnabled = enabled
        }
    }
    
    var switchChanged: ((_ on: Bool) -> ())? {
        didSet {
            switcher.addTarget(self, action: #selector(IconLabelSwitchTableViewCell.switched(_:)), for: .valueChanged)
        }
    }
    
    func switched(_ sender: UISwitch) {
        if let switchChanged = switchChanged {
            switchChanged(switcher.isOn)
        }
    }
}
