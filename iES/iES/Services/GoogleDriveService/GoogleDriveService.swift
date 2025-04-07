////
////  GoogleDriveService.swift
////  iES
////
////  Created by Никита Пивоваров on 05.04.2025.
////
//
//import Foundation
//
//struct Config {
//    let clientID: String
//    let authScope: String
//    let redirectURI: String
//}
//

import Foundation
import GoogleDriveClient

enum GoogleDriveService {
    private static let config = Config(
        clientID: "<token>.apps.googleusercontent.com",
        authScope: "https://www.googleapis.com/auth/drive",
        redirectURI: "com.googleusercontent.apps.<token>://"
    )
    
    static let client: Client = .live(config: config)
    
    static func isSignedIn() async -> Bool {
        return await client.auth.isSignedIn()
    }
    
    static func save(model: Data, fileName: String) async {
        guard await isSignedIn() else { return }
        
        do {
            if let previousId = UserDefaults.standard.string(forKey: Settings.Keys.googleDrivePreviousId), !previousId.isEmpty {
                try await client.deleteFile.callAsFunction(fileId: previousId)
            }
            let newFile = try await client.createFile.callAsFunction(
                name: fileName,
                spaces: "drive",
                mimeType: "application/json",
                parents: [],
                data: model
            )
            UserDefaults.standard.set(newFile.id, forKey: Settings.Keys.googleDrivePreviousId)
        } catch {
            
        }
    }
    
    static func getFile(fileId: String) async -> Data? {
        do {
            var fileId = fileId
            if fileId.isEmpty {
                let files = try await client.listFiles.callAsFunction()
                guard let iesFile = files.files.first(where: { file in
                    file.name == "ies.json"
                }) else { return nil }
                fileId = iesFile.id
            }
            let fileData = try await client.getFileData.callAsFunction(fileId: fileId)
            return fileData
        } catch {
            print(error)
            return nil
        }
    }
    
    static func signIn() async {
        await client.auth.signIn()
    }
    
    static func signOut() async {
        await client.auth.signOut()
    }
    
    static func handleRedirect(url: URL) async {
        do {
            _ = try await client.auth.handleRedirect(url)
        } catch {
            print(error)
        }
    }
}
