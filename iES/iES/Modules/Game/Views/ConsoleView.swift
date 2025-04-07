//
//  MetalView.swift
//  iES
//
//  Created by Никита Пивоваров on 17.11.2024.
//

import SwiftUI
import Metal
import MetalKit


struct ConsoleView: UIViewControllerRepresentable {
    typealias UIViewControllerType = NesRomViewController
    
    private let gameModel: GameModel
    private let profileModel: ProfileModel
    @Environment(\.modelContext) var modelContext
    
    init(game: GameModel, profile: ProfileModel) {
        self.gameModel = game
        self.profileModel = profile
    }
    
    func makeUIViewController(context: Context) -> NesRomViewController {
        let vc = NesRomViewController()
        
        let cartridge = Cartridge(from: gameModel.gameData)
        vc.setup(cartridge: cartridge, gameModel: gameModel, profile: profileModel, modelContext: modelContext)
        
        return vc
    }
    
    func updateUIViewController(_ uiViewController: NesRomViewController, context: Context) {
        
    }
}
