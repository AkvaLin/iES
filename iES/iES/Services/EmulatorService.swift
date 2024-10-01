//
//  EmulatorService.swift
//  iES
//
//  Created by Никита Пивоваров on 01.10.2024.
//

struct EmulatorService {
    
    struct EmulatorSettings {
        let audio: EmulatorAudioSettings
        let graphics: EmulatorGraphicsSettings
    }
    
    struct EmulatorAudioSettings {
        let volume: Double
        let rate: Double
    }
    
    struct EmulatorGraphicsSettings {
        
        struct Resolution {
            let width: Int
            let height: Int
        }
        
        let resolution: Resolution
    }
    
    static func loadSettings() throws -> EmulatorSettings {
        return .init(audio: .init(volume: 0.5, rate: 0.5), graphics: .init(resolution: .init(width: 640, height: 480)))
    }
    
    static func changeAudioSettings() {
        
    }
    
    static func changeGraphicsSettings() {
        
    }
}
