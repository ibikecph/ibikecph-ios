//
//  FindRouteToolbarView.swift
//  I Bike CPH
//
//  Created by Tobias Due Munk on 04/06/15.
//  Copyright (c) 2015 I Bike CPH. All rights reserved.
//

import UIKit

protocol FindRouteToolbarDelegate: RouteTypeToolbarDelegate {
    func didSelectReverseRoute()
    func didSelectRoute()
    func didSelectFrom()
    func didSelectTo()
}

class FindRouteToolbarView: ToolbarView {

    var delegate: FindRouteToolbarDelegate? {
        didSet {
            routeTypeToolbarView.delegate = delegate
        }
    }

    var showBrokenRoute: Bool = false {
        didSet {
            if showBrokenRoute {
                extraToolbarViewContainer.add(toolbarView: brokenRouteToolbarView)
                setNeedsLayout()
                setNeedsUpdateConstraints()
                return
            }
            extraToolbarViewContainer.removeToolbar()
        }
    }

    let brokenRouteToolbarView: RouteBrokenToolbarView = RouteBrokenToolbarView()
    
    @IBOutlet weak var fromButton: UIButton!
    @IBOutlet weak var toButton: UIButton!
    @IBOutlet weak var routeButton: UIButton!
    @IBOutlet weak var routeTypeToolbarView: RouteTypeToolbarView!
    @IBOutlet weak var routeStatsToolbarView: RouteStatsToolbarView!
    @IBOutlet weak var extraToolbarViewContainer: ToolbarViewContainer!
    
    @IBOutlet weak var reverseRouteButton: UIButton!
    
    @IBAction func didTapReverseItems(_ sender: AnyObject) {
        delegate?.didSelectReverseRoute()
    }
    @IBAction func didTapRoute(_ sender: AnyObject) {
        delegate?.didSelectRoute()
    }
    @IBAction func didTapFromButton(_ sender: AnyObject) {
        delegate?.didSelectFrom()
    }
    @IBAction func didTapToButton(_ sender: AnyObject) {
        delegate?.didSelectTo()
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        fromButton.updateToItem(nil)
        toButton.updateToItem(nil)
        routeButton.isEnabled = false
    }
    
}

extension FindRouteToolbarView {
    
    func updateWithFromItem(_ fromItem: SearchListItem?, toItem: SearchListItem?) {
        fromButton.updateToItem(fromItem)
        toButton.updateToItem(toItem)
        routeButton.isEnabled = fromItem != nil && toItem != nil
        reverseRouteButton.isEnabled = fromItem?.type != .currentLocation
    }
}

private extension UIButton {
    func updateToItem(_ item: SearchListItem?) {
        let title: String? = {
            if let item = item {
                return item.name
            }
            return nil
        }()
        setTitle(title, for: UIControlState())
    }
}
