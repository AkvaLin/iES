//
//  SettingsConstants.swift
//  iES
//
//  Created by Никита Пивоваров on 11.10.2024.
//

import SwiftUI

enum SettingsConstants {
    enum AppSettings {
        enum Language: Hashable {
            case ru
            case en
        }
        enum Theme: Hashable {
            case light
            case dark
            case system
            /// custom color theme where first color -> background, second -> accent
            case custom(Color, Color)
        }
    }
}
