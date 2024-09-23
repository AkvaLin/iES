//
//  LibraryItemModel.swift
//  iES
//
//  Created by Никита Пивоваров on 03.08.2024.
//

import Foundation
import SwiftUI

struct LibraryItemModel: Identifiable, Hashable, Equatable {
    let id = UUID()
    let title: String
    let icon: Image
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
