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
    
    fileprivate let baseUrl = SMRouteSettings.sharedInstance().api_base_url + "/terms"
    
    enum Result {
        case success(JSON)
        case other(ServerResult)
    }
    
    func requestOverlaysGeoJSON(_ filename: String, completion: @escaping (Result) -> ()) {
        let path = "http://assets.ibikecph.dk/geodata/" + filename + ".geojson"
        request(path) { result in
            switch result {
                case .successJSON(let json, _): completion(.success(json))
                default: completion(.other(result))
            }
        }
    }
    
}
