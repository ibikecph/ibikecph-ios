//
//  TurnInstructionsCollectionViewCell.swift
//  I Bike CPH
//
//  Created by Tobias Due Munk on 26/01/15.
//  Copyright (c) 2015 I Bike CPH. All rights reserved.
//

import UIKit
import NibDesignable

class TurnInstructionsCollectionViewCell: NibDesignableCollectionViewCell {
    @IBOutlet weak var directionImageView: UIImageView!
    @IBOutlet var distanceLabel: UILabel!
    @IBOutlet weak var wayNameLabel: UILabel!
    
    override var selected: Bool {
        set {
            // Do nothing to avoid highlight on selection
        }
        get {
            return false
        }
    }
}

extension TurnInstructionsCollectionViewCell {
    
    func configure(instruction: SMTurnInstruction) {
        directionImageView.image = instruction.directionIcon()
        wayNameLabel.text = instruction.wayName.localized
        distanceLabel.text = formatDistance(Float(instruction.lengthInMeters))
    }
}
