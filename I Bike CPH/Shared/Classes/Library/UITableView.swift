//
//  UITableView.swift
//  I Bike CPH
//
//  Created by Tobias Due Munk on 09/04/15.
//  Copyright (c) 2015 I Bike CPH. All rights reserved.
//

import UIKit

extension UITableView {
    
    func cellWithIdentifier<T: UITableViewCell>(style: UITableViewCellStyle = .Default, reuseIdentifier: String) -> T {
        return dequeueReusableCellWithIdentifier(reuseIdentifier) as? T ?? T(style: style, reuseIdentifier: reuseIdentifier)
    }
    
    func cellWithIdentifier<T: UITableViewCell>(identifier: String, forIndexPath indexPath: NSIndexPath, fallbackStyle style: UITableViewCellStyle = .Default) -> T {
        if let cell = dequeueReusableCellWithIdentifier(identifier, forIndexPath: indexPath) as? T {
            return cell
        }
        return T(style: style, reuseIdentifier: identifier)
    }
}