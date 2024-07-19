//
//  Item.swift
//  simple-pwd-generator
//
//  Created by Eli Selkin on 7/19/24.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
