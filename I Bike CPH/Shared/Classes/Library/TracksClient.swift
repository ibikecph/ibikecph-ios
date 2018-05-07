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
    
    fileprivate let baseUrl = SMRouteSettings.sharedInstance().api_base_url
    
    enum UploadResult {
        case success(trackServerId: String)
        case other(ServerResult)
    }
    
    enum Result {
        case success
        case other(ServerResult)
    }
    
    enum DeleteResult {
        case success
        case notAuthorized
        case notFound
        case other(ServerResult)
    }
    
    func upload(_ track: Track, completion: @escaping (UploadResult) -> ()) {
        let path = baseUrl! + "/tracks"
        guard let serverUpload = track.jsonForServerUpload() else {
            completion(.other(ServerResult.failed(error: NSError(domain: "No JSON for server upload.", code: 0, userInfo: nil))))
            return
        }
        do {
            let data = try serverUpload.rawData()
            upload(data, toPath: path, configureRequest: { theRequest in
                theRequest.allowsCellularAccess = false
                return theRequest
            }) { result in
                switch result {
                    case .successJSON(let json, _):
                        if let serverId = json["data"]["id"].int {
                            completion(.success(trackServerId: String(serverId)))
                        } else {
                            completion(.other(ServerResult.failedParsingError))
                        }
                    default: completion(.other(result))
                }
            }
            return
        } catch let error as NSError {
            completion(.other(ServerResult.failed(error: error)))
            return
        }
//        completion(.Other(ServerResult.FailedEncodingError))
    }
    
    
    func delete(_ track: Track, completion: @escaping (DeleteResult) -> ()) {
        let serverId = track.serverId
        if serverId == "" {
            completion(.other(ServerResult.failedEncodingError))
            return
        }
        let path = baseUrl! + "/tracks/" + serverId
        
        guard let trackToken = UserHelper.trackToken() else {
            completion(.other(ServerResult.failedEncodingError))
            return
        }
        do {
            let data = try JSON(["signature" : trackToken]).rawData()
            request(path, configureRequest: { theRequest in
                theRequest.httpMethod = "DELETE"
                theRequest.httpBody = data
                return theRequest
            }) { result in
                switch result {
                    case .successJSON(let json, let statusCode):
                        if let success = json["success"].bool {
                            if success {
                                completion(.success)
                            } else if statusCode == 404 {
                                completion(.notFound)
                            } else if statusCode == 401 {
                                completion(.notAuthorized)
                            } else {
                                completion(.other(ServerResult.failedNoSuccess))
                            }
                        } else {
                            completion(.other(ServerResult.failedNoSuccess))
                        }
                    default: completion(.other(result))
                }
                return
            }
            return
        } catch let error as NSError {
            completion(.other(ServerResult.failed(error: error)))
            return
        }
    }
}

