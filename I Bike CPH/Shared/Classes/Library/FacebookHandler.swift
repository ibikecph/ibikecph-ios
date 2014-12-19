//
//  Facebook.swift
//  I Bike CPH
//
//  Created by Tobias Due Munk on 18/12/14.
//  Copyright (c) 2014 I Bike CPH. All rights reserved.
//

import Foundation
import Accounts
import Social




@objc public class FacebookHandler: NSObject {
    public typealias Completion = (UserInfo?, NSError?) -> ()
    
    public struct UserInfo {
        let id: String
        let email: String
        let token: String
    }
    
    private let accountStore = ACAccountStore()
    
    // Wrapper function for public method for Objective-C compatibility
    @objc public func request(completion: (identifier: NSString!, email: NSString!, token: NSString!, error: NSError) -> ()) {
        let swiftCompletion: Completion = { (userInfo, error) in
            if let userInfo = userInfo {
                completion(identifier: userInfo.id, email: userInfo.email, token: userInfo.token, error: error!)
            } else {
                completion(identifier: nil, email: nil, token: nil, error: error!)
            }
        }
        self.request(swiftCompletion)
    }
    
    public func request(completion: Completion) {
        let options = [
            ACFacebookAppIdKey as String : SMRouteSettings.sharedInstance().fb_app_id,
            ACFacebookPermissionsKey as String : ["email"]
        ]
        let accountType = accountStore.accountTypeWithAccountTypeIdentifier(ACAccountTypeIdentifierFacebook)
        accountStore.requestAccessToAccountsWithType(accountType, options: options) { [weak self] (granted, error) -> Void in
            if !granted {
                print("Facebook request access failed")
                if let error = error {
                    println("... with error: \(error)")
                }
                self?.failed(completion: completion)
                return
            }
            println("Facebook granted access")
            if let account = self?.accountStore.accountsWithAccountType(accountType).first as? ACAccount {
                let facebookCredential = account.credential
                let accessToken = facebookCredential.oauthToken // TODO: Verify that this token is the correct one to use
                self?.renewAccount(account, token: accessToken, completion: completion)
                return
            }
            print("Facebook has account")
        }
    }
    
    private func renewAccount(account: ACAccount, token: String, completion: Completion) {
        accountStore.renewCredentialsForAccount(account) { [weak self] (result: ACAccountCredentialRenewResult, error) -> Void in
            
            switch result {
            case .Failed:
                print("Facebook failed renew credentials for account: \(account)")
                if let error = error {
                    println("...with error: \(error)")
                    self?.failed(account: account, error: error, completion: completion)
                    return
                }
                self?.failed(account: account, completion: completion)
            case .Rejected:
                print("Facebook rejected renew credentials for account: \(account)")
                if let error = error {
                    println("...with error: \(error)")
                    self?.failed(account: account, error: error, completion: completion)
                    return
                }
                self?.failed(account: account, completion: completion)
            case .Renewed:
                println("Facebook renewed credentials for account: \(account)")
                self?.accountStore.saveAccount(account) { (success, error) -> Void in
                    if !success {
                        print("Facebook account save failed")
                        if let error = error {
                            println("... with error: \(error)")
                            self?.failed(account: account, error: error, completion: completion)
                            return
                        }
                        self?.failed(account: account, completion: completion)
                        return
                    }
                    println("Facebook account saved")
                    self?.getInfoFromAccount(account, token: token, completion: completion)
                }
            }
        }
    }
    
    private func failed(account: ACAccount? = nil, error: NSError? = nil, completion: Completion) {
        Async.main {
            completion(nil, error)
        }
    }
    
    private func getInfoFromAccount(account: ACAccount, token: String, completion: Completion) {
        let url = NSURL(string: "https://graph.facebook.com/me")
        let request = SLRequest(forServiceType: SLServiceTypeFacebook, requestMethod: .GET, URL: url, parameters: nil)
        request.account = account
        request.performRequestWithHandler { [weak self] (data, response, error) -> Void in
            if let error = error {
                println("Facebook failed request with error \(error)")
                return
            }
            if response.statusCode != 200 {
                println("Facebook failed request with statuscode \(response.statusCode)")
                return
            }
            var deserializationError: NSError?
            if let userData = NSJSONSerialization.JSONObjectWithData(data, options: nil, error: &deserializationError) as? NSDictionary {
                if let deserializationError = deserializationError {
                    self?.failed(account: account, completion: completion)
                    return
                }
                self?.succeededWithUserData(userData, token: token, completion: completion)
            } else {
                println("Facebook failed request with no deserialized data")
            }
        }
    }
    
    func succeededWithUserData(data: NSDictionary, token: String, completion: Completion) {
        println("Facebook succeeded with user data \(data)")
        if let userID = data["id"] as? String {
            if let email = data["email"] as? String {
                let user = UserInfo(id: userID, email: email, token: token)
                Async.main {
                    completion(user, nil)
                }
                return
            }
//            if let firstName = data["first_name"] {
//                if let lastName = data["lastName"] {
//                    
//                }
//            }
        }
        self.failed(error: nil, completion: completion)
    }
    
    
}
