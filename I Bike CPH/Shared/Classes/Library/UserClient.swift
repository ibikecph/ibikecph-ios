//
//  UserClient.swift
//  I Bike CPH
//
//  Created by Tobias Due Munk on 09/09/15.
//  Copyright (c) 2015 I Bike CPH. All rights reserved.
//

import UIKit
import SwiftyJSON
import Async

class UserClient: ServerClient {
    static let instance = UserClient()
    
    fileprivate let baseUrl = SMRouteSettings.sharedInstance().api_base_url
    
    enum HasTokenResult {
        case success(hasToken: Bool)
        case other(ServerResult)
    }
    
    enum UserResult {
        case success(name: String, imageUrl: UIImage?)
        case other(ServerResult)
    }
    
    enum Result {
        case success()
        case other(ServerResult)
    }
    
    func hasTrackToken(_ completion: @escaping (HasTokenResult) -> ()) {
        let path = baseUrl! + "/users/has_password"
        
        request(path, configureRequest: { theRequest in
            theRequest.httpMethod = "POST"
            return theRequest
        }) { result in
            Async.main {
                switch result {
                case .successJSON(let json, _):
                    if let hasToken = json["has_password"].bool {
                        completion(.success(hasToken: hasToken))
                    } else {
                        completion(.other(ServerResult.failedNoSuccess))
                    }
                default: completion(.other(result))
                }
            }
            return
        }
    }
    
    func addTrackToken(_ token: String, completion: @escaping (Result) -> ()) {
        let path = baseUrl! + "/users/add_password"
        
        let json: JSON = [ "user" : ["password" : token]]
        do {
            let data = try json.rawData()
            request(path, configureRequest: { theRequest in
                theRequest.httpBody = data
                theRequest.httpMethod = "POST"
                return theRequest
            }) { result in
                Async.main {
                    switch result {
                    case .successJSON(let json, _):
                        if let trackToken = json["data"]["signature"].string {
                            AppHelper.delegate()?.appSettings["signature"] = trackToken
                            completion(.success())
                        } else {
                            completion(.other(ServerResult.failedNoSuccess))
                        }
                    default: completion(.other(result))
                    }
                }
                return
            }
            return
        } catch let error as NSError {
            completion(.other(ServerResult.failed(error: error)))
            return
        }
//        completion(.Other(ServerResult.FailedEncodingError))
    }
    
    func userData(_ completion: @escaping (UserResult) -> ()) {
        if let id = UserHelper.id() {
            let path = baseUrl! + "/users/" + id
            request(path) { result in
                switch result {
                case .successJSON(let json, _):
                    if let name = json["data"]["name"].string {
                        let image: UIImage? = {
                            if let string = json["data"]["image_url"].string,
                                let url = URL(string: string),
                                let data = try? Data(contentsOf: url),
                                let image = UIImage(data: data) {
                                    return image
                            }
                            return nil
                        }()
                        Async.main { completion(.success(name: name, imageUrl: image)) }
                    } else {
                        Async.main { completion(.other(ServerResult.failedNoSuccess)) }
                    }
                default: Async.main { completion(.other(result)) }
                }
                return
            }
            return
        }
        completion(.other(ServerResult.failedEncodingError))
    }
}

extension UserClient {
    @objc func hasTrackTokenObjc(_ completion: @escaping (_ success: Bool, _ error: NSError?) -> ()) {
        hasTrackToken { result in
            switch result {
            case .success(let hasToken): completion(hasToken, nil)
            case .other(let otherResult):
                switch otherResult {
                case .successJSON(let json, _):
                    let message = json["info"].stringValue
                    completion(false, error: NSError(domain: "UserClient", code: 0, userInfo: [NSLocalizedDescriptionKey : message]))
                case .failed(let error):
                    completion(false, error)
                default:
                    completion(false, NSError(domain: "UserClient", code: 0, userInfo: nil))
                }
            }
        }
    }
    
    class func sharedInstance() -> UserClient {
        return instance
    }
}
