//
//  IntroductionView.swift
//  I Bike CPH
//
//  Created by Troels Michael Trebbien on 20/05/16.
//  Copyright © 2016 I Bike CPH. All rights reserved.
//

import UIKit
import EAIntroView

class IntroductionView: EAIntroView, EAIntroDelegate {
    
    override init(frame: CGRect) {
        // Create pages
        var pages = [EAIntroPage]()
        
        let introPage = EAIntroPage()
        let introPageView = UIView.init(frame: frame)
        introPageView.backgroundColor = UIColor.clearColor()
        
        let footerButtonFrame = CGRect(x: 0,
                                       y: frame.size.height-60,
                                       width: frame.size.width,
                                       height: 60)
        let footerButton = UIButton.init(frame: footerButtonFrame)
        let footerButtonFont = UIFont.preferredFontForTextStyle(UIFontTextStyleHeadline)
        var attributes: [String: AnyObject] = [NSFontAttributeName: footerButtonFont,
                                               NSForegroundColorAttributeName: UIColor.whiteColor()]
        var attributedTitle = NSAttributedString.init(string: "continue_button_text".localized, attributes: attributes)
        footerButton.setAttributedTitle(attributedTitle, forState: .Normal)
        attributes = [NSFontAttributeName: footerButtonFont,
                      NSForegroundColorAttributeName: UIColor.whiteColor().colorWithAlphaComponent(0.5)]
        attributedTitle = NSAttributedString.init(string: "continue_button_text".localized, attributes: attributes)
        footerButton.setAttributedTitle(attributedTitle, forState: .Highlighted)
        footerButton.backgroundColor = UIColor.blackColor()
        introPageView.addSubview(footerButton)
        
        let statusBarBackgroundViewFrame = CGRect(x: 0, y: 0, width: frame.size.width, height: 30)
        let statusBarBackgroundView = UIView.init(frame: statusBarBackgroundViewFrame)
        statusBarBackgroundView.backgroundColor = UIColor.blackColor()
        introPageView.addSubview(statusBarBackgroundView)
        
        let headerImage = UIImage(named: "IntroductionGreenestRouteHeader")
        let headerImageViewFrame = CGRect(x: 0,
                                          y: statusBarBackgroundViewFrame.size.height,
                                          width: frame.size.width,
                                          height: headerImage?.size.height ?? 0)
        let headerImageView = UIImageView.init(frame: headerImageViewFrame)
        headerImageView.clipsToBounds = true
        headerImageView.image = headerImage
        headerImageView.contentMode = .Center
        introPageView.addSubview(headerImageView)
        
        let titleLabelFrame = CGRect(x: 20,
                                     y: headerImageViewFrame.origin.y + headerImageViewFrame.size.height + 10,
                                     width: frame.size.width - 40,
                                     height: 35)
        let titleLabel = UILabel.init(frame: titleLabelFrame)
        titleLabel.text = "introduction_greenest_route_header_ibc".localized
        titleLabel.textAlignment = .Center
        titleLabel.textColor = UIColor.blackColor()
        titleLabel.font = UIFont.boldSystemFontOfSize(24)
        introPageView.addSubview(titleLabel)
        
        let leafIconImage = poGreenRouteImage(width: 44, color: Styler.tintColor())
        let leafIconImageViewFrame = CGRect(x: 0,
                                            y: titleLabelFrame.origin.y + titleLabelFrame.size.height + 10,
                                            width: frame.size.width,
                                            height: leafIconImage?.size.height ?? 0)
        let leafIconImageView = UIImageView.init(frame: leafIconImageViewFrame)
        leafIconImageView.image = leafIconImage
        leafIconImageView.contentMode = .Center
        introPageView.addSubview(leafIconImageView)
        
        let bodyTextViewFrame = CGRect(x: 20,
                                       y: leafIconImageViewFrame.origin.y + leafIconImageViewFrame.size.height + 10,
                                       width: frame.size.width-40,
                                       height: frame.size.height - (titleLabelFrame.origin.y + titleLabelFrame.size.height) - footerButtonFrame.size.height - 30)
        let bodyTextView = UITextView.init(frame: bodyTextViewFrame)
        bodyTextView.textColor = UIColor.blackColor()
        bodyTextView.text = "introduction_greenest_route_body_ibc".localized + "\n\n" + "introduction_greenest_route_footer_ibc".localized
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
        
        super.init(frame: frame, andPages: pages)
        
        self.swipeToExit = false
        self.skipButton = nil
        self.pageControl = nil
        self.scrollingEnabled = false
        self.scrollView.scrollEnabled = false
        self.delegate = self
        footerButton.addTarget(self, action: #selector(pressedFooterButton), forControlEvents: .TouchUpInside)
        self.backgroundColor = UIColor.whiteColor()
    }
    
    required init!(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func pressedFooterButton(sender: UIButton) {
        self.hideWithFadeOutDuration(0.5)
    }

// MARK: EAIntroDelegate
    
    func introDidFinish(introView: EAIntroView!, wasSkipped: Bool) {
        Settings.sharedInstance.turnstile.didSeeIntroduction = true
    }
}