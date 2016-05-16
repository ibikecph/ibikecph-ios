//
//  Overlays.swift
//  I Bike CPH
//
//  Created by Tobias Due Munk on 08/01/15.
//  Copyright (c) 2015 I Bike CPH. All rights reserved.
//

import Foundation
import SwiftyJSON
import SwiftHEXColors

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
    
    var menuIcon: UIImage? {
        let name: String = {
            switch self {
                case .CycleSuperHighways: return "SuperCycleHighway"
                case .BikeServiceStations: return "serviceStation"
                case .HarborRing: return "serviceStation"
                case .GreenPaths: return "serviceStation"
            }
        }()
        return UIImage(named: name)
    }
}

class Overlays {
    struct OverlayAnnotations {
        var locations = [[CLLocation]]()
        var colors = [UIColor]()
        var annotations = [Annotation]()
        var type: OverlayType
        
        init(type: OverlayType) {
            self.type = type
        }
        
//        mutating func updateAnnotations(mapView: MapView?) {
//            self.annotations.removeAll()
//            guard let mv = mapView else {
//                return
//            }
//            switch self.type {
//            case .CycleSuperHighways:
//            case .BikeServiceStations:
//            case .HarborRing:
//                if let json = self.JSONFromFile("harbor_ring", fileExtension: "geojson") {
//                    self.setLocationsFromJSON(json)
//                    self.setColorsFromJSON(json)
//                    self.setPathAnnotations(mv)
//                }
//                
//            case .GreenPaths:
//                if let json = self.JSONFromFile("green_paths", fileExtension: "geojson") {
//                    self.setLocationsFromJSON(json)
//                    self.setColorsFromJSON(json)
//                    self.setPathAnnotations(mv)
//                }
//                
//            }
//        }
        
        mutating func setPathAnnotations(mapView: MapView) {
            self.annotations = []
            if self.locations.count == self.colors.count {
                for (color, locations) in zip(self.colors, self.locations) {
                    let annotation = mapView.addPathWithLocations(locations, lineColor: color, lineWidth: 4.0)
                    self.annotations.append(annotation)
                }
            }
        }
        
        mutating func setLocationsFromJSON(json: JSON) {
            self.locations.removeAll()
            guard let features = json["features"].array else {
                return
            }
            for feature in features {
                guard let coordinates = feature["geometry", "coordinates"].array else {
                    continue
                }
                var featureLocations = [CLLocation]()
                for coordinate in coordinates {
                    if let longitude = coordinate[0].double, latitude = coordinate[1].double {
                        featureLocations.append(CLLocation(latitude: latitude, longitude: longitude))
                    }
                }
                self.locations.append(featureLocations)
            }
        }
        
        mutating func setColorsFromJSON(json: JSON) {
            self.colors.removeAll()
            guard let features = json["features"].array else {
                return
            }
            for feature in features {
                guard let colorString = feature["properties", "color"].string else {
                    continue
                }
                if let color = UIColor(hexString: colorString, alpha: 0.5) {
                    self.colors.append(color)
                }
            }
        }
        
        func JSONFromFile(filename: String, fileExtension: String) -> JSON? {
            guard let filePath = NSBundle.mainBundle().pathForResource(filename, ofType: fileExtension) else {
                return nil
            }
            guard let data = NSData(contentsOfFile: filePath) else {
                return nil
            }
            return JSON(data)
        }
    }
    
    private var cycleSuperHighwayAnnotations = OverlayAnnotations(type: .CycleSuperHighways)
    private var bikeServiceAnnotations = OverlayAnnotations(type: .BikeServiceStations)
    private var harborRingAnnotations = OverlayAnnotations(type: .HarborRing)
    private var greenPathsAnnotations = OverlayAnnotations(type: .GreenPaths)
    
    var mapView: MapView? {
        didSet {
            self.updateOverlays()
        }
    }
    
    func updateOverlays() {
        guard let mv = self.mapView else {
            return
        }
        
        let settings = Settings.sharedInstance
        
        // Show/hide Cycle Super Highways
        mv.removeAnnotations(self.cycleSuperHighwayAnnotations.annotations)
        if (settings.overlays.showCycleSuperHighways) {
            mv.addAnnotations(self.cycleSuperHighwayAnnotations.annotations)
        }

        // Show/hide Cycle Service Stations
        mv.removeAnnotations(self.bikeServiceAnnotations.annotations)
        if (settings.overlays.showBikeServiceStations) {
            mv.addAnnotations(self.bikeServiceAnnotations.annotations)
        }
        
        // Show/hide Harbor Ring
        mv.removeAnnotations(self.harborRingAnnotations.annotations)
        if (settings.overlays.showHarborRing) {
            mv.addAnnotations(self.harborRingAnnotations.annotations)
        }
        
        // Show/hide Green Paths
        mv.removeAnnotations(self.greenPathsAnnotations.annotations)
        if (settings.overlays.showGreenPaths) {
            mv.addAnnotations(self.greenPathsAnnotations.annotations)
        }

        mv.mapView.setZoom(mv.mapView.zoom + 0.0001, animated: false)
    }
    
    func updateAnnotations() {
        guard let mv = self.mapView else {
            return
        }
        self.cycleSuperHighwayAnnotations.setPathAnnotations(mv)
        self.bikeServiceAnnotations.setPathAnnotations(mv)
        self.harborRingAnnotations.setPathAnnotations(mv)
        self.greenPathsAnnotations.setPathAnnotations(mv)
    }
}