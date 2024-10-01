//
//  SettingsViewModel.swift
//  iES
//
//  Created by Никита Пивоваров on 01.10.2024.
//

import Foundation

class SettingsViewModel: ObservableObject {
    
    func changeTheme() {
        AppService.setColorScheme(colorScheme: .device)
    }
    
    func changeLanguage() {
        AppService.setLanguage(language: "")
    }
    
    func changeGraphicsSettings() {
        EmulatorService.changeGraphicsSettings()
    }
    
    func changeAudioSettings() {
        EmulatorService.changeAudioSettings()
    }
}
