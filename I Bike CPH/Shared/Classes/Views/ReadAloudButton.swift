//
//  ReadAloudButton.swift
//  I Bike CPH
//

import UIKit


class ReadAloudButton: UIButton {

    var circleColor: UIColor {
        return Settings.sharedInstance.readAloud.on ? Styler.tintColor() : UIColor(red:0.41, green:0.41, blue:0.41, alpha:1)
    }
    override var isHighlighted: Bool {
        didSet {
            highlight(isHighlighted)
        }
    }
    
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
    
    deinit {
        unobserve()
    }
    
    fileprivate var observerTokens = [AnyObject]()
    fileprivate func unobserve() {
        for observerToken in self.observerTokens {
            NotificationCenter.unobserve(observerToken)
        }
        NotificationCenter.unobserve(self)
    }
    
    func setup() {
        adjustsImageWhenHighlighted = false
        highlight(false)
        self.setupSettingsObserver()
        self.updateState()
        
        self.addTarget(self, action: #selector(self.touchedUpInside(_:)), for: .touchUpInside)
    }
    
    fileprivate func setupSettingsObserver() {
        self.observerTokens.append(NotificationCenter.observe(settingsUpdatedNotification) { [weak self] notification in
            self?.updateState()
        })
    }
    
    fileprivate func updateState() {
        let imageName = Settings.sharedInstance.readAloud.on ? "read_aloud_on" : "read_aloud_off"
        self.setImage(UIImage(named: imageName), for: UIControlState())
        self.setNeedsDisplay()
    }
    
    @objc fileprivate func touchedUpInside(_ sender: UIButton!) {
        Settings.sharedInstance.readAloud.on = !Settings.sharedInstance.readAloud.on
    }
    
    func highlight(_ highlight: Bool = false) {
        shadow(highlight)
    }
    
    func shadow(_ lifted: Bool = false) {
        layer.masksToBounds = false
        let offset = lifted  ? 4 : 0.5
        layer.shadowOffset = CGSize(width: 0, height: offset)
        layer.shadowRadius = lifted ? 4.5 : 1.5
        layer.shadowOpacity =  0.5
    }
    
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        
        // Take account for off-center content
        let verticalOffset = contentEdgeInsets.top - contentEdgeInsets.bottom
        let horizontalOffset = contentEdgeInsets.left - contentEdgeInsets.right
        let topInset = max(verticalOffset, 0)
        let leftInset = max(horizontalOffset, 0)
        let bottomInset = max(-verticalOffset, 0)
        let rightInset = max(-horizontalOffset, 0)
        let inset = UIEdgeInsets(top: topInset, left: leftInset, bottom: bottomInset, right: rightInset)
        let circleRect = UIEdgeInsetsInsetRect(rect, inset)
        // Draw circle
        let context = UIGraphicsGetCurrentContext()
        context?.setFillColor(circleColor.cgColor)
        context?.fillEllipse (in: circleRect)
        context?.fillPath()
    }
}
