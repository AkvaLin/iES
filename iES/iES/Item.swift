//
//  Item.swift
//  iES
//
//  Created by Никита Пивоваров on 21.05.2024.
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
