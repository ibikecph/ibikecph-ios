//
//  UserTerms.swift
//  I Bike CPH
//
//  Created by Tobias Due Munk on 22/07/15.
//  Copyright (c) 2015 I Bike CPH. All rights reserved.
//

import Foundation
import SwiftyJSON

struct UserTerms {
    
    let url: URL? = URL(string: "accept_user_terms_link".localized)
    let version: Int
    let humanReadableText: String
    
    init?(json: JSON) {
        let language = UserDefaults.standard.array(forKey: "AppleLanguages")?.first as? String
        let humanReadableKey = "important_parts_description_" + (language == "da" ? "da" : "en")
        if let
            versionString = json["version"].string,
            let humanReadableText = json[humanReadableKey].string
        {
            self.version = Int(versionString) ?? 0
            self.humanReadableText = humanReadableText
            return
        }
        return nil
    }
}
