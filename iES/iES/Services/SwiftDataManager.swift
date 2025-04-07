//
//  SwiftDataManager.swift
//  iES
//
//  Created by Никита Пивоваров on 07.04.2025.
//

import Foundation
import SwiftData

enum SwiftDataManager {
    static func insert<T>(_ model: T, context: ModelContext, completion: @escaping (Bool) -> Void) where T : PersistentModel {
        context.insert(model)
        performOnUpdate(context: context) { result in
            completion(result)
        }
    }
    
    static func delete<T>(_ model: T, context: ModelContext, completion: @escaping (Bool) -> Void) where T : PersistentModel {
        context.delete(model)
        performOnUpdate(context: context) { result in
            completion(result)
        }
    }
    
    static func updateLastActivity(profile: ProfileModel, lastActivity: String, context: ModelContext, completion: @escaping (Bool) -> Void) {
        profile.lastActivity = lastActivity
        performOnUpdate(context: context) { result in
            completion(result)
        }
    }
    
    static func updateLastTimePlayed(for game: GameModel, context: ModelContext, completion: @escaping (Bool) -> Void) {
        game.lastTimePlayed = .now
        performOnUpdate(context: context) { result in
            completion(result)
        }
    }
    
    static func performOnUpdate(context: ModelContext, completion: @escaping (Bool) -> Void) {
        do {
            let models = try getModels(context: context)
            try saveToCloud(profile: models.profile, games: models.games) { result in
                completion(result)
            }
        } catch {
            print(error)
            completion(false)
        }
    }
    
    private static func saveToCloud(profile: ProfileModel, games: [GameModel], completion: @escaping (Bool) -> Void) throws {
        Task {
            let codableData = try CloudServiceConverter.getCodableData(profile: profile, games: games)
            await CloudService.save(model: codableData)
            completion(true)
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
