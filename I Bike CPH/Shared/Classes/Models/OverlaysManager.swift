//
//  OverlaysManager.swift
//  I Bike CPH
//
//  Created by Tobias Due Munk on 08/01/15.
//  Copyright (c) 2015 I Bike CPH. All rights reserved.
//

import Foundation
import SwiftyJSON
import SwiftyUserDefaults
import SwiftHEXColors

let overlaysUpdatedNotification = "overlaysUpdatedNotification"

enum OverlayType {
    case CycleSuperHighways
    case BikeServiceStations
    case HarborRing
    case GreenPaths
    
    var localizedDescription: String {
        switch self {
            case .CycleSuperHighways: return "cycle_super_highways".localized
            case .BikeServiceStations: return "service_stations".localized
            case .HarborRing: return "harbor_ring".localized
            case .GreenPaths: return "green_paths".localized
        }
    }
}

extension DefaultsKeys {
    // Saved Overlays GeoJSON
    static let harborRingGeoJSON = DefaultsKey<Dictionary<String,AnyObject>?>("harborRingGeoJSON")
    static let greenPathsGeoJSON = DefaultsKey<Dictionary<String,AnyObject>?>("greenPathsGeoJSON")
}

@objc class OverlaysManager: NSObject {
    
    static let sharedInstance = OverlaysManager()
    
    private struct OverlayAnnotations {
        var locations = [[CLLocationCoordinate2D]]()
        var color = Styler.tintColor().colorWithAlphaComponent(0.5)
        var annotations = [Annotation]()
        var type: OverlayType
        
        init(type: OverlayType, json: JSON) {
            self.type = type
            switch self.type {
            case .BikeServiceStations:
                self.setImageLocationsFromJSON(json)
            case .CycleSuperHighways, .HarborRing, .GreenPaths:
                self.setPathLocationsFromGeoJSON(json)
                self.setColorFromGeoJSON(json)
            }
        }
        
        mutating func updateAnnotations(mapView: MapView?) {
            guard let mv = mapView else {
                return
            }
            switch self.type {
            case .BikeServiceStations:
                self.setMarkerAnnotations(mv)
            case .CycleSuperHighways, .HarborRing, .GreenPaths:
                self.setPathAnnotations(mv)
            }
        }
        
        mutating func updateOverlay(mapView: MapView?) {
            guard let mv = mapView else {
                return
            }
            let settings = Settings.sharedInstance
            var overlayEnabled: Bool
            switch self.type {
            case .CycleSuperHighways:
                overlayEnabled = settings.overlays.showCycleSuperHighways
            case .BikeServiceStations:
                overlayEnabled = settings.overlays.showBikeServiceStations
            case .HarborRing:
                overlayEnabled = settings.overlays.showHarborRing
            case .GreenPaths:
                overlayEnabled = settings.overlays.showGreenPaths
            }
            mv.removeAnnotations(self.annotations)
            if (overlayEnabled) {
                mv.addAnnotations(self.annotations)
            }
        }
        
        private mutating func setPathAnnotations(mapView: MapView) {
            mapView.removeAnnotations(self.annotations)
            self.annotations = []
            for locations in self.locations {
                let annotation = mapView.addPath(locations, lineColor: self.color, lineWidth: 4.0)
                mapView.removeAnnotation(annotation)
                self.annotations.append(annotation)
            }
        }
        
        private mutating func setMarkerAnnotations(mapView: MapView) {
            mapView.removeAnnotations(self.annotations)
            self.annotations = []
            for coordinates in self.locations {
                for coordinate in coordinates {
                    let annotation = ServiceStationsAnnotation(mapView: mapView, coordinate: coordinate)
                    mapView.removeAnnotation(annotation)
                    self.annotations.append(annotation)
                }
            }
        }
        
        private mutating func setImageLocationsFromJSON(json: JSON) {
            self.locations.removeAll()
            guard let stations = json["stations"].array else {
                return
            }
            for station in stations {
                guard let type = station["type"].string where type == "service" else {
                    continue
                }
                guard let coordinates = station["coords"].string else {
                    continue
                }
                let scalars = coordinates.componentsSeparatedByString(" ")
                guard scalars.count == 2 else {
                    continue
                }
                let formatter = NSNumberFormatter()
                formatter.locale = NSLocale(localeIdentifier: "en_US")
                if let latitude = formatter.numberFromString(scalars[0])?.doubleValue,
                       longitude = formatter.numberFromString(scalars[1])?.doubleValue {
                    let coordinate = CLLocationCoordinate2DMake(longitude, latitude)
                    self.locations.append([coordinate])
                }
            }
        }
        
        private mutating func setPathLocationsFromGeoJSON(json: JSON) {
            self.locations.removeAll()
            guard let features = json["features"].array else {
                return
            }
            for feature in features {
                guard let coordinates = feature["geometry", "coordinates"].array else {
                    continue
                }
                var featureLocations = [CLLocationCoordinate2D]()
                for coordinate in coordinates {
                    if let longitude = coordinate[0].double, latitude = coordinate[1].double {
                        featureLocations.append(CLLocationCoordinate2D(latitude: latitude, longitude: longitude))
                    }
                }
                self.locations.append(featureLocations)
            }
        }
        
        private mutating func setColorFromGeoJSON(json: JSON) {
            self.color = Styler.tintColor().colorWithAlphaComponent(0.5)
            guard let colorString = json["properties", "color"].string else {
                return
            }
            if let color = UIColor(hexString: colorString, alpha: 0.66) {
                self.color = color
            }
        }
        
    }
    
    private var cycleSuperHighwayAnnotations: OverlayAnnotations? {
        didSet {
            self.cycleSuperHighwayAnnotations?.updateAnnotations(self.mapView)
            self.cycleSuperHighwayAnnotations?.updateOverlay(self.mapView)
        }
    }
    private var bikeServiceAnnotations: OverlayAnnotations? {
        didSet {
            self.bikeServiceAnnotations?.updateAnnotations(self.mapView)
            self.bikeServiceAnnotations?.updateOverlay(self.mapView)
        }
    }
    private var harborRingAnnotations: OverlayAnnotations? {
        didSet {
            self.harborRingAnnotations?.updateAnnotations(self.mapView)
            self.harborRingAnnotations?.updateOverlay(self.mapView)
            NotificationCenter.post(overlaysUpdatedNotification, object: self)
        }
    }
    private var greenPathsAnnotations: OverlayAnnotations? {
        didSet {
            self.greenPathsAnnotations?.updateAnnotations(self.mapView)
            self.greenPathsAnnotations?.updateOverlay(self.mapView)
            NotificationCenter.post(overlaysUpdatedNotification, object: self)
        }
    }
    
    var mapView: MapView? {
        didSet {
            self.updateAllAnnotations()
            self.updateAllOverlays()
        }
    }
    
    override init() {
        super.init()
        fetchData()
        
        // Since the class is a singleton there's no need to unobserve
        NotificationCenter.observe(settingsUpdatedNotification) { [weak self] notification in
            self?.updateAllOverlays()
        }
    }
    
    private func fetchData() {
        if let json = self.JSONFromFile("cycle_super_highways", fileExtension: "geojson") {
            self.cycleSuperHighwayAnnotations = OverlayAnnotations(type: .CycleSuperHighways, json: json)
        }
        
        if let json = self.JSONFromFile("stations", fileExtension: "json") {
            self.bikeServiceAnnotations = OverlayAnnotations(type: .BikeServiceStations, json: json)
        }
        
        OverlaysClient.sharedInstance.requestOverlaysGeoJSON("havneringen") { result in
            switch result {
                case .Success(let json):
                    self.harborRingAnnotations = OverlayAnnotations(type: .HarborRing, json: json)
                    if let dictionary = json.dictionaryObject {
                        Defaults[.harborRingGeoJSON] = dictionary
                    }
                default:
                    // Try to use cached GeoJSON data if available
                    if let dictionary = Defaults[.harborRingGeoJSON] {
                        self.harborRingAnnotations = OverlayAnnotations(type: .HarborRing, json: JSON(dictionary))
                    }
            }
        }
        
        OverlaysClient.sharedInstance.requestOverlaysGeoJSON("groenne_stier") { result in
            switch result {
                case .Success(let json):
                    self.greenPathsAnnotations = OverlayAnnotations(type: .GreenPaths, json: json)
                    if let dictionary = json.dictionaryObject {
                        Defaults[.greenPathsGeoJSON] = dictionary
                    }
                default:
                    // Try to use cached GeoJSON data if available
                    if let dictionary = Defaults[.greenPathsGeoJSON] {
                        self.greenPathsAnnotations = OverlayAnnotations(type: .GreenPaths, json: JSON(dictionary))
                    }
            }
        }
    }
    
    private func annotationOfType(type: OverlayType) -> OverlayAnnotations? {
        switch type {
        case .CycleSuperHighways:
            return self.cycleSuperHighwayAnnotations
        case .BikeServiceStations:
            return self.bikeServiceAnnotations
        case .HarborRing:
            return self.harborRingAnnotations
        case .GreenPaths:
            return self.greenPathsAnnotations
        }
    }
    
    func titleForOverlay(type: OverlayType) -> String {
        guard self.annotationOfType(type) != nil else {
            return type.localizedDescription + " (" + "not_currently_available".localized + ")"
        }
        return type.localizedDescription
    }
    
    func iconImageForOverlay(type: OverlayType) -> UIImage? {
        let iconWidth: CGFloat = 22
        switch type {
            case .CycleSuperHighways: return UIImage(named: "SuperCycleHighway")
            case .BikeServiceStations: return UIImage(named: "serviceStation")
            case .HarborRing, .GreenPaths:
                guard let annotations = self.annotationOfType(type) else {
                    return poPathOverlayIconImage(width: iconWidth, color: UIColor.grayColor())
                }
                return poPathOverlayIconImage(width: iconWidth, color: annotations.color)
        }
    }
    
    func isOverlaySelected(type: OverlayType) -> Bool {
        switch type {
            case .CycleSuperHighways: return Settings.sharedInstance.overlays.showCycleSuperHighways
            case .BikeServiceStations: return Settings.sharedInstance.overlays.showBikeServiceStations
            case .HarborRing: return Settings.sharedInstance.overlays.showHarborRing
            case .GreenPaths: return Settings.sharedInstance.overlays.showGreenPaths
        }
    }
    
    func selectOverlay(selected: Bool, type: OverlayType) {
        switch type {
            case .CycleSuperHighways: Settings.sharedInstance.overlays.showCycleSuperHighways = selected
            case .BikeServiceStations: Settings.sharedInstance.overlays.showBikeServiceStations = selected
            case .HarborRing: Settings.sharedInstance.overlays.showHarborRing = selected
            case .GreenPaths: Settings.sharedInstance.overlays.showGreenPaths = selected
        }
    }
    
    func updateAllOverlays() {
        self.cycleSuperHighwayAnnotations?.updateOverlay(self.mapView)
        self.bikeServiceAnnotations?.updateOverlay(self.mapView)
        self.harborRingAnnotations?.updateOverlay(self.mapView)
        self.greenPathsAnnotations?.updateOverlay(self.mapView)
    }
    
    private func updateAllAnnotations() {
        self.cycleSuperHighwayAnnotations?.updateAnnotations(self.mapView)
        self.bikeServiceAnnotations?.updateAnnotations(self.mapView)
        self.harborRingAnnotations?.updateAnnotations(self.mapView)
        self.greenPathsAnnotations?.updateAnnotations(self.mapView)
    }
    
    private func JSONFromFile(filename: String, fileExtension: String) -> JSON? {
        guard let filePath = NSBundle.mainBundle().pathForResource(filename, ofType: fileExtension) else {
            return nil
        }
        guard let data = NSData(contentsOfFile: filePath) else {
            return nil
        }
        return JSON(data: data)
    }
}