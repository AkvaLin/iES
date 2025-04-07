//
//  ProfileModel.swift
//  iES
//
//  Created by Никита Пивоваров on 28.03.2025.
//

import Foundation
import SwiftData

@Model
class ProfileModel {
    var name: String
    @Attribute(.externalStorage) var profileImageData: Data?
    var lastActivity: String?
    var timePlayed: [String: TimeInterval]
    var accountRegisterDate: Date
    
    init(
        name: String,
        profileImageData: Data? = nil,
        lastActivity: String? = nil,
        timePlayed: [String : TimeInterval] = [:],
        accountRegisterDate: Date = .now
    ) {
        self.name = name
        self.profileImageData = profileImageData
        self.lastActivity = lastActivity
        self.timePlayed = timePlayed
        self.accountRegisterDate = accountRegisterDate
    }
}
