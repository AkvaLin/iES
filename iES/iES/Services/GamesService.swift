//
//  GameService.swift
//  iES
//
//  Created by Никита Пивоваров on 01.10.2024.
//

import Foundation
import SwiftData

actor GamesService {
    
    static var container = try? ModelContainer(for: GameModel.self)
    
    static func getDescriptor(limit: Int = 0) -> FetchDescriptor<GameModel> {
        var descriptor = FetchDescriptor<GameModel>(sortBy: [SortDescriptor(\.lastTimePlayed, order: .reverse)])
        descriptor.fetchLimit = limit
        return descriptor
    }
    
    static func updateLastTimePlayed(for game: GameModel) {
        game.lastTimePlayed = .now
    }
}

@Model
class GameModel {
    var title: String
    var imageData: Data?
    var lastTimePlayed: Date
    var gameData: Data
    var isAutoSaveEnabled: Bool
    var state: EmulatorState?
    
    init(title: String, imageData: Data? = nil, lastTimePlayed: Date, gameData: Data, isAutoSaveEnabled: Bool = false, state: EmulatorState? = nil) {
        self.title = title
        self.imageData = imageData
        self.lastTimePlayed = lastTimePlayed
        self.gameData = gameData
        self.isAutoSaveEnabled = isAutoSaveEnabled
        self.state = state
    }
}
