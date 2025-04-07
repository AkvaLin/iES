//
//  SettingsViewModel.swift
//  iES
//
//  Created by Никита Пивоваров on 01.10.2024.
//

import Foundation
import SwiftUI

class SettingsViewModel: ObservableObject {
    @Published var selectedLanguage: SettingsConstants.AppSettings.Language = .en
    @Published var selectedColorScheme: SettingsConstants.AppSettings.Theme = .light {
        didSet {
            // changeTheme()
            withAnimation {
                if selectedColorScheme != .dark,
                   selectedColorScheme != .light,
                   selectedColorScheme != .system {
                    isColorPickersShown = true
                } else {
                    isColorPickersShown = false
                }
            }
        }
    }
    @Published var customBackgroundColor: Color = .black
    @Published var customAccentColor: Color = .accent
    @Published var isColorPickersShown = false
    @Published var showYandexDiskAuth = false
    
    // MARK: - UserDefaults
    @AppStorage(Settings.Keys.metalFxEnabled)
    var metalFxEnabled: Bool = Settings.DefaultValues.defaultMetalFxEnabled
    @AppStorage(Settings.Keys.nearestNeighborRendering)
    var nearestNeighborRendering: Bool = Settings.DefaultValues.defaultNearestNeighborRendering
    @AppStorage(Settings.Keys.integerScaling)
    var integerScaling: Bool = Settings.DefaultValues.defaultIntegerScaling
    @AppStorage(Settings.Keys.audioEnabled)
    var enableAudio: Bool = Settings.DefaultValues.defaultAudioEnabled
    @AppStorage(Settings.Keys.audioFiltersEnabled)
    var audioFilter: Bool = Settings.DefaultValues.defaultAudioFiltersEnabled
    @AppStorage(Settings.Keys.sampleRate)
    var sampleRate: Int = Settings.DefaultValues.defaultSampleRate.rawValue
    @AppStorage(Settings.Keys.scanlines)
    var scanlines: Int = Int(Settings.DefaultValues.defaultScanlines.rawValue)
    @AppStorage(Settings.Keys.yandexDisk)
    var yandexDisk: Bool = Settings.DefaultValues.yandexDisk
    @AppStorage(Settings.Keys.googleDrive)
    var googleDrive: Bool = Settings.DefaultValues.googleDrive
    
    func changeTheme() {
        AppService.setColorScheme(colorScheme: .device)
    }
    
    func changeLanguage() {
        AppService.setLanguage(language: "")
    }
}
