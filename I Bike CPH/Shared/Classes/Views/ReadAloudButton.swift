//
//  ReadAloudButton.swift
//  I Bike CPH
//

import UIKit


class ReadAloudButton: UIButton {

    var circleColor: UIColor {
        return Settings.sharedInstance.readAloud.on ? Styler.tintColor() : UIColor.lightGrayColor()
    }
    override var highlighted: Bool {
        didSet {
            highlight(highlighted)
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
        super.init(frame: CGRectZero)
        setup()
    }
    
    deinit {
        unobserve()
    }
    
    private var observerTokens = [AnyObject]()
    private func unobserve() {
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
        
        self.addTarget(self, action: #selector(self.touchedUpInside(_:)), forControlEvents: .TouchUpInside)
    }
    
    private func setupSettingsObserver() {
        self.observerTokens.append(NotificationCenter.observe(settingsUpdatedNotification) { [weak self] notification in
            self?.updateState()
        })
    }
    
    private func updateState() {
        let imageName = Settings.sharedInstance.readAloud.on ? "Compas unselected" : "Compas selected"
        self.setImage(UIImage(named: imageName), forState: .Normal)
        self.setNeedsDisplay()
    }
    
    @objc private func touchedUpInside(sender: UIButton!) {
        Settings.sharedInstance.readAloud.on = !Settings.sharedInstance.readAloud.on
    }
    
    func highlight(highlight: Bool = false) {
        shadow(highlight)
    }
    
    func shadow(lifted: Bool = false) {
        layer.masksToBounds = false
        let offset = lifted  ? 4 : 0.5
        layer.shadowOffset = CGSize(width: 0, height: offset)
        layer.shadowRadius = lifted ? 4.5 : 1.5
        layer.shadowOpacity =  0.5
    }
    
    override func drawRect(rect: CGRect) {
        super.drawRect(rect)
        
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
        CGContextSetFillColorWithColor(context, circleColor.CGColor)
        CGContextFillEllipseInRect (context, circleRect)
        CGContextFillPath(context)
    }
}
