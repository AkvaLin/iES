//
//  CloudService.swift
//  iES
//
//  Created by Никита Пивоваров on 05.04.2025.
//

import Foundation

enum CloudService {
    
    static func save(model: Data) async {
        if UserDefaults.standard.bool(forKey: Settings.Keys.yandexDisk),
           let token = KeychainManager.instance.getToken(forKey: Settings.Keys.yandexToken)
        {
            await YandexDiskService.save(model: model, token: token, fileName: "ies.json")
        }
        if UserDefaults.standard.bool(forKey: Settings.Keys.googleDrive) {
            await GoogleDriveService.save(model: model, fileName: "ies.json")
        }
    }
    
    static func load() async -> Data? {
        if UserDefaults.standard.bool(forKey: Settings.Keys.googleDrive)
        {
            let data = await GoogleDriveService.getFile()
            if data != nil {
                return data
            }
        }
        if UserDefaults.standard.bool(forKey: Settings.Keys.yandexDisk),
           let token = UserDefaults.standard.string(forKey: Settings.Keys.yandexToken)
        {
            let data = await YandexDiskService.getFile(token: token, fileName: "ies.json")
            if data != nil {
                return data
            }
        }
        return nil
    }
}
