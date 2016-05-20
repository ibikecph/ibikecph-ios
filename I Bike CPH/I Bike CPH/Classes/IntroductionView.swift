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
        
        let bodyTexts = "introduction_greenest_route_body_ibc".localized.componentsSeparatedByString("\n")
        print(bodyTexts)
        
        let pageOne = EAIntroPage()
        pageOne.title = "introduction_greenest_route_header_ibc".localized
        pageOne.titleIconView = UIImageView.init(image: UIImage(named: "Cargo"))
        pageOne.desc = bodyTexts.count > 0 ? bodyTexts[0] : ""
        pageOne.descSideMargin = 30.0
        pages.append(pageOne)
        
        let pageTwo = EAIntroPage()
        pageTwo.titleIconView = UIImageView.init(image: UIImage(named: "Green"))
        pageTwo.desc = bodyTexts.count > 1 ? bodyTexts[1] : ""
        pageTwo.descSideMargin = 30.0
        pages.append(pageTwo)
        
        let pageThree = EAIntroPage()
        pageThree.desc = bodyTexts.count > 2 ? bodyTexts[2] : ""
        pageThree.descSideMargin = 30.0
        pages.append(pageThree)
        
        return pages
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame, andPages: self.introPages)
        self.backgroundColor = UIColor.blackColor().colorWithAlphaComponent(0.8)
    }
    
    required init!(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
