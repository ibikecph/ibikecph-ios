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




@objc open class FacebookHandler: NSObject {
    public typealias Completion = (UserInfo?, NSError?) -> ()
    
    public struct UserInfo {
        let id: String
        let email: String
        let token: String
    }
    
    let errorDomain = "facebook"
    let errorAccessNotAllowed = 3001
    
    fileprivate let accountStore = ACAccountStore()
    
    // Wrapper function for public method for Objective-C compatibility
    @objc open func request(_ completion: @escaping (_ identifier: NSString?, _ email: NSString?, _ token: NSString?, _ error: NSError?) -> ()) {
        let swiftCompletion: Completion = { (userInfo, error) in
            if let userInfo = userInfo {
                completion(userInfo.id as NSString, userInfo.email as NSString, userInfo.token as NSString, error)
            } else {
                completion(nil, nil, nil, error)
            }
        }
        self.request(swiftCompletion)
    }
    
    open func request(_ completion: @escaping Completion) {
        let options: [AnyHashable: Any] = [
            ACFacebookAppIdKey as String : SMRouteSettings.sharedInstance().fb_app_id,
            ACFacebookPermissionsKey as String : ["email"]
        ]
        let accountType = accountStore.accountType(withAccountTypeIdentifier: ACAccountTypeIdentifierFacebook)
        accountStore.requestAccessToAccounts(with: accountType, options: options) { (granted, error) -> Void in
            if !granted {
                let error = error ?? NSError(domain: self.errorDomain, code: self.errorAccessNotAllowed, userInfo:[NSLocalizedDescriptionKey : "Access to facebook is not allowed"])
                print("Facebook request access failed with error: \(error)")
                
                self.failed(error: error as NSError, completion: completion)
                return
            }
            
            print("Facebook granted access")
            if let account = self.accountStore.accounts(with: accountType).first as? ACAccount {
                print("Facebook has account")
                self.renewAccount(account, completion: completion)
                return
            }
            print("Facebook has no account")
        }
    }
    
    fileprivate func renewAccount(_ account: ACAccount, completion: @escaping Completion) {
        accountStore.renewCredentials(for: account) {(result: ACAccountCredentialRenewResult, error) -> Void in
            
            switch result {
                case .failed:
                    print("Facebook failed renew credentials for account: \(account)")
                    if let error = error {
                        print("...with error: \(error)")
                    }
                    self.failed(account, error: error as! NSError, completion: completion)
                case .rejected:
                    print("Facebook rejected renew credentials for account: \(account)")
                    if let error = error {
                        print("...with error: \(error)")
                    }
                    self.failed(account, error: error as! NSError, completion: completion)
                case .renewed:
                    print("Facebook renewed credentials for account: \(account)")
                    self.accountStore.saveAccount(account) { (success, error) -> Void in
                        if !success {
                            print("Facebook account save failed")
                            if let error = error {
                                print("... with error: \(error)")
                            }
                            self.failed(account, error: error as! NSError, completion: completion)
                            return
                        }
                        print("Facebook account saved")
                        let token = account.credential.oauthToken
                        self.getInfoFromAccount(account, token: token!, completion: completion)
                    }
                }
        }
    }
    
    fileprivate func failed(_ account: ACAccount? = nil, error: NSError? = nil, completion: @escaping Completion) {
        Async.main {
            completion(nil, error)
        }
    }
    
    fileprivate func getInfoFromAccount(_ account: ACAccount, token: String, completion: @escaping Completion) {
        let url = URL(string: "https://graph.facebook.com/me")
        let request = SLRequest(forServiceType: SLServiceTypeFacebook, requestMethod: .GET, url: url, parameters: nil)
        request?.account = account
        request?.perform { (data, response, error) -> Void in
            if let error = error {
                print("Facebook failed request with error \(error)")
                return
            }
            if response?.statusCode != 200 {
                print("Facebook failed request with statuscode \(response?.statusCode)")
                return
            }
            
            do {
                let userData = try JSONSerialization.jsonObject(with: data!, options: JSONSerialization.ReadingOptions(rawValue: 0)) as? NSDictionary
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
    
    func succeededWithUserData(_ data: NSDictionary, token: String, completion: @escaping Completion) {
        print("Facebook succeeded with user data \(data)")
        if let
            userID = data["id"] as? String,
            let email = data["email"] as? String
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
