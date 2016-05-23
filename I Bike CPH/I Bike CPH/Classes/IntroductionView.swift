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
        
        let introPage = EAIntroPage()
        let introPageView = UIView.init(frame: frame)
        introPageView.backgroundColor = UIColor.clearColor()
        
        let headerImage = UIImage(named: "IntroductionGreenestRouteHeader")
        let headerImageViewFrame = CGRect(x: 0, y: 30, width: frame.size.width, height: headerImage?.size.height ?? 0)
        let headerImageView = UIImageView.init(frame: headerImageViewFrame)
        headerImageView.clipsToBounds = true
        headerImageView.image = headerImage
        headerImageView.contentMode = .Center
        introPageView.addSubview(headerImageView)
        
        let titleLabelFrame = CGRect(x: 0,
                                     y: headerImageViewFrame.origin.y + headerImageViewFrame.size.height + 10,
                                     width: frame.size.width,
                                     height: 35)
        let titleLabel = UILabel.init(frame: titleLabelFrame)
        titleLabel.text = "introduction_greenest_route_header_ibc".localized
        titleLabel.textAlignment = .Center
        titleLabel.textColor = UIColor.whiteColor()
        titleLabel.font = UIFont.boldSystemFontOfSize(26)
        introPageView.addSubview(titleLabel)
        
        let footerButtonFrame = CGRect(x: 0,
                                       y: frame.size.height-60,
                                       width: frame.size.width,
                                       height: 60)
        let footerButton = UIButton.init(frame: footerButtonFrame)
        footerButton.titleLabel?.font = UIFont.systemFontOfSize(16)
        footerButton.titleLabel?.textAlignment = .Center
        footerButton.titleLabel?.textColor = Styler.tintColor()
        footerButton.backgroundColor = UIColor.whiteColor()
        footerButton.titleLabel?.text = "OK".localized
        introPageView.addSubview(footerButton)
        
        let bodyTextViewFrame = CGRect(x: 20,
                                       y: titleLabelFrame.origin.y + titleLabelFrame.size.height + 20,
                                       width: frame.size.width-20,
                                       height: frame.size.height - (titleLabelFrame.origin.y + titleLabelFrame.size.height) - footerButtonFrame.size.height - 30)
        let bodyTextView = UITextView.init(frame: bodyTextViewFrame)
        bodyTextView.textColor = UIColor.whiteColor()
        bodyTextView.text = "introduction_greenest_route_body_ibc".localized
        bodyTextView.textAlignment = .Left
        bodyTextView.editable = false
        bodyTextView.selectable = false
        bodyTextView.showsHorizontalScrollIndicator = false
        bodyTextView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 10, right: 0)
        bodyTextView.backgroundColor = UIColor.clearColor()
        bodyTextView.font = UIFont.preferredFontForTextStyle(UIFontTextStyleBody)
        introPageView.addSubview(bodyTextView)
        
        introPage.customView = introPageView
        pages.append(introPage)
        
        // Instantiate this here for alignment reasons
//        let leafIconImageView = UIImageView.init(image: UIImage(named: "Green"))
        
        super.init(frame: frame, andPages: pages)
        
        self.backgroundColor = Styler.tintColor()
    }
    
    required init!(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
