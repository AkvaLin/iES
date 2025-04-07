//
//  GoogleDriveService.swift
//  iES
//
//  Created by Никита Пивоваров on 05.04.2025.
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
            if let previousId = try await getId() {
                try await client.deleteFile.callAsFunction(fileId: previousId)
            }
            _ = try await client.createFile.callAsFunction(
                name: fileName,
                spaces: "drive",
                mimeType: "application/json",
                parents: [],
                data: model
            )
        } catch {
            
        }
    }
    
    static func getFile() async -> Data? {
        do {
            guard let fileId = try await getId() else { return nil }
            let fileData = try await client.getFileData.callAsFunction(fileId: fileId)
            return fileData
        } catch {
            print(error)
            return nil
        }
    }
    
    static func signIn() async -> Bool {
        await client.auth.signIn()
        return await client.auth.isSignedIn()
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
    
    private static func getId() async throws -> String? {
        let files = try await client.listFiles.callAsFunction()
        guard let iesFile = files.files.first(where: { file in
            file.name == "ies.json"
        }) else { return nil }
        return iesFile.id
    }
}
