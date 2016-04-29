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
    
    let errorDomain = "facebook"
    let errorAccessNotAllowed = 3001
    
    private let accountStore = ACAccountStore()
    
    // Wrapper function for public method for Objective-C compatibility
    @objc public func request(completion: (identifier: NSString!, email: NSString!, token: NSString!, error: NSError!) -> ()) {
        let swiftCompletion: Completion = { (userInfo, error) in
            if let userInfo = userInfo {
                completion(identifier: userInfo.id, email: userInfo.email, token: userInfo.token, error: error)
            } else {
                completion(identifier: nil, email: nil, token: nil, error: error)
            }
        }
        self.request(swiftCompletion)
    }
    
    public func request(completion: Completion) {
        let options: [NSObject : AnyObject] = [
            ACFacebookAppIdKey as String : SMRouteSettings.sharedInstance().fb_app_id,
            ACFacebookPermissionsKey as String : ["email"]
        ]
        let accountType = accountStore.accountTypeWithAccountTypeIdentifier(ACAccountTypeIdentifierFacebook)
        accountStore.requestAccessToAccountsWithType(accountType, options: options) { (granted, error) -> Void in
            if !granted {
                let error = error ?? NSError(domain: self.errorDomain, code: self.errorAccessNotAllowed, userInfo:[NSLocalizedDescriptionKey : "Access to facebook is not allowed"])
                print("Facebook request access failed with error: \(error)")
                
                self.failed(error: error, completion: completion)
                return
            }
            
            print("Facebook granted access")
            if let account = self.accountStore.accountsWithAccountType(accountType).first as? ACAccount {
                print("Facebook has account")
                self.renewAccount(account, completion: completion)
                return
            }
            print("Facebook has no account")
        }
    }
    
    private func renewAccount(account: ACAccount, completion: Completion) {
        accountStore.renewCredentialsForAccount(account) {(result: ACAccountCredentialRenewResult, error) -> Void in
            
            switch result {
                case .Failed:
                    print("Facebook failed renew credentials for account: \(account)")
                    if let error = error {
                        print("...with error: \(error)")
                    }
                    self.failed(account, error: error, completion: completion)
                case .Rejected:
                    print("Facebook rejected renew credentials for account: \(account)")
                    if let error = error {
                        print("...with error: \(error)")
                    }
                    self.failed(account, error: error, completion: completion)
                case .Renewed:
                    print("Facebook renewed credentials for account: \(account)")
                    self.accountStore.saveAccount(account) { (success, error) -> Void in
                        if !success {
                            print("Facebook account save failed")
                            if let error = error {
                                print("... with error: \(error)")
                            }
                            self.failed(account, error: error, completion: completion)
                            return
                        }
                        print("Facebook account saved")
                        let token = account.credential.oauthToken
                        self.getInfoFromAccount(account, token: token, completion: completion)
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
        request.performRequestWithHandler { (data, response, error) -> Void in
            if let error = error {
                print("Facebook failed request with error \(error)")
                return
            }
            if response.statusCode != 200 {
                print("Facebook failed request with statuscode \(response.statusCode)")
                return
            }
            
            do {
                let userData = try NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions(rawValue: 0)) as? NSDictionary
                if userData != nil {
                    
                    self.succeededWithUserData(userData!, token: token, completion: completion)
                }
            } catch let error as NSError {
                print("Facebook failed request with no deserialized data")
                self.failed(account,  error: error, completion: completion)
                return
            }
        }
    }
    
    func succeededWithUserData(data: NSDictionary, token: String, completion: Completion) {
        print("Facebook succeeded with user data \(data)")
        if let
            userID = data["id"] as? String,
            email = data["email"] as? String
        {
            let user = UserInfo(id: userID, email: email, token: token)
            Async.main {
                completion(user, nil)
            }
            return
        }
        self.failed(error: nil, completion: completion)
    }
    
    
}
