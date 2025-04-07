//
//  SwiftDataManager.swift
//  iES
//
//  Created by Никита Пивоваров on 07.04.2025.
//

import Foundation
import SwiftData

enum SwiftDataManager {
    static func insert<T>(_ model: T, context: ModelContext) where T : PersistentModel {
        context.insert(model)
        performOnUpdate(context: context)
    }
    
    static func delete<T>(_ model: T, context: ModelContext) where T : PersistentModel {
        context.delete(model)
        performOnUpdate(context: context)
    }
    
    static func updateLastActivity(profile: ProfileModel, lastActivity: String, context: ModelContext) {
        profile.lastActivity = lastActivity
        performOnUpdate(context: context)
    }
    
    static func updateLastTimePlayed(for game: GameModel, context: ModelContext) {
        game.lastTimePlayed = .now
        performOnUpdate(context: context)
    }
    
    static func performOnUpdate(context: ModelContext) {
        do {
            let models = try getModels(context: context)
            try saveToCloud(profile: models.profile, games: models.games)
        } catch {
            print(error)
        }
    }
    
    private static func saveToCloud(profile: ProfileModel, games: [GameModel]) throws {
        Task {
            let codableData = try CloudServiceConverter.getCodableData(profile: profile, games: games)
            await CloudService.save(model: codableData)
        }
    }
    
    private static func getModels(context: ModelContext) throws -> (profile: ProfileModel, games: [GameModel]) {
        let profile = ProfileService.getProfile(context: context)
        do {
            let games = try context.fetch(GamesService.getDescriptor())
            return (profile: profile, games: games)
        } catch {
            throw error
        }
    }
}
