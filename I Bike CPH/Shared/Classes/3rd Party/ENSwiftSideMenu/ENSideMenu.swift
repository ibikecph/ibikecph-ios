//
//  SideMenu.swift
//  SwiftSideMenu
//
//  Created by Evgeny on 24.07.14.
//  Copyright (c) 2014 Evgeny Nazarov. All rights reserved.
//

import UIKit

@objc public protocol ENSideMenuDelegate {
    @objc optional func sideMenuWillOpen()
    @objc optional func sideMenuWillClose()
    @objc optional func sideMenuShouldOpenSideMenu () -> Bool
}

@objc public protocol ENSideMenuProtocol {
    var sideMenu : ENSideMenu? { get }
    func setContentViewController(_ contentViewController: UIViewController)
}

public enum ENSideMenuAnimation : Int {
    case none
    case `default`
}

public enum ENSideMenuPosition : Int {
    case left
    case right
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
        var iteration : UIViewController? = self.parent
        if (iteration == nil) {
            return topMostController()
        }
        repeat {
            if (iteration is ENSideMenuProtocol) {
                return iteration as? ENSideMenuProtocol
            } else if (iteration?.parent != nil && iteration?.parent != iteration) {
                iteration = iteration!.parent
            } else {
                iteration = nil
            }
        } while (iteration != nil)
        
        return iteration as? ENSideMenuProtocol
    }
    
    internal func topMostController () -> ENSideMenuProtocol? {
        var topController : UIViewController? = UIApplication.shared.keyWindow?.rootViewController
        while (topController?.presentedViewController is ENSideMenuProtocol) {
            topController = topController?.presentedViewController
        }
        
        return topController as? ENSideMenuProtocol
    }
}


open class ENSideMenu: NSObject {
    
    fileprivate var menuPosition: ENSideMenuPosition = .left
    open var animationDuration = 0.2
    fileprivate let sideMenuContainerView =  UIView()
    fileprivate(set) var menuViewController : UIViewController!
    fileprivate var sourceViewController : UIViewController!
    fileprivate var sourceView : UIView!
    fileprivate var needUpdateApperance : Bool = false
    open weak var delegate : ENSideMenuDelegate?
    fileprivate(set) var isMenuOpen: Bool = false
    open var allowLeftSwipe: Bool = true
    open var allowRightSwipe: Bool = true
    fileprivate var screenEdgePan1GestureRecognizer: UIScreenEdgePanGestureRecognizer?
    fileprivate var screenEdgePan2GestureRecognizer: UIScreenEdgePanGestureRecognizer?
    fileprivate var panInitialProgress: CGFloat?
    fileprivate var leftConstraint: NSLayoutConstraint?
    
    public init(sourceViewController: UIViewController, menuPosition: ENSideMenuPosition) {
        super.init()
        self.sourceViewController = sourceViewController
        self.sourceView = self.sourceViewController.view
        self.menuPosition = menuPosition
        self.setupMenuView()
    
        // Edge swipe
        screenEdgePan1GestureRecognizer = UIScreenEdgePanGestureRecognizer(target: self, action: #selector(ENSideMenu.handlePan(_:)))
        screenEdgePan1GestureRecognizer!.delegate = self
        screenEdgePan1GestureRecognizer!.edges = (menuPosition == .left) ? .left : .right
        sourceView.addGestureRecognizer(screenEdgePan1GestureRecognizer!)
        // Add swipe gesture recognizer to container
        screenEdgePan2GestureRecognizer = UIScreenEdgePanGestureRecognizer(target: self, action: #selector(ENSideMenu.handlePan(_:)))
        screenEdgePan2GestureRecognizer!.delegate = self
        screenEdgePan2GestureRecognizer!.edges = (menuPosition == .left) ? .right : .left
        sideMenuContainerView.addGestureRecognizer(screenEdgePan2GestureRecognizer!)
        
        setMenu(isMenuOpen, animated: false)
    }

    public convenience init(sourceViewController: UIViewController, menuViewController menu: UIViewController, menuPosition: ENSideMenuPosition) {
        self.init(sourceViewController: sourceViewController, menuPosition: menuPosition)
        menuViewController = menu
        sourceViewController.addChildViewController(menuViewController)
        let menuView = menuViewController.view
        sideMenuContainerView.addSubview(menuView!)
        menuViewController.didMove(toParentViewController: sourceViewController)
        
        menuView?.translatesAutoresizingMaskIntoConstraints = false
        sourceView.addConstraint(NSLayoutConstraint(item: menuView, attribute: .left, relatedBy: .equal, toItem: sideMenuContainerView, attribute: .left, multiplier: 1, constant: 0))
        sourceView.addConstraint(NSLayoutConstraint(item: menuView, attribute: .right, relatedBy: .equal, toItem: sideMenuContainerView, attribute: .right, multiplier: 1, constant: 0))
        sourceView.addConstraint(NSLayoutConstraint(item: menuView, attribute: .bottom, relatedBy: .equal, toItem: sideMenuContainerView, attribute: .bottom, multiplier: 1, constant: 0))
        sourceView.addConstraint(NSLayoutConstraint(item: menuView, attribute: .top, relatedBy: .equal, toItem: sideMenuContainerView, attribute: .top, multiplier: 1, constant: 0))
    }

    fileprivate func setupMenuView() {
        
        // Configure side menu container
        sideMenuContainerView.backgroundColor = .clear
        sideMenuContainerView.clipsToBounds = false
        sideMenuContainerView.layer.masksToBounds = false
        sideMenuContainerView.layer.shadowOffset = (menuPosition == .left) ? CGSize(width: 0.5, height: 0) : CGSize(width: -0.5, height: 0)
        sideMenuContainerView.layer.shadowRadius = 0
        sideMenuContainerView.layer.shadowOpacity = 0.125
        
        sourceView.addSubview(sideMenuContainerView)
        
        sideMenuContainerView.translatesAutoresizingMaskIntoConstraints = false
        leftConstraint = NSLayoutConstraint(item: sideMenuContainerView, attribute: .left, relatedBy: .equal, toItem: sourceView, attribute: .left, multiplier: 1, constant: 0)
        sourceView.addConstraint(leftConstraint!)
        sourceView.addConstraint(NSLayoutConstraint(item: sideMenuContainerView, attribute: .width, relatedBy: .equal, toItem: sourceView, attribute: .width, multiplier: 1, constant: 0))
        sourceView.addConstraint(NSLayoutConstraint(item: sideMenuContainerView, attribute: .top, relatedBy: .equal, toItem: sourceView, attribute: .top, multiplier: 1, constant: 0))
        sourceView.addConstraint(NSLayoutConstraint(item: sideMenuContainerView, attribute: .bottom, relatedBy: .equal, toItem: sourceView, attribute: .bottom, multiplier: 1, constant: 0))
    }
    
    
    func setMenu(_ shouldOpen: Bool, animated: Bool = true) {
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
    
    fileprivate func updateToPositionOpen(_ open: CGFloat, animated: Bool) {
        let open = min(max(open, 0), 1)
        
        let width = sourceView.frame.width
        let xPosition = (menuPosition == .left) ? progress(open, from: -width, to: 0) : progress(open, from: width, to: 0)
        
        let shadowAlpha = min(Float(open), 0.125)
        self.leftConstraint?.constant = xPosition
        sourceView.setNeedsUpdateConstraints()
        if animated {
            UIView.animate(withDuration: animationDuration, animations: {
                self.sourceView.layoutIfNeeded()
                self.sideMenuContainerView.layer.shadowOpacity = shadowAlpha
            })
        } else {
            self.sideMenuContainerView.layer.shadowOpacity = shadowAlpha
        }
    }
    
    fileprivate func progress(_ progress: CGFloat, from: CGFloat, to: CGFloat) -> CGFloat {
        return (1 - progress) * from + progress * to
    }
    
    internal func handlePan(_ gesture: UIPanGestureRecognizer) {
        let width = sourceView.frame.width
        var progress = gesture.translation(in: gesture.view!).x / width
        let shouldReverse = self.menuPosition == .right
        if shouldReverse {
            progress *= -1
        }
        if isMenuOpen {
            progress += 1
        }
        
        switch gesture.state {
            case .began: break
            case .changed:
                var progress = gesture.translation(in: gesture.view!).x / width
                let shouldReverse = self.menuPosition == .right
                if shouldReverse {
                    progress *= -1
                }
                if isMenuOpen {
                    progress += 1
                }
                updateToPositionOpen(progress, animated: false)
            case .cancelled:
                fallthrough
            case .ended:
                let endOpen = progress > 0.5
                setMenu(endOpen)
            default: break
        }
    }
    
    open func toggleMenu () {
        if (isMenuOpen) {
            setMenu(false)
        }
        else {
            setMenu(true)
        }
    }
    
    open func showSideMenu () {
        if (!isMenuOpen) {
            setMenu(true)
        }
    }
    
    open func hideSideMenu () {
        if (isMenuOpen) {
            setMenu(false)
        }
    }
}


extension ENSideMenu: UIGestureRecognizerDelegate {
    
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldBeRequiredToFailBy otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        
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
