//
//  LibraryViewModel.swift
//  iES
//
//  Created by Никита Пивоваров on 03.08.2024.
//

import Foundation
import SwiftUI

class LibraryViewModel: ObservableObject {
    
    @Published var modelToPresent: GameModel? = nil
    /// - warning: Always set the model to present first
    @Published var isDetailsPresented = false {
        willSet {
            if newValue, modelToPresent == nil {
                isDetailsPresented = false
            }
        }
    }
    @Published var detailsViewOffset: CGSize = .init(width: 0, height: 500)
    @Published var sortBy: SortType = .name
    @Published var showDeleteAlert = false
    @Published var modelToDelete: GameModel? = nil
}

extension LibraryViewModel {
    enum SortType {
        case name
        case dateAdded
        case datePlayed
    }
}
