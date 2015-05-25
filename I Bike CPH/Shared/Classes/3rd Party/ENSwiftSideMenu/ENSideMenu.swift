//
//  SideMenu.swift
//  SwiftSideMenu
//
//  Created by Evgeny on 24.07.14.
//  Copyright (c) 2014 Evgeny Nazarov. All rights reserved.
//

import UIKit

@objc public protocol ENSideMenuDelegate {
    optional func sideMenuWillOpen()
    optional func sideMenuWillClose()
    optional func sideMenuShouldOpenSideMenu () -> Bool
}

@objc public protocol ENSideMenuProtocol {
    var sideMenu : ENSideMenu? { get }
    func setContentViewController(contentViewController: UIViewController)
}

public enum ENSideMenuAnimation : Int {
    case None
    case Default
}

public enum ENSideMenuPosition : Int {
    case Left
    case Right
}

public extension UIViewController {
    
    public func toggleSideMenuView () {
        sideMenuController()?.sideMenu?.toggleMenu()
    }
    
    public func hideSideMenuView () {
        sideMenuController()?.sideMenu?.hideSideMenu()
    }
    
    public func showSideMenuView () {
        sideMenuController()?.sideMenu?.showSideMenu()
    }
    
    public func isSideMenuOpen () -> Bool {
        let sieMenuOpen = self.sideMenuController()?.sideMenu?.isMenuOpen
        return sieMenuOpen!
    }
    
    /**
     * You must call this method from viewDidLayoutSubviews in your content view controlers so it fixes size and position of the side menu when the screen
     * rotates.
     * A convenient way to do it might be creating a subclass of UIViewController that does precisely that and then subclassing your view controllers from it.
     */
    func fixSideMenuSize() {
        if let navController = self.navigationController as? ENSideMenuNavigationController {
            navController.sideMenu?.updateFrame()
        }
    }
    
    public func sideMenuController () -> ENSideMenuProtocol? {
        var iteration : UIViewController? = self.parentViewController
        if (iteration == nil) {
            return topMostController()
        }
        do {
            if (iteration is ENSideMenuProtocol) {
                return iteration as? ENSideMenuProtocol
            } else if (iteration?.parentViewController != nil && iteration?.parentViewController != iteration) {
                iteration = iteration!.parentViewController
            } else {
                iteration = nil
            }
        } while (iteration != nil)
        
        return iteration as? ENSideMenuProtocol
    }
    
    internal func topMostController () -> ENSideMenuProtocol? {
        var topController : UIViewController? = UIApplication.sharedApplication().keyWindow?.rootViewController
        while (topController?.presentedViewController is ENSideMenuProtocol) {
            topController = topController?.presentedViewController
        }
        
        return topController as? ENSideMenuProtocol
    }
}

public class ENSideMenu: NSObject {
    
    public var menuWidth: CGFloat = UIScreen.mainScreen().bounds.width {
        didSet {
            needUpdateApperance = true
            updateFrame()
        }
    }
    private var menuPosition:ENSideMenuPosition = .Left
    public var animationDuration = 0.2
    private let sideMenuContainerView =  UIView()
    private var menuViewController : UIViewController!
    private var sourceView : UIView!
    private var needUpdateApperance : Bool = false
    public weak var delegate : ENSideMenuDelegate?
    private(set) var isMenuOpen: Bool = false
    public var allowLeftSwipe: Bool = true
    public var allowRightSwipe: Bool = true
    private var screenEdgePanGestureRecognizer: UIScreenEdgePanGestureRecognizer?
    private var panInitialProgress: CGFloat?
    
    public init(sourceView: UIView, menuPosition: ENSideMenuPosition) {
        super.init()
        self.sourceView = sourceView
        self.menuPosition = menuPosition
        self.setupMenuView()
    
        // Edge swipe
        screenEdgePanGestureRecognizer = UIScreenEdgePanGestureRecognizer(target: self, action: "handlePan:")
        screenEdgePanGestureRecognizer!.delegate = self
        screenEdgePanGestureRecognizer!.edges = (menuPosition == .Left) ? .Left : .Right
        sourceView.addGestureRecognizer(screenEdgePanGestureRecognizer!)
        // Add swipe gesture recognizer to container
        let panGestureRecognizer = UIPanGestureRecognizer(target: self, action: "handlePan:")
        panGestureRecognizer.delegate = self
        sideMenuContainerView.addGestureRecognizer(panGestureRecognizer)
    }

    public convenience init(sourceView: UIView, menuViewController: UIViewController, menuPosition: ENSideMenuPosition) {
        self.init(sourceView: sourceView, menuPosition: menuPosition)
        self.menuViewController = menuViewController
        self.menuViewController.view.frame = sideMenuContainerView.bounds
        self.menuViewController.view.autoresizingMask = .FlexibleHeight | .FlexibleWidth
        sideMenuContainerView.addSubview(self.menuViewController.view)
    }

    public convenience init(sourceView: UIView, view: UIView, menuPosition: ENSideMenuPosition) {
        self.init(sourceView: sourceView, menuPosition: menuPosition)
        view.frame = sideMenuContainerView.bounds
        view.autoresizingMask = .FlexibleHeight | .FlexibleWidth
        sideMenuContainerView.addSubview(view)
    }

    /**
     * Do not make this function private, it must be called from your own UIViewControllers (using the fixSideMenuSize function of the extension).
     */
    func updateFrame() {
        let width = sourceView.frame.size.width
        let height = sourceView.frame.size.height
        let menuFrame = CGRectMake(
            (menuPosition == .Left) ?
                isMenuOpen ? 0 : -menuWidth-1.0 :
                isMenuOpen ? width - menuWidth : width+1.0,
            sourceView.frame.origin.y,
            menuWidth,
            height
        )
        sideMenuContainerView.frame = menuFrame
    }
    
    private func setupMenuView() {
        
        // Configure side menu container
        updateFrame()

        sideMenuContainerView.backgroundColor = UIColor.clearColor()
        sideMenuContainerView.clipsToBounds = false
        sideMenuContainerView.layer.masksToBounds = false
        sideMenuContainerView.layer.shadowOffset = (menuPosition == .Left) ? CGSizeMake(1.0, 1.0) : CGSizeMake(-1.0, -1.0)
        sideMenuContainerView.layer.shadowRadius = 0.5
        sideMenuContainerView.layer.shadowOpacity = 0.125
        sideMenuContainerView.layer.shadowPath = UIBezierPath(rect: sideMenuContainerView.bounds).CGPath
        
        sourceView.addSubview(sideMenuContainerView)
    }
    
    
    func animateMenu(shouldOpen: Bool) {
        if (shouldOpen && delegate?.sideMenuShouldOpenSideMenu?() == false) {
            return
        }
        updateSideMenuApperanceIfNeeded()
        isMenuOpen = shouldOpen
        
        if (shouldOpen) {
            delegate?.sideMenuWillOpen?()
        } else {
            delegate?.sideMenuWillClose?()
        }
        
        let position: CGFloat = shouldOpen ? 1 : 0
        updateToPositionOpen(position, animated: true)
    }
    
    private func updateToPositionOpen(open: CGFloat, animated: Bool) {
        let open = min(max(open, 0), 1)
        
        let width = sourceView.frame.size.width
        let height = sourceView.frame.size.height
        let xPosition = (menuPosition == .Left) ? progress(open, from: -menuWidth, to: 0) : progress(open, from: width, to: width - menuWidth)
        let destFrame = CGRectMake(xPosition, 0, menuWidth, height)
        
        let shadowAlpha = min(Float(open), 0.125)
        if animated {
            UIView.animateWithDuration(animationDuration, animations: {
                self.sideMenuContainerView.frame = destFrame
                self.sideMenuContainerView.layer.shadowOpacity = shadowAlpha
            })
        } else {
            sideMenuContainerView.frame = destFrame
            self.sideMenuContainerView.layer.shadowOpacity = shadowAlpha
        }
    }
    
    private func progress(progress: CGFloat, from: CGFloat, to: CGFloat) -> CGFloat {
        return (1 - progress) * from + progress * to
    }
    
    internal func handlePan(gesture: UIPanGestureRecognizer) {
        var progress = gesture.translationInView(gesture.view!).x / self.menuWidth
        let shouldReverse = self.menuPosition == .Right
        if shouldReverse {
            progress *= -1
        }
        if isMenuOpen {
            progress += 1
        }
        
        switch gesture.state {
            case .Began: break
            case .Changed:
                var progress = gesture.translationInView(gesture.view!).x / self.menuWidth
                let shouldReverse = self.menuPosition == .Right
                if shouldReverse {
                    progress *= -1
                }
                if isMenuOpen {
                    progress += 1
                }
                updateToPositionOpen(progress, animated: false)
            case .Cancelled:
                fallthrough
            case .Ended:
                let endOpen = progress > 0.5
                animateMenu(endOpen)
            default: break
        }
    }
    
    private func updateSideMenuApperanceIfNeeded () {
        if (needUpdateApperance) {
            var frame = sideMenuContainerView.frame
            frame.size.width = menuWidth
            sideMenuContainerView.frame = frame
            sideMenuContainerView.layer.shadowPath = UIBezierPath(rect: sideMenuContainerView.bounds).CGPath

            needUpdateApperance = false
        }
    }
    
    public func toggleMenu () {
        if (isMenuOpen) {
            animateMenu(false)
        }
        else {
            updateSideMenuApperanceIfNeeded()
            animateMenu(true)
        }
    }
    
    public func showSideMenu () {
        if (!isMenuOpen) {
            animateMenu(true)
        }
    }
    
    public func hideSideMenu () {
        if (isMenuOpen) {
            animateMenu(false)
        }
    }
}


extension ENSideMenu: UIGestureRecognizerDelegate {
    
    public func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldBeRequiredToFailByGestureRecognizer otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        if gestureRecognizer == screenEdgePanGestureRecognizer {
            return true
        }
        return false
    }
}