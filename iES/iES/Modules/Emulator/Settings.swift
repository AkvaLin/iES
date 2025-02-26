//
//  SettingsEnum.swift
//  iES
//
//  Created by Никита Пивоваров on 10.01.2025.
//


import Foundation

protocol SettingsEnum {
    var friendlyName: String { get }
    var storedValue: Any { get }
}

protocol SettingsProtocol {
    static func registerDefaultsIfNeeded()
}

enum Settings: SettingsProtocol {
    enum Keys {
        static let autoSave = "autoSave"
        static let loadLastSave = "loadLastSave"
        static let sampleRate = "sampleRate"
        static let audioEnabled = "audioEnabled"
        static let audioFiltersEnabled = "audioFiltersEnabled"
        static let audioSessionNotifyOthersOnDeactivation = "audioSessionNotifyOthersOnDeactivation"
        static let saveDataExists = "saveDataExists"
        static let nearestNeighborRendering = "nearestNeighborRendering"
        static let checkForRedundantFrames = "checkForRedundantFrames"
        static let integerScaling = "integerScaling"
        static let scanlines = "scanlines"
        static let metalFxEnabled = "metalFxEnabled"
    }
    
    enum DefaultValues {
        static let defaultSampleRate: SampleRate = SampleRate._22050Hz
        static let defaultAudioSessionNotifyOthersOnDeactivation = true
        static let defaultAudioEnabled: Bool = true
        static let defaultAudioFiltersEnabled: Bool = true
        static let defaultAutoSave: Bool = true
        static let defaultLoadLastSave: Bool = true
        static let defaultSaveDataExists: Bool = false
        static let defaultNearestNeighborRendering: Bool = true
        static let defaultCheckForRedundantFrames: Bool = false
        static let defaultIntegerScaling: Bool = false
        static let defaultScanlines: Scanlines = Scanlines.off
        static let defaultMetalFxEnabled: Bool = false
    }

    static func registerDefaultsIfNeeded() {
        UserDefaults.standard.register(defaults: [
            Keys.loadLastSave: DefaultValues.defaultLoadLastSave,
            Keys.autoSave: DefaultValues.defaultAutoSave,
            Keys.sampleRate: DefaultValues.defaultSampleRate.rawValue,
            Keys.audioEnabled: DefaultValues.defaultAudioEnabled,
            Keys.audioFiltersEnabled: DefaultValues.defaultAudioFiltersEnabled,
            Keys.audioSessionNotifyOthersOnDeactivation: DefaultValues.defaultAudioSessionNotifyOthersOnDeactivation,
            Keys.saveDataExists: DefaultValues.defaultSaveDataExists,
            Keys.nearestNeighborRendering: DefaultValues.defaultNearestNeighborRendering,
            Keys.checkForRedundantFrames: DefaultValues.defaultCheckForRedundantFrames,
            Keys.integerScaling: DefaultValues.defaultIntegerScaling,
            Keys.scanlines: Int(DefaultValues.defaultScanlines.rawValue)
        ])
    }
}
