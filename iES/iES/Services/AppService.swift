//
//  AppService.swift
//  iES
//
//  Created by Никита Пивоваров on 01.10.2024.
//

import SwiftUI

struct AppService {
    
    enum UIColorScheme {
        case light
        case dark
        case device
        case custom(Color, Color)
    }
    
    static func setColorScheme(colorScheme scheme: UIColorScheme) { }
    
    static func setLanguage(language: String) { }
    
    static func changeCloudSettings() { }
}
