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

    lazy var timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .none // No date
        return formatter
    }()
    
    override var isSelected: Bool {
        set {
            // Do nothing to avoid highlight on selection
        }
        get {
            return false
        }
    }
}

extension TurnInstructionsCollectionViewCell {
    
    func configure(_ instruction: SMTurnInstruction) {
        directionImageView.image = instruction.directionIcon
        let isPublic = instruction.routeType != .bike && instruction.routeType != .walk
        if isPublic {
            wayNameLabel.text = instruction.descriptionString
            distanceLabel.text = timeFormatter.string(from: instruction.routeLineTime)
        } else {
            wayNameLabel.text = instruction.wayName.localized
            distanceLabel.text = SMRouteUtils.formatDistance(inMeters: Float(instruction.lengthInMeters))
        }
    }
}
