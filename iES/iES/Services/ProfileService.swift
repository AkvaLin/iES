//
//  ProfileService.swift
//  iES
//
//  Created by Никита Пивоваров on 05.04.2025.
//

import Foundation
import SwiftData

enum ProfileService {
    static func getProfile(context: ModelContext) -> ProfileModel {
        let descriptor = FetchDescriptor<ProfileModel>()
        let profiles = try? context.fetch(descriptor)
        
        if let profiles, let profile = profiles.first {
            return profile
        } else {
            let profile = ProfileModel(name: "Player", profileImageData: nil)
            context.insert(profile)
            return profile
        }
    }
    
    static func updateLastActivity(profile: ProfileModel, lastActivity: String, context: ModelContext) {
        SwiftDataManager.updateLastActivity(profile: profile, lastActivity: lastActivity, context: context) { _ in }
    }
    
    static func updateProfile(
        name: String,
        profileImageData: Data?,
        lastActivity: String?,
        timePlayed: [String: TimeInterval],
        accountRegisterDate: Date,
        context: ModelContext
    ) {
        let profile = getProfile(context: context)
        profile.name = name
        profile.profileImageData = profileImageData
        profile.lastActivity = lastActivity
        profile.timePlayed = timePlayed
        profile.accountRegisterDate = accountRegisterDate
    }
}
