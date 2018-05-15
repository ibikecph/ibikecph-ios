//
//  UserTermsClient.swift
//  I Bike CPH
//
//  Created by Tobias Due Munk on 22/07/15.
//  Copyright (c) 2015 I Bike CPH. All rights reserved.
//

import Foundation
import SwiftyUserDefaults
// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}

// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func > <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l > r
  default:
    return rhs < lhs
  }
}


class UserTermsClient: ServerClient {
    static let instance = UserTermsClient()
    
    fileprivate let baseUrl = SMRouteSettings.sharedInstance().api_base_url + "/terms"
    
    fileprivate let latestVerifiedVersionKey = "UserTermsLatestVerifiedVersionKey"
    var latestVerifiedVersion: Int? {
        get { return Defaults[latestVerifiedVersionKey].int }
        set { Defaults[latestVerifiedVersionKey] = newValue }
    }
    
    enum Result {
        case success(UserTerms, new: Bool)
        case other(ServerResult)
    }
    
    func requestUserTerms(_ completion: @escaping (Result) -> ()) {
        let path = baseUrl
        request(path) { result in
            switch result {
                case .successJSON(let json, _):
                    if let userTerms = UserTerms(json: json) {
                        let newVersion = userTerms.version
                        let currentVersion = UserTermsClient.instance.latestVerifiedVersion
                        let new = newVersion > currentVersion
                        completion(.success(userTerms, new: new))
                    } else {
                        completion(.other(ServerResult.failedParsingError))
                    }
                default: completion(.other(result))
            }
        }
    }
    
}
