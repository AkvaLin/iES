//
//  iESApp.swift
//  iES
//
//  Created by Никита Пивоваров on 21.05.2024.
//

import SwiftUI
import SwiftData

@main
struct iESApp: App {
    @StateObject var csManager = ColorSchemeManager()
    var body: some Scene {
        WindowGroup {
            HomeView()
                .environmentObject(csManager)
                .onAppear {
                    Settings.registerDefaultsIfNeeded()
                    csManager.applyColorScheme()
                }
        }
        .modelContainer(for: [GameModel.self, ProfileModel.self])
    }
}
