//
//  OverlaysClient.swift
//  I Bike CPH
//
//  Created by Troels Michael Trebbien on 17/05/16.
//  Copyright © 2016 I Bike CPH. All rights reserved.
//

import Foundation
import SwiftyJSON

class OverlaysClient: ServerClient {
    static let sharedInstance = OverlaysClient()
    
    private let baseUrl = SMRouteSettings.sharedInstance().api_base_url + "/terms"
    
    enum Result {
        case Success(JSON)
        case Other(ServerResult)
    }
    
    func requestOverlaysGeoJSON(filename: String, completion: (Result) -> ()) {
        let path = "http://assets.ibikecph.dk/geodata/" + filename + ".geojson"
        request(path) { result in
            switch result {
                case .SuccessJSON(let json, _): completion(.Success(json))
                default: completion(.Other(result))
            }
        }
    }
    
}