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
    
    override init(frame: CGRect) {
        // Create pages
        var pages = [EAIntroPage]()
        let bodyTexts = "introduction_greenest_route_body_ibc".localized.componentsSeparatedByString("\n")
        
        var titleViewPositionY: CGFloat
        var titleIconPositionY: CGFloat
        var titlePositionY: CGFloat
        var descPositionY: CGFloat
        var descSideMargin: CGFloat
        
        // Make up for poor customization options in EAIntroView
        print(frame.size.height)
        switch frame.size.height {
        case 0..<481:
            // iPhone 4S
            titleViewPositionY = 50
            titleIconPositionY = 250
            titlePositionY = 250
            descPositionY = titlePositionY + 50
            descSideMargin = 30
        case 481..<668:
            // iPhone 5, 5S, 6, 6S
            titleViewPositionY = 100
            titleIconPositionY = 300
            titlePositionY = 250
            descPositionY = titlePositionY + 50
            descSideMargin = 50
        default:
            // Any other device (like iPhone 6, 6S)
            titleViewPositionY = 150
            titleIconPositionY = 350
            titlePositionY = 250
            descPositionY = titlePositionY + 50
            descSideMargin = 70
        }
        
        // Instantiate this here for alignment reasons
        let leafIconImageView = UIImageView.init(image: UIImage(named: "Green"))
        
        let pageOne = EAIntroPage()
        pageOne.title = "introduction_greenest_route_header_ibc".localized
        pageOne.titleIconView = UIView(frame: leafIconImageView.frame)
        pageOne.titleIconPositionY = titleIconPositionY
        pageOne.titlePositionY = titlePositionY
        pageOne.descPositionY = descPositionY
        pageOne.desc = bodyTexts.count > 0 ? bodyTexts[0] : ""
        pageOne.descSideMargin = descSideMargin
        pages.append(pageOne)
        
        let pageTwo = EAIntroPage()
        pageTwo.title = " "
        pageTwo.titleIconView = UIView(frame: leafIconImageView.frame)
        pageTwo.titleIconPositionY = titleIconPositionY
        pageTwo.titlePositionY = titlePositionY
        pageTwo.descPositionY = descPositionY
        pageTwo.desc = bodyTexts.count > 1 ? bodyTexts[1] : ""
        pageTwo.descSideMargin = descSideMargin
        pages.append(pageTwo)
        
        let pageThree = EAIntroPage()
        pageThree.title = "introduction_greenest_route_footer_ibc".localized
        pageThree.titleIconView = leafIconImageView
        pageThree.titleIconPositionY = titleIconPositionY
        pageThree.titlePositionY = titlePositionY
        pageThree.descPositionY = descPositionY
        pageThree.desc = bodyTexts.count > 2 ? bodyTexts[2] : ""
        pageThree.descSideMargin = descSideMargin
        pages.append(pageThree)
        
        super.init(frame: frame, andPages: pages)
        
        let titleView = UIImageView.init(image: UIImage(named: "IntroductionGreenestRouteHeader"))
        titleView.layer.cornerRadius = 5.0
        titleView.clipsToBounds = true
        titleView.layer.borderWidth = 1.0
        titleView.layer.borderColor = UIColor.whiteColor().CGColor
        
        self.titleView = titleView
        self.titleViewY = titleViewPositionY
        self.backgroundColor = UIColor.blackColor().colorWithAlphaComponent(0.8)
    }
    
    required init!(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
