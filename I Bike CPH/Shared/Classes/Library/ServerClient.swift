//
//  ServerClient.swift
//  I Bike CPH
//
//  Created by Tobias Due Munk on 20/08/15.
//  Copyright (c) 2015 I Bike CPH. All rights reserved.
//

import Foundation

private let bundleVersion = NSBundle.mainBundle().objectForInfoDictionaryKey(String(kCFBundleVersionKey)) as! String
private let userAgent = "IBikeCPH/\(bundleVersion)/iOS"
private let apiDefaultAccept = ["Accept": "application/vnd.ibikecph.v1"]
private let apiUserAgent = ["User-Agent": userAgent]
private let apiDefaultHeaders = ["Content-Type": "application/json"]

class ServerClient {
    let session: NSURLSession
    
    init(session: NSURLSession = NSURLSession.sharedSession()) {
        self.session = session
    }
    
    enum ServerResult {
        case SuccessJSON(JSON, statusCode: Int)
        case Failed(error: NSError)
        case FailedNoData
        case FailedNoPath
        case FailedParsingError
        case FailedEncodingError
        case FailedNoSuccess
    }
    
    func request(path: String, configureRequest: (NSMutableURLRequest -> NSMutableURLRequest)? = nil, completion: (ServerResult) -> ()) {
        if let url = NSURL(string: path.stringByAddingUrlAuthToken()){
            var request = NSMutableURLRequest(URL: url)
            request.addDefaultHeaders()
            if let configureRequest = configureRequest {
                request = configureRequest(request)
            }
            let task = session.dataTaskWithRequest(request) { data, response, error in
                if let error = error {
                    completion(.Failed(error: error))
                    return
                }
                if let data = data {
                    var parsingError: NSError? = nil
                    let json = JSON(data: data, error: &parsingError)
                    if let error = parsingError {
                        completion(.Failed(error: error))
                        return
                    }
                    let statusCode = (response as? NSHTTPURLResponse)?.statusCode ?? 200
                    completion(.SuccessJSON(json, statusCode: statusCode))
                    self.checkForInvalidToken(json)
                } else {
                    completion(.FailedNoData)
                }
            }
            task.resume()
        } else {
            completion(.FailedNoPath)
        }
    }
    
    func upload(data: NSData, var toPath path: String, configureRequest: (NSMutableURLRequest -> NSMutableURLRequest)? = nil, completion: (ServerResult) -> ()) {
        if let url = NSURL(string: path.stringByAddingUrlAuthToken()) {
            var request = NSMutableURLRequest(URL: url)
            request.addDefaultHeaders()
            request.HTTPMethod = "POST"
            if let configureRequest = configureRequest {
                request = configureRequest(request)
            }
            let task = session.uploadTaskWithRequest(request, fromData: data) { data, response, error in
                if let error = error {
                    completion(.Failed(error: error))
                    return
                }
                if let data = data {
                    var parsingError: NSError? = nil
                    let json = JSON(data: data, error: &parsingError)
                    if let error = parsingError {
                        completion(.Failed(error: error))
                        return
                    }
                    let statusCode = (response as? NSHTTPURLResponse)?.statusCode ?? 200
                    completion(.SuccessJSON(json, statusCode: statusCode))
                    self.checkForInvalidToken(json)
                } else {
                    completion(.FailedNoData)
                }
            }
            task.resume()
        } else {
            completion(.FailedNoPath) 
        }
    }

    private func checkForInvalidToken(json: JSON) {
        if let invalidToken = json["invalid_token"].bool where invalidToken == true {
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
    
     func stringByAddingUrlParameters(parameters: [String: String]) -> String {
        var newString = self
        for (key, value) in parameters {
            if let string = value.stringByAddingPercentEscapesUsingEncoding(NSUTF8StringEncoding) {
                newString = stringByAddingUrlParameter(key: key, value: string)
            }
        }
        return newString
    }
    
    func stringByAddingUrlParameter(#key: String, value: String) -> String {
        let first = !(self as NSString).containsString("?")
        var newString = self
        newString += first ? "?" : "&"
        newString += key + "=" + value
        return newString
    }
}