//
//  GameService.swift
//  iES
//
//  Created by Никита Пивоваров on 01.10.2024.
//

import Foundation

struct GamesService {
    
    struct GameModel {
        let title: String
        let description: String?
        let imageData: Data?
        let timePlayed: Int
        let isFavorite: Bool
        
        init(title: String, description: String, imageData: Data, timePlayed: Int, isFavorite: Bool) {
            self.title = title
            self.description = description
            self.imageData = imageData
            self.timePlayed = timePlayed
            self.isFavorite = isFavorite
        }
        
        init(isEmpty: Bool) {
            if isEmpty {
                self.title = ""
                self.description = ""
                self.imageData = nil
                self.timePlayed = 0
                self.isFavorite = false
            } else {
                self.title = "Game title"
                self.description = "Game description"
                self.imageData = Data()
                self.timePlayed = 0
                self.isFavorite = false
            }
        }
    }
    
    static func addGame() { }
    
    static func removeGame() { }
    
    static func getGames() -> [GameModel] {
        return [GameModel(isEmpty: false)]
    }
}
