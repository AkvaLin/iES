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
        .init(title: "Mario", icon: Image(systemName: "printer.dotmatrix.filled.and.paper")),
        .init(title: "kjsdakfjnas;kdgnjklasndgljkadfnlgkjnskdgnlaksd", icon: Image(systemName: "printer.dotmatrix.filled.and.paper")),
        .init(title: "ksandmfkj nsakl nsakdjln flkasnd fkjasnd lkfna slkdnf kjlasdnfkl jnasdlk fn ahbsdfkjhg kas gdfjkhg ashjkdf gasgdfjhk gasjkhdf gahjksdvg fjkgasdjhkf gajshkg fdjkhasg dkfhjgas jkdfg asgdf gjhdfsag ", icon: Image(systemName: "printer.dotmatrix.filled.and.paper")),
        .init(title: "Game", icon: Image(systemName: "printer.dotmatrix.filled.and.paper")),
        .init(title: "Game", icon: Image(systemName: "printer.dotmatrix.filled.and.paper")),
        .init(title: "Game", icon: Image(systemName: "printer.dotmatrix.filled.and.paper")),
        .init(title: "Game", icon: Image(systemName: "printer.dotmatrix.filled.and.paper")),
        .init(title: "Game", icon: Image(systemName: "printer.dotmatrix.filled.and.paper")),
        .init(title: "Game", icon: Image(systemName: "printer.dotmatrix.filled.and.paper")),
        .init(title: "Game", icon: Image(systemName: "printer.dotmatrix.filled.and.paper")),
        .init(title: "Game", icon: Image(systemName: "printer.dotmatrix.filled.and.paper")),
    ]
    @Published var modelToPresent: LibraryItemModel? = nil
    /// - warning: Always set the model to present first
    @Published var isDetailsPresented = false {
        willSet {
            if newValue, modelToPresent == nil {
                isDetailsPresented = false
            }
        }
        didSet {
            if oldValue {
                modelToPresent = nil
            }
        }
    }
    @Published var detailsViewOffset: CGSize = .init(width: 0, height: 500)
}
