//
//  AppService.swift
//  iES
//
//  Created by Никита Пивоваров on 01.10.2024.
//

import SwiftUI

struct AppService {
    
    enum UIColorScheme: Int {
        case device, light, dark
    }
    
    static func setColorScheme(colorScheme scheme: UIColorScheme) { }
    
    static func setLanguage(language: String) { }
    
    static func changeCloudSettings() { }
}

class ColorSchemeManager: ObservableObject {
    
    @AppStorage("colorScheme") var colorScheme: AppService.UIColorScheme = .device {
        didSet {
            applyColorScheme()
        }
    }
    
    var keyWindow: UIWindow? {
        guard let scene = UIApplication.shared.connectedScenes.first,
              let windowSceneDelegate = scene.delegate as? UIWindowSceneDelegate,
              let window = windowSceneDelegate.window else {
            return nil
        }
        return window
    }
    
    func applyColorScheme() {
        keyWindow?.overrideUserInterfaceStyle = UIUserInterfaceStyle(rawValue: colorScheme.rawValue) ?? .unspecified
    }
}
