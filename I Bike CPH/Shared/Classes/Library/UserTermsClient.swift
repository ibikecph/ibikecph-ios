//
//  UserTermsClient.swift
//  I Bike CPH
//
//  Created by Tobias Due Munk on 22/07/15.
//  Copyright (c) 2015 I Bike CPH. All rights reserved.
//

import Foundation

class UserTermsClient: ServerClient {
    static let instance = UserTermsClient()
    
    private let baseUrl = API_SERVER + "/terms"
    
    private let latestVerifiedVersionKey = "UserTermsLatestVerifiedVersionKey"
    var latestVerifiedVersion: Int? {
        get { return Defaults[latestVerifiedVersionKey].int }
        set { Defaults[latestVerifiedVersionKey] = newValue }
    }
    
    enum Result {
        case Success(UserTerms, new: Bool)
        case Other(ServerResult)
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
                        completion(.Success(userTerms, new: new))
                    } else {
                        completion(.Other(ServerResult.FailedParsingError))
                    }
                default: completion(.Other(result))
            }
        }
    }
    
}