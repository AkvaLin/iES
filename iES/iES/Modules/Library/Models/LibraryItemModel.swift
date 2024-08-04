//
//  LibraryItemModel.swift
//  iES
//
//  Created by Никита Пивоваров on 03.08.2024.
//

import Foundation
import SwiftUI

struct LibraryItemModel: Identifiable {
    let id = UUID()
    let title: String
    let icon: Image
}
