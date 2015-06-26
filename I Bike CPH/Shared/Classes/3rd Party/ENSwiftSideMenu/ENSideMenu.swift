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
        let sideMenuOpen = self.sideMenuController()?.sideMenu?.isMenuOpen
        return sideMenuOpen!
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
    
    private var menuPosition: ENSideMenuPosition = .Left
    public var animationDuration = 0.2
    private let sideMenuContainerView =  UIView()
    private(set) var menuViewController : UIViewController!
    private var sourceViewController : UIViewController!
    private var sourceView : UIView!
    private var needUpdateApperance : Bool = false
    public weak var delegate : ENSideMenuDelegate?
    private(set) var isMenuOpen: Bool = false
    public var allowLeftSwipe: Bool = true
    public var allowRightSwipe: Bool = true
    private var screenEdgePan1GestureRecognizer: UIScreenEdgePanGestureRecognizer?
    private var screenEdgePan2GestureRecognizer: UIScreenEdgePanGestureRecognizer?
    private var panInitialProgress: CGFloat?
    private var leftConstraint: NSLayoutConstraint?
    
    public init(sourceViewController: UIViewController, menuPosition: ENSideMenuPosition) {
        super.init()
        self.sourceViewController = sourceViewController
        self.sourceView = self.sourceViewController.view
        self.menuPosition = menuPosition
        self.setupMenuView()
    
        // Edge swipe
        screenEdgePan1GestureRecognizer = UIScreenEdgePanGestureRecognizer(target: self, action: "handlePan:")
        screenEdgePan1GestureRecognizer!.delegate = self
        screenEdgePan1GestureRecognizer!.edges = (menuPosition == .Left) ? .Left : .Right
        sourceView.addGestureRecognizer(screenEdgePan1GestureRecognizer!)
        // Add swipe gesture recognizer to container
        screenEdgePan2GestureRecognizer = UIScreenEdgePanGestureRecognizer(target: self, action: "handlePan:")
        screenEdgePan2GestureRecognizer!.delegate = self
        screenEdgePan2GestureRecognizer!.edges = (menuPosition == .Left) ? .Right : .Left
        sideMenuContainerView.addGestureRecognizer(screenEdgePan2GestureRecognizer!)
        
        setMenu(isMenuOpen, animated: false)
    }

    public convenience init(sourceViewController: UIViewController, menuViewController menu: UIViewController, menuPosition: ENSideMenuPosition) {
        self.init(sourceViewController: sourceViewController, menuPosition: menuPosition)
        menuViewController = menu
        sourceViewController.addChildViewController(menuViewController)
        let menuView = menuViewController.view
        sideMenuContainerView.addSubview(menuView)
        menuViewController.didMoveToParentViewController(sourceViewController)
        
        menuView.setTranslatesAutoresizingMaskIntoConstraints(false)
        sourceView.addConstraint(NSLayoutConstraint(item: menuView, attribute: .Left, relatedBy: .Equal, toItem: sideMenuContainerView, attribute: .Left, multiplier: 1, constant: 0))
        sourceView.addConstraint(NSLayoutConstraint(item: menuView, attribute: .Right, relatedBy: .Equal, toItem: sideMenuContainerView, attribute: .Right, multiplier: 1, constant: 0))
        sourceView.addConstraint(NSLayoutConstraint(item: menuView, attribute: .Bottom, relatedBy: .Equal, toItem: sideMenuContainerView, attribute: .Bottom, multiplier: 1, constant: 0))
        sourceView.addConstraint(NSLayoutConstraint(item: menuView, attribute: .Top, relatedBy: .Equal, toItem: sideMenuContainerView, attribute: .Top, multiplier: 1, constant: 0))
    }

    private func setupMenuView() {
        
        // Configure side menu container
        sideMenuContainerView.backgroundColor = .clearColor()
        sideMenuContainerView.clipsToBounds = false
        sideMenuContainerView.layer.masksToBounds = false
        sideMenuContainerView.layer.shadowOffset = (menuPosition == .Left) ? CGSizeMake(0.5, 0) : CGSizeMake(-0.5, 0)
        sideMenuContainerView.layer.shadowRadius = 0
        sideMenuContainerView.layer.shadowOpacity = 0.125
        
        sourceView.addSubview(sideMenuContainerView)
        
        sideMenuContainerView.setTranslatesAutoresizingMaskIntoConstraints(false)
        leftConstraint = NSLayoutConstraint(item: sideMenuContainerView, attribute: .Left, relatedBy: .Equal, toItem: sourceView, attribute: .Left, multiplier: 1, constant: 0)
        sourceView.addConstraint(leftConstraint!)
        sourceView.addConstraint(NSLayoutConstraint(item: sideMenuContainerView, attribute: .Width, relatedBy: .Equal, toItem: sourceView, attribute: .Width, multiplier: 1, constant: 0))
        sourceView.addConstraint(NSLayoutConstraint(item: sideMenuContainerView, attribute: .Top, relatedBy: .Equal, toItem: sourceView, attribute: .Top, multiplier: 1, constant: 0))
        sourceView.addConstraint(NSLayoutConstraint(item: sideMenuContainerView, attribute: .Bottom, relatedBy: .Equal, toItem: sourceView, attribute: .Bottom, multiplier: 1, constant: 0))
    }
    
    
    func setMenu(shouldOpen: Bool, animated: Bool = true) {
        if (shouldOpen && delegate?.sideMenuShouldOpenSideMenu?() == false) {
            return
        }
        isMenuOpen = shouldOpen
        
        if (shouldOpen) {
            delegate?.sideMenuWillOpen?()
        } else {
            delegate?.sideMenuWillClose?()
        }
        
        let position: CGFloat = shouldOpen ? 1 : 0
        updateToPositionOpen(position, animated: animated)
    }
    
    private func updateToPositionOpen(open: CGFloat, animated: Bool) {
        let open = min(max(open, 0), 1)
        
        let width = sourceView.frame.width
        let xPosition = (menuPosition == .Left) ? progress(open, from: -width, to: 0) : progress(open, from: width, to: 0)
        
        let shadowAlpha = min(Float(open), 0.125)
        self.leftConstraint?.constant = xPosition
        sourceView.setNeedsUpdateConstraints()
        if animated {
            UIView.animateWithDuration(animationDuration, animations: {
                self.sourceView.layoutIfNeeded()
                self.sideMenuContainerView.layer.shadowOpacity = shadowAlpha
            })
        } else {
            self.sideMenuContainerView.layer.shadowOpacity = shadowAlpha
        }
    }
    
    private func progress(progress: CGFloat, from: CGFloat, to: CGFloat) -> CGFloat {
        return (1 - progress) * from + progress * to
    }
    
    internal func handlePan(gesture: UIPanGestureRecognizer) {
        let width = sourceView.frame.width
        var progress = gesture.translationInView(gesture.view!).x / width
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
                var progress = gesture.translationInView(gesture.view!).x / width
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
                setMenu(endOpen)
            default: break
        }
    }
    
    public func toggleMenu () {
        if (isMenuOpen) {
            setMenu(false)
        }
        else {
            setMenu(true)
        }
    }
    
    public func showSideMenu () {
        if (!isMenuOpen) {
            setMenu(true)
        }
    }
    
    public func hideSideMenu () {
        if (isMenuOpen) {
            setMenu(false)
        }
    }
}


extension ENSideMenu: UIGestureRecognizerDelegate {
    
    public func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldBeRequiredToFailByGestureRecognizer otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        
        if gestureRecognizer == screenEdgePan1GestureRecognizer {
            // If other gesture is screen from same edge
            if let other = otherGestureRecognizer as? UIScreenEdgePanGestureRecognizer {
                let sameEdges = screenEdgePan1GestureRecognizer!.edges == other.edges
                return !sameEdges
            }
            // Screen edge pan should overrule all other gestures
            let menuIsClosed = !isMenuOpen
            return menuIsClosed
        }
        return false
    }
}