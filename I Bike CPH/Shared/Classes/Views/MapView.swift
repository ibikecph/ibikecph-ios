//
//  MapView.swift
//  I Bike CPH
//
//  Created by Tobias Due Munk on 04/06/15.
//  Copyright (c) 2015 I Bike CPH. All rights reserved.
//

import UIKit
import MapboxGL


class MapView: UIView {
    
//    var location: CLLocation? {
//        didSet {
//            if let location = location {
//                mapView.setCenterCoordinate(location.coordinate, zoomLevel: zoomLevel, animated: true)
//            }
//            setAnnotation(location)
//        }
//    }
    let mapView: MGLMapView = {
        MGLAccountManager.setMapboxMetricsEnabledSettingShownInApp(true)
        let initRect = CGRect(x: 0, y: 0, width: 1, height: 1) // Has to has some height and width
        let map = MGLMapView(frame: initRect, accessToken: "pk.eyJ1IjoidG9iaWFzZG0iLCJhIjoiTDZabnJEVSJ9.vrLJuuThWDNBmf157JY2FQ")
        map.styleURL = NSURL(string: "asset://styles/mapbox-streets-v7.json")
        return map
    }()
    
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
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
    
        mapView.frame = max(bounds.width, bounds.height) == 0 ? CGRect(x: 0, y: 0, width: 1, height: 1) : bounds
    }
    
    private func setAnnotation(location: CLLocation?) {
        // Remove all
        mapView.removeAnnotations(mapView.annotations)
        // Add new
        if let location = location {
            let annotation = Annotation(location: location)
            mapView.addAnnotation(annotation)
        }
    }
}

class Annotation: NSObject, MGLAnnotation {
    
    @objc var coordinate: CLLocationCoordinate2D
    init(location: CLLocation) {
        coordinate = location.coordinate
    }
}
