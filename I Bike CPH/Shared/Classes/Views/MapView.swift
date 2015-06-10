//
//  MapView.swift
//  I Bike CPH
//
//  Created by Tobias Due Munk on 04/06/15.
//  Copyright (c) 2015 I Bike CPH. All rights reserved.
//

import UIKit
import MapboxGL


protocol MapViewDelegate {
    func didSelectCoordinate(coordinate: CLLocationCoordinate2D)
}


class MapView: UIView {
    
    let mapView: MGLMapView = {
        MGLAccountManager.setMapboxMetricsEnabledSettingShownInApp(true)
        let initRect = CGRect(x: 0, y: 0, width: 1, height: 1) // Has to has some height and width
        let map = MGLMapView(frame: initRect, accessToken: "pk.eyJ1IjoidG9iaWFzZG0iLCJhIjoiTDZabnJEVSJ9.vrLJuuThWDNBmf157JY2FQ")
        map.styleURL = NSURL(string: "asset://styles/mapbox-streets-v7.json")
        return map
    }()
    
    var delegate: MapViewDelegate?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    init() {
        super.init(frame: CGRectZero)
        setup()
    }
    
    func setup() {
        addSubview(mapView)
        
        // Add long-press to drop pin
        let longPress = UILongPressGestureRecognizer(target: self, action: "didLongPress:")
        mapView.addGestureRecognizer(longPress)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
    
        mapView.frame = max(bounds.width, bounds.height) == 0 ? CGRect(x: 0, y: 0, width: 1, height: 1) : bounds
    }
    
    func didLongPress(gesture: UILongPressGestureRecognizer) {
        if gesture.state == .Began {
            let point = gesture.locationInView(mapView)
            let coordinate = mapView.convertPoint(point, toCoordinateFromView: mapView)
            delegate?.didSelectCoordinate(coordinate)
        }
    }
}
