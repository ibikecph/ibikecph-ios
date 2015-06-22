//
//  MapView.swift
//  I Bike CPH
//
//  Created by Tobias Due Munk on 04/06/15.
//  Copyright (c) 2015 I Bike CPH. All rights reserved.
//

import UIKit


protocol MapViewTrackingDelegate {
    func didChangeUserTrackingMode(mode: MapView.UserTrackingMode)
}
protocol MapViewDelegate {
    func didSelectCoordinate(coordinate: CLLocationCoordinate2D)
    func didSelectAnnotation(annotation: Annotation)
}

//private class TileSource: RMAbstractWebMapSource {
//    
//    override init() {
//        super.init()
//        minZoom = 4
//        maxZoom = Float(MAX_MAP_ZOOM)
//    }
//    
//    override func URLForTile(tile: RMTile) -> NSURL! {
//        let urlString = "http://tiles.ibikecph.dk/tiles/\(tile.zoom)/\(tile.x)/\(tile.y).png"
//        let url = NSURL(string: urlString)
//        return url!
//    }
//    
//    
//    
////    func shortName() -> String {
////        return "I Bike CPH"
////    }
////    override let shortName = "I Bike CPH"
//    private(set) override var shortName = "I Bike CPH"
//}


extension RMUserTrackingMode: Equatable {}
public func ==(lhs: RMUserTrackingMode, rhs: RMUserTrackingMode) -> Bool {
    return lhs.value == rhs.value
}


class MapView: UIView {
    
    enum UserTrackingMode: Int {
        case None, Follow, FollowWithHeading
        
        func rmUserTrackingMode() -> RMUserTrackingMode {
            switch self {
                case .None: return RMUserTrackingModeNone
                case .Follow: return RMUserTrackingModeFollow
                case .FollowWithHeading: return RMUserTrackingModeFollowWithHeading
            }
        }
        
        static func build(rmUserTrackingMode: RMUserTrackingMode) -> UserTrackingMode {
            switch rmUserTrackingMode {
                case RMUserTrackingModeNone: return .None
                case RMUserTrackingModeFollow: return .Follow
                case RMUserTrackingModeFollowWithHeading: return .FollowWithHeading
                default: return .None
            }
        }
    }
    
    private(set) lazy var mapView: RMMapView = {
        let tileSource = SMiBikeCPHMapTileSource()
        let rect = CGRect(x: 0, y: 0, width: 1, height: 1)
        RMConfiguration.sharedInstance().accessToken = "pk.eyJ1IjoidG9iaWFzZG0iLCJhIjoiTDZabnJEVSJ9.vrLJuuThWDNBmf157JY2FQ"
        let map = RMMapView(frame: rect, andTilesource: tileSource)
        return map
    }()
    
    var delegate: MapViewDelegate?
    var trackingDelegate: MapViewTrackingDelegate?
    
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
        
        mapView.delegate = self
        
        // Add long-press to drop pin
        let longPress = UILongPressGestureRecognizer(target: self, action: "didLongPress:")
        mapView.addGestureRecognizer(longPress)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
    
        mapView.frame = max(bounds.width, bounds.height) == 0 ? CGRect(x: 0, y: 0, width: 1, height: 1) : bounds
    }

    func addPath(coordinates: [CLLocationCoordinate2D], lineColor: UIColor = Styler.tintColor()) -> Annotation {
    
        // Annotation
        var pathAnnotation = Annotation()
        pathAnnotation.mapView = mapView
        mapView.addAnnotation(pathAnnotation)
        // Shape
        var shape = RMShape(view: mapView)
        if let firstCoordinate = coordinates.first {
            pathAnnotation.coordinate = firstCoordinate
        }
        shape.lineColor = lineColor
        shape.lineWidth = 4.0
        shape.lineJoin = "round"
        shape.lineCap = "round"
        pathAnnotation.layer = shape
        // Add coordinates
        var waypoints: [CLLocation] = [CLLocation]()
        for coordinate in coordinates {
            shape.addLineToCoordinate(coordinate)
            let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
            waypoints.append(location)
        }
        // Bounding box
        pathAnnotation.setBoundingBoxFromLocations(waypoints)
        
        mapView.setNeedsDisplay() // Bug in RMMapView. Workaround to make sure it renders added path
        
        return pathAnnotation
    }
    
    func zoomToAnnotation(annotation: Annotation, animated: Bool = true, padding: Double = 0.2) {
        // Padding
        let bounds = mapView.sphericalTrapezium(forProjectedRect: annotation.projectedBoundingBox).padded(padding: padding)
        // Zoom
        mapView.zoomWithLatitudeLongitudeBoundsSouthWest(bounds.southWest, northEast: bounds.northEast, animated: animated)
    }
}


/// Proxy for RMMapView
extension MapView {
    var centerCoordinate: CLLocationCoordinate2D {
        set {
            mapView.centerCoordinate = newValue
        }
        get {
            return mapView.centerCoordinate
        }
    }
    var zoomLevel: Double {
        set {
            mapView.zoom = Float(newValue)
        }
        get {
            return Double(mapView.zoom)
        }
    }
    var showsUserLocation: Bool {
        set {
            mapView.showsUserLocation = newValue
        }
        get {
            return mapView.showsUserLocation
        }
    }
    var userTrackingMode: UserTrackingMode {
        set {
            mapView.userTrackingMode = newValue.rmUserTrackingMode()
        }
        get {
            return UserTrackingMode.build(mapView.userTrackingMode)
        }
    }
    func centerCoordinate(coordinate: CLLocationCoordinate2D, zoomLevel: Double, animated: Bool = true) {
        mapView.setZoom(Float(zoomLevel), atCoordinate: coordinate, animated: animated)
    }
    func addAnnotation(annotation: Annotation) {
        mapView.addAnnotation(annotation)
    }
    func addAnnotations(annotations: [Annotation]) {
        mapView.addAnnotations(annotations)
    }
    func removeAnnotation(annotation: Annotation) {
        mapView.removeAnnotation(annotation)
    }
    func removeAnnotations(annotations: [Annotation]) {
        mapView.removeAnnotations(annotations)
    }
    func removeAllAnnotations() {
        mapView.removeAllAnnotations()
    }
}


extension MapView: RMMapViewDelegate {
    
    func mapView(mapView: RMMapView, didSelectAnnotation annotation: RMAnnotation) {
        if let annotation = annotation as? Annotation {
            delegate?.didSelectAnnotation(annotation)
        }
    }
    
    func longPressOnMap(map: RMMapView, at point: CGPoint) {
        let coordinate = mapView.pixelToCoordinate(point)
        delegate?.didSelectCoordinate(coordinate)
    }
    
    func mapView(mapView: RMMapView, didChangeUserTrackingMode mode: RMUserTrackingMode, animated: Bool) {
        let mode = UserTrackingMode.build(mode)
        trackingDelegate?.didChangeUserTrackingMode(mode)
    }
    
    func mapView(mapView: RMMapView!, layerForAnnotation annotation: RMAnnotation!) -> RMMapLayer! {
        if annotation.annotationType == nil {
            return nil
        }
        switch annotation.annotationType {
            case "marker", "station":
                let marker = RMMarker(UIImage: annotation.annotationIcon, anchorPoint: annotation.anchorPoint)
                return marker
            case "path":
                let path = RMShape(view: mapView)
                path.zPosition = CGFloat(-FLT_MAX)
                let userInfo = annotation.userInfo as? [String : AnyObject]
                path.lineColor = userInfo?["lineColor"] as? UIColor ?? Styler.tintColor()
                path.lineWidth = userInfo?["lineWidth"] as? Float ?? 1
                path.scaleLineWidth = false
                path.opacity = PATH_OPACITY
                path.fillColor = userInfo?["fillColor"] as? UIColor ?? Styler.backgroundColor()
                if let closePath = userInfo?["closePath"] as? Bool where closePath {
                    path.closePath()
                }
                if let locations = userInfo?["linePoints"] as? [CLLocation] {
                    for location in locations {
                        path.addLineToCoordinate(location.coordinate)
                    }
                }
                return path
            case "line":
                let line = RMShape(view: mapView)
                line.zPosition = CGFloat(-FLT_MAX)
                let userInfo = annotation.userInfo as? [String : AnyObject]
                line.lineColor = userInfo?["lineColor"] as? UIColor ?? Styler.tintColor()
                line.lineWidth = userInfo?["lineWidth"] as? Float ?? 1
                line.scaleLineWidth = true
                line.opacity = PATH_OPACITY
                line.fillColor = userInfo?["fillColor"] as? UIColor ?? Styler.backgroundColor()
                if let
                    start = userInfo?["lineStart"] as? CLLocation,
                    end = userInfo?["lineStart"] as? CLLocation
                {
                    line.addLineToCoordinate(start.coordinate)
                    line.addLineToCoordinate(end.coordinate)
                }
                return line
            default:
                return nil
        }
    }
}


extension RMSphericalTrapezium {
    func padded(padding: Double = 0.2) -> RMSphericalTrapezium {
        var northEast = self.northEast
        var southWest = self.southWest
        
        let latitudeDiff = abs(northEast.latitude - southWest.latitude)
        let longitudeDiff = abs(northEast.longitude - southWest.longitude)
        
        northEast.latitude += latitudeDiff * padding;
        northEast.longitude += longitudeDiff * padding;
        
        southWest.latitude -= latitudeDiff * padding;
        southWest.longitude -= longitudeDiff * padding;
        
        return RMSphericalTrapezium(southWest: southWest, northEast: northEast)
    }
}


extension RMMapView {
    func sphericalTrapezium(forProjectedRect rect: RMProjectedRect) -> RMSphericalTrapezium {
        let neProjected = RMProjectedPoint(x: rect.origin.x + rect.size.width, y: rect.origin.y + rect.size.height)
        var ne = projectedPointToCoordinate(neProjected)
        let swProjected = RMProjectedPoint(x: rect.origin.x, y: rect.origin.y )
        var sw = projectedPointToCoordinate(swProjected)
        return RMSphericalTrapezium(southWest: sw, northEast: ne)
    }
}

