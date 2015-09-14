//
//  UserClient.swift
//  I Bike CPH
//
//  Created by Tobias Due Munk on 09/09/15.
//  Copyright (c) 2015 I Bike CPH. All rights reserved.
//

import UIKit

class UserClient: ServerClient {
    static let instance = UserClient()
    
    private let baseUrl = API_SERVER
    
    enum HasTokenResult {
        case Success(hasToken: Bool)
        case Other(ServerResult)
    }
    
    enum UserResult {
        case Success(name: String, imageUrl: UIImage?)
        case Other(ServerResult)
    }
    
    enum Result {
        case Success()
        case Other(ServerResult)
    }
    
    func hasTrackToken(completion: (HasTokenResult) -> ()) {
        let path = baseUrl + "/users/has_password"
        var error: NSError?
        
        request(path, configureRequest: { theRequest in
            theRequest.HTTPMethod = "POST"
            return theRequest
        }) { result in
            Async.main {
                switch result {
                case .SuccessJSON(let json):
                    if let hasToken = json["has_password"].bool {
                        completion(.Success(hasToken: hasToken))
                    } else {
                        completion(.Other(ServerResult.FailedNoSuccess))
                    }
                default: completion(.Other(result))
                }
            }
        }
    }
    
    func addTrackToken(token: String, completion: (Result) -> ()) {
        let path = baseUrl + "/users/add_password"
        
        let json: JSON = [ "user" : ["password" : token]]
        var error: NSError?
        if let data = json.rawData(error: &error)
        {
            request(path, configureRequest: { theRequest in
                theRequest.HTTPBody = data
                theRequest.HTTPMethod = "POST"
                return theRequest
            }) { result in
                Async.main {
                    switch result {
                    case .SuccessJSON(let json):
                        if let trackToken = json["data"]["signature"].string {
                            AppHelper.delegate()?.appSettings["signature"] = trackToken
                            completion(.Success())
                        } else {
                            completion(.Other(ServerResult.FailedNoSuccess))
                        }
                    default: completion(.Other(result))
                    }
                }
            }
            return
        }
        if let error = error {
            completion(.Other(ServerResult.Failed(error: error)))
            return
        }
        completion(.Other(ServerResult.FailedEncodingError))
    }
    
    func userData(completion: (UserResult) -> ()) {
        if let id = UserHelper.id() {
            let path = baseUrl + "/users/" + id
            request(path) { result in
                switch result {
                case .SuccessJSON(let json):
                    if let name = json["data"]["name"].string {
                        let image: UIImage? = {
                            if let string = json["data"]["image_url"].string,
                                url = NSURL(string: string),
                                data = NSData(contentsOfURL: url),
                                image = UIImage(data: data) {
                                    return image
                            }
                            return nil
                        }()
                        Async.main { completion(.Success(name: name, imageUrl: image)) }
                    } else {
                        Async.main { completion(.Other(ServerResult.FailedNoSuccess)) }
                    }
                default: Async.main { completion(.Other(result)) }
                }
                return
            }
            return
        }
        completion(.Other(ServerResult.FailedEncodingError))
    }
}
