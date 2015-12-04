//
//  RouteBrokenToolbarView.swift
//  I Bike CPH
//
//  Created by Tobias Due Munk on 04/06/15.
//  Copyright (c) 2015 I Bike CPH. All rights reserved.
//

import UIKit
import ORStackView


protocol RouteBrokenToolbarViewDelegate {
    func didChangePage(page: Int)
}

class RouteBrokenToolbarView: ToolbarView {

    @IBOutlet weak var contentView: UIView!
    var delegate: RouteBrokenToolbarViewDelegate? = nil

    lazy var stackScrollView: ORStackScrollView = {
        let scroll = ORStackScrollView()
        scroll.stackView.direction = .Horizontal
        scroll.pagingEnabled = true
        scroll.alwaysBounceHorizontal = false
        scroll.showsHorizontalScrollIndicator = false
        scroll.delegate = self
        return scroll
    }()

    let pageControl: UIPageControl = {
        let pageControl = UIPageControl()
        pageControl.pageIndicatorTintColor = Styler.foregroundSecondaryColor()
        pageControl.currentPageIndicatorTintColor = Styler.tintColor()
        return pageControl
    }()

    var currentPage: Int = 0 {
        didSet {
            if oldValue != currentPage {
                pageControl.currentPage = currentPage
                delegate?.didChangePage(currentPage)
            }
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        updateToViews([])
    }
    
    func updateToRoutes(routes: [RouteComposite]) {
        let views = routes.map { RouteBrokenView(route: $0) }
        updateToViews(views)
    }

    func updateToViews(views: [UIView]) {
        if stackScrollView.superview == nil {
            contentView.addSubview(stackScrollView)
            stackScrollView.setTranslatesAutoresizingMaskIntoConstraints(false)
            addConstraints([
                NSLayoutConstraint(item: stackScrollView, attribute: .Top, relatedBy: .Equal, toItem: contentView, attribute: .Top, multiplier: 1, constant: 5),
                NSLayoutConstraint(item: stackScrollView, attribute: .Left, relatedBy: .Equal, toItem: contentView, attribute: .Left, multiplier: 1, constant: 0),
                NSLayoutConstraint(item: stackScrollView, attribute: .Right, relatedBy: .GreaterThanOrEqual, toItem: contentView, attribute: .Right, multiplier: 1, constant: 0)
                ])
        }
        if pageControl.superview == nil {
            contentView.addSubview(pageControl)
            pageControl.setTranslatesAutoresizingMaskIntoConstraints(false)
            addConstraints([
                NSLayoutConstraint(item: pageControl, attribute: .Top, relatedBy: .Equal, toItem: stackScrollView, attribute: .Bottom, multiplier: 1, constant: 0),
                NSLayoutConstraint(item: pageControl, attribute: .Left, relatedBy: .Equal, toItem: contentView, attribute: .Left, multiplier: 1, constant: 0),
                NSLayoutConstraint(item: pageControl, attribute: .Right, relatedBy: .GreaterThanOrEqual, toItem: contentView, attribute: .Right, multiplier: 1, constant: 0),
                NSLayoutConstraint(item: pageControl, attribute: .Bottom, relatedBy: .Equal, toItem: contentView, attribute: .Bottom, multiplier: 1, constant: 0),
                NSLayoutConstraint(item: pageControl, attribute: .Height, relatedBy: .Equal, toItem: nil, attribute: .NotAnAttribute, multiplier: 1, constant: 28)
                ])
        }

        let stack = stackScrollView.stackView
        stack.removeAllSubviews()
        for view in views {
            stack.addSubview(view, withPrecedingMargin: 0, sideMargin: 0)
            addConstraint(NSLayoutConstraint(item: view, attribute: .Width, relatedBy: .Equal, toItem: contentView, attribute: .Width, multiplier: 1, constant: 0))
        }
        if views.count == 0 {
            let activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: .WhiteLarge)
            activityIndicator.color = Styler.tintColor()
            activityIndicator.startAnimating()
            stack.addSubview(activityIndicator, withPrecedingMargin: 0, sideMargin: 0)
            addConstraint(NSLayoutConstraint(item: activityIndicator, attribute: .Width, relatedBy: .Equal, toItem: contentView, attribute: .Width, multiplier: 1, constant: 0))
            addConstraint(NSLayoutConstraint(item: activityIndicator, attribute: .Height, relatedBy: .Equal, toItem: contentView, attribute: .Height, multiplier: 1, constant: -5))
        }

        // Page control
        pageControl.currentPage = 0
        pageControl.numberOfPages = views.count
        pageControl.hidden = views.count < 1
    }
}

extension RouteBrokenToolbarView: UIScrollViewDelegate {

    func scrollViewDidScroll(scrollView: UIScrollView) {
        if scrollView == stackScrollView {
            let pageWidth = scrollView.frame.width
            let page = Int(floor((scrollView.contentOffset.x * 2.0 + pageWidth) / (pageWidth * 2.0)))
            currentPage = page
        }
    }
}