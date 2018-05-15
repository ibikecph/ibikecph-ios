//
//  UITableView.swift
//  I Bike CPH
//
//  Created by Tobias Due Munk on 09/04/15.
//  Copyright (c) 2015 I Bike CPH. All rights reserved.
//

import UIKit

extension UITableView {
    
    func cellWithIdentifier<T: UITableViewCell>(_ style: UITableViewCellStyle = .default, reuseIdentifier: String) -> T {
        return dequeueReusableCell(withIdentifier: reuseIdentifier) as? T ?? T(style: style, reuseIdentifier: reuseIdentifier)
    }
    
    func cellWithIdentifier<T: UITableViewCell>(_ identifier: String, forIndexPath indexPath: IndexPath, fallbackStyle style: UITableViewCellStyle = .default) -> T {
        if let cell = dequeueReusableCell(withIdentifier: identifier, for: indexPath) as? T {
            return cell
        }
        return T(style: style, reuseIdentifier: identifier)
    }
}
