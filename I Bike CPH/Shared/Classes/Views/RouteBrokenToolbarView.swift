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
    func didChangePage(_ page: Int)
}

class RouteBrokenToolbarView: ToolbarView {

    @IBOutlet weak var contentView: UIView!
    var delegate: RouteBrokenToolbarViewDelegate? = nil

    lazy var stackScrollView: ORStackScrollView = {
        let scroll = ORStackScrollView()
        scroll.stackView.direction = .horizontal
        scroll.isPagingEnabled = true
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
    
    func updateToRoutes(_ routes: [RouteComposite]) {
        let views = routes.map { RouteBrokenView(route: $0) }
        updateToViews(views)
    }

    func updateToViews(_ views: [UIView]) {
        if stackScrollView.superview == nil {
            contentView.addSubview(stackScrollView)
            stackScrollView.translatesAutoresizingMaskIntoConstraints = false
            addConstraints([
                NSLayoutConstraint(item: stackScrollView, attribute: .top, relatedBy: .equal, toItem: contentView, attribute: .top, multiplier: 1, constant: 5),
                NSLayoutConstraint(item: stackScrollView, attribute: .left, relatedBy: .equal, toItem: contentView, attribute: .left, multiplier: 1, constant: 0),
                NSLayoutConstraint(item: stackScrollView, attribute: .right, relatedBy: .greaterThanOrEqual, toItem: contentView, attribute: .right, multiplier: 1, constant: 0)
                ])
        }
        if pageControl.superview == nil {
            contentView.addSubview(pageControl)
            pageControl.translatesAutoresizingMaskIntoConstraints = false
            addConstraints([
                NSLayoutConstraint(item: pageControl, attribute: .top, relatedBy: .equal, toItem: stackScrollView, attribute: .bottom, multiplier: 1, constant: 0),
                NSLayoutConstraint(item: pageControl, attribute: .left, relatedBy: .equal, toItem: contentView, attribute: .left, multiplier: 1, constant: 0),
                NSLayoutConstraint(item: pageControl, attribute: .right, relatedBy: .greaterThanOrEqual, toItem: contentView, attribute: .right, multiplier: 1, constant: 0),
                NSLayoutConstraint(item: pageControl, attribute: .bottom, relatedBy: .equal, toItem: contentView, attribute: .bottom, multiplier: 1, constant: 0),
                NSLayoutConstraint(item: pageControl, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 28)
                ])
        }

        let stack = stackScrollView.stackView
        stack?.removeAllSubviews()
        for view in views {
            stack?.addSubview(view, withPrecedingMargin: 0, sideMargin: 0)
            addConstraint(NSLayoutConstraint(item: view, attribute: .width, relatedBy: .equal, toItem: contentView, attribute: .width, multiplier: 1, constant: 0))
        }
        if views.count == 0 {
            let activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: .whiteLarge)
            activityIndicator.color = Styler.tintColor()
            activityIndicator.startAnimating()
            stack?.addSubview(activityIndicator, withPrecedingMargin: 0, sideMargin: 0)
            addConstraint(NSLayoutConstraint(item: activityIndicator, attribute: .width, relatedBy: .equal, toItem: contentView, attribute: .width, multiplier: 1, constant: 0))
            addConstraint(NSLayoutConstraint(item: activityIndicator, attribute: .height, relatedBy: .equal, toItem: contentView, attribute: .height, multiplier: 1, constant: -5))
        }

        // Page control
        pageControl.currentPage = 0
        pageControl.numberOfPages = views.count
        pageControl.isHidden = views.count < 1
    }
}

extension RouteBrokenToolbarView: UIScrollViewDelegate {

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView == stackScrollView {
            let pageWidth = scrollView.frame.width
            let page = Int(floor((scrollView.contentOffset.x * 2.0 + pageWidth) / (pageWidth * 2.0)))
            currentPage = page
        }
    }
}
