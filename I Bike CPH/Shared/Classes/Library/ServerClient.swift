//
//  ServerClient.swift
//  I Bike CPH
//
//  Created by Tobias Due Munk on 20/08/15.
//  Copyright (c) 2015 I Bike CPH. All rights reserved.
//

import Foundation
import SwiftyJSON

private let bundleVersion = Bundle.main.object(forInfoDictionaryKey: String(kCFBundleVersionKey)) as! String
private let userAgent = "IBikeCPH/\(bundleVersion)/iOS"
private let apiDefaultAccept = ["Accept": "application/vnd.ibikecph.v1"]
private let apiUserAgent = ["User-Agent": userAgent]
private let apiDefaultHeaders = ["Content-Type": "application/json"]

class ServerClient: NSObject {
    let session: URLSession
    
    init(session: URLSession = URLSession.shared) {
        self.session = session
    }
    
    enum ServerResult {
        case successJSON(JSON, statusCode: Int)
        case failed(error: NSError)
        case failedNoData
        case failedNoPath
        case failedParsingError
        case failedEncodingError
        case failedNoSuccess
    }
    
    func request(_ path: String, configureRequest: ((NSMutableURLRequest) -> NSMutableURLRequest)? = nil, completion: @escaping (ServerResult) -> ()) {
        if let url = URL(string: path.stringByAddingUrlAuthToken()){
            var request = NSMutableURLRequest(url: url)
            request.addDefaultHeaders()
            if let configureRequest = configureRequest {
                request = configureRequest(request)
            }
            let task = session.dataTask(with: request as URLRequest, completionHandler: { data, response, error in
                if let error = error {
                    completion(.failed(error: error as NSError))
                    return
                }
                if let data = data {
                    var parsingError: NSError? = nil
                    let json = JSON(data: data, error: &parsingError)
                    if let error = parsingError {
                        completion(.failed(error: error as NSError))
                        return
                    }
                    let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 200
                    completion(.successJSON(json, statusCode: statusCode))
                    self.checkForInvalidToken(json)
                } else {
                    completion(.failedNoData)
                }
            }) 
            task.resume()
        } else {
            completion(.failedNoPath)
        }
    }
    
    func upload(_ data: Data, toPath path: String, configureRequest: ((NSMutableURLRequest) -> NSMutableURLRequest)? = nil, completion: @escaping (ServerResult) -> ()) {
        if let url = URL(string: path.stringByAddingUrlAuthToken()) {
            var request = NSMutableURLRequest(url: url)
            request.addDefaultHeaders()
            request.httpMethod = "POST"
            if let configureRequest = configureRequest {
                request = configureRequest(request)
            }
            let task = session.uploadTask(with: request as URLRequest, from: data, completionHandler: { data, response, error in
                if let error = error {
                    completion(.failed(error: error as NSError))
                    return
                }
                if let data = data {
                    var parsingError: NSError? = nil
                    let json = JSON(data: data, error: &parsingError)
                    if let error = parsingError {
                        completion(.failed(error: error))
                        return
                    }
                    let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 200
                    completion(.successJSON(json, statusCode: statusCode))
                    self.checkForInvalidToken(json)
                } else {
                    completion(.failedNoData)
                }
            }) 
            task.resume()
        } else {
            completion(.failedNoPath) 
        }
    }

    fileprivate func checkForInvalidToken(_ json: JSON) {
        if let invalidToken = json["invalid_token"].bool, invalidToken == true {
            UserHelper.logout()
            NotificationCenter.post("invalidToken")
        }
    }
}


extension NSMutableURLRequest {
    
    func addDefaultHeaders() {
        for (key, value) in apiDefaultHeaders {
            setValue(value, forHTTPHeaderField: key)
        }
        for (key, value) in apiDefaultAccept {
            setValue(value, forHTTPHeaderField: key)
        }
        for (key, value) in apiUserAgent {
            setValue(value, forHTTPHeaderField: key)
        }
    }
}


extension String {
    
    internal func stringByAddingUrlAuthToken() -> String {
        if let authToken = UserHelper.authToken() {
            return stringByAddingUrlParameters(["auth_token": authToken ])
        }
        return self
    }
    
     func stringByAddingUrlParameters(_ parameters: [String: String]) -> String {
        var newString = self
        for (key, value) in parameters {
// TODO: Use NSURLComponents to encode to components component-wiser instead
            if let string = value.addingPercentEncoding(withAllowedCharacters: NSCharacterSet.alphanumerics) {
                newString = stringByAddingUrlParameter(key, value: string)
            }
        }
        return newString
    }
    
    func stringByAddingUrlParameter(_ key: String, value: String) -> String {
        let first = !(self as NSString).contains("?")
        var newString = self
        newString += first ? "?" : "&"
        newString += key + "=" + value
        return newString
    }
}
