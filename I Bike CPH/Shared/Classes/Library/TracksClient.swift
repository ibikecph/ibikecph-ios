//
//  TracksClient.swift
//  I Bike CPH
//
//  Created by Tobias Due Munk on 20/08/15.
//  Copyright (c) 2015 I Bike CPH. All rights reserved.
//

import Foundation
import SwiftyJSON

class TracksClient: ServerClient {
    static let sharedInstance = TracksClient()
    
    private let baseUrl = SMRouteSettings.sharedInstance().api_base_url
    
    enum UploadResult {
        case Success(trackServerId: String)
        case Other(ServerResult)
    }
    
    enum Result {
        case Success
        case Other(ServerResult)
    }
    
    enum DeleteResult {
        case Success
        case NotAuthorized
        case NotFound
        case Other(ServerResult)
    }
    
    func upload(track: Track, completion: (UploadResult) -> ()) {
        let path = baseUrl + "/tracks"
        guard let serverUpload = track.jsonForServerUpload() else {
            completion(.Other(ServerResult.Failed(error: NSError(domain: "No JSON for server upload.", code: 0, userInfo: nil))))
            return
        }
        do {
            let data = try serverUpload.rawData()
            upload(data, toPath: path, configureRequest: { theRequest in
                theRequest.allowsCellularAccess = false
                return theRequest
            }) { result in
                switch result {
                    case .SuccessJSON(let json, _):
                        if let serverId = json["data"]["id"].int {
                            completion(.Success(trackServerId: String(serverId)))
                        } else {
                            completion(.Other(ServerResult.FailedParsingError))
                        }
                    default: completion(.Other(result))
                }
            }
            return
        } catch let error as NSError {
            completion(.Other(ServerResult.Failed(error: error)))
            return
        }
        // Is this ever reached?!
        completion(.Other(ServerResult.FailedEncodingError))
    }
    
    
    func delete(track: Track, completion: (DeleteResult) -> ()) {
        let serverId = track.serverId
        if serverId == "" {
            completion(.Other(ServerResult.FailedEncodingError))
            return
        }
        let path = baseUrl + "/tracks/" + serverId
        var error: NSError?
        
        if let
            trackToken = UserHelper.trackToken(),
            data = JSON(["signature" : trackToken]).rawData(error: &error)
        {
            request(path, configureRequest: { theRequest in
                theRequest.HTTPMethod = "DELETE"
                theRequest.HTTPBody = data
                return theRequest
            }) { result in
                switch result {
                    case .SuccessJSON(let json, let statusCode):
                        if let success = json["success"].bool {
                            if success {
                                completion(.Success)
                            } else if statusCode == 404 {
                                completion(.NotFound)
                            } else if statusCode == 401 {
                                completion(.NotAuthorized)
                            } else {
                                completion(.Other(ServerResult.FailedNoSuccess))
                            }
                        } else {
                            completion(.Other(ServerResult.FailedNoSuccess))
                        }
                    default: completion(.Other(result))
                }
                return
            }
            return
        }
        if let error = error {
            completion(.Other(ServerResult.Failed(error: error)))
            return
        }
        completion(.Other(ServerResult.FailedEncodingError))
    }
}

