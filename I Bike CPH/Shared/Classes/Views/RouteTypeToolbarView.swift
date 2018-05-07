//
//  RouteTypeToolbarView.swift
//  I Bike CPH
//
//  Created by Tobias Due Munk on 04/06/15.
//  Copyright (c) 2015 I Bike CPH. All rights reserved.
//

import UIKit

protocol RouteTypeToolbarDelegate {
    func didChangeType(_ type: RouteType)
}

class RouteTypeToolbarView: ToolbarView {

    @IBOutlet weak var leftButton: UIButton!
    @IBOutlet weak var centerButton: UIButton!
    @IBOutlet weak var rightButton: UIButton!
    
    fileprivate var type: RouteType {
        get {
            return RouteTypeHandler.instance.type
        }
        set {
            if newValue != type {
                RouteTypeHandler.instance.type = newValue
                updateUI()
                delegate?.didChangeType(RouteTypeHandler.instance.type)
            }
        }
    }
    fileprivate let validTypes = RouteType.validTypes()
    fileprivate var buttons: [UIButton] {
        return [leftButton, centerButton, rightButton]
    }
    
    var delegate: RouteTypeToolbarDelegate?
    
    override func setup() {
        super.setup()
        
        updateUI()
    }
    
    fileprivate func validType(_ index: Int) -> RouteType {
        return index < validTypes.count ? validTypes[index] : .disabled
    }
    
    @IBAction func didTapLeftButton(_ sender: AnyObject) {
        type = validType(0)
    }
    @IBAction func didTapCenterButton(_ sender: AnyObject) {
        type = validType(1)
    }
    @IBAction func didTapRightButton(_ sender: AnyObject) {
        type = validType(2)
    }
    
    func updateUI() {
        for (index, button) in buttons.enumerated() {
            let type = validType(index)
            button.isEnabled = (type != .disabled)
            let typeViewModel = RouteTypeViewModel(type: type)
            // Set image
            button.setImage(typeViewModel.iconImage, for: UIControlState())
            // Set selection
            button.tintColor = typeViewModel.selected ? Styler.tintColor() : Styler.foregroundColor()
        }
    }
}

