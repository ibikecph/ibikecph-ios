//
//  IntroductionView.swift
//  I Bike CPH
//
//  Created by Troels Michael Trebbien on 20/05/16.
//  Copyright © 2016 I Bike CPH. All rights reserved.
//

import UIKit
import EAIntroView

class IntroductionView: EAIntroView {

    let introPages: [EAIntroPage] = {
        var pages = [EAIntroPage]()
        let pageOne = EAIntroPage()
        pageOne.title = "introduction_greenest_route_header_ibc".localized
        pageOne.desc = "introduction_greenest_route_body_ibc".localized
        pageOne.bgColor = UIColor.blackColor().colorWithAlphaComponent(0.8)
        pageOne.descSideMargin = 30.0
        pageOne.titlePositionY = 50.0
        print(pageOne.titlePositionY)
        pages.append(pageOne)
        
        return pages
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame, andPages: self.introPages)
        print(frame)
    }
    
    required init!(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
