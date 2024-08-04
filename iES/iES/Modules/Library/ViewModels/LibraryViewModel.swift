//
//  LibraryViewModel.swift
//  iES
//
//  Created by Никита Пивоваров on 03.08.2024.
//

import Foundation
import SwiftUI

class LibraryViewModel: ObservableObject {
    
    @Published var games: [LibraryItemModel] = [
        .init(title: "Game", icon: Image(systemName: "printer.dotmatrix.filled.and.paper")),
        .init(title: "Game", icon: Image(systemName: "printer.dotmatrix.filled.and.paper")),
        .init(title: "Game", icon: Image(systemName: "printer.dotmatrix.filled.and.paper")),
        .init(title: "Game", icon: Image(systemName: "printer.dotmatrix.filled.and.paper")),
        .init(title: "Game", icon: Image(systemName: "printer.dotmatrix.filled.and.paper")),
        .init(title: "Game", icon: Image(systemName: "printer.dotmatrix.filled.and.paper")),
        .init(title: "Game", icon: Image(systemName: "printer.dotmatrix.filled.and.paper")),
        .init(title: "Game", icon: Image(systemName: "printer.dotmatrix.filled.and.paper")),
        .init(title: "Game", icon: Image(systemName: "printer.dotmatrix.filled.and.paper")),
        .init(title: "Game", icon: Image(systemName: "printer.dotmatrix.filled.and.paper")),
        .init(title: "Game", icon: Image(systemName: "printer.dotmatrix.filled.and.paper")),
    ]
}
