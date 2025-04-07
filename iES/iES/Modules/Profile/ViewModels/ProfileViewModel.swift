//
//  ProfileViewModel.swift
//  iES
//
//  Created by Никита Пивоваров on 01.10.2024.
//

import Foundation
import SwiftData

class ProfileViewModel: ObservableObject {
    @Published var playerName: String = "" {
        didSet {
            model?.name = playerName
        }
    }
    @Published var imageData: Data? = nil {
        didSet {
            model?.profileImageData = imageData
            if let modelContext {
                SwiftDataManager.performOnUpdate(context: modelContext)
            }
        }
    }
    @Published var showProfileDataFetchError = false
    @Published var model: ProfileModel? = nil
    private var modelContext: ModelContext?
    
    var playingTime: String {
        let duration: Duration = .seconds(model?.timePlayed.values.reduce(0, +) ?? 0)
        return duration.formatted(.time(pattern: .hourMinute))
    }
    var gamesPlayed: Int {
        model?.timePlayed.keys.count ?? 0
    }
    var accountAge: String {
        let formatter = RelativeDateTimeFormatter()
        return formatter.localizedString(for: model?.accountRegisterDate ?? .now, relativeTo: .now)
    }
    var lastActivity: String {
        model?.lastActivity ?? ""
    }
    var statistics: [Statistic] {
        guard let model else { return [] }
        return model.timePlayed.map { (key: String, value: TimeInterval) in
            return Statistic(
                title: key,
                value: Duration.seconds(value).formatted(.time(pattern: .hourMinute))
            )
        }
    }
    
    func onAppear(context: ModelContext) {
        guard let model else { return }
        playerName = model.name
        imageData = model.profileImageData
        self.model = model
        self.modelContext = context
    }
    
    struct Statistic: Identifiable, Hashable {
        let id = UUID()
        let title: String
        let value: String
    }
}
