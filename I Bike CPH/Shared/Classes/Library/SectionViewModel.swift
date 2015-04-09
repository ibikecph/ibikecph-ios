//
//  SectionViewModel.swift
//  I Bike CPH
//
//  Created by Tobias Due Munk on 09/04/15.
//  Copyright (c) 2015 I Bike CPH. All rights reserved.
//

import Foundation

struct SectionViewModel<T> {
    let title: String?
    let footer: String?
    let items: [T]
    
    init(title: String? = nil, footer: String? = nil, items: [T]) {
        self.title = title
        self.footer = footer
        self.items = items
    }
}