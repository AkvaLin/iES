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
    var body: some Scene {
        WindowGroup {
            HomeView()
                .onAppear {
                    Settings.registerDefaultsIfNeeded()
                }
        }
        .modelContainer(for: [GameModel.self])
    }
}
