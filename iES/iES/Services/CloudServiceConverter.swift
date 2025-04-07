//
//  CloudServiceConverter.swift
//  iES
//
//  Created by Никита Пивоваров on 05.04.2025.
//

import Foundation
import SwiftData

enum CloudServiceConverter {
    static func getCodableData(profile: ProfileModel, games: [GameModel]) throws
        -> Data
    {
        let codableProfile = CloudServiceSaveModel.CloudServiceProfileModel(
            name: profile.name,
            profileImageData: profile.profileImageData,
            lastActivity: profile.lastActivity,
            timePlayed: profile.timePlayed,
            accountRegisterDate: profile.accountRegisterDate
        )
        let codableGames = games.map { game in
            let state: EmulatorState? =
                if let state = game.state {
                    EmulatorState(from: state)
                } else {
                    nil
                }

            return CloudServiceSaveModel.CloudServiceGameModel(
                id: game.id,
                title: game.title,
                imageData: game.imageData,
                lastTimePlayed: game.lastTimePlayed,
                gameData: game.gameData,
                isAutoSaveEnabled: game.isAutoSaveEnabled,
                state: state
            )
        }
        let codableSaveModel = CloudServiceSaveModel(
            profile: codableProfile, games: codableGames)

        do {
            return try JSONEncoder().encode(codableSaveModel)
        } catch {
            throw error
        }
    }

    static func getCodableStruct(data: Data) throws -> CloudServiceSaveModel {
        do {
            return try JSONDecoder().decode(
                CloudServiceSaveModel.self, from: data)
        } catch {
            throw error
        }
    }

    static func saveFromCodableStruct(
        _ data: CloudServiceSaveModel, context: ModelContext
    ) {
        let profile = data.profile
        ProfileService.updateProfile(
            name: profile.name,
            profileImageData: profile.profileImageData,
            lastActivity: profile.lastActivity,
            timePlayed: profile.timePlayed,
            accountRegisterDate: profile.accountRegisterDate,
            context: context
        )
        GamesService.updateGames(games: data.games, context: context)
    }
}

struct CloudServiceSaveModel: Codable {

    let profile: CloudServiceProfileModel
    let games: [CloudServiceGameModel]

    struct CloudServiceProfileModel: Codable {
        let name: String
        let profileImageData: Data?
        let lastActivity: String?
        let timePlayed: [String: TimeInterval]
        let accountRegisterDate: Date
    }

    struct CloudServiceGameModel: Codable {
        let id: UUID
        let title: String
        let imageData: Data?
        let lastTimePlayed: Date
        let gameData: Data
        let isAutoSaveEnabled: Bool
        let state: EmulatorState?
    }
}
