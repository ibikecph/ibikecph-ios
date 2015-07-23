//
//  UserTermsClient.swift
//  I Bike CPH
//
//  Created by Tobias Due Munk on 22/07/15.
//  Copyright (c) 2015 I Bike CPH. All rights reserved.
//

import Foundation

class UserTermsClient {
    static let instance = UserTermsClient()
    
    private let baseUrl = "http://kodekode.dk/ibikecph-terms.json"
    
    private let latestVerifiedVersionKey = "UserTermsLatestVerifiedVersionKey"
    var latestVerifiedVersion: Int? {
        get { return Defaults[latestVerifiedVersionKey].int }
        set { Defaults[latestVerifiedVersionKey] = newValue }
    }
    
    enum Result {
        case SuccessUserTerms(UserTerms, new: Bool)
        case SuccessJSON(JSON)
        case Failed(error: NSError)
        case FailedNoData
        case FailedNoPath
        case FailedParsingError
    }
    
    func requestUserTerms(completion: (Result) -> ()) {
        let path = baseUrl
        request(path) { result in
            switch result {
                case .SuccessJSON(let json):
                    if let userTerms = UserTerms(json: json) {
                        let newVersion = userTerms.version
                        let currentVersion = UserTermsClient.instance.latestVerifiedVersion
                        let new = newVersion > currentVersion
                        completion(.SuccessUserTerms(userTerms, new: new))
                    } else {
                        completion(.FailedParsingError)
                    }
                default: completion(result)
            }
        }
    }
    
    private func request(path: String, completion: (Result) -> ()) {
        if let url = NSURL(string: path){
            let task = NSURLSession.sharedSession().dataTaskWithURL(url) { data, response, error in
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
                    completion(.SuccessJSON(json))
                } else {
                    completion(.FailedNoData)
                }
            }
            task.resume()
        } else {
            completion(.FailedNoPath)
        }
    }
}