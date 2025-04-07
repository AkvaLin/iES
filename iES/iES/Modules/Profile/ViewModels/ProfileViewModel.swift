//
//  ProfileViewModel.swift
//  iES
//
//  Created by Никита Пивоваров on 01.10.2024.
//

import Foundation
import SwiftData

class ProfileViewModel: ObservableObject {
    @Published var nameTextFieldEnabled = false
    @Published var playerNameTextField: String = ""
    @Published var playerName: String = "" {
        didSet {
            model?.name = playerName
        }
    }
    @Published var imageData: Data? = nil {
        didSet {
            model?.profileImageData = imageData
            if let modelContext {
                isLoading = true
                SwiftDataManager.performOnUpdate(context: modelContext) { [weak self] _ in
                    self?.isLoading = false
                }
            }
        }
    }
    @Published var showProfileDataFetchError = false
    @Published var model: ProfileModel? = nil
    @Published var isLoading = false
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
    
    func saveName(context: ModelContext) {
        isLoading = true
        model?.name = playerNameTextField
        playerName = playerNameTextField
        SwiftDataManager.performOnUpdate(context: context) { [weak self] _ in
            self?.isLoading = false
        }
    }
    
    struct Statistic: Identifiable, Hashable {
        let id = UUID()
        let title: String
        let value: String
    }
}
