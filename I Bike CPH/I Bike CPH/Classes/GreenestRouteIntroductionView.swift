//
//  GreenestRouteIntroductionView.swift
//  I Bike CPH
//
//  Created by Troels Michael Trebbien on 24/05/16.
//  Copyright © 2016 I Bike CPH. All rights reserved.
//

import UIKit
import SnapKit

class GreenestRouteIntroductionView: UIView {

    let headerImageView = UIImageView()
    let titleLabel = UILabel()
    let scrollView = UIScrollView()
    let bodyLabel = UILabel()
    let leafImageView = UIImageView()
    let footerLabel = UILabel()
    let footerButton = UIButton()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = UIColor.white
        self.setupSubViews()
        self.setupConstraints()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    func setupSubViews() {
        self.headerImageView.image = UIImage(named: "IntroductionGreenestRouteHeader")
        self.headerImageView.clipsToBounds = true
        self.headerImageView.contentMode = .center
        self.addSubview(self.headerImageView)
        
        self.titleLabel.text = "introduction_greenest_route_header_ibc".localized
        self.titleLabel.textAlignment = .center
        self.titleLabel.textColor = UIColor.black
        self.titleLabel.font = UIFont.boldSystemFont(ofSize: 24)
        self.addSubview(self.titleLabel)
        
        self.scrollView.showsHorizontalScrollIndicator = false
        self.addSubview(self.scrollView)
        
        self.bodyLabel.text = "introduction_greenest_route_body_ibc".localized
        self.bodyLabel.textColor = UIColor.black
        self.bodyLabel.font = UIFont.systemFont(ofSize: 16)
        self.bodyLabel.textAlignment = .left
        self.bodyLabel.numberOfLines = 0
        self.scrollView.addSubview(self.bodyLabel)
        
        self.leafImageView.image = poGreenRouteImage(width: 44, color: Styler.tintColor())
        self.leafImageView.contentMode = .center
        self.scrollView.addSubview(self.leafImageView)
        
        self.footerLabel.text = "introduction_greenest_route_footer_ibc".localized
        self.footerLabel.font = self.bodyLabel.font
        self.footerLabel.textColor = self.bodyLabel.textColor
        self.footerLabel.textAlignment = .left
        self.footerLabel.numberOfLines = 0
        self.scrollView.addSubview(self.footerLabel)
        
        let footerButtonFont = UIFont.preferredFont(forTextStyle: UIFontTextStyle.headline)
        var attributes: [String: AnyObject] = [NSFontAttributeName: footerButtonFont,
                                               NSForegroundColorAttributeName: UIColor.white]
        var attributedTitle = NSAttributedString.init(string: "continue_button_text".localized, attributes: attributes)
        self.footerButton.setAttributedTitle(attributedTitle, for: UIControlState())
        attributes = [NSFontAttributeName: footerButtonFont,
                      NSForegroundColorAttributeName: UIColor.white.withAlphaComponent(0.5)]
        attributedTitle = NSAttributedString.init(string: "continue_button_text".localized, attributes: attributes)
        self.footerButton.setAttributedTitle(attributedTitle, for: .highlighted)
        self.footerButton.backgroundColor = UIColor.black
        self.addSubview(self.footerButton)
        
    }
    
    func setupConstraints() {
        self.headerImageView.snp_makeConstraints { (make) -> Void in
            make.top.equalTo(self).offset(20)
            make.left.right.equalTo(self)
            make.height.equalTo(self).multipliedBy(0.25)
        }
        
        self.titleLabel.snp_makeConstraints { (make) -> Void in
            make.top.equalTo(self.headerImageView.snp_bottom).offset(10)
            make.left.equalTo(self).offset(20)
            make.right.equalTo(self).offset(-20)
        }
        
        self.scrollView.snp_makeConstraints { (make) -> Void in
            make.top.equalTo(self.titleLabel.snp_bottom).offset(10)
            make.left.right.equalTo(self)
        }
        
        self.bodyLabel.snp_makeConstraints { (make) -> Void in
            make.top.equalTo(self.scrollView)
            make.left.equalTo(self.scrollView).offset(20)
            make.right.equalTo(self.scrollView).offset(-20)
            make.width.equalTo(self).offset(-40)
        }
        
        self.leafImageView.snp_makeConstraints { (make) -> Void in
            make.top.equalTo(self.bodyLabel.snp_bottom).offset(10)
            make.left.right.equalTo(self.scrollView)
            make.width.equalTo(self)
        }
        
        self.footerLabel.snp_makeConstraints { (make) -> Void in
            make.top.equalTo(self.leafImageView.snp_bottom).offset(10)
            make.left.equalTo(self.scrollView).offset(20)
            make.right.equalTo(self.scrollView).offset(-20)
            make.bottom.equalTo(self.scrollView).offset(-10)
            make.width.equalTo(self).offset(-40)
        }
        
        self.footerButton.snp_makeConstraints { (make) -> Void in
            make.top.equalTo(self.scrollView.snp_bottom)
            make.height.equalTo(60)
            make.left.right.bottom.equalTo(self)
        }
    }
}
