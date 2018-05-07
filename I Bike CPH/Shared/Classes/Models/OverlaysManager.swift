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
    case cycleSuperHighways
    case bikeServiceStations
    case harborRing
    case greenPaths
    
    var localizedDescription: String {
        switch self {
            case .cycleSuperHighways: return "cycle_super_highways".localized
            case .bikeServiceStations: return "service_stations".localized
            case .harborRing: return "harbor_ring".localized
            case .greenPaths: return "green_paths".localized
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
    
    let availableOverlays: [OverlayType] = {
        if macro.isCykelPlanen {
            return [
//                .CycleSuperHighways,
//                .BikeServiceStations
            ]
        }
        if macro.isIBikeCph {
            return [
                .harborRing,
                .greenPaths
            ]
        }
        return []
    }()
    
    fileprivate struct OverlayAnnotations {
        var locations = [[CLLocationCoordinate2D]]()
        var color = Styler.tintColor().withAlphaComponent(0.5)
        var name = ""
        var annotations = [Annotation]()
        var type: OverlayType
        
        init(type: OverlayType, json: JSON) {
            self.type = type
            switch self.type {
            case .bikeServiceStations:
                self.setImageLocationsFromJSON(json)
            case .cycleSuperHighways, .harborRing, .greenPaths:
                self.setPathLocationsFromGeoJSON(json)
                self.setColorFromGeoJSON(json)
                self.setNameFromGeoJSON(json)
            }
        }
        
        mutating func updateAnnotations(_ mapView: MapView?) {
            guard let mv = mapView else {
                return
            }
            switch self.type {
            case .bikeServiceStations:
                self.setMarkerAnnotations(mv)
            case .cycleSuperHighways, .harborRing, .greenPaths:
                self.setPathAnnotations(mv)
            }
        }
        
        mutating func updateOverlay(_ mapView: MapView?) {
            guard let mv = mapView else {
                return
            }
            let settings = Settings.sharedInstance
            var overlayEnabled: Bool
            switch self.type {
            case .cycleSuperHighways:
                overlayEnabled = settings.overlays.showCycleSuperHighways
            case .bikeServiceStations:
                overlayEnabled = settings.overlays.showBikeServiceStations
            case .harborRing:
                overlayEnabled = settings.overlays.showHarborRing
            case .greenPaths:
                overlayEnabled = settings.overlays.showGreenPaths
            }
            // If Overlay is not even available then it should always be disabled
            // This can happen if an overlay has turn unavailable from one app version to the next
            overlayEnabled = overlayEnabled && OverlaysManager.sharedInstance.availableOverlays.contains(self.type)
            mv.removeAnnotations(self.annotations)
            if (overlayEnabled) {
                mv.addAnnotations(self.annotations)
            }
        }
        
        fileprivate mutating func setPathAnnotations(_ mapView: MapView) {
            mapView.removeAnnotations(self.annotations)
            self.annotations = []
            for locations in self.locations {
                let annotation = mapView.addPath(locations, lineColor: self.color, lineWidth: 4.0)
                mapView.removeAnnotation(annotation)
                self.annotations.append(annotation)
            }
        }
        
        fileprivate mutating func setMarkerAnnotations(_ mapView: MapView) {
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
        
        fileprivate mutating func setImageLocationsFromJSON(_ json: JSON) {
            self.locations.removeAll()
            guard let stations = json["stations"].array else {
                return
            }
            for station in stations {
                guard let type = station["type"].string, type == "service" else {
                    continue
                }
                guard let coordinates = station["coords"].string else {
                    continue
                }
                let scalars = coordinates.components(separatedBy: " ")
                guard scalars.count == 2 else {
                    continue
                }
                let formatter = NumberFormatter()
                formatter.locale = Locale(localeIdentifier: "en_US")
                if let latitude = formatter.number(from: scalars[0])?.doubleValue,
                       let longitude = formatter.number(from: scalars[1])?.doubleValue {
                    let coordinate = CLLocationCoordinate2DMake(longitude, latitude)
                    self.locations.append([coordinate])
                }
            }
        }
        
        fileprivate mutating func setPathLocationsFromGeoJSON(_ json: JSON) {
            self.locations.removeAll()
            guard let features = json["features"].array else {
                return
            }
            for feature in features {
                guard let type = feature["geometry","type"].string, let coordinates = feature["geometry","coordinates"].array else {
                    continue
                }
                if type == "LineString" {
                    self.locations.append(self.locationsFromCoordinatesArray(coordinates))
                }
                if type == "MultiLineString" {
                    for subArray in coordinates {
                        if let subCoordinatesArray = subArray.array {
                            self.locations.append(self.locationsFromCoordinatesArray(subCoordinatesArray))
                        }
                    }
                }
            }
        }
        
        fileprivate func locationsFromCoordinatesArray(_ coordinates: [JSON]) -> [CLLocationCoordinate2D] {
            var featureLocations = [CLLocationCoordinate2D]()
            for coordinate in coordinates {
                if let longitude = coordinate[0].double, let latitude = coordinate[1].double {
                    featureLocations.append(CLLocationCoordinate2D(latitude: latitude, longitude: longitude))
                }
            }
            return featureLocations
        }
        
        fileprivate mutating func setColorFromGeoJSON(_ json: JSON) {
            self.color = Styler.tintColor().withAlphaComponent(0.5)
            guard let colorString = json["properties", "color"].string else {
                return
            }
            if let color = UIColor(hexString: colorString, alpha: 0.66) {
                self.color = color
            }
        }
        
        fileprivate mutating func setNameFromGeoJSON(_ json: JSON) {
            self.name = self.type.localizedDescription
            
            // Default to English locale
            var localePrefix = "en"
            guard let preferredLocale = Locale.preferredLanguages.first else {
                return
            }
            if preferredLocale.hasPrefix("da") {
                localePrefix = "da"
            }
            guard let nameString = json["properties", "name", localePrefix].string else {
                return
            }
            self.name = nameString
        }
        
    }
    
    fileprivate var cycleSuperHighwayAnnotations: OverlayAnnotations? {
        didSet {
            self.cycleSuperHighwayAnnotations?.updateAnnotations(self.mapView)
            self.cycleSuperHighwayAnnotations?.updateOverlay(self.mapView)
        }
    }
    fileprivate var bikeServiceAnnotations: OverlayAnnotations? {
        didSet {
            self.bikeServiceAnnotations?.updateAnnotations(self.mapView)
            self.bikeServiceAnnotations?.updateOverlay(self.mapView)
        }
    }
    fileprivate var harborRingAnnotations: OverlayAnnotations? {
        didSet {
            self.harborRingAnnotations?.updateAnnotations(self.mapView)
            self.harborRingAnnotations?.updateOverlay(self.mapView)
            NotificationCenter.post(overlaysUpdatedNotification, object: self)
        }
    }
    fileprivate var greenPathsAnnotations: OverlayAnnotations? {
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
    
    fileprivate func fetchData() {
        if let json = self.JSONFromFile("cycle_super_highways", fileExtension: "geojson") {
            self.cycleSuperHighwayAnnotations = OverlayAnnotations(type: .cycleSuperHighways, json: json)
        }
        
        if let json = self.JSONFromFile("stations", fileExtension: "json") {
            self.bikeServiceAnnotations = OverlayAnnotations(type: .bikeServiceStations, json: json)
        }
        
        OverlaysClient.sharedInstance.requestOverlaysGeoJSON("havneringen") { result in
            switch result {
                case .success(let json):
                    self.harborRingAnnotations = OverlayAnnotations(type: .harborRing, json: json)
                    if let dictionary = json.dictionaryObject {
                        Defaults[.harborRingGeoJSON] = dictionary
                    }
                default:
                    // Try to use cached GeoJSON data if available
                    if let dictionary = Defaults[.harborRingGeoJSON] {
                        self.harborRingAnnotations = OverlayAnnotations(type: .harborRing, json: JSON(dictionary))
                    }
            }
        }
        
        OverlaysClient.sharedInstance.requestOverlaysGeoJSON("groenne_stier") { result in
            switch result {
                case .success(let json):
                    self.greenPathsAnnotations = OverlayAnnotations(type: .greenPaths, json: json)
                    if let dictionary = json.dictionaryObject {
                        Defaults[.greenPathsGeoJSON] = dictionary
                    }
                default:
                    // Try to use cached GeoJSON data if available
                    if let dictionary = Defaults[.greenPathsGeoJSON] {
                        self.greenPathsAnnotations = OverlayAnnotations(type: .greenPaths, json: JSON(dictionary))
                    }
            }
        }
    }
    
    fileprivate func annotationOfType(_ type: OverlayType) -> OverlayAnnotations? {
        switch type {
        case .cycleSuperHighways:
            return self.cycleSuperHighwayAnnotations
        case .bikeServiceStations:
            return self.bikeServiceAnnotations
        case .harborRing:
            return self.harborRingAnnotations
        case .greenPaths:
            return self.greenPathsAnnotations
        }
    }
    
    func titleForOverlay(_ type: OverlayType) -> String {
        guard let annotation = self.annotationOfType(type) else {
            return type.localizedDescription + " (" + "not_currently_available".localized + ")"
        }
        return annotation.name
    }
    
    func iconImageForOverlay(_ type: OverlayType) -> UIImage? {
        let iconWidth: CGFloat = 22
        switch type {
            case .cycleSuperHighways: return UIImage(named: "SuperCycleHighway")
            case .bikeServiceStations: return UIImage(named: "serviceStation")
            case .harborRing, .greenPaths:
                guard let annotations = self.annotationOfType(type) else {
                    return poPathOverlayIconImage(width: iconWidth, color: UIColor.gray)
                }
                return poPathOverlayIconImage(width: iconWidth, color: annotations.color)
        }
    }
    
    func isOverlaySelected(_ type: OverlayType) -> Bool {
        switch type {
            case .cycleSuperHighways: return Settings.sharedInstance.overlays.showCycleSuperHighways
            case .bikeServiceStations: return Settings.sharedInstance.overlays.showBikeServiceStations
            case .harborRing: return Settings.sharedInstance.overlays.showHarborRing
            case .greenPaths: return Settings.sharedInstance.overlays.showGreenPaths
        }
    }
    
    func selectOverlay(_ selected: Bool, type: OverlayType) {
        switch type {
            case .cycleSuperHighways: Settings.sharedInstance.overlays.showCycleSuperHighways = selected
            case .bikeServiceStations: Settings.sharedInstance.overlays.showBikeServiceStations = selected
            case .harborRing: Settings.sharedInstance.overlays.showHarborRing = selected
            case .greenPaths: Settings.sharedInstance.overlays.showGreenPaths = selected
        }
    }
    
    func updateAllOverlays() {
        self.cycleSuperHighwayAnnotations?.updateOverlay(self.mapView)
        self.bikeServiceAnnotations?.updateOverlay(self.mapView)
        self.harborRingAnnotations?.updateOverlay(self.mapView)
        self.greenPathsAnnotations?.updateOverlay(self.mapView)
    }
    
    fileprivate func updateAllAnnotations() {
        self.cycleSuperHighwayAnnotations?.updateAnnotations(self.mapView)
        self.bikeServiceAnnotations?.updateAnnotations(self.mapView)
        self.harborRingAnnotations?.updateAnnotations(self.mapView)
        self.greenPathsAnnotations?.updateAnnotations(self.mapView)
    }
    
    fileprivate func JSONFromFile(_ filename: String, fileExtension: String) -> JSON? {
        guard let filePath = Bundle.main.path(forResource: filename, ofType: fileExtension) else {
            return nil
        }
        guard let data = try? Data(contentsOf: URL(fileURLWithPath: filePath)) else {
            return nil
        }
        return JSON(data: data)
    }
}
