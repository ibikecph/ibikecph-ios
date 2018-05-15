//
//  ToolbarView.swift
//  I Bike CPH
//
//  Created by Tobias Due Munk on 04/06/15.
//  Copyright (c) 2015 I Bike CPH. All rights reserved.
//

import UIKit
import NibDesignable

class ToolbarView: NibDesignable {
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    init() {
        super.init(frame: CGRect.zero)
        setup()
    }
    
    func setup() {
        SMTranslation.translateView(self)
        prepareForReuse()
    }
    
    func prepareForReuse() {
        // For subclassing
    }
}
